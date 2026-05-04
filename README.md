# Bioinformatics Pipeline Language Comparison

This directory compares languages for defining bioinformatics pipelines that can transpile to CWL, Nextflow, and/or WDL.

## Summary Statistics (3 pipelines, all languages)

| Language | Total Tokens | Files | Lines | Tokens/Line |
|----------|-------------|-------|-------|-------------|
| **Nickel** | 1447 | 3 | 414 | 3.50 |
| **WDL** | 1034 | 3 | 425 | 2.43 |
| **Nix** | 861 | 3 | 149 | 5.78 |
| **SWL** | 782 | 21 | 183 | 4.27 |
| **Python DSL** | 766 | 3 | 285 | 2.69 |
| **Nextflow** | 826 | 3 | 317 | 2.61 |
| **CWL** | 1187 | 21 | 665 | 1.78 |

## Pipelines

- **SNV Calling**: 6 steps (BWA → MarkDuplicates → BaseRecalibrator → ApplyBQSR → HaplotypeCaller → VariantFilter)
- **CNV Calling**: 8 steps (BWA → SortBAM → IndexBAM → CollectReadCounts → CollectGC → DenoiseCoverage → SegmentCNV → CallCNV)
- **RNA-seq**: 4 steps (Trimmomatic → STAR → FastQC → featureCounts)

## Language Details

| Language | Files/Pipeline | Description |
|----------|----------------|-------------|
| **CWL** | 5-9 | Common Workflow Language - verbose, separate files for workflow and tasks |
| **Nextflow** | 1 | DSL2-based, HPC-friendly, single file |
| **WDL** | 1 | Workflow Description Language - Terra-compatible |
| **Python DSL** | 1 | Custom Python-based DSL for multi-target transpilation |
| **Nickel** | 1 | Pure configuration language, generates CWL |
| **Nix** | 1 | Nix expression language, generates CWL |
| **SWL** | 5-9 | Shell Workflow Language - annotated shell scripts with pipe composition |

## Run Token Counter

```bash
python3 count_tokens.py
```

## Files

| File | Description |
|------|-------------|
| `count_tokens.py` | Script that counts non-comment lines and tokens |
| `comparison.md` | Full analysis with realistic code examples |
| `cwl/`, `nextflow/`, `wdl/`, `python/`, `nickel/`, `nix/`, `swl/` | Language-specific implementations |