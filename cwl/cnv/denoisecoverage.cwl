cwlVersion: v1.0
class: CommandLineTool

baseCommand: gatk DenoiseReadCounts

# CWL resources
requirements:
  - class: ResourceRequirement
    coresMin: 2
    ramMin: 4096
    outdirMin: 1024

arguments:
  - --count-table
  - $(inputs.counts.path)
  - --gc-curve-file
  - $(inputs.gc_file.path)
  - --reference-panel
  - $(inputs.reference_panel[0].path)
  - -O
  - denoised_cr

inputs:
  counts: File
  gc_file: File
  reference_panel:
    type: array
    items: File

outputs:
  denoised_cr:
    type: File
    outputBinding:
      glob: "denoised_cr.tsv"