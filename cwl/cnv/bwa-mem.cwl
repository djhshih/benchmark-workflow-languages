cwlVersion: v1.0
class: CommandLineTool
requirements:
  InlineJavascriptRequirement: {}
  DockerRequirement:
    dockerPull: quay.io/biocontainers/mulled-v2-ad317f19f5881324e963f6a6d464d696a2825ab6:c59b7a73c87a9fe81737d5d628e10a3b5807f453-0
  ResourceRequirement:
    coresMin: 4
    ramMin: 8192
    diskMb: 10240
inputs:
  sample_name: string
  reads:
    type: array
    items: File
  reference: File
  reference_fai: File
outputs:
  output_bam:
    type: File
    outputBinding:
      glob: "*.sorted.bam"
  output_bam_index:
    type: File
    outputBinding:
      glob: "*.sorted.bam.bai"
  bwa_log:
    type: File
    outputBinding:
      glob: "*.bwa.log"
baseCommand: ["bash"]
arguments:
  - valueFrom: >-
      set -e &&
      bwa mem -t $(runtime.cores) -R "@RG\tID:$(inputs.sample_name)\tLB:1\tPL:ILLUMINA\tSM:$(inputs.sample_name)"
      $(inputs.reference) $(inputs.reads[0]) $(inputs.reads[1])
      2> $(inputs.sample_name).bwa.log |
      samtools sort -@ $(runtime.cores - 1) -m 2G -o $(inputs.sample_name).sorted.bam - &&
      samtools index $(inputs.sample_name).sorted.bam
    shellQuote: false
