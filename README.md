# Bioinformatics Workflow Language Comparison

This directory compares workflow languages for defining bioinformatics pipelines.

## Summary Statistics (3 pipelines, all languages)

| Language | Lines | Tokens | Bash Tokens | WF Tokens | Task Tokens | Non-Bash |
|----------|-------|--------|-------------|-----------|-------------|----------|
| **CWL** | 665 | 3907 | 0 | 1098 | 2809 | 3907 |
| **Nextflow** | 317 | 2327 | 617 | 618 | 1092 | 1710 |
| **WDL** | 434 | 2714 | 687 | 761 | 1266 | 2027 |
| **Python DSL** | 285 | 1517 | 111 | 870 | 536 | 1406 |
| **Nickel** | 309 | 2838 | 666 | 1012 | 1160 | 2172 |
| **Nix** | 291 | 2820 | 637 | 1018 | 1165 | 2183 |
| **SWL** | 280 | 2185 | 1729 | 291 | 165 | 456 |
| **Snakemake** | 224 | 1633 | 514 | 103 | 1016 | 1119 |

**Notes**: 
- Tokens = WF Tokens + Task Tokens + Bash Tokens
- Non-Bash = WF Tokens + Task Tokens
- Tokens counted using OpenAI's `o200k_harmony` BPE tokenizer (via `tiktoken`)

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
