cwlVersion: v1.0
class: CommandLineTool

baseCommand: gatk ModelSegments

# CWL resources
requirements:
  - class: ResourceRequirement
    coresMin: 2
    ramMin: 4096
    outdirMin: 1024

arguments:
  - --denoised-copy-ratios
  - $(inputs.segments.path)
  - -O
  - $(inputs.sample_name)_cnv.vcf

inputs:
  segments: File
  sample_name: string

outputs:
  cnv_calls:
    type: File
    outputBinding:
      glob: "*.vcf"