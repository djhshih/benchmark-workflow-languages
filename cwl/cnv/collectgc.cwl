cwlVersion: v1.0
class: CommandLineTool

baseCommand: gatk CountGC

# CWL resources
requirements:
  - class: ResourceRequirement
    coresMin: 1
    ramMin: 2048
    outdirMin: 1024

arguments:
  - -R
  - $(inputs.reference.path)
  - -L
  - $(inputs.intervals.path)
  - -O
  - gc.txt

inputs:
  reference: File
  intervals: File

outputs:
  gc_file:
    type: File
    outputBinding:
      glob: "gc.txt"