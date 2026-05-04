cwlVersion: v1.0
class: CommandLineTool

baseCommand: fastqc

requirements:
  - class: ResourceRequirement
    coresMin: 2
    ramMin: 4096
    outdirMin: 512

arguments:
  - "--outdir"
  - $(inputs.output_dir.path)

inputs:
  reads:
    type:
      type: array
      items: File
  output_dir: Directory

outputs:
  reports:
    type:
      type: array
      items: File
    outputBinding:
      glob: "*.html"