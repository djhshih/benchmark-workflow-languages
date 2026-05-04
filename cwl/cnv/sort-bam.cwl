cwlVersion: v1.0
class: CommandLineTool

baseCommand: samtools sort

# CWL resources
requirements:
  - class: ResourceRequirement
    coresMin: 2
    ramMin: 4096
    outdirMin: 1024

arguments:
  - -o
  - sorted.bam
  - $(inputs.alignment.path)

inputs:
  alignment: File

outputs:
  sorted_bam:
    type: File
    outputBinding:
      glob: "sorted.bam"