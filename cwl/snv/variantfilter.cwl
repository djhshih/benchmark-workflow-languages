cwlVersion: v1.0
class: CommandLineTool
requirements:
  InlineJavascriptRequirement: {}
  DockerRequirement:
    dockerPull: quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0
  ResourceRequirement:
    coresMin: 4
    ramMin: 8704
    diskMb: 5120
inputs:
  input_vcf: File
  input_vcf_index: File
  sample_name: string
  reference: File
  reference_dict: File
  reference_fai: File
  dbsnp_vcf: File
  dbsnp_vcf_index:
    type:
      - "null"
      - File
outputs:
  filtered_vcf:
    type: File
    outputBinding:
      glob: "*.variant_filter.vcf.gz"
  filtered_vcf_index:
    type: File
    outputBinding:
      glob: "*.variant_filter.vcf.gz.tbi"
baseCommand: ["bash"]
arguments:
  - valueFrom: >-
      gatk --java-options '-Xmx8192M -XX:ParallelGCThreads=1' VariantRecalibrator
      -R $(inputs.reference) -V $(inputs.input_vcf)
      --resource:dbsnp,known=false,training=true,truth=true,prior=15.0 $(inputs.dbsnp_vcf)
      -O $(inputs.sample_name).variant_filter.vcf.gz
      --tranches-file $(inputs.sample_name).tranches
      --rscript-file $(inputs.sample_name).plots.R
      --tranche 100.0 --tranche 99.9 --tranche 99.0 --tranche 90.0
      --max-gaussians 4
    shellQuote: false
