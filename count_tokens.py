#!/usr/bin/env python3
"""Count non-comment lines and tokens in pipeline files.

Metrics:
- Lines: Non-comment, non-blank lines
- Tokens: Space-separated tokens (including punctuation like = : , { } etc)
- WF Tokens: Tokens from workflow/orchestration files (the main pipeline definition)
- Task Tokens: Tokens from task/step definition files (individual task implementations)

File classification by language:
- CWL:   Workflow .cwl files = WF, CommandLineTool .cwl files = Task
- SWL:   .swl files = WF, .sh files = Task (shell scripts with # in/out/run annotations)
- Nextflow: Single .nf file = WF (process definitions = Task)
- WDL:   Single .wdl file = WF (tasks and workflow in same file)
- Python: Single .py file = WF (DSL defines both workflow and tasks)
- Nickel: Single .ncl file = WF (nickel functions define both)
- Nix:   Single .nix file = WF (nix expressions define both)

For single-file languages (Nextflow, WDL, Python, Nickel, Nix), all tokens are WF tokens.
For multi-file languages (CWL, SWL), tokens split between workflow and task files.
"""

import os
import re
import sys
from pathlib import Path
from collections import defaultdict

import tiktoken

_tokenizer = tiktoken.get_encoding("o200k_harmony")

def strip_comments(content, language):
    """Remove comments based on language."""
    lines = content.split('\n')
    result = []
    
    for line in lines:
        stripped = line.strip()
        
        if not stripped:
            continue
        
        if language == 'swl':
            if stripped.startswith('#'):
                after_hash = stripped[1:].strip()
                # Keep #? and # in / # out / # run lines (exactly), skip task config
                if after_hash.startswith('?') or after_hash.startswith('in') or after_hash.startswith('out') or after_hash.startswith('run'):
                    result.append(line)
                continue
        elif language == 'nf':
            if stripped.startswith('#'):
                if stripped.startswith('#?'):
                    result.append(line)
                continue
        elif language in ['cwl', 'wdl', 'ncl', 'nix', 'smk']:
            if stripped.startswith('#'):
                continue
        elif language == 'py':
            if stripped.startswith('#'):
                continue
        
        result.append(line)
    
    return '\n'.join(result)

def strip_swl_comment_part(line):
    """For SWL comments, strip everything after | (which is a comment within a comment)."""
    if '#' in line:
        parts = line.split('#', 1)
        code_part = parts[0]
        comment_part = parts[1] if len(parts) > 1 else ''
        
        if '|' in comment_part:
            comment_part = comment_part.split('|')[0]
        
        return code_part + '#' + comment_part
    return line

def count_tokens(content, language):
    """Count tokens in content using tiktoken o200k_harmony tokenizer."""
    return len(_tokenizer.encode(content))

def get_token_list(content, language):
    """Get list of token IDs in content using tiktoken o200k_harmony tokenizer."""
    return _tokenizer.encode(content)

