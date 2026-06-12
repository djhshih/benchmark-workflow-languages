import unittest
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from count_tokens import (
    strip_comments, count_tokens, get_token_list,
    count_nf_tokens, count_wdl_tokens, count_py_tokens,
    count_nickel_tokens, count_snakemake_tokens,
    extract_bash_tokens,
)
from collections import defaultdict


class TestStripComments(unittest.TestCase):

    def test_strip_cwl_comments(self):
        content = "# this is a comment\nfoo: bar\n# another comment\nbaz: qux\n"
        result = strip_comments(content, 'cwl')
        self.assertEqual(result, "foo: bar\nbaz: qux")

    def test_keep_swl_annotations(self):
        content = "#@ some comment\n# in\n#   reads [file]\n# out\nset -e\nbwa mem\n"
        result = strip_comments(content, 'swl')
        self.assertIn('# in', result)
        self.assertIn('#   reads [file]', result)
        self.assertIn('# out', result)
        self.assertIn('set -e', result)
        self.assertIn('bwa mem', result)
        self.assertNotIn('#@', result)

    def test_strip_nf_comments(self):
        content = "# comment\n#? meta\nprocess foo {\n}\n"
        result = strip_comments(content, 'nf')
        self.assertIn('#? meta', result)
        self.assertNotIn('# comment', result)
        self.assertIn('process foo {', result)

    def test_strip_wdl_comments(self):
        content = "# comment\ntask foo {}\n"
        result = strip_comments(content, 'wdl')
        self.assertNotIn('# comment', result)
        self.assertIn('task foo {}', result)

    def test_strip_py_comments(self):
        content = "# comment\nx = 1\n"
        result = strip_comments(content, 'py')
        self.assertNotIn('# comment', result)
        self.assertIn('x = 1', result)

    def test_strip_smk_comments(self):
        content = "# comment\nrule all:\n    input: []\n"
        result = strip_comments(content, 'smk')
        self.assertNotIn('# comment', result)
        self.assertIn('rule all:', result)


class TestSnakemakeRuleAllDetection(unittest.TestCase):
    """Verify the fix for the 'all' substring bug."""

    def test_rule_all_exact_match(self):
        content = (
            "configfile: \"config.yaml\"\n"
            "rule all:\n"
            "    input:\n"
            "        []\n"
            "rule bwa_mem:\n"
            "    input:\n"
            "        {}\n"
            "    output:\n"
            "        {}\n"
            "    shell:\n"
            "        \"bwa mem -XX:ParallelGCThreads=1\"\n"
            "rule haplotype_caller:\n"
            "    input:\n"
            "        {}\n"
            "    output:\n"
            "        {}\n"
            "    shell:\n"
            "        \"gatk HaplotypeCaller\"\n"
        )
        wf_t, task_t = count_snakemake_tokens(content)
        self.assertGreater(task_t, 0, "Task tokens should be positive")
        self.assertGreater(wf_t, 0, "WF tokens should be positive")

        task_bash = extract_bash_tokens(content, 'smk')
        self.assertGreater(task_bash, 0, "Bash tokens should be positive")


class TestWDLExtractBash(unittest.TestCase):
    """Verify WDL extract_bash_tokens handles command { ... } blocks."""

    def test_command_block_brace_style(self):
        content = (
            "task foo {\n"
            "  command {\n"
            "    echo hello\n"
            "    bwa mem -R '@RG\\tID:1'\n"
            "  }\n"
            "  output {\n"
            "    String out = read_string(stdout())\n"
            "  }\n"
            "}\n"
        )
        bash_t = extract_bash_tokens(content, 'wdl')
        self.assertGreater(bash_t, 0)

    def test_command_block_no_overflow(self):
        content = (
            "task foo {\n"
            "  command {\n"
            "    echo hello\n"
            "  }\n"
            "  output {\n"
            "    String out = read_string(stdout())\n"
            "  }\n"
            "}\n"
            "task bar {\n"
            "  command {\n"
            "    echo world\n"
            "  }\n"
            "}\n"
        )
        bash_t = extract_bash_tokens(content, 'wdl')
        all_tokens = len(get_token_list(content, 'wdl'))
        self.assertLess(bash_t, all_tokens,
                        "Bash tokens should not exceed total tokens")


class TestPythonCountPyTokens(unittest.TestCase):
    """Verify Python TOOLS dict is correctly included in task tokens."""

    def test_tools_dict_included(self):
        content = (
            "@dataclass\n"
            "class Tool:\n"
            "    name: str\n"
            "    base_command: str\n"
            "TOOLS = {\n"
            "    \"bwa_mem\": Tool(\n"
            "        name=\"bwa_mem\",\n"
            "        base_command='bwa mem -t 4 -R \"@RG\\tID:1\" ref.fa',\n"
            "    ),\n"
            "}\n"
        )
        wf_t, task_t = count_py_tokens(content)
        self.assertGreater(task_t, 0, "Task tokens should include TOOLS dict")
        total = wf_t + task_t
        self.assertGreater(total, 0)

    def test_class_defs_included(self):
        content = (
            "class Resource:\n"
            "    cpu: int = 1\n"
            "class Tool:\n"
            "    name: str\n"
            "TOOLS = {}\n"
        )
        wf_t, task_t = count_py_tokens(content)
        self.assertGreater(task_t, 0)


