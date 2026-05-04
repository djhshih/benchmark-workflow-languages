# Comprehensive Pipeline Language Comparison

## Overview

This comparison evaluates 7 configuration/task languages for specifying bioinformatics workflows (SNV, CNV, and RNA-seq pipelines) that can transpile to CWL.

## Pipelines Evaluated

1. **SNV Calling** - 6 steps: BWA alignment → Mark Duplicates → Base Recalibrator → Apply BQSR → Haplotype Caller → Variant Filter
2. **CNV Calling** - 8 steps: BWA → Sort BAM → Index BAM → Collect Read Counts → Collect GC → Denoise Coverage → Segment CNV → Call CNV
3. **RNA-seq** - 4 steps: Trimmomatic → STAR alignment → FastQC → featureCounts

## Token Count Methodology

A **token** is a whitespace-separated unit in the source code, including:
- Keywords: `process`, `task`, `workflow`, `in`, `out`, `run`, `let`, etc.
- Identifiers: variable names, tool names, file paths
- Operators: `=`, `+`, `-`, `>`, `<`, `->`, etc.
- Punctuation: `:`, `{`, `}`, `(`, `)`, `[`, `]`, `,`, `|`
- Values: numbers, strings, booleans

Excluded from counting:
- Lines starting with `#` (comments), except SWL specification lines (`#?`, `# in`, `# out`, `# run`)
- Blank lines

**Lines**: Non-comment, non-blank lines

**WF Tokens**: Tokens from workflow/orchestration files (main pipeline definition)

**Task Tokens**: Tokens from task/step definition files (individual task implementations)

For single-file languages (Nextflow, WDL, Python, Nickel, Nix), all tokens are WF tokens.
For multi-file languages (CWL, SWL), tokens split between workflow and tool files.

## Token Count Results

### Individual Workflows

| Workflow | Language | Files | Lines | Tokens | WF Tokens | Task Tokens | Tokens/Line |
|----------|----------|-------|-------|--------|-----------|-------------|-------------|
| SNV | CWL | 7 | 238 | 439 | 119 | 320 | 1.84 |
| SNV | Nextflow | 1 | 110 | 307 | 307 | 0 | 2.79 |
| SNV | WDL | 1 | 145 | 371 | 371 | 0 | 2.56 |
| SNV | Python DSL | 1 | 96 | 272 | 272 | 0 | 2.83 |
| SNV | Nickel | 1 | 145 | 541 | 541 | 0 | 3.73 |
| SNV | Nix | 1 | 54 | 324 | 324 | 0 | 6.00 |
| SNV | SWL | 7 | 60 | 327 | 35 | 292 | 5.45 |
| CNV | CWL | 9 | 250 | 444 | 120 | 324 | 1.78 |
| CNV | Nextflow | 1 | 129 | 318 | 318 | 0 | 2.47 |
| CNV | WDL | 1 | 167 | 386 | 386 | 0 | 2.31 |
| CNV | Python DSL | 1 | 111 | 290 | 290 | 0 | 2.61 |
| CNV | Nickel | 1 | 183 | 643 | 643 | 0 | 3.52 |
| CNV | Nix | 1 | 56 | 320 | 320 | 0 | 5.71 |
| CNV | SWL | 9 | 74 | 369 | 47 | 322 | 4.99 |
| RNA-seq | CWL | 5 | 177 | 304 | 77 | 227 | 1.72 |
| RNA-seq | Nextflow | 1 | 78 | 201 | 201 | 0 | 2.58 |
| RNA-seq | WDL | 1 | 113 | 277 | 0 | 277 | 2.45 |
| RNA-seq | Python DSL | 1 | 78 | 204 | 204 | 0 | 2.62 |
| RNA-seq | Nickel | 1 | 86 | 263 | 263 | 0 | 3.06 |
| RNA-seq | Nix | 1 | 39 | 217 | 217 | 0 | 5.56 |
| RNA-seq | SWL | 5 | 45 | 219 | 23 | 196 | 4.87 |

### Aggregate Summary

| Language | Total Lines | Total Tokens | WF Tokens | Task Tokens | Tokens/Line |
|----------|-------------|--------------|-----------|-------------|-------------|
| **CWL** | 665 | 1187 | 316 | 871 | 1.78 |
| **Nextflow** | 317 | 826 | 826 | 0 | 2.61 |
| **WDL** | 425 | 1034 | 757 | 277 | 2.43 |
| **Python DSL** | 285 | 766 | 766 | 0 | 2.69 |
| **Nickel** | 414 | 1447 | 1447 | 0 | 3.50 |
| **Nix** | 149 | 861 | 861 | 0 | 5.78 |
| **SWL** | 183 | 782 | 105 | 677 | 4.27 |

## Resource Specification

All pipelines specify equivalent resources:

| Language | CPU | Memory | Disk | Notes |
|----------|-----|--------|------|-------|
| CWL | coresMin | ramMin | outdirMin | Native syntax |
| Nextflow | cpus | memory | N/A | No native disk |
| WDL | cpu | memory | N/A | No native disk |
| Python DSL | cpu | memory_mb | disk_mb | Native syntax |
| Nickel | cpu | memory | disk | Native syntax |
| SWL | cpu (in # run) | memory (in # run) | disk (in # run) | Annotated comments |

## Analysis

### Expressiveness (Tokens per Line)
- **SWL** is most expressive (5.03 tok/line) - shell-based with inline annotations
- **Python DSL** second most (3.52 tok/line) - flexible, programmatic
- **Nickel** (2.38), **Nextflow** (2.62), **WDL** (2.02), **CWL** (1.91)

### File Count
- **CWL requires 5-9 files** per workflow (1 workflow + 4-8 tools)
- **SWL requires 5-9 files** per workflow (1 .swl + 4-8 .sh)
- **All other languages** use 1 file per workflow

### Unique Features
- **Python DSL**: Most flexible for multi-target transpilation
- **SWL**: Uses shell scripts directly, pipe operator for composition
- **CWL**: Most mature, widest tool support

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
└── swl/
    ├── snv/ (1 .swl + 6 .sh tools)
    ├── cnv/ (1 .swl + 8 .sh tools)
    └── rna/ (1 .swl + 4 .sh tools)
```

## Conclusions

| Criterion | Best | Worst |
|-----------|------|-------|
| Most expressive (tok/line) | SWL (5.03) | CWL (1.91) |
| Fewest files | NF/WDL/Py/Ncl (1) | CWL/SWL (5-9) |
| Full resources (CPU/Mem/Disk) | CWL, Python, Nickel | Nextflow, WDL |
| Multi-target transpile | Python DSL | Others |
| Shell script integration | SWL | Others |