def count_nf_tokens(content):
    """Count workflow tokens and tool/process tokens in Nextflow."""
    lines = content.split('\n')
    
    # Find workflow block and process blocks
    wf_start = -1
    wf_end = -1
    proc_starts = []
    proc_ends = []
    
    i = 0
    while i < len(lines):
        stripped = lines[i].strip()
        if not stripped or stripped.startswith('#'):
            i += 1
            continue
        
        tokens = [t for t in re.split(r'(\s+|[=,:{}\[\]()".])', stripped) if t and t.strip()]
        
        if 'workflow' in tokens and '{' in stripped and wf_start < 0:
            wf_start = i
            brace_count = stripped.count('{') - stripped.count('}')
            j = i + 1
            while j < len(lines) and brace_count > 0:
                brace_count += lines[j].count('{') - lines[j].count('}')
                if brace_count == 0:
                    wf_end = j
                    break
                j += 1
            i = j + 1
            continue
        
        if 'process' in tokens and '{' in stripped:
            proc_starts.append(i)
            brace_count = stripped.count('{') - stripped.count('}')
            j = i + 1
            while j < len(lines) and brace_count > 0:
                brace_count += lines[j].count('{') - lines[j].count('}')
                if brace_count == 0:
                    proc_ends.append(j)
                    break
                j += 1
            i = j + 1
            continue
        
        i += 1
    
    # Track which lines are in workflow or task blocks
    block_indices = set()
    for idx in range(wf_start, wf_end + 1) if wf_start >= 0 else []:
        block_indices.add(idx)
    for start, end in zip(proc_starts, proc_ends):
        for idx in range(start, end + 1):
            block_indices.add(idx)
    
    # Get workflow content
    wf_content = '\n'.join(lines[wf_start:wf_end+1]) if wf_start >= 0 and wf_end >= 0 else ''
    wf_tokens = len(get_token_list(wf_content, 'nf'))
    
    # Get task content - all process blocks
    task_tokens = 0
    for start, end in zip(proc_starts, proc_ends):
        task_content = '\n'.join(lines[start:end+1])
        task_tokens += len(get_token_list(task_content, 'nf'))
    
    # Add any content not in blocks to workflow (params, etc)
    extra_content = ''
    for i, line in enumerate(lines):
        if i not in block_indices and line.strip() and not line.strip().startswith('#'):
            extra_content += line + '\n'
    
    if extra_content:
        wf_tokens += len(get_token_list(extra_content, 'nf'))
    
    return wf_tokens, task_tokens

def count_wdl_tokens(content):
    """Count workflow tokens and task tokens in WDL."""
    lines = content.split('\n')
    
    wf_start = -1
    wf_end = -1
    task_starts = []
    task_ends = []
    
    i = 0
    while i < len(lines):
        stripped = lines[i].strip()
        if not stripped or stripped.startswith('#'):
            i += 1
            continue
        
        if 'workflow' in stripped and '{' in stripped and wf_start < 0:
            wf_start = i
            brace_count = stripped.count('{') - stripped.count('}')
            j = i + 1
            while j < len(lines) and brace_count > 0:
                brace_count += lines[j].count('{') - lines[j].count('}')
                if brace_count == 0:
                    wf_end = j
                    break
                j += 1
            i = j + 1
            continue
        
        if stripped.startswith('task') and '{' in stripped:
            task_starts.append(i)
            brace_count = stripped.count('{') - stripped.count('}')
            j = i + 1
            while j < len(lines) and brace_count > 0:
                brace_count += lines[j].count('{') - lines[j].count('}')
                if brace_count == 0:
                    task_ends.append(j)
                    break
                j += 1
            i = j + 1
            continue
        
        i += 1
    
    # Get workflow content
    wf_content = '\n'.join(lines[wf_start:wf_end+1]) if wf_start >= 0 and wf_end >= 0 else ''
    wf_tokens = len(get_token_list(wf_content, 'wdl'))
    
    # Get task content - all task blocks
    task_content = ''
    for start, end in zip(task_starts, task_ends):
        task_content += '\n' + '\n'.join(lines[start:end+1])
    
    task_tokens = len(get_token_list(task_content, 'wdl'))
    
    return wf_tokens, task_tokens

