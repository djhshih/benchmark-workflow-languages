# Workflow Language Comparison

## Overview

This comparison evaluates 8 configuration/task languages for specifying bioinformatics workflows (SNV, CNV, and RNA-seq pipelines) that can transpile to CWL.

## Pipelines Evaluated

1. **SNV Calling** - 6 steps: BWA alignment → Mark Duplicates → Base Recalibrator → Apply BQSR → Haplotype Caller → Variant Filter
2. **CNV Calling** - 8 steps: BWA → Sort BAM → Index BAM → Collect Read Counts → Collect GC → Denoise Coverage → Segment CNV → Call CNV
3. **RNA-seq** - 4 steps: Trimmomatic → STAR alignment → FastQC → featureCounts

## Token Count Methodology

Tokens are counted using OpenAI's `o200k_harmony` BPE tokenizer (via the `tiktoken` Python package) applied to non-comment, non-blank lines.

Excluded from counting:
- Lines starting with `#` (comments), except SWL specification lines (`#?`, `# in`, `# out`, `# run`)
- Blank lines

**Lines**: Non-comment, non-blank lines

**WF Tokens**: Tokens from workflow/orchestration definitions (main pipeline control flow)

**Task Tokens**: Tokens from task/step definitions (individual tool implementations)

**Bash Tokens**: Tokens from bash/shell commands (extracted from command blocks)

### Language-Specific Splitting Rules:

- **CWL**: Workflow .cwl files = WF, CommandLineTool .cwl files = Task (no bash)
- **SWL**: .swl files = WF, .sh files = Task (bash extracted from non-comment lines)
- **Nextflow**: `workflow {}` block = WF, `process {}` blocks = Task (bash from triple-quoted strings)
- **WDL**: `workflow {}` block = WF, `task {}` blocks = Task (bash from command blocks)
- **Python DSL**: Pipeline definition = WF, Tool/Step/Resource classes = Task (bash from base_command)
- **Nickel**: `in {}` block = WF, `let` bindings = Task (bash from second string after Task)
- **Nix**: `in {}` block = WF, `let` bindings = Task (bash from second string after Task)
- **Snakemake**: `rule all` + configfile = WF, other rules = Task (bash from shell: blocks)

## Directory Structure

```
comparison/
├── cwl/
│   ├── snv/ (7 files: workflow + 6 tools)
│   ├── cnv/ (9 files: workflow + 8 tools)
│   └── rna/ (5 files: workflow + 4 tools)
├── nextflow/
│   ├── snv/main.nf
│   ├── cnv/main.nf
│   └── rna/main.nf
├── wdl/
│   ├── snv/main.wdl
│   ├── cnv/main.wdl
│   └── rna/main.wdl
├── python/
│   ├── snv/main.py
│   ├── cnv/main.py
│   └── rna/main.py
├── nickel/
│   ├── snv/main.ncl
│   ├── cnv/main.ncl
│   └── rna/main.ncl
├── nix/
│   ├── snv/default.nix
│   ├── cnv/default.nix
│   └── rna/default.nix
├── swl/
│   ├── snv/ (1 .swl + 6 .sh tools)
│   ├── cnv/ (1 .swl + 8 .sh tools)
│   └── rna/ (1 .swl + 4 .sh tools)
└── snakemake/
    ├── snv/Snakefile
    ├── cnv/Snakefile
    └── rna/Snakefile
```

## Token Count Results

### Individual Workflows

| Workflow | Language | Files | Lines | Tokens | WF Tok | Task Tok | Bash |
|----------|----------|-------|-------|--------|--------|----------|------|
| SNV | CWL | 7 | 238 | 1441 | 430 | 1011 | 0 |
| SNV | Nextflow | 1 | 110 | 879 | 238 | 400 | 241 |
| SNV | WDL | 1 | 145 | 955 | 299 | 400 | 256 |
| SNV | Python DSL | 1 | 96 | 540 | 326 | 163 | 51 |
| SNV | Nickel | 1 | 121 | 1027 | 370 | 422 | 235 |
| SNV | Nix | 1 | 101 | 981 | 376 | 399 | 206 |
| SNV | SWL | 7 | 75 | 703 | 85 | 387 | 231 |
| SNV | Nix | 1 | 101 | 981 | 376 | 399 | 206 |
| SNV | Snakemake | 1 | 78 | 539 | 35 | 316 | 188 |
| CNV | CWL | 9 | 250 | 1464 | 423 | 1041 | 0 |
| CNV | Nextflow | 1 | 129 | 881 | 241 | 448 | 192 |
| CNV | WDL | 1 | 167 | 945 | 281 | 457 | 207 |
| CNV | Python DSL | 1 | 111 | 567 | 353 | 169 | 45 |
| CNV | Nickel | 1 | 116 | 1099 | 392 | 492 | 215 |
| CNV | SWL | 9 | 95 | 778 | 99 | 486 | 193 |
| CNV | Nix | 1 | 117 | 1113 | 392 | 506 | 215 |
| CNV | Snakemake | 1 | 95 | 586 | 35 | 376 | 175 |
| RNA-seq | CWL | 5 | 177 | 1002 | 245 | 757 | 0 |
| RNA-seq | Nextflow | 1 | 78 | 567 | 139 | 244 | 184 |
| RNA-seq | WDL | 1 | 122 | 814 | 181 | 409 | 224 |
| RNA-seq | Python DSL | 1 | 78 | 410 | 191 | 204 | 15 |
| RNA-seq | Nickel | 1 | 72 | 712 | 250 | 246 | 216 |
| RNA-seq | SWL | 5 | 57 | 521 | 43 | 287 | 191 |
| RNA-seq | Snakemake | 1 | 51 | 508 | 33 | 324 | 151 |

**Note**: Tokens = WF + Task + Bash

### Aggregate Summary

| Language | Lines | Tokens | Bash Tok | WF Tok | Task Tok | Non-Bash |
|----------|-------|--------|----------|--------|----------|----------|
| **CWL** | 665 | 3907 | 0 | 1098 | 2809 | 3907 |
| **Nextflow** | 317 | 2327 | 617 | 618 | 1092 | 1710 |
| **WDL** | 434 | 2714 | 687 | 761 | 1266 | 2027 |
| **Python DSL** | 285 | 1517 | 111 | 870 | 536 | 1406 |
| **Nickel** | 309 | 2838 | 666 | 1012 | 1160 | 2172 |
| **Nix** | 291 | 2820 | 637 | 1018 | 1165 | 2183 |
| **SWL** | 227 | 2002 | 615 | 227 | 1160 | 1387 |
| **Snakemake** | 224 | 1633 | 514 | 103 | 1016 | 1119 |

**Note**: Non-Bash = WF + Task = Tokens - Bash

