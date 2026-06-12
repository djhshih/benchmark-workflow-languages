cwlVersion: v1.0
class: CommandLineTool
requirements:
  InlineJavascriptRequirement: {}
  DockerRequirement:
    dockerPull: quay.io/biocontainers/bcftools:1.10.2--h4f4756c_2
  ResourceRequirement:
    coresMin: 1
    ramMin: 256
    diskMb: 512
inputs:
  sample_name: string
  input_vcf: File
  input_vcf_index: File
outputs:
  stats:
    type: File
    outputBinding:
      glob: "*.vcf.stats"
baseCommand: ["bcftools", "stats"]
arguments:
  - valueFrom: $(inputs.input_vcf)
  - ">"
  - valueFrom: $(inputs.sample_name).vcf.stats
shellQuote: false
