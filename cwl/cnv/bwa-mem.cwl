cwlVersion: v1.0
class: CommandLineTool

baseCommand: bwa mem

# CWL resources
requirements:
  - class: ResourceRequirement
    coresMin: 4
    ramMin: 8192
    outdirMin: 1024

arguments:
  - "-t"
  - $(runtime.cores)
  - $(inputs.reference.basename)
  - $(inputs.reads[0])
  - $(inputs.reads[1])

inputs:
  reads:
    type: array
    items: File
  reference: File

outputs:
  alignment:
    type: File
    outputBinding:
      glob: "*.sam"