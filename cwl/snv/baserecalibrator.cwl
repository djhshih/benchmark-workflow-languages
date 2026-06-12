cwlVersion: v1.0
class: CommandLineTool
requirements:
  InlineJavascriptRequirement: {}
  DockerRequirement:
    dockerPull: quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0
  ResourceRequirement:
    coresMin: 2
    ramMin: 1536
    diskMb: 5120
inputs:
  input_bam: File
  input_bam_index: File
  sample_name: string
  reference: File
  reference_dict: File
  reference_fai: File
  known_sites:
    type:
      - "null"
      - array
    items: File
  dbsnp_vcf: File
  dbsnp_vcf_index:
    type:
      - "null"
      - File
outputs:
  recal_table:
    type: File
    outputBinding:
      glob: "*.recal.table"
baseCommand: ["bash"]
arguments:
  - valueFrom: >-
      gatk --java-options '-Xmx1024M -XX:ParallelGCThreads=1' BaseRecalibrator
      --use-original-qualities -I $(inputs.input_bam) -R $(inputs.reference)
      --known-sites $(inputs.dbsnp_vcf) -O $(inputs.sample_name).recal.table
    shellQuote: false