def count_py_tokens(content):
    """Count workflow tokens and task tokens in Python DSL."""
    lines = content.split('\n')
    
    # Find TOOLS dict and Pipeline definition
    tools_start = -1
    tools_end = -1
    pipeline_start = -1
    pipeline_end = -1
    
    in_tools = False
    in_pipeline = False
    brace_count = 0
    
    for i, line in enumerate(lines):
        stripped = line.strip()
        
        if stripped.startswith('TOOLS'):
            in_tools = True
            tools_start = i
            brace_count = 0
            continue
        
        if in_tools:
            brace_count += stripped.count('{') - stripped.count('}')
            if brace_count == 0 and '{' in lines[i]:
                tools_end = i
                in_tools = False
                continue
        
        if 'PIPELINE' in stripped and '=' in stripped:
            pipeline_start = i
            brace_count = 0
            in_pipeline = True
            continue
        
        if in_pipeline:
            brace_count += stripped.count('{') - stripped.count('}')
            if brace_count == 0 and stripped.endswith(')'):
                pipeline_end = i
                in_pipeline = False
                continue
    
    # Get workflow content - Pipeline definition
    wf_content = '\n'.join(lines[pipeline_start:pipeline_end+1]) if pipeline_start >= 0 and pipeline_end >= 0 else ''
    wf_tokens = len(get_token_list(wf_content, 'py'))
    
    # Get task content - TOOLS dict + class definitions
    task_content = ''
    if tools_start >= 0 and tools_end >= 0:
        task_content += '\n'.join(lines[tools_start:tools_end+1]) + '\n'
    
    # Add class definitions (Resource, Tool, Step, Pipeline)
    for i, line in enumerate(lines):
        if line.strip().startswith('class '):
            class_start = i
            indent = len(line) - len(line.lstrip())
            j = i + 1
            while j < len(lines):
                if lines[j].strip() and not lines[j].strip().startswith('#'):
                    next_indent = len(lines[j]) - len(lines[j].lstrip())
                    if next_indent <= indent and lines[j].strip():
                        break
                j += 1
            task_content += '\n'.join(lines[class_start:j]) + '\n'
    
    task_tokens = len(get_token_list(task_content, 'py'))
    
    return wf_tokens, task_tokens

def count_nickel_tokens(content):
    """Count workflow tokens and task tokens in Nickel."""
    lines = content.split('\n')
    
    # Find workflow block (after "in {")
    wf_start = -1
    wf_end = -1
    
    for i, line in enumerate(lines):
        if 'in {' in line:
            wf_start = i
            brace_count = line.count('{') - line.count('}')
            j = i + 1
            while j < len(lines):
                brace_count += lines[j].count('{') - lines[j].count('}')
                if brace_count == 0:
                    wf_end = j
                    break
                j += 1
            break
    
    # Get workflow content
    wf_content = '\n'.join(lines[wf_start:wf_end+1]) if wf_start >= 0 and wf_end >= 0 else ''
    wf_tokens = len(get_token_list(wf_content, 'ncl'))
    
    # Get task content - everything between "let" and "in"
    task_content = '\n'.join(lines[:wf_start]) if wf_start > 0 else ''
    task_tokens = len(get_token_list(task_content, 'ncl'))
    
    return wf_tokens, task_tokens

def count_snakemake_tokens(content):
    """Count workflow tokens and task tokens in Snakemake."""
    lines = content.split('\n')
    
    # Find all rule blocks using indentation (Snakemake uses indentation, not braces)
    rule_blocks = []
    current_start = -1
    current_indent = -1
    
    for i, line in enumerate(lines):
        stripped = line.strip()
        if not stripped or stripped.startswith('#'):
            continue
        
        # Check if this line starts a new rule
        if stripped.startswith('rule '):
            if current_start >= 0:
                rule_blocks.append((current_start, i - 1))
            current_start = i
            current_indent = len(line) - len(line.lstrip())
            continue
        
        # Track when the rule block ends (next line at same or lower indent)
        if current_start >= 0 and stripped:
            indent = len(line) - len(line.lstrip())
            if indent <= current_indent and not stripped.startswith('rule '):
                rule_blocks.append((current_start, i - 1))
                current_start = -1
                current_indent = -1
    
    if current_start >= 0:
        rule_blocks.append((current_start, len(lines) - 1))
    
    # Track which lines are in rule blocks
    rule_indices = set()
    for start, end in rule_blocks:
        for idx in range(start, end + 1):
            rule_indices.add(idx)
    
    # Get workflow content - rule all + configfile + other top-level content
    wf_lines = []
    for line in lines:
        if 'configfile:' in line:
            wf_lines.append(line)
    
    # Find rule all block - put in WORKFLOW (the entry point/orchestration)
    for start, end in rule_blocks:
        rule_content = '\n'.join(lines[start:end+1])
        if 'all' in rule_content:
            for i in range(start, end + 1):
                wf_lines.append(lines[i])
            break
    
    # Add other non-rule content to workflow
    for i, line in enumerate(lines):
        if i not in rule_indices and line.strip() and not line.strip().startswith('#'):
            wf_lines.append(line)
    
    wf_content = '\n'.join(wf_lines)
    wf_tokens = len(get_token_list(wf_content, 'smk'))
    
    # Get task content - all rule blocks except rule all (each rule is a task)
    task_content = ''
    for start, end in rule_blocks:
        rule_content = '\n'.join(lines[start:end+1])
        if 'all' not in rule_content:
            task_content += '\n' + rule_content
    
    task_tokens = len(get_token_list(task_content, 'smk'))
    
    return wf_tokens, task_tokens

