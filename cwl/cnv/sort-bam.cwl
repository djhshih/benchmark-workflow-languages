cwlVersion: v1.0
class: CommandLineTool
requirements:
  InlineJavascriptRequirement: {}
  DockerRequirement:
    dockerPull: quay.io/biocontainers/samtools:1.21--h96c455f_1
  ResourceRequirement:
    coresMin: 4
    ramMin: 8192
    diskMb: 10240
inputs:
  sample_name: string
  alignment: File
outputs:
  coordinate_sorted_bam:
    type: File
    outputBinding:
      glob: "*.coordinate_sorted.bam"
  coordinate_sorted_bam_index:
    type: File
    outputBinding:
      glob: "*.coordinate_sorted.bam.bai"
baseCommand: ["bash"]
arguments:
  - valueFrom: >-
      samtools sort -@ $(runtime.cores) -m 4G -o $(inputs.sample_name).coordinate_sorted.bam
      -T $(inputs.sample_name).tmp $(inputs.alignment) &&
      samtools index $(inputs.sample_name).coordinate_sorted.bam
    shellQuote: false
