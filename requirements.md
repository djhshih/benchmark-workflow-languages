# Requirements for Running Pipelines

This document lists all software dependencies required to execute the bioinformatics pipelines in this comparison.

## Core Workflow Runners

| Language | Tool | Version |
|----------|------|---------|
| CWL | [cwltool](https://github.com/common-workflow-language/cwltool) | >= 3.0 |
| Nextflow | [nextflow](https://www.nextflow.io/) | >= 22.0 |
| WDL | [cromwell](https://github.com/broadinstitute/cromwell) | >= 50.0 |
| Snakemake | [snakemake](https://snakemake.github.io/) | >= 7.0 |
| Nickel | [nickel](https://nickel-lang.org/) | >= 0.11.0 |
| Nix | [nix](https://nixos.org/nix/) | >= 2.18 |
| SWL | Custom runner (see `extra/transcompile.py`) | - |
| Python | Python 3.10+ | - |

## Bioinformatics Tools

### SNV Pipeline

| Tool | Purpose | Version |
|------|---------|---------|
| [bwa](https://github.com/lh3/bwa) | Read alignment | >= 0.7.17 |
| [samtools](http://www.htslib.org/) | SAM/BAM manipulation | >= 1.15 |
| [Picard](https://broadinstitute.github.io/picard/) | MarkDuplicates | >= 2.27 |
| [GATK](https://github.com/broadinstitute/gatk) | BaseRecalibrator, ApplyBQSR, HaplotypeCaller, VariantRecalibrator | >= 4.4 |

### CNV Pipeline

| Tool | Purpose | Version |
|------|---------|---------|
| bwa | Read alignment | >= 0.7.17 |
| samtools | SAM/BAM manipulation | >= 1.15 |
| GATK | CollectReadCounts, CountGC, DenoiseReadCounts, SegmentDenoisedCopyRatios, ModelSegments | >= 4.4 |

### RNA-seq Pipeline

| Tool | Purpose | Version |
|------|---------|---------|
| [Trimmomatic](http://www.usadellab.org/cms/?page=trimmomatic) | Quality trimming | >= 0.39 |
| [FASTQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) | QC analysis | >= 0.11 |
| [STAR](https://github.com/alexdobin/STAR) | Splice-aware alignment | >= 2.7 |
| [featureCounts](http://subread.sourceforge.net/) | Read counting | >= 2.0 |

## Reference Data

The pipelines require the following reference data:

- **Genome reference** (`reference.fa`) - FASTA file
- **Reference dictionary** (`reference.dict`) - Created by Picard CreateSequenceDictionary
- **Reference index** (`reference.fa.fai`) - Created by samtools faidx
- **Known variant sites** (`dbsnp.vcf`) - For BQSR
- **Target intervals** (`targets.bed`) - For CNV calling
- **Reference panel** (PoN) - Panel of Normals for CNV denoising
- **STAR index** - Pre-built STAR index directory
- **GTF annotation** (`annotation.gtf`) - Gene annotation for featureCounts

## Installation

### Using Conda

```bash
conda create -n pipelines -c bioconda -c conda-forge \
  bwa samtools picard gatk4 star subread fastqc trimmomatic \
  cwltool snakemake nextflow
conda activate pipelines
```

### Using Nix

```bash
nix-shell -p bwa samtools gatk4 star subread fastqc trimmomatic
```

### For CWL

```bash
pip install cwltool
```

### For Nextflow

```bash
curl -s https://get.nextflow.io | bash
```

### For WDL

Download Cromwell from https://github.com/broadinstitute/cromwell/releases

### For Snakemake

```bash
pip install snakemake
```

### For Nickel

```bash
nix-env -iA nixpkgs.nickel
```

## Running the Pipelines

### CWL

```bash
cwltool cwl/snv/workflow.cwl inputs.yaml
```

### Nextflow

```bash
nextflow run nextflow/snv/main.nf -params-file inputs.yaml
```

### WDL

```bash
java -jar cromwell.jar run wdl/snv/main.wdl -inputs inputs.yaml
```

### Snakemake

```bash
snakemake -s snakemake/snv/Snakefile
```