def extract_bash_tokens(content, language):
    """Extract bash/shell command tokens from task definitions."""
    if language == 'cwl':
        return 0
    
    lines = content.split('\n')
    bash_lines = []
    in_bash = False
    
    if language == 'swl':
        for line in lines:
            if not line.strip():
                continue
            if line.startswith('#') and any(kw in line for kw in ['#?', '# in', '# out', '# run']):
                continue
            if line.strip():
                bash_lines.append(line)
        return len(get_token_list('\n'.join(bash_lines), 'swl'))
    
    if language == 'nf':
        in_triple = False
        triple_char = None
        for line in lines:
            if not in_triple:
                if '"""' in line or "'''" in line:
                    in_triple = True
                    triple_char = '"""' if '"""' in line else "'''"
                    if line.strip().count(triple_char) >= 2:
                        continue
            else:
                if triple_char in line and line.strip().count(triple_char) >= 1:
                    in_triple = False
                    continue
                if line.strip():
                    bash_lines.append(line)
        return len(get_token_list('\n'.join(bash_lines), 'nf'))
    
    if language == 'wdl':
        for i, line in enumerate(lines):
            stripped = line.strip()
            if stripped.startswith('command'):
                in_bash = True
                j = i + 1
                while j < len(lines):
                    if '>>>' in lines[j]:
                        break
                    if lines[j].strip() and not lines[j].strip().startswith('>'):
                        bash_lines.append(lines[j])
                    j += 1
        return len(get_token_list('\n'.join(bash_lines), 'wdl'))
    
    if language == 'py':
        in_tool = False
        for line in lines:
            stripped = line.strip()
            if stripped.startswith('TOOLS'):
                in_tool = True
            if in_tool and 'base_command=' in stripped:
                parts = stripped.split('base_command=')
                if len(parts) > 1:
                    cmd_part = parts[1].rstrip(',').strip('"').strip("'")
                    bash_lines.append(cmd_part)
        return len(get_token_list('\n'.join(bash_lines), 'py'))
    
    if language == 'ncl' or language == 'nix':
        for i, line in enumerate(lines):
            stripped = line.strip()
            if stripped.endswith('Task') or '=' in stripped and 'Task' in stripped:
                j = i + 1
                quote_count = 0
                while j < len(lines) and quote_count < 2:
                    if '"' in lines[j]:
                        quote_count += lines[j].count('"') // 2
                        if quote_count >= 2:
                            import re
                            quotes = re.findall(r'"([^"]*)"', '\n'.join(lines[i:j+1]))
                            if len(quotes) >= 2:
                                bash_lines.append(quotes[1])
                            break
                    j += 1
        return len(get_token_list('\n'.join(bash_lines), language))
    
    if language == 'smk':
        for i, line in enumerate(lines):
            stripped = line.strip()
            if stripped.startswith('shell:'):
                j = i
                while j < len(lines):
                    if lines[j].strip() and not lines[j].strip().startswith('shell:'):
                        if lines[j].strip().startswith('rule ') or lines[j].strip().startswith('input:') or lines[j].strip().startswith('output:') or lines[j].strip().startswith('resources:') or lines[j].strip().startswith('params:') or lines[j].strip().startswith('name:'):
                            break
                        bash_lines.append(lines[j])
                    j += 1
        return len(get_token_list('\n'.join(bash_lines), 'smk'))
    
    return 0

