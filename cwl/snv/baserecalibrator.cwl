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
  input_bam:
    type: File
    inputBinding:
      prefix: -I
  input_bam_index: File
  sample_name: string
  reference:
    type: File
    inputBinding:
      prefix: -R
  reference_dict: File
  reference_fai: File
  known_sites:
    type: array
    items: File
    inputBinding:
      prefix: --known-sites
  dbsnp_vcf:
    type: File
    inputBinding:
      prefix: --known-sites
  dbsnp_vcf_index:
    type:
      - "null"
      - File
outputs:
  recal_table:
    type: File
    outputBinding:
      glob: "*.recal.table"
baseCommand: [gatk]
arguments:
  - --java-options
  - -Xmx1024M
  - -XX:ParallelGCThreads=1
  - BaseRecalibrator
  - --use-original-qualities
  - -O
  - valueFrom: $(inputs.sample_name).recal.table
