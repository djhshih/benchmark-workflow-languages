cwlVersion: v1.0
class: CommandLineTool

baseCommand: fastqc

requirements:
  - class: ResourceRequirement
    coresMin: 1
    ramMin: 2048

inputs:
  reads:
    type: array
    items: File
    inputBinding:
      position: 1

outputs:
  reports:
    type: array
    items: File
    outputBinding:
      glob: "*.html"