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
                if stripped.startswith('#?') or stripped.startswith('# in') or stripped.startswith('# out') or stripped.startswith('# run') or stripped.startswith('# in:') or stripped.startswith('# out:') or stripped.startswith('# run:'):
                    result.append(line)
                continue
        elif language == 'nf':
            if stripped.startswith('#'):
                if stripped.startswith('#?'):
                    result.append(line)
                continue
        elif language in ['cwl', 'wdl', 'ncl', 'nix']:
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
    """Count tokens in content (non-comment lines only)."""
    tokens = []
    for line in content.split('\n'):
        if line.strip():
            if language == 'swl' and '#' in line:
                line = strip_swl_comment_part(line)
                if line.startswith('#'):
                    line = line[1:].strip()
            
            parts = re.split(r'\s+', line)
            tokens.extend([t for t in parts if t])
    
    return len(tokens)

def count_nf_tokens(content):
    """Count workflow tokens and tool/process tokens in Nextflow."""
    workflow_tokens = 0
    task_tokens = 0
    in_workflow = False
    in_process = False
    brace_count = 0
    in_global_section = True
    
    for line in content.split('\n'):
        stripped = line.strip()
        if not stripped or stripped.startswith('#'):
            continue
        
        tokens = re.split(r'\s+', stripped)
        
        for token in tokens:
            if not token:
                continue
            
            if token == 'workflow':
                in_workflow = True
                in_process = False
                in_global_section = False
                brace_count = 0
            elif token == 'process':
                in_process = True
                in_workflow = False
                in_global_section = False
                brace_count = 0
            elif in_workflow or in_process:
                if token == '{':
                    brace_count += 1
                elif token == '}':
                    brace_count -= 1
                    if brace_count == 0:
                        if in_workflow:
                            in_workflow = False
                        elif in_process:
                            in_process = False
            
            if in_workflow:
                workflow_tokens += 1
            elif in_process:
                task_tokens += 1
            elif in_global_section and (token == 'params' or token.startswith('params.') or token.startswith('nextflow.')):
                workflow_tokens += 1
    
    return workflow_tokens, task_tokens

def count_nickel_tokens(content):
    """Count workflow tokens and task tokens in Nickel."""
    workflow_tokens = 0
    task_tokens = 0
    in_workflow = False
    in_task = False
    brace_count = 0
    
    for line in content.split('\n'):
        stripped = line.strip()
        if not stripped or stripped.startswith('#'):
            continue
        
        tokens = re.split(r'\s+', stripped)
        
        for token in tokens:
            if not token:
                continue
            
            if token == 'let' or token == 'in':
                in_workflow = True
                in_task = False
                brace_count = 0
            elif token == 'Task' or (token.startswith('let') and '=' not in stripped):
                in_task = True
                in_workflow = False
                brace_count = 0
            elif in_workflow or in_task:
                if token == '{':
                    brace_count += 1
                elif token == '}':
                    brace_count -= 1
                    if brace_count == 0:
                        if in_workflow:
                            in_workflow = False
                        elif in_task:
                            in_task = False
            
            if in_workflow:
                workflow_tokens += 1
            elif in_task:
                task_tokens += 1
            elif token == 'let' or token == 'in' or token == 'Task':
                workflow_tokens += 1
    
    return workflow_tokens, task_tokens

