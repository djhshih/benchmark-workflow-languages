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

### Language-Specific Splitting Rules:

- **CWL**: Workflow .cwl files = WF, CommandLineTool .cwl files = Task
- **SWL**: .swl files = WF, .sh files = Task
- **Nextflow**: `workflow {}` block = WF, `process {}` blocks = Task
- **WDL**: `workflow {}` block = WF, `task {}` blocks = Task
- **Python DSL**: Pipeline definition = WF, Tool/Step/Resource classes = Task
- **Nickel**: `in {}` block = WF, `let` bindings = Task
- **Nix**: `in {}` block = WF, `let` bindings = Task
- **Snakemake**: `rule all` + configfile = WF, other rules = Task

## Token Count Results

### Individual Workflows

| Workflow | Language | Files | Lines | Tokens | WF Tokens | Task Tokens | Tokens/Line |
|----------|----------|-------|-------|--------|-----------|-------------|-------------|
| SNV | CWL | 7 | 238 | 941 | 260 | 681 | 3.95 |
| SNV | Nextflow | 1 | 110 | 720 | 175 | 545 | 6.55 |
| SNV | WDL | 1 | 145 | 781 | 249 | 532 | 5.39 |
| SNV | Python DSL | 1 | 96 | 608 | 388 | 220 | 6.33 |
| SNV | Nickel | 1 | 121 | 937 | 353 | 584 | 7.74 |
| SNV | Nix | 1 | 101 | 880 | 353 | 527 | 8.71 |
| SNV | SWL | 7 | 89 | 393 | 47 | 346 | 4.42 |
| SNV | Snakemake | 1 | 78 | 487 | 29 | 458 | 6.24 |
| CNV | CWL | 9 | 250 | 970 | 273 | 697 | 3.88 |
| CNV | Nextflow | 1 | 129 | 741 | 187 | 554 | 5.74 |
| CNV | WDL | 1 | 167 | 802 | 251 | 551 | 4.80 |
| CNV | Python DSL | 1 | 111 | 660 | 440 | 220 | 5.95 |
| CNV | Nickel | 1 | 108 | 846 | 330 | 516 | 7.83 |
| CNV | Nix | 1 | 109 | 855 | 330 | 525 | 7.84 |
| CNV | SWL | 9 | 118 | 437 | 63 | 374 | 3.70 |
| CNV | Snakemake | 1 | 95 | 533 | 27 | 506 | 5.61 |
| RNA-seq | CWL | 5 | 177 | 765 | 169 | 596 | 4.32 |
| RNA-seq | Nextflow | 1 | 78 | 546 | 139 | 407 | 7.00 |
| RNA-seq | WDL | 1 | 113 | 655 | 143 | 512 | 5.80 |
| RNA-seq | Python DSL | 1 | 78 | 479 | 256 | 223 | 6.14 |
| RNA-seq | Nickel | 1 | 67 | 597 | 225 | 372 | 8.91 |
| RNA-seq | Nix | 1 | 68 | 606 | 225 | 381 | 8.91 |
| RNA-seq | SWL | 5 | 67 | 297 | 31 | 266 | 4.43 |
| RNA-seq | Snakemake | 1 | 51 | 458 | 27 | 431 | 8.98 |

### Aggregate Summary

| Language | Total Lines | Total Tokens | WF Tokens | Task Tokens | Tokens/Line |
|----------|-------------|--------------|-----------|-------------|-------------|
| **CWL** | 665 | 2676 | 702 | 1974 | 4.02 |
| **Nextflow** | 317 | 2007 | 501 | 1506 | 6.33 |
| **WDL** | 425 | 2238 | 643 | 1595 | 5.27 |
| **Python DSL** | 285 | 1747 | 1084 | 663 | 6.13 |
| **Nickel** | 296 | 2380 | 908 | 1472 | 8.04 |
| **Nix** | 278 | 2341 | 908 | 1433 | 8.42 |
| **SWL** | 274 | 1127 | 141 | 986 | 4.11 |
| **Snakemake** | 224 | 1478 | 83 | 1395 | 6.60 |

**Note**: Total = WF Tokens + Task Tokens (trivial identity by construction).

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

### File Count
- **CWL requires 5-9 files** per workflow (1 workflow + 4-8 tools)
- **SWL requires 5-9 files** per workflow (1 .swl + 4-8 .sh)
- **All other languages** use 1 file per workflow

### WF vs Task Distribution
- **Snakemake**: Most task-heavy (95%+ in tasks) - each rule is a task
- **CWL**: High task ratio (74%) - separate tool files
- **Nickel/Nix**: Balanced (~60% tasks) - let bindings vs in block

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
| Most expressive (tok/line) | CWL (4.02) | Nix (8.42) |
| Fewest files | NF/WDL/Py/Ncl/Nix/Smk (1) | CWL/SWL (5-9) |
| Full resources (CPU/Mem/Disk) | CWL, Python, Nickel, Nix, Snakemake | Nextflow, WDL |
| Multi-target transpile | Python DSL | Others |
| Shell script integration | SWL | Others |
| Most task-oriented | Snakemake (94% tasks) | - |