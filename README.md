# Bioinformatics Pipeline Language Comparison

This directory compares languages for defining bioinformatics pipelines that can transpile to CWL, Nextflow, and/or WDL.

## Summary Statistics (3 pipelines, all languages)

| Language | Lines | Tokens | Bash Tokens | WF Tokens | Task Tokens | Non-Bash |
|----------|-------|--------|-------------|-----------|-------------|----------|
| **CWL** | 665 | 2676 | 0 | 702 | 1974 | 2676 |
| **Nextflow** | 317 | 2007 | 500 | 501 | 1006 | 1507 |
| **WDL** | 425 | 2238 | 508 | 643 | 1087 | 1730 |
| **Python DSL** | 285 | 1747 | 48 | 1084 | 615 | 1699 |
| **Nickel** | 296 | 2380 | 579 | 908 | 893 | 1801 |
| **Nix** | 278 | 2341 | 545 | 908 | 888 | 1796 |
| **SWL** | 274 | 1127 | 515 | 141 | 471 | 612 |
| **Snakemake** | 224 | 1478 | 458 | 83 | 937 | 1020 |

**Notes**: 
- Tokens = WF Tokens + Task Tokens + Bash Tokens (trivial identity)
- Non-Bash = WF Tokens + Task Tokens = Tokens - Bash Tokens
- Indentation levels counted as `[indent]` tokens (4 spaces = 1 indent, except SWL uses 2 spaces = 1 indent)

## Pipelines

- **SNV Calling**: 6 steps (BWA → MarkDuplicates → BaseRecalibrator → ApplyBQSR → HaplotypeCaller → VariantFilter)
- **CNV Calling**: 8 steps (BWA → SortBAM → IndexBAM → CollectReadCounts → CountGC → DenoiseReadCounts → SegmentDenoisedCopyRatios → ModelSegments)
- **RNA-seq**: 4 steps (Trimmomatic → STAR → FastQC → featureCounts)

## Language Details

| Language | Files/Pipeline | Description |
|----------|----------------|-------------|
| **CWL** | 5-9 | Common Workflow Language - verbose, separate files for workflow and tasks |
| **Nextflow** | 1 | DSL2-based, HPC-friendly, single file (workflow {} vs process {}) |
| **WDL** | 1 | Workflow Description Language - Terra-compatible (workflow {} vs task {}) |
| **Python DSL** | 1 | Custom Python-based DSL (Pipeline vs Tool definitions) |
| **Nickel** | 1 | Pure configuration language (in block vs let blocks) |
| **Nix** | 1 | Nix expression language (in block vs let blocks) |
| **SWL** | 5-9 | Shell Workflow Language - .swl files = workflow, .sh files = tasks |
| **Snakemake** | 1 | Python-based DSL, rule-based (rule all + configfile vs other rules) |

See the [nixflow][nixflow] repo on how Nix and Nickel can be used to generate
CWL.

[nixflow]: https://github.com/djhshih/nixflow

## Run Token Counter

```bash
python3 count_tokens.py
```

## Files

| File | Description |
|------|-------------|
| `count_tokens.py` | Script that counts non-comment lines, tokens, and splits WF/Task/Bash |
| `comparison.md` | Full analysis with per-pipeline token counts |
| `cwl/`, `nextflow/`, `wdl/`, `python/`, `nickel/`, `nix/`, `swl/`, `snakemake/` | Language-specific implementations |
