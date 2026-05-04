cwlVersion: v1.0
class: CommandLineTool

baseCommand: samtools index

# CWL resources
requirements:
  - class: ResourceRequirement
    coresMin: 1
    ramMin: 2048
    outdirMin: 1024

arguments:
  - $(inputs.bam.path)

inputs:
  bam: File

outputs:
  indexed_bam:
    type: File
    outputBinding:
      glob: "*.bai"