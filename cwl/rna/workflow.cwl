cwlVersion: v1.0
class: Workflow
inputs:
  sample_name: string
  reads:
    type: array
    items: File
  adapters: File
  reference_index: Directory
  reference_fasta: File
  annotation: File
  strandedness:
    type: string
    default: "NONE"
outputs:
  counts:
    type: File
    outputSource: feature_counts/counts
  counts_summary:
    type: File
    outputSource: feature_counts/summary
  fastqc_reports:
    type: array
    items: File
    outputSource: fastqc/reports
  star_alignment:
    type: File
    outputSource: star_alignment/alignment
  star_log:
    type: File
    outputSource: star_alignment/log
steps:
  trim:
    run: trimmomatic.cwl
    in:
      sample_name: sample_name
      reads: reads
      adapters: adapters
    out: [trimmed_reads, unpaired_reads]
  star_alignment:
    run: star.cwl
    in:
      sample_name: sample_name
      reads: trim/trimmed_reads
      reference_index_dir: reference_index
      reference_fasta: reference_fasta
    out: [alignment, log]
  fastqc:
    run: fastqc.cwl
    in:
      sample_name: sample_name
      reads: trim/trimmed_reads
    out: [reports]
  feature_counts:
    run: featurecounts.cwl
    in:
      sample_name: sample_name
      alignment: star_alignment/alignment
      annotation: annotation
      strandedness: strandedness
    out: [counts, summary]
requirements:
  - class: SubworkflowFeatureRequirement
  - class: MultipleInputFeatureRequirement
