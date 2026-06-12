cwlVersion: v1.0
class: CommandLineTool
requirements:
  DockerRequirement:
    dockerPull: quay.io/biocontainers/samtools:1.21--h96c455f_1
  ResourceRequirement:
    coresMin: 1
    ramMin: 2048
    diskMb: 2048
inputs:
  bam: File
outputs:
  indexed_bam:
    type: File
    outputBinding:
      glob: "*.sorted.bam"
  index_file:
    type: File
    outputBinding:
      glob: "*.bai"
baseCommand: [samtools, index]
arguments:
  - valueFrom: $(inputs.bam)
