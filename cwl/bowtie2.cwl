cwlVersion: v1.0
class: CommandLineTool

baseCommand: bowtie2

requirements:
  - class: ResourceRequirement
    coresMin: 4
    ramMin: 8192

arguments:
  - "-x"
  - $(inputs.reference_index.basename)
  - "-1"
  - $(inputs.reads[0])
  - "-2"
  - $(inputs.reads[1])
  - "--threads"
  - $(runtime.cores)
  - "-S"
  - alignment.sam

inputs:
  reads:
    type: array
    items: File
  reference:
    type: File
  reference_index:
    type: File

outputs:
  alignment:
    type: File
    outputBinding:
      glob: "*.sam"

  sorted_bam:
    type: File
    outputBinding:
      glob: "*.bam"