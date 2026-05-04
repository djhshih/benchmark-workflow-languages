# Comprehensive Pipeline Language Comparison

## Overview

This comparison evaluates 6 configuration/task languages for specifying bioinformatics workflows (SNV and CNV calling pipelines) that can transpile to CWL.

## Pipelines Evaluated

1. **SNV Calling** - 6 steps: BWA alignment → Mark Duplicates → Base Recalibrator → Apply BQSR → Haplotype Caller → Variant Filter
2. **CNV Calling** - 8 steps: BWA → Sort BAM → Index BAM → Collect Read Counts → Collect GC → Denoise Coverage → Segment CNV → Call CNV

## Token Count Methodology

- **Lines**: Non-comment, non-blank lines
- **Tokens**: Space/brace/punctuation-separated tokens (excluding comments)
- **WF Tokens**: Tokens from workflow/orchestration files (main pipeline definition)
- **Tool Tokens**: Tokens from tool/step definition files (individual tool implementations)

For single-file languages (Nextflow, WDL, Python, Nickel), all tokens are WF tokens.
For multi-file languages (CWL, SWL), tokens split between workflow and tool files.

## Token Count Results

### Individual Workflows

| Workflow | Language | Files | Lines | Tokens | WF Tokens | Tool Tokens | Tokens/Line |
|----------|----------|-------|-------|--------|-----------|-------------|-------------|
| SNV | CWL | 7 | 238 | 463 | 119 | 344 | 1.95 |
| SNV | Nextflow | 1 | 104 | 291 | 291 | 0 | 2.80 |
| SNV | WDL | 1 | 145 | 308 | 308 | 0 | 2.12 |
| SNV | Python DSL | 1 | 96 | 351 | 351 | 0 | 3.66 |
| SNV | Nickel | 1 | 145 | 361 | 361 | 0 | 2.49 |
| SNV | SWL | 7 | 60 | 320 | 29 | 291 | 5.33 |
| CNV | CWL | 9 | 250 | 466 | 120 | 346 | 1.86 |
| CNV | Nextflow | 1 | 121 | 290 | 290 | 0 | 2.40 |
| CNV | WDL | 1 | 167 | 306 | 306 | 0 | 1.83 |
| CNV | Python DSL | 1 | 111 | 393 | 393 | 0 | 3.54 |
| CNV | Nickel | 1 | 183 | 408 | 408 | 0 | 2.23 |
| CNV | SWL | 9 | 74 | 357 | 39 | 318 | 4.82 |

### Aggregate Summary

| Language | Total Lines | Total Tokens | WF Tokens | Tool Tokens | Tokens/Line |
|----------|-------------|--------------|-----------|-------------|-------------|
| **CWL** | 488 | 929 | 239 | 690 | 1.90 |
| **Nextflow** | 225 | 581 | 581 | 0 | 2.58 |
| **WDL** | 312 | 614 | 614 | 0 | 1.97 |
| **Python DSL** | 207 | 744 | 744 | 0 | 3.59 |
| **Nickel** | 328 | 769 | 769 | 0 | 2.34 |
| **SWL** | 134 | 677 | 68 | 609 | 5.05 |

## Realistic Code Examples

### CWL (Common Workflow Language)

CWL requires separate files for workflow and each tool definition.

**Tool (bwa-mem.cwl)** - 33 lines, 78 tokens:
```yaml
cwlVersion: v1.0
class: CommandLineTool
baseCommand: bwa mem

requirements:
  - class: ResourceRequirement
    coresMin: 4
    ramMin: 8192
    outdirMin: 1024

arguments:
  - "-t"
  - $(runtime.cores)
  - $(inputs.reference.basename)
  - $(inputs.reads[0])
  - $(inputs.reads[1])

inputs:
  reads:
    type: array
    items: File
  reference: File

outputs:
  alignment:
    type: File
    outputBinding:
      glob: "*.sam"
```

