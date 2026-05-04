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
  known_sites:
    type: array
    items: File

outputs:
  variants:
    type: File
    outputSource: variant_filter/filtered_variants
  recal_table:
    type: File
    outputSource: base_recal/recal_table
  alignment:
    type: File
    outputSource: mark_duplicates/deduped_bam

steps:
  align:
    run: bwa-mem.cwl
    in:
      reads: reads
      reference: reference
    out: [alignment]

  mark_duplicates:
    run: markduplicates.cwl
    in:
      alignment: align/alignment
      sample_name: sample_name
    out: [deduped_bam, metrics]

  base_recal:
    run: baserecalibrator.cwl
    in:
      input: mark_duplicates/deduped_bam
      reference: reference
      reference_dict: reference_dict
      known_sites: known_sites
    out: [recal_table, report]

  apply_recal:
    run: applybqsr.cwl
    in:
      input: mark_duplicates/deduped_bam
      recal_table: base_recal/recal_table
      reference: reference
    out: [recalibrated_bam]

  variant_call:
    run: haplotypecaller.cwl
    in:
      input: apply_recal/recalibrated_bam
      reference: reference
      reference_dict: reference_dict
      reference_fai: reference_fai
    out: [variants]

  variant_filter:
    run: variantfilter.cwl
    in:
      variants: variant_call/variants
      reference: reference
    out: [filtered_variants]

requirements:
  - class: SubworkflowFeatureRequirement
  - class: MultipleInputFeatureRequirement