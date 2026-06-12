cwlVersion: v1.0
class: Workflow
requirements:
  InlineJavascriptRequirement: {}
inputs:
  sample_name: string
  reads: File
  reference_fasta: File
  reference_fasta_fai: File
  platform:
    type: string
    default: "ont"
  preset:
    type: string
    default: "map-ont"
  clair3_model:
    type: string
    default: "r941_prom_sup_g5014"
outputs:
  alignment:
    type: File
    outputSource: minimap2_map/output_bam
  alignment_index:
    type: File
    outputSource: minimap2_map/output_bam_index
  variants:
    type: File
    outputSource: clair3_call/output_vcf
  variants_index:
    type: File
    outputSource: clair3_call/output_vcf_index
  vcf_stats:
    type: File
    outputSource: bcftools_stats/stats
  coverage_summary:
    type: File
    outputSource: mosdepth_cov/summary
  multiqc_report:
    type: File
    outputSource: multiqc_report/report
steps:
  minimap2_map:
    run: minimap2-map.cwl
    in:
      sample_name: sample_name
      reads: reads
      reference_fasta: reference_fasta
      preset: preset
      platform: platform
    out: [output_bam, output_bam_index]
  mosdepth_cov:
    run: mosdepth.cwl
    in:
      sample_name: sample_name
      bam: minimap2_map/output_bam
      bam_index: minimap2_map/output_bam_index
    out: [summary, global_dist]
  clair3_call:
    run: clair3.cwl
    in:
      sample_name: sample_name
      bam: minimap2_map/output_bam
      bam_index: minimap2_map/output_bam_index
      reference_fasta: reference_fasta
      reference_fasta_fai: reference_fasta_fai
      platform: platform
      model: clair3_model
    out: [output_vcf, output_vcf_index]
  bcftools_stats:
    run: bcftools-stats.cwl
    in:
      sample_name: sample_name
      input_vcf: clair3_call/output_vcf
      input_vcf_index: clair3_call/output_vcf_index
    out: [stats]
  multiqc_report:
    run: multiqc.cwl
    in:
      sample_name: sample_name
      reports:
        - mosdepth_cov/summary
        - bcftools_stats/stats
    out: [report]
