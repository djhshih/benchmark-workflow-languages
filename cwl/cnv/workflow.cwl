cwlVersion: v1.0
class: Workflow
inputs:
  sample_name: string
  reads:
    type: array
    items: File
  reference: File
  reference_dict: File
  reference_fai: File
  preprocessed_intervals: File
  common_variant_sites: File
  common_variant_sites_index:
    type:
      - "null"
      - File
  pon:
    type:
      - "null"
      - File
outputs:
  alignment_bam:
    type: File
    outputSource: index_bam/indexed_bam
  alignment_bam_index:
    type: File
    outputSource: index_bam/index_file
  read_counts:
    type: File
    outputSource: collect_read_counts/read_counts
  allelic_counts:
    type: File
    outputSource: collect_allelic_counts/allelic_counts
  denoised_copy_ratios:
    type: File
    outputSource: denoise_read_counts/denoised_copy_ratios
  standardized_copy_ratios:
    type: File
    outputSource: denoise_read_counts/standardized_copy_ratios
  copy_ratio_segments:
    type: File
    outputSource: model_segments/copy_ratio_segments
  called_segments:
    type: File
    outputSource: call_copy_ratio_segments/called_segments
steps:
  bwa_mem:
    run: bwa-mem.cwl
    in:
      sample_name: sample_name
      reads: reads
      reference: reference
      reference_fai: reference_fai
    out: [output_bam, output_bam_index, bwa_log]
  sort_bam:
    run: sort-bam.cwl
    in:
      sample_name: sample_name
      alignment: bwa_mem/output_bam
    out: [coordinate_sorted_bam]
  index_bam:
    run: index-bam.cwl
    in:
      bam: sort_bam/coordinate_sorted_bam
    out: [indexed_bam, index_file]
  collect_read_counts:
    run: collectreadcounts.cwl
    in:
      sample_name: sample_name
      bam: index_bam/indexed_bam
      bam_index: index_bam/index_file
      reference: reference
      reference_fai: reference_fai
      intervals: preprocessed_intervals
    out: [read_counts]
  collect_allelic_counts:
    run: collectalleliccounts.cwl
    in:
      sample_name: sample_name
      bam: index_bam/indexed_bam
      bam_index: index_bam/index_file
      reference: reference
      reference_fai: reference_fai
      common_variant_sites: common_variant_sites
      common_variant_sites_index: common_variant_sites_index
    out: [allelic_counts]
  denoise_read_counts:
    run: denoisecoverage.cwl
    in:
      sample_name: sample_name
      read_counts: collect_read_counts/read_counts
      pon: pon
    out: [denoised_copy_ratios, standardized_copy_ratios]
  model_segments:
    run: segmentcnv.cwl
    in:
      sample_name: sample_name
      denoised_copy_ratios: denoise_read_counts/denoised_copy_ratios
      allelic_counts: collect_allelic_counts/allelic_counts
    out: [copy_ratio_segments, model_segments]
  call_copy_ratio_segments:
    run: callcnv.cwl
    in:
      sample_name: sample_name
      segments: model_segments/copy_ratio_segments
    out: [called_segments, called_igv_segments]
requirements:
  - class: SubworkflowFeatureRequirement
  - class: MultipleInputFeatureRequirement
  - class: ScatterFeatureRequirement
