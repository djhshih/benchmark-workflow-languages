# Bioinformatics Pipeline Language Comparison

This directory compares languages for defining bioinformatics pipelines that can transpile to CWL, Nextflow, and/or WDL.

## Summary Statistics (3 pipelines, all languages)

| Language | Total Tokens | WF Tokens | Task Tokens | Lines | Tokens/Line |
|----------|-------------|-----------|-------------|-------|-------------|
| **Nickel** | 2380 | 908 | 1472 | 296 | 8.04 |
| **Nix** | 2341 | 908 | 1433 | 278 | 8.42 |
| **CWL** | 2676 | 702 | 1974 | 665 | 4.02 |
| **WDL** | 2238 | 643 | 1595 | 425 | 5.27 |
| **Python DSL** | 1747 | 1084 | 663 | 285 | 6.13 |
| **Nextflow** | 2007 | 501 | 1506 | 317 | 6.33 |
| **SWL** | 1127 | 141 | 986 | 274 | 4.11 |
| **Snakemake** | 1478 | 83 | 1395 | 224 | 6.60 |

Run `count_tokens.py` to see what tokens are counted.

## Pipelines

- **SNV Calling**: 6 steps (BWA → MarkDuplicates → BaseRecalibrator → ApplyBQSR → HaplotypeCaller → VariantFilter)
- **CNV Calling**: 8 steps (BWA → SortBAM → IndexBAM → CollectReadCounts → CountGC → DenoiseReadCounts → SegmentDenoisedCopyRatios → ModelSegments)
- **RNA-seq**: 4 steps (Trimmomatic → STAR → FastQC → featureCounts)

## Language Details

| Language | Files/Pipeline | Description |
|----------|----------------|-------------|
| **CWL** | 5-9 | Common Workflow Language based on YAML |
| **Nextflow** | 1 | Groovy-based DSL (workflow {} vs process {}) |
| **WDL** | 1 | Workflow Description Language (workflow {} vs task {}) |
| **Python DSL** | 1 | Custom Python-based DSL (Pipeline vs Tool definitions) |
| **Nickel** | 1 | Pure configuration language |
| **Nix** | 1 | Nix expression language |
| **SWL** | 5-9 | Simple Workflow Language - .swl files = workflow, .sh files = tasks |
| **Snakemake** | 1 | Python-based DSL, rule-based (rule all + other rules) |

## Run Token Counter

```bash
python3 count_tokens.py
```

## Files

| File | Description |
|------|-------------|
| `count_tokens.py` | Script that counts non-comment lines, tokens, and splits WF/Task |
| `comparison.md` | Full analysis with per-pipeline token counts |
| `cwl/`, `nextflow/`, `wdl/`, `python/`, `nickel/`, `nix/`, `swl/`, `snakemake/` | Language-specific implementations |