def main():
    workflows = ['snv', 'cnv', 'rna']
    languages = ['cwl', 'nf', 'wdl', 'py', 'ncl', 'swl', 'nix']
    
    results = defaultdict(lambda: {'lines': 0, 'tokens': 0, 'workflow_tokens': 0, 'task_tokens': 0, 'files': []})
    
    base_dir = Path('.')
    
    ext_map = {'cwl': '.cwl', 'nf': '.nf', 'wdl': '.wdl', 'py': '.py', 'ncl': '.ncl', 'swl': '.swl', 'nix': '.nix'}
    dir_map = {'cwl': 'cwl', 'nf': 'nextflow', 'wdl': 'wdl', 'py': 'python', 'ncl': 'nickel', 'swl': 'swl', 'nix': 'nix'}
    
    for workflow in workflows:
        for lang in languages:
            lang_dir_name = dir_map[lang]
            lang_dir = base_dir / lang_dir_name / workflow
            
            if not lang_dir.exists():
                continue
            
            if lang == 'py':
                for py_file in lang_dir.glob('*.py'):
                    with open(py_file, 'r') as f:
                        content = f.read()
                    content_no_comments = strip_comments(content, lang)
                    tokens = count_tokens(content_no_comments, lang)
                    results[(workflow, lang)]['lines'] += len(content_no_comments.split('\n'))
                    results[(workflow, lang)]['tokens'] += tokens
                    results[(workflow, lang)]['workflow_tokens'] += tokens
                    results[(workflow, lang)]['files'].append(str(py_file))
            elif lang == 'swl':
                for sh_file in lang_dir.glob('*.sh'):
                    with open(sh_file, 'r') as f:
                        content = f.read()
                    content_no_comments = strip_comments(content, 'swl')
                    tokens = count_tokens(content_no_comments, 'swl')
                    results[(workflow, lang)]['files'].append(str(sh_file))
                    results[(workflow, lang)]['lines'] += len(content_no_comments.split('\n'))
                    results[(workflow, lang)]['tokens'] += tokens
                    results[(workflow, lang)]['task_tokens'] += tokens
                
                for swl_file in lang_dir.glob('*.swl'):
                    with open(swl_file, 'r') as f:
                        content = f.read()
                    content_no_comments = strip_comments(content, 'swl')
                    tokens = count_tokens(content_no_comments, 'swl')
                    results[(workflow, lang)]['files'].append(str(swl_file))
                    results[(workflow, lang)]['lines'] += len(content_no_comments.split('\n'))
                    results[(workflow, lang)]['tokens'] += tokens
                    results[(workflow, lang)]['workflow_tokens'] += tokens
            else:
                for file_path in lang_dir.rglob(f'*{ext_map[lang]}'):
                    with open(file_path, 'r') as f:
                        content = f.read()
                    content_no_comments = strip_comments(content, lang)
                    tokens = count_tokens(content_no_comments, lang)
                    
                    is_workflow = 'class: Workflow' in content or 'workflow {' in content or 'workflow snv_calling' in content or 'workflow cnv_calling' in content or 'dfn.Workflow' in content or 'name = ' in content or 'outputs = ' in content
                    
                    results[(workflow, lang)]['files'].append(str(file_path))
                    results[(workflow, lang)]['lines'] += len(content_no_comments.split('\n'))
                    results[(workflow, lang)]['tokens'] += tokens
                    
                    if lang == 'nf':
                        workflow_tokens, task_tokens = count_nf_tokens(content_no_comments)
                        results[(workflow, lang)]['workflow_tokens'] += workflow_tokens
                        results[(workflow, lang)]['task_tokens'] += task_tokens
                    elif lang == 'ncl' or lang == 'nix':
                        workflow_tokens, task_tokens = count_nickel_tokens(content_no_comments)
                        results[(workflow, lang)]['workflow_tokens'] += workflow_tokens
                        results[(workflow, lang)]['task_tokens'] += task_tokens
                    elif is_workflow:
                        results[(workflow, lang)]['workflow_tokens'] += tokens
                    else:
                        results[(workflow, lang)]['task_tokens'] += tokens
    
    print("")
    print("INDIVIDUAL WORKFLOWS")
    print("-" * 98)
    print(f"{'Workflow':<10} {'Language':<10} {'Files':>6} {'Lines':>7} {'Tokens':>8} {'WF Tok':>8} {'Task Tok':>9}")
    print("-" * 98)
    
    total_tokens = defaultdict(int)
    total_wf = defaultdict(int)
    total_tools = defaultdict(int)
    total_lines = defaultdict(int)
    
    for workflow in workflows:
        for lang in languages:
            key = (workflow, lang)
            data = results[key]
            if data['files']:
                file_count = len(data['files'])
                print(f"{workflow:<10} {lang:<10} {file_count:>6} {data['lines']:>7} {data['tokens']:>8} {data['workflow_tokens']:>8} {data['task_tokens']:>9}")
                total_lines[lang] += data['lines']
                total_tokens[lang] += data['tokens']
                total_wf[lang] += data['workflow_tokens']
                total_tools[lang] += data['task_tokens']
    
    print("-" * 98)
    print(f"{'TOTAL':<10} {'':<10} {sum([len(results[(w,l)]['files']) for w in workflows for l in languages if results[(w,l)]['files']]):>6} {sum(total_lines.values()):>7} {sum(total_tokens.values()):>8} {sum(total_wf.values()):>8} {sum(total_tools.values()):>9}")
    print()
    
    print("Summary by language (excluding comments, SWL '|' handled):")
    print("-" * 80)
    print(f"{'Language':<10} {'Lines':<8} {'Tokens':<10} {'WF Tokens':<12} {'Task Tokens':<12} {'Tokens/Line':<12}")
    print("-" * 80)
    for lang in languages:
        if total_tokens[lang] > 0:
            tokens_per_line = total_tokens[lang] / total_lines[lang] if total_lines[lang] > 0 else 0
            print(f"{lang:<10} {total_lines[lang]:<8} {total_tokens[lang]:<10} {total_wf[lang]:<12} {total_tools[lang]:<12} {tokens_per_line:<12.2f}")

if __name__ == "__main__":
    os.chdir('/home/davids/projects/nixflow/experiments/comparison')
    main()