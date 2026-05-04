#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow

inputs:
  reads:
    type: array
    items: File
  reference:
    type: File
  reference_index:
    type: File
    label: Bowtie2 index
  adapters:
    type: File

outputs:
  trimmed_reports:
    type: array
    items: File
    outputSource: trim/step_log
  alignment:
    type: File
    outputSource: align/sorted_bam
  qc_reports:
    type: array
    items: File
    outputSource: post_qc/reports

steps:
  initial_qc:
    run: fastqc.cwl
    in:
      reads: reads
    out: [reports]

  trim:
    run: trimmomatic.cwl
    in:
      reads: reads
      adapters: adapters
    out: [trimmed_reads, step_log]

  post_qc:
    run: fastqc.cwl
    in:
      reads: trim/trimmed_reads
    out: [reports]

  align:
    run: bowtie2.cwl
    in:
      reads: trim/trimmed_reads
      reference: reference
      reference_index: reference_index
    out: [sorted_bam]

requirements:
  - class: SubworkflowFeatureRequirement