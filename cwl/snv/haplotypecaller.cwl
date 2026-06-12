cwlVersion: v1.0
class: CommandLineTool
requirements:
  InlineJavascriptRequirement: {}
  DockerRequirement:
    dockerPull: quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0
  ResourceRequirement:
    coresMin: 4
    ramMin: 4608
    diskMb: 10240
inputs:
  input_bam: File
  input_bam_index: File
  sample_name: string
  reference: File
  reference_dict: File
  reference_fai: File
outputs:
  output_vcf:
    type: File
    outputBinding:
      glob: "*.g.vcf.gz"
  output_vcf_index:
    type: File
    outputBinding:
      glob: "*.g.vcf.gz.tbi"
baseCommand: ["bash"]
arguments:
  - valueFrom: >-
      gatk --java-options '-Xmx4096M -XX:ParallelGCThreads=1' HaplotypeCaller
      -R $(inputs.reference) -I $(inputs.input_bam) -O $(inputs.sample_name).g.vcf.gz
      --emit-ref-confidence GVCF
    shellQuote: false
