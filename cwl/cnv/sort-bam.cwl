cwlVersion: v1.0
class: CommandLineTool
requirements:
  InlineJavascriptRequirement: {}
  DockerRequirement:
    dockerPull: quay.io/biocontainers/samtools:1.21--h96c455f_1
  ResourceRequirement:
    coresMin: 2
    ramMin: 4096
    diskMb: 10240
inputs:
  sample_name: string
  alignment: File
outputs:
  coordinate_sorted_bam:
    type: File
    outputBinding:
      glob: "*.coordinate_sorted.bam"
baseCommand: [samtools, sort]
arguments:
  - -@
  - valueFrom: $(runtime.cores)
  - -m
  - 4G
  - -T
  - valueFrom: $(inputs.sample_name).tmp
  - -o
  - valueFrom: $(inputs.sample_name).coordinate_sorted.bam
  - valueFrom: $(inputs.alignment)
