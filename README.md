# Bioinformatics Workflow Language Comparison

This directory compares workflow languages for defining bioinformatics pipelines.

## Summary Statistics (3 pipelines, all languages)

| Language | Lines | Tokens | Bash Tokens | WF Tokens | Task Tokens | Non-Bash |
|----------|-------|--------|-------------|-----------|-------------|----------|
| **CWL** | 665 | 2676 | 0 | 702 | 1974 | 2676 |
| **Nextflow** | 317 | 2053 | 504 | 489 | 1060 | 1549 |
| **WDL** | 434 | 2330 | 532 | 675 | 1123 | 1798 |
| **Python DSL** | 285 | 1747 | 48 | 1084 | 615 | 1699 |
| **Nickel** | 309 | 2637 | 621 | 1010 | 1006 | 2016 |
| **Nix** | 291 | 2598 | 587 | 1010 | 1001 | 2011 |
| **SWL** | 280 | 1271 | 579 | 141 | 551 | 692 |
| **Snakemake** | 224 | 1697 | 467 | 128 | 1102 | 1230 |

**Notes**: 
- Tokens = WF Tokens + Task Tokens + Bash Tokens
- Non-Bash = WF Tokens + Task Tokens
- Indentation levels counted as `[indent]` tokens (4 spaces = 1 indent, except SWL, which uses 2 spaces = 1 indent)

## Pipelines

- **SNV Calling**: 6 steps (BWA → MarkDuplicates → BaseRecalibrator → ApplyBQSR → HaplotypeCaller → VariantFilter)
- **CNV Calling**: 8 steps (BWA → SortBAM → IndexBAM → CollectReadCounts → CountGC → DenoiseReadCounts → SegmentDenoisedCopyRatios → ModelSegments)
- **RNA-seq**: 4 steps (Trimmomatic → STAR → FastQC → featureCounts)

## Language Details

| Language | Files/Pipeline | Description |
|----------|----------------|-------------|
| **CWL** | 5-9 | Common Workflow Language, separate files for workflow and tasks |
| **Nextflow** | 1 | DSL2-based, HPC-friendly, single file (workflow {} vs process {}) |
| **WDL** | 1 | Workflow Description Language, single file (workflow {} vs task {}) |
| **Python DSL** | 1 | Custom Python-based DSL (Pipeline vs Tool definitions) |
| **Nickel** | 1 | Pure configuration language |
| **Nix** | 1 | Nix expression language |
| **SWL** | 5-9 | Shell Workflow Language - .swl files = workflow, .sh files = tasks |
| **Snakemake** | 1 | Python-based DSL, rule-based (rule all vs other rules) |

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
