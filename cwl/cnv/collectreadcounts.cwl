cwlVersion: v1.0
class: CommandLineTool

baseCommand: gatk CollectReadCounts

# CWL resources
requirements:
  - class: ResourceRequirement
    coresMin: 2
    ramMin: 4096
    outdirMin: 1024

arguments:
  - -I
  - $(inputs.bam.path)
  - -R
  - $(inputs.reference.path)
  - -L
  - $(inputs.intervals.path)
  - -O
  - counts.tsv

inputs:
  bam: File
  reference: File
  intervals: File

outputs:
  counts:
    type: File
    outputBinding:
      glob: "counts.tsv"