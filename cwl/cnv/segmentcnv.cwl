cwlVersion: v1.0
class: CommandLineTool

baseCommand: gatk SegmentDenoisedCopyRatios

# CWL resources
requirements:
  - class: ResourceRequirement
    coresMin: 2
    ramMin: 4096
    outdirMin: 1024

arguments:
  - --denoised-copy-ratios
  - $(inputs.denoised_cr.path)
  - -O
  - segments.tsv

inputs:
  denoised_cr: File
  intervals: File

outputs:
  segments:
    type: File
    outputBinding:
      glob: "segments.tsv"