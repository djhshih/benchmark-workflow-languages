cwlVersion: v1.0
class: Workflow

inputs:
  reads:
    type:
      type: array
      items: File
  adapters: File
  reference_index: Directory
  annotation: File

outputs:
  counts:
    type: File
    outputSource: feature_counts/counts
  fastqc_reports:
    type:
      type: array
      items: File
    outputSource: fastqc/reports

steps:
  trim:
    run: trimmomatic.cwl
    in:
      reads: reads
      adapters: adapters
    out: [trimmed_reads]

  align:
    run: star.cwl
    in:
      reads: trim/trimmed_reads
      reference_index: reference_index
    out: [alignment]

  fastqc:
    run: fastqc.cwl
    in:
      reads: trim/trimmed_reads
    out: [reports]

  feature_counts:
    run: featurecounts.cwl
    in:
      alignment: align/alignment
      annotation: annotation
    out: [counts]

requirements:
  - class: SubworkflowFeatureRequirement
  - class: MultipleInputFeatureRequirement