# Workflow Language Comparison

## Overview

This comparison evaluates 8 configuration/task languages for specifying bioinformatics workflows (SNV, CNV, and RNA-seq pipelines) that can transpile to CWL.

## Pipelines Evaluated

1. **SNV Calling** - 6 steps: BWA alignment → Mark Duplicates → Base Recalibrator → Apply BQSR → Haplotype Caller → Variant Filter
2. **CNV Calling** - 8 steps: BWA → Sort BAM → Index BAM → Collect Read Counts → Collect GC → Denoise Coverage → Segment CNV → Call CNV
3. **RNA-seq** - 4 steps: Trimmomatic → STAR alignment → FastQC → featureCounts

## Token Count Methodology

A **token** is a whitespace-separated unit in the source code, including:
- Keywords: `process`, `task`, `workflow`, `in`, `out`, `run`, `let`, `rule`, etc.
- Identifiers: variable names, tool names, file paths
- Operators: `=`, `+`, `-`, `>`, `<`, `->`, etc.
- Punctuation: `:`, `{`, `}`, `(`, `)`, `[`, `]`, `,`, `|`, `.`, `"`, `'`
- **Indentation**: `[indent]` tokens (4 spaces = 1 indent for most languages; SWL uses 2 spaces = 1 indent)

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
| SNV | CWL | 7 | 238 | 941 | 260 | 681 | 0 |
| SNV | Nextflow | 1 | 110 | 738 | 175 | 372 | 191 |
| SNV | WDL | 1 | 145 | 781 | 249 | 337 | 195 |
| SNV | Python DSL | 1 | 96 | 608 | 388 | 196 | 24 |
| SNV | Nickel | 1 | 121 | 937 | 353 | 361 | 223 |
| SNV | Nix | 1 | 101 | 880 | 353 | 338 | 189 |
| SNV | SWL | 7 | 92 | 426 | 47 | 176 | 203 |
| SNV | Snakemake | 1 | 78 | 571 | 44 | 358 | 169 |
| CNV | CWL | 9 | 250 | 970 | 273 | 697 | 0 |
| CNV | Nextflow | 1 | 129 | 765 | 187 | 432 | 146 |
| CNV | WDL | 1 | 167 | 802 | 251 | 401 | 150 |
| CNV | Python DSL | 1 | 111 | 660 | 440 | 204 | 16 |
| CNV | Nickel | 1 | 116 | 999 | 393 | 414 | 192 |
| CNV | Nix | 1 | 117 | 1008 | 393 | 423 | 192 |
| CNV | SWL | 9 | 118 | 484 | 63 | 229 | 192 |
| CNV | Snakemake | 1 | 95 | 601 | 42 | 404 | 155 |
| RNA-seq | CWL | 5 | 177 | 765 | 169 | 596 | 0 |
| RNA-seq | Nextflow | 1 | 78 | 550 | 127 | 256 | 167 |
| RNA-seq | WDL | 1 | 122 | 747 | 175 | 385 | 187 |
| RNA-seq | Python DSL | 1 | 78 | 479 | 256 | 215 | 8 |
| RNA-seq | Nickel | 1 | 72 | 701 | 264 | 231 | 206 |
| RNA-seq | Nix | 1 | 73 | 710 | 264 | 240 | 206 |
| RNA-seq | SWL | 5 | 70 | 361 | 31 | 146 | 184 |
| RNA-seq | Snakemake | 1 | 51 | 525 | 42 | 340 | 143 |

**Note**: Tokens = WF + Task + Bash

### Aggregate Summary

| Language | Lines | Tokens | Bash Tok | WF Tok | Task Tok | Non-Bash |
|----------|-------|--------|----------|--------|----------|----------|
| **CWL** | 665 | 2676 | 0 | 702 | 1974 | 2676 |
| **Nextflow** | 317 | 2053 | 504 | 489 | 1060 | 1549 |
| **WDL** | 434 | 2330 | 532 | 675 | 1123 | 1798 |
| **Python DSL** | 285 | 1747 | 48 | 1084 | 615 | 1699 |
| **Nickel** | 309 | 2637 | 621 | 1010 | 1006 | 2016 |
| **Nix** | 291 | 2598 | 587 | 1010 | 1001 | 2011 |
| **SWL** | 280 | 1271 | 579 | 141 | 551 | 692 |
| **Snakemake** | 224 | 1697 | 467 | 128 | 1102 | 1230 |

**Note**: Non-Bash = WF + Task = Tokens - Bash

