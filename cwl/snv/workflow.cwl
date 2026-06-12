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
  dbsnp_vcf: File
  dbsnp_vcf_index:
    type:
      - "null"
      - File
outputs:
  variants:
    type: File
    outputSource: variant_filter/filtered_vcf
  variants_index:
    type: File
    outputSource: variant_filter/filtered_vcf_index
  recal_table:
    type: File
    outputSource: base_recal/recal_table
  alignment:
    type: File
    outputSource: mark_duplicates/deduped_bam
  alignment_index:
    type: File
    outputSource: mark_duplicates/deduped_bam_index
  recalibrated_bam:
    type: File
    outputSource: apply_bqsr/recalibrated_bam
  recalibrated_bam_index:
    type: File
    outputSource: apply_bqsr/recalibrated_bam_index
steps:
  bwa_mem:
    run: bwa-mem.cwl
    in:
      sample_name: sample_name
      reads: reads
      reference: reference
      reference_fai: reference_fai
    out: [output_bam, output_bam_index, bwa_log]
  mark_duplicates:
    run: markduplicates.cwl
    in:
      sample_name: sample_name
      input_bam: bwa_mem/output_bam
      input_bam_index: bwa_mem/output_bam_index
    out: [deduped_bam, deduped_bam_index, metrics]
  base_recal:
    run: baserecalibrator.cwl
    in:
      sample_name: sample_name
      input_bam: mark_duplicates/deduped_bam
      input_bam_index: mark_duplicates/deduped_bam_index
      reference: reference
      reference_dict: reference_dict
      reference_fai: reference_fai
      known_sites: known_sites
      dbsnp_vcf: dbsnp_vcf
      dbsnp_vcf_index: dbsnp_vcf_index
    out: [recal_table]
  apply_bqsr:
    run: applybqsr.cwl
    in:
      sample_name: sample_name
      input_bam: mark_duplicates/deduped_bam
      input_bam_index: mark_duplicates/deduped_bam_index
      recal_table: base_recal/recal_table
      reference: reference
      reference_dict: reference_dict
      reference_fai: reference_fai
    out: [recalibrated_bam, recalibrated_bam_index, recalibrated_bam_md5]
  haplotype_caller:
    run: haplotypecaller.cwl
    in:
      sample_name: sample_name
      input_bam: apply_bqsr/recalibrated_bam
      input_bam_index: apply_bqsr/recalibrated_bam_index
      reference: reference
      reference_dict: reference_dict
      reference_fai: reference_fai
    out: [output_vcf, output_vcf_index]
  variant_filter:
    run: variantfilter.cwl
    in:
      sample_name: sample_name
      input_vcf: haplotype_caller/output_vcf
      input_vcf_index: haplotype_caller/output_vcf_index
      reference: reference
      reference_dict: reference_dict
      reference_fai: reference_fai
      dbsnp_vcf: dbsnp_vcf
      dbsnp_vcf_index: dbsnp_vcf_index
    out: [filtered_vcf, filtered_vcf_index]
requirements:
  - class: SubworkflowFeatureRequirement
  - class: MultipleInputFeatureRequirement
  - class: ScatterFeatureRequirement