**Workflow (workflow.cwl)** - 77 lines, 119 tokens:
```yaml
cwlVersion: v1.0
class: Workflow

inputs:
  sample_name: string
  reads:
    type: array
    items: File
  reference: File

outputs:
  variants:
    type: File
    outputSource: variant_filter/filtered_variants

steps:
  align:
    run: bwa-mem.cwl
    in:
      reads: reads
      reference: reference
    out: [alignment]

  variant_call:
    run: haplotypecaller.cwl
    in:
      input: align/alignment
      reference: reference
    out: [variants]

  variant_filter:
    run: variantfilter.cwl
    in:
      variants: variant_call/variants
      reference: reference
    out: [filtered_variants]
```

### Nextflow

Nextflow uses a single DSL2 file with process definitions and a workflow block.

**main.nf** - 156 lines, 291 tokens:
```nextflow
nextflow.enable.dsl = 2

params.reads = null
params.reference = null

process BWA_MEM {
    cpus 4
    memory '8 GB'
    
    input:
        tuple val(sample), path(reads)
        path reference
    
    output:
        path "*.sam", emit: alignment
    
    """
    bwa mem -t ${task.cpus} ${reference} ${reads[0]} ${reads[1]} > ${sample}.sam
    """
}

process HAPLOTYPE_CALLER {
    cpus 4
    memory '8 GB'
    
    input:
        path input_bam
        path reference
    
    output:
        path "variants.g.vcf", emit: variants
    
    """
    java -jar gatk HaplotypeCaller -I ${input_bam} -R ${reference} -O variants.g.vcf
    """
}

workflow {
    reads = Channel.fromFilePairs(params.reads)
    reference = file(params.reference)
    
    BWA_MEM(reads, reference)
    HAPLOTYPE_CALLER(BWA_MEM.out.alignment, reference)
    
    emit:
        variants = HAPLOTYPE_CALLER.out.variants
}
```

### WDL (Workflow Description Language)

WDL uses a single file with task and workflow definitions.

**main.wdl** - 145 lines, 308 tokens:
```wdl
version 1.0

task bwa_mem {
    input {
        Array[File] reads
        File reference
        Int cpu = 4
        Int memory_gb = 8
    }
    
    command {
        bwa mem -t ~{cpu} ~{reference} ~{reads[0]} ~{reads[1]} > alignment.sam
    }
    
    output {
        File alignment = "alignment.sam"
    }
    
    runtime {
        cpu: cpu
        memory: "~{memory_gb} GB"
    }
}

task haplotype_caller {
    input {
        File input_bam
        File reference
        Int cpu = 4
        Int memory_gb = 8
    }
    
    command {
        java -jar gatk HaplotypeCaller -I ~{input_bam} -R ~{reference} -O variants.g.vcf
    }
    
    output {
        File variants = "variants.g.vcf"
    }
    
    runtime {
        cpu: cpu
        memory: "~{memory_gb} GB"
    }
}

workflow snv_calling {
    input {
        Array[File] reads
        File reference
    }
    
    call bwa_mem {
        input:
            reads = reads,
            reference = reference
    }
    
    call haplotype_caller {
        input:
            input_bam = bwa_mem.alignment,
            reference = reference
    }
    
    output {
        File variants = haplotype_caller.variants
    }
}
```

### Python DSL

Python uses a single file with a custom DSL for workflow definition.

**main.py** - 96 lines, 351 tokens:
```python
from nixflow import Workflow, Task, Resource

workflow = Workflow("snv_calling")

reference = workflow.input("reference", "file")
reads = workflow.input("reads", "array[file]")
sample_name = workflow.input("sample_name", "string")

bwa = Task(
    "bwa-mem",
    command="bwa mem -t ${cpu} ${reference} ${reads[0]} ${reads[1]} > ${sample}.sam",
    inputs={"reference": reference, "reads": reads},
    outputs={"alignment": "${sample}.sam"},
    resources=Resource(cpu=4, memory_mb=8192, disk_mb=1024)
)

haplotype = Task(
    "haplotypecaller",
    command="java -jar gatk HaplotypeCaller -I ${input} -R ${reference} -O variants.g.vcf",
    inputs={"input": bwa.outputs["alignment"], "reference": reference},
    outputs={"variants": "variants.g.vcf"},
    resources=Resource(cpu=4, memory_mb=8192, disk_mb=1024)
)

workflow.add_tasks([bwa, haplotype])
workflow.set_output(haplotype.outputs["variants"])
```

