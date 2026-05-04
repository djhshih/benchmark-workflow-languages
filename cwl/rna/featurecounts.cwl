cwlVersion: v1.0
class: CommandLineTool

baseCommand: featureCounts

requirements:
  - class: ResourceRequirement
    coresMin: 4
    ramMin: 8192
    outdirMin: 1024

arguments:
  - "-T"
  - $(runtime.cores)
  - "-a"
  - $(inputs.annotation.path)
  - "-o"
  - $(outputs.counts.path)
  - $(inputs.alignment.path)

inputs:
  alignment: File
  annotation: File

outputs:
  counts:
    type: File
    outputBinding:
      glob: "*.txt"
  summary:
    type: File
    outputBinding:
      glob: "*.txt.summary"