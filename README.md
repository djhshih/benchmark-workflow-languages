# Bioinformatics Pipeline Language Comparison

This directory compares languages for defining bioinformatics pipelines that can transpile to CWL, Nextflow, and/or WDL.

## Implemented Languages

| Language | Files | Tokens/Line | Description |
|----------|-------|-------------|-------------|
| **CWL** | 7-9/workflow | 1.90 | Common Workflow Language - verbose, separate files for workflow and tools |
| **Nextflow** | 1/workflow | 2.58 | DSL2-based, HPC-friendly, single file |
| **WDL** | 1/workflow | 1.97 | Workflow Description Language - Terra-compatible |
| **Python DSL** | 1/workflow | 3.59 | Custom Python-based DSL for multi-target transpilation |
| **Nickel** | 1/workflow | 2.34 | Pure configuration language, generates CWL |
| **SWL** | 7-9/workflow | 5.05 | Shell Workflow Language - annotated shell scripts with pipe composition |

## Pipelines

- **SNV Calling**: 6 steps (BWA → MarkDuplicates → BaseRecalibrator → ApplyBQSR → HaplotypeCaller → VariantFilter)
- **CNV Calling**: 8 steps (BWA → SortBAM → IndexBAM → CollectReadCounts → CollectGC → DenoiseCoverage → SegmentCNV → CallCNV)

## Files

| File | Description |
|------|-------------|
| `count_tokens.py` | Script that counts non-comment lines and tokens |
| `comparison.md` | Full analysis with realistic code examples |
| `cwl/`, `nextflow/`, `wdl/`, `python/`, `nickel/`, `swl/` | Language-specific implementations |

## Run Token Counter

```bash
python3 count_tokens.py
```