def main():
    workflows = ['snv', 'cnv', 'rna']
    languages = ['cwl', 'nf', 'wdl', 'py', 'ncl', 'swl', 'nix', 'smk']
    
    results = defaultdict(lambda: {'lines': 0, 'tokens': 0, 'workflow_tokens': 0, 'task_tokens': 0, 'bash_tokens': 0, 'files': [], 'token_lists': {}})
    
    file_records = []
    
    base_dir = Path('.')
    
    ext_map = {'cwl': '.cwl', 'nf': '.nf', 'wdl': '.wdl', 'py': '.py', 'ncl': '.ncl', 'swl': '.swl', 'nix': '.nix', 'smk': ''}
    dir_map = {'cwl': 'cwl', 'nf': 'nextflow', 'wdl': 'wdl', 'py': 'python', 'ncl': 'nickel', 'swl': 'swl', 'nix': 'nix', 'smk': 'snakemake'}
    
    for workflow in workflows:
        for lang in languages:
            lang_dir_name = dir_map[lang]
            lang_dir = base_dir / lang_dir_name / workflow
            
            if not lang_dir.exists():
                continue
            
            if lang == 'py':
                for py_file in sorted(lang_dir.glob('*.py')):
                    with open(py_file, 'r') as f:
                        content = f.read()
                    content_no_comments = strip_comments(content, lang)
                    token_list = get_token_list(content_no_comments, lang)
                    workflow_tokens, task_tokens = count_py_tokens(content_no_comments)
                    bash_tokens = extract_bash_tokens(content_no_comments, 'py')
                    tokens = workflow_tokens + task_tokens
                    lines = len(content_no_comments.split('\n'))
                    results[(workflow, lang)]['lines'] += lines
                    results[(workflow, lang)]['tokens'] += tokens
                    results[(workflow, lang)]['workflow_tokens'] += workflow_tokens
                    results[(workflow, lang)]['task_tokens'] += task_tokens - bash_tokens
                    results[(workflow, lang)]['bash_tokens'] += bash_tokens
                    results[(workflow, lang)]['files'].append(str(py_file))
                    results[(workflow, lang)]['token_lists'][str(py_file)] = token_list
                    file_records.append((workflow, lang, str(py_file), lines, tokens, workflow_tokens, task_tokens - bash_tokens, bash_tokens))
            elif lang == 'swl':
                for sh_file in sorted(lang_dir.glob('*.sh')):
                    with open(sh_file, 'r') as f:
                        content = f.read()
                    token_list = get_token_list(content, 'swl')
                    tokens = len(token_list)
                    bash_tokens = extract_bash_tokens(content, 'swl')
                    lines = len(content.split('\n'))
                    results[(workflow, lang)]['files'].append(str(sh_file))
                    results[(workflow, lang)]['lines'] += lines
                    results[(workflow, lang)]['tokens'] += tokens
                    results[(workflow, lang)]['task_tokens'] += tokens - bash_tokens
                    results[(workflow, lang)]['bash_tokens'] += bash_tokens
                    results[(workflow, lang)]['token_lists'][str(sh_file)] = token_list
                    file_records.append((workflow, lang, str(sh_file), lines, tokens, 0, tokens - bash_tokens, bash_tokens))
                
                for swl_file in sorted(lang_dir.glob('*.swl')):
                    with open(swl_file, 'r') as f:
                        content = f.read()
                    token_list = get_token_list(content, 'swl')
                    tokens = len(token_list)
                    lines = len(content.split('\n'))
                    results[(workflow, lang)]['files'].append(str(swl_file))
                    results[(workflow, lang)]['lines'] += lines
                    results[(workflow, lang)]['tokens'] += tokens
                    results[(workflow, lang)]['workflow_tokens'] += tokens
                    results[(workflow, lang)]['token_lists'][str(swl_file)] = token_list
                    file_records.append((workflow, lang, str(swl_file), lines, tokens, tokens, 0, 0))
            else:
                for file_path in sorted(lang_dir.rglob(f'*{ext_map[lang]}')):
                    if lang == 'smk' and file_path.name == 'config.yaml':
                        continue
                    with open(file_path, 'r') as f:
                        content = f.read()
                    content_no_comments = strip_comments(content, lang)
                    token_list = get_token_list(content_no_comments, lang)
                    lines = len(content_no_comments.split('\n'))
                    
                    is_workflow = 'class: Workflow' in content or 'workflow {' in content or 'workflow snv_calling' in content or 'workflow cnv_calling' in content or 'dfn.Workflow' in content or 'name = ' in content or 'outputs = ' in content
                    
                    if lang == 'nf':
                        workflow_tokens, task_tokens = count_nf_tokens(content_no_comments)
                        bash_tokens = extract_bash_tokens(content_no_comments, 'nf')
                        tokens = workflow_tokens + task_tokens
                        results[(workflow, lang)]['workflow_tokens'] += workflow_tokens
                        results[(workflow, lang)]['task_tokens'] += task_tokens - bash_tokens
                        results[(workflow, lang)]['bash_tokens'] += bash_tokens
                        file_records.append((workflow, lang, str(file_path), lines, tokens, workflow_tokens, task_tokens - bash_tokens, bash_tokens))
                    elif lang == 'wdl':
                        workflow_tokens, task_tokens = count_wdl_tokens(content_no_comments)
                        bash_tokens = extract_bash_tokens(content_no_comments, 'wdl')
                        tokens = workflow_tokens + task_tokens
                        results[(workflow, lang)]['workflow_tokens'] += workflow_tokens
                        results[(workflow, lang)]['task_tokens'] += task_tokens - bash_tokens
                        results[(workflow, lang)]['bash_tokens'] += bash_tokens
                        file_records.append((workflow, lang, str(file_path), lines, tokens, workflow_tokens, task_tokens - bash_tokens, bash_tokens))
                    elif lang == 'ncl' or lang == 'nix':
                        workflow_tokens, task_tokens = count_nickel_tokens(content_no_comments)
                        bash_tokens = extract_bash_tokens(content_no_comments, lang)
                        tokens = workflow_tokens + task_tokens
                        results[(workflow, lang)]['workflow_tokens'] += workflow_tokens
                        results[(workflow, lang)]['task_tokens'] += task_tokens - bash_tokens
                        results[(workflow, lang)]['bash_tokens'] += bash_tokens
                        file_records.append((workflow, lang, str(file_path), lines, tokens, workflow_tokens, task_tokens - bash_tokens, bash_tokens))
                    elif lang == 'smk':
                        workflow_tokens, task_tokens = count_snakemake_tokens(content_no_comments)
                        bash_tokens = extract_bash_tokens(content_no_comments, 'smk')
                        tokens = workflow_tokens + task_tokens
                        results[(workflow, lang)]['workflow_tokens'] += workflow_tokens
                        results[(workflow, lang)]['task_tokens'] += task_tokens - bash_tokens
                        results[(workflow, lang)]['bash_tokens'] += bash_tokens
                        file_records.append((workflow, lang, str(file_path), lines, tokens, workflow_tokens, task_tokens - bash_tokens, bash_tokens))
                    elif is_workflow:
                        tokens = len(token_list)
                        results[(workflow, lang)]['workflow_tokens'] += tokens
                        results[(workflow, lang)]['bash_tokens'] += 0
                        file_records.append((workflow, lang, str(file_path), lines, tokens, tokens, 0, 0))
                    else:
                        tokens = len(token_list)
                        bash_tokens = extract_bash_tokens(content_no_comments, lang)
                        results[(workflow, lang)]['task_tokens'] += tokens - bash_tokens
                        results[(workflow, lang)]['bash_tokens'] += bash_tokens
                        file_records.append((workflow, lang, str(file_path), lines, tokens, 0, tokens - bash_tokens, bash_tokens))
                    
                    results[(workflow, lang)]['files'].append(str(file_path))
                    results[(workflow, lang)]['lines'] += lines
                    results[(workflow, lang)]['tokens'] += tokens
                    results[(workflow, lang)]['token_lists'][str(file_path)] = token_list
    
    print("")
    print("INDIVIDUAL WORKFLOWS")
    print("-" * 98)
    print(f"{'Workflow':<10} {'Language':<10} {'Files':>6} {'Lines':>7} {'Tokens':>8} {'WF Tok':>8} {'Task Tok':>9} {'Bash':>8}")
    print("-" * 98)
    
    total_tokens = defaultdict(int)
    total_wf = defaultdict(int)
    total_tools = defaultdict(int)
    total_bash = defaultdict(int)
    total_lines = defaultdict(int)
    
    for workflow in workflows:
        for lang in languages:
            key = (workflow, lang)
            data = results[key]
            if data['files']:
                file_count = len(data['files'])
                print(f"{workflow:<10} {lang:<10} {file_count:>6} {data['lines']:>7} {data['tokens']:>8} {data['workflow_tokens']:>8} {data['task_tokens']:>9} {data['bash_tokens']:>8}")
                total_lines[lang] += data['lines']
                total_tokens[lang] += data['tokens']
                total_wf[lang] += data['workflow_tokens']
                total_tools[lang] += data['task_tokens']
                total_bash[lang] += data['bash_tokens']
    
    print("-" * 98)
    print(f"{'TOTAL':<10} {'':<10} {sum([len(results[(w,l)]['files']) for w in workflows for l in languages if results[(w,l)]['files']]):>6} {sum(total_lines.values()):>7} {sum(total_tokens.values()):>8} {sum(total_wf.values()):>8} {sum(total_tools.values()):>9} {sum(total_bash.values()):>8}")
    print()
    
    print("Summary by language:")
    print("-" * 80)
    print(f"{'Language':<10} {'Lines':<8} {'Tokens':<10} {'Bash Tok':<10} {'WF Tok':<10} {'Task Tok':<10} {'Non-Bash':<10}")
    print("-" * 80)
    for lang in languages:
        if total_tokens[lang] > 0:
            non_bash = total_tokens[lang] - total_bash[lang]
            print(f"{lang:<10} {total_lines[lang]:<8} {total_tokens[lang]:<10} {total_bash[lang]:<10} {total_wf[lang]:<10} {total_tools[lang]:<10} {non_bash:<10}")

    # Print comprehensive token lists for each language
    print()
    print("=" * 100)
    print("COMPREHENSIVE TOKEN LISTS BY LANGUAGE")
    print("=" * 100)
    
    for lang in languages:
        print()
        print(f"## {lang.upper()} ##")
        print("-" * 50)
        
        for workflow in workflows:
            key = (workflow, lang)
            data = results[key]
            if not data['files']:
                continue
            
            print(f"\n### {workflow.upper()} ###")
            
            for filepath in data['files']:
                token_list = data['token_lists'].get(filepath, [])
                filename = filepath.split('/')[-1]
                unique_tokens = sorted(set(token_list))
                print(f"\n{filename} ({len(token_list)} tokens, {len(unique_tokens)} unique):")
                # Print unique tokens: token (1), token (2), ...
                token_strs = [f"{t} ({i+1})" for i, t in enumerate(unique_tokens)]
                print("  " + ", ".join(token_strs))
    
    # Write per-file granular results to CSV
    import csv
    with open('token_counts.csv', 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['workflow', 'language', 'file', 'lines', 'total_tokens', 'wf_tokens', 'task_tokens', 'bash_tokens'])
        for rec in sorted(file_records):
            writer.writerow(rec)

if __name__ == "__main__":
    main()
