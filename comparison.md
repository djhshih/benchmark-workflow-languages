# Comprehensive Pipeline Language Comparison

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

## Token Count Results

### Individual Workflows

| Workflow | Language | Files | Lines | Tokens | WF Tok | Task Tok | Bash |
|----------|----------|-------|-------|--------|--------|----------|------|
| SNV | CWL | 7 | 238 | 941 | 260 | 681 | 0 |
| SNV | Nextflow | 1 | 110 | 720 | 175 | 354 | 191 |
| SNV | WDL | 1 | 145 | 781 | 249 | 337 | 195 |
| SNV | Python DSL | 1 | 96 | 608 | 388 | 196 | 24 |
| SNV | Nickel | 1 | 121 | 937 | 353 | 361 | 223 |
| SNV | Nix | 1 | 101 | 880 | 353 | 338 | 189 |
| SNV | SWL | 7 | 89 | 393 | 47 | 158 | 188 |
| SNV | Snakemake | 1 | 78 | 487 | 29 | 294 | 164 |
| CNV | CWL | 9 | 250 | 970 | 273 | 697 | 0 |
| CNV | Nextflow | 1 | 129 | 741 | 187 | 408 | 146 |
| CNV | WDL | 1 | 167 | 802 | 251 | 401 | 150 |
| CNV | Python DSL | 1 | 111 | 660 | 440 | 204 | 16 |
| CNV | Nickel | 1 | 108 | 846 | 330 | 343 | 173 |
| CNV | Nix | 1 | 109 | 855 | 330 | 352 | 173 |
| CNV | SWL | 9 | 118 | 437 | 63 | 203 | 171 |
| CNV | Snakemake | 1 | 95 | 533 | 27 | 355 | 151 |
| RNA-seq | CWL | 5 | 177 | 765 | 169 | 596 | 0 |
| RNA-seq | Nextflow | 1 | 78 | 546 | 139 | 244 | 163 |
| RNA-seq | WDL | 1 | 113 | 655 | 143 | 349 | 163 |
| RNA-seq | Python DSL | 1 | 78 | 479 | 256 | 215 | 8 |
| RNA-seq | Nickel | 1 | 67 | 597 | 225 | 189 | 183 |
| RNA-seq | Nix | 1 | 68 | 606 | 225 | 198 | 183 |
| RNA-seq | SWL | 5 | 67 | 297 | 31 | 110 | 156 |
| RNA-seq | Snakemake | 1 | 51 | 458 | 27 | 288 | 143 |

**Note**: Tokens = WF + Task + Bash (trivial identity)

### Aggregate Summary

| Language | Lines | Tokens | Bash Tok | WF Tok | Task Tok | Non-Bash |
|----------|-------|--------|----------|--------|----------|----------|
| **CWL** | 665 | 2676 | 0 | 702 | 1974 | 2676 |
| **Nextflow** | 317 | 2007 | 500 | 501 | 1006 | 1507 |
| **WDL** | 425 | 2238 | 508 | 643 | 1087 | 1730 |
| **Python DSL** | 285 | 1747 | 48 | 1084 | 615 | 1699 |
| **Nickel** | 296 | 2380 | 579 | 908 | 893 | 1801 |
| **Nix** | 278 | 2341 | 545 | 908 | 888 | 1796 |
| **SWL** | 274 | 1127 | 515 | 141 | 471 | 612 |
| **Snakemake** | 224 | 1478 | 458 | 83 | 937 | 1020 |

**Note**: Non-Bash = WF + Task = Tokens - Bash

## Resource Specification

All pipelines specify equivalent resources:

| Language | CPU | Memory | Disk | Notes |
|----------|-----|--------|------|-------|
| CWL | coresMin | ramMin | outdirMin | Native syntax |
| Nextflow | cpus | memory | N/A | No native disk |
| WDL | cpu | memory | N/A | No native disk |
| Python DSL | cpu | memory_mb | disk_mb | Native syntax |
| Nickel | cpu | memory | disk | Native syntax |
| Nix | cpu | memory | disk | Native syntax |
| SWL | cpu (in # run) | memory (in # run) | disk (in # run) | Annotated comments |
| Snakemake | cpu | mem_mb | disk_mb | Native syntax |

## Analysis

### Expressiveness (Tokens per Line)
- **Nix** and **Nickel** are least expressive (8+ tok/line) - highly structured configuration
- **CWL** most concise (4 tok/line) - declarative YAML
- **SWL** moderate (4 tok/line) - shell-based with annotations

### Bash Token Distribution
- **CWL**: No bash tokens (declarative, no verbatim commands)
- **SWL**: Highest bash ratio (46%) - actual shell scripts
- **WDL/Nix/Nickel**: ~23-25% bash (command strings in task definitions)
- **Snakemake**: 31% bash (shell: blocks)

### File Count
- **CWL requires 5-9 files** per workflow (1 workflow + 4-8 tools)
- **SWL requires 5-9 files** per workflow (1 .swl + 4-8 .sh)
- **All other languages** use 1 file per workflow

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

## Conclusions

| Criterion | Best | Worst |
|-----------|------|-------|
| Most concise (tok/line) | CWL (4.02) | Nix (8.42) |
| Fewest files | NF/WDL/Py/Ncl/Nix/Smk (1) | CWL/SWL (5-9) |
| Most bash-oriented | SWL (46%) | CWL (0%) |
| Full resources (CPU/Mem/Disk) | CWL, Python, Nickel, Nix, Snakemake | Nextflow, WDL |