class TestAllLanguagesNoNegatives(unittest.TestCase):
    """Verify no language produces negative token counts."""

    def _run_for_file(self, lang, content):
        stripped = strip_comments(content, lang)
        tokens = len(get_token_list(stripped, lang))
        lines = len(stripped.split('\n'))
        output = {'tokens': tokens, 'lines': lines, 'wf': 0, 'task': 0, 'bash': 0}

        if lang == 'nf':
            wf_t, task_t = count_nf_tokens(stripped)
            bash_t = extract_bash_tokens(stripped, 'nf')
            output['wf'] = wf_t
            output['task'] = task_t - bash_t
            output['bash'] = bash_t
        elif lang == 'wdl':
            wf_t, task_t = count_wdl_tokens(stripped)
            bash_t = extract_bash_tokens(stripped, 'wdl')
            output['wf'] = wf_t
            output['task'] = task_t - bash_t
            output['bash'] = bash_t
        elif lang == 'py':
            wf_t, task_t = count_py_tokens(stripped)
            bash_t = extract_bash_tokens(stripped, 'py')
            output['wf'] = wf_t
            output['task'] = task_t - bash_t
            output['bash'] = bash_t
        elif lang in ('ncl', 'nix'):
            wf_t, task_t = count_nickel_tokens(stripped)
            bash_t = extract_bash_tokens(stripped, lang)
            output['wf'] = wf_t
            output['task'] = task_t - bash_t
            output['bash'] = bash_t
        elif lang == 'smk':
            wf_t, task_t = count_snakemake_tokens(stripped)
            bash_t = extract_bash_tokens(stripped, 'smk')
            output['wf'] = wf_t
            output['task'] = task_t - bash_t
            output['bash'] = bash_t
        else:
            output['task'] = tokens

        return output

    def test_small_pipeline_no_negatives(self):
        pipelines = {
            'nf': "#!/usr/bin/env nextflow\nnextflow.enable.dsl=2\n\nworkflow {\n  bwa_mem()\n}\n\nprocess bwa_mem {\n  input:\n  path reads\n  script:\n  \"\"\"\n  bwa mem ref.fa $reads > out.sam\n  \"\"\"\n}\n",
            'wdl': "version 1.0\n\nworkflow test {\n  call align\n}\n\ntask align {\n  input {\n    File reads\n  }\n  command {\n    bwa mem ref.fa ~{reads} > out.sam\n  }\n  output {\n    File sam = \"out.sam\"\n  }\n}\n",
            'py': "TOOLS = {\n  \"align\": Tool(\n    name=\"align\",\n    base_command='bwa mem ref.fa',\n  ),\n}\nPIPELINE = Pipeline(\n    name=\"test\",\n    tools=TOOLS,\n    steps=[],\n)\n",
            'smk': "rule all:\n    input:\n        \"out.sam\"\nrule align:\n    input:\n        \"ref.fa\",\n        \"reads.fq\"\n    output:\n        \"out.sam\"\n    shell:\n        \"bwa mem {input} > {output}\"\n",
        }
        for lang, content in pipelines.items():
            with self.subTest(lang=lang):
                result = self._run_for_file(lang, content)
                self.assertGreaterEqual(result['wf'], 0, f"{lang}: wf_tokens < 0")
                self.assertGreaterEqual(result['task'], 0, f"{lang}: task_tokens < 0")
                self.assertGreaterEqual(result['bash'], 0, f"{lang}: bash_tokens < 0")

    def test_task_consistency(self):
        nf_content = "nextflow.enable.dsl=2\n\nworkflow {\n  foo()\n}\n\nprocess foo {\n  \"\"\"\n  echo hello\n  \"\"\"\n}\n"
        stripped = strip_comments(nf_content, 'nf')
        total = len(get_token_list(stripped, 'nf'))
        wf_t, task_t = count_nf_tokens(stripped)
        bash_t = extract_bash_tokens(stripped, 'nf')
        self.assertEqual(total, wf_t + task_t,
                         "Total tokens should equal wf + task tokens")


class TestSWLBashSeparation(unittest.TestCase):
    """Verify SWL .sh file token separation."""

    def test_bash_less_than_total(self):
        content = "# in\n#   x file\n# out\n#   y file = x.out\n# run\n#   cpu = 1\necho hello\n"
        stripped = strip_comments(content, 'swl')
        total = len(get_token_list(stripped, 'swl'))
        bash_lines = [l for l in stripped.split('\n') if l.strip() and not l.strip().startswith('#')]
        bash_t = len(get_token_list('\n'.join(bash_lines), 'swl')) if bash_lines else 0
        task_nonbash = total - bash_t
        self.assertGreater(task_nonbash, 0, "Non-bash tokens should be positive")
        self.assertGreater(total, bash_t, "Total tokens should exceed bash tokens")


class TestFullPipelineConsistency(unittest.TestCase):
    """Verify full pipeline run produces no negatives and consistent totals."""

    def test_all_workflows_consistent(self):
        from count_tokens import main as count_main
        import io
        old_stdout = sys.stdout
        sys.stdout = io.StringIO()
        try:
            count_main()
        finally:
            sys.stdout = old_stdout

        import csv
        with open('token_counts.csv') as f:
            reader = csv.DictReader(f)
            for row in reader:
                wf = int(row['wf_tokens'])
                task = int(row['task_tokens'])
                bash = int(row['bash_tokens'])
                total = int(row['total_tokens'])
                with self.subTest(file=row['file']):
                    self.assertGreaterEqual(wf, 0, f"wf_tokens negative in {row['file']}")
                    self.assertGreaterEqual(task, 0, f"task_tokens negative in {row['file']}")
                    self.assertGreaterEqual(bash, 0, f"bash_tokens negative in {row['file']}")
                    self.assertEqual(total, wf + task + bash,
                                     f"Token counts don't add up in {row['file']}: "
                                     f"{total} != {wf} + {task} + {bash}")


if __name__ == '__main__':
    unittest.main()