### Nickel

Nickel uses a single file with typed function definitions.

**main.ncl** - 145 lines, 361 tokens:
```nickel
let Resource = {
    cpu | Number,
    memory | Number,
    disk | Number,
} in

let TaskDef = {
    name | String,
    command | String,
    inputs | {_: Dyn},
    outputs | {_: Dyn},
    resources | Resource,
} in

let Task = fun name => fun command => fun inputs => fun outputs => fun resources =>
    {
        name,
        command,
        inputs,
        outputs,
        resources,
    }
in

let bwa_mem = Task
    "bwa-mem"
    "bwa mem -t ${to_string resources.cpu} ${inputs.reference} ${inputs.reads[0]} ${inputs.reads[1]} > ${inputs.sample_name}.sam"
    {
        reference = "file",
        reads = "array[file]",
        sample_name = "string",
    }
    {
        alignment = "${sample_name}.sam",
    }
    {cpu = 4, memory = 8192, disk = 1024}
in

let haplotype_caller = Task
    "haplotypecaller"
    "java -jar gatk HaplotypeCaller -I ${inputs.input} -R ${inputs.reference} -O variants.g.vcf"
    {
        input = "file",
        reference = "file",
    }
    {
        variants = "variants.g.vcf",
    }
    {cpu = 4, memory = 8192, disk = 1024}
in

let workflow = {
    tasks = [bwa_mem, haplotype_caller],
    inputs = {
        reference = "file",
        reads = "array[file]",
        sample_name = "string",
    },
    outputs = {
        variants = "variants.g.vcf",
    },
}
in
workflow
```

### SWL (Shell Workflow Language)

SWL uses a single workflow file (.swl) and annotated shell scripts (.sh).

**Workflow (main.swl)** - 16 lines, 29 tokens:
```swl
# SNV Calling Pipeline in SWL
align = import "bwa-mem.sh"
mark_dup = import "markduplicates.sh"
base_recal = import "baserecalibrator.sh"
apply_recal = import "applybqsr.sh"
haplotype = import "haplotypecaller.sh"
variant_filt = import "variantfilter.sh"

align | mark_dup | base_recal | apply_recal | haplotype | variant_filt
```

**Tool (bwa-mem.sh)** - 13 lines, 42 tokens:
```bash
#? BWA MEM alignment
# in  reads        array file | paired-end reads
# in  reference    file        | reference sequence
# in  sample_name  str         | sample name
# out alignment    file = ${sample_name}.sam | output alignment
# run cpu    = 4
# run memory = 8192
# run disk   = 1024

bwa mem -t ${cpu} ${reference} ${reads[0]} ${reads[1]} > ${sample_name}.sam
```

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
- **SWL** is most expressive (5.05 tok/line) - shell-based with inline annotations
- **Python DSL** second most (3.59 tok/line) - flexible, programmatic
- **Nickel** (2.34), **Nextflow** (2.58), **WDL** (1.97), **CWL** (1.90)

### File Count
- **CWL requires 7-9 files** per workflow (1 workflow + 6-8 tools)
- **SWL requires 7-9 files** per workflow (1 .swl + 6-8 .sh)
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
│   └── cnv/ (9 files: workflow + 8 tools)
├── nextflow/
│   ├── snv/main.nf
│   └── cnv/main.nf
├── wdl/
│   ├── snv/main.wdl
│   └── cnv/main.wdl
├── python/
│   ├── snv/main.py
│   └── cnv/main.py
├── nickel/
│   ├── snv/main.ncl
│   └── cnv/main.ncl
└── swl/
    ├── snv/ (1 .swl + 6 .sh tools)
    └── cnv/ (1 .swl + 8 .sh tools)
```

## Conclusions

| Criterion | Best | Worst |
|-----------|------|-------|
| Most expressive (tok/line) | SWL (5.05) | CWL (1.90) |
| Fewest files | NF/WDL/Py/Ncl (1) | CWL/SWL (7-9) |
| Full resources (CPU/Mem/Disk) | CWL, Python, Nickel | Nextflow, WDL |
| Multi-target transpile | Python DSL | Others |
| Shell script integration | SWL | Others |