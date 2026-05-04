cwlVersion: v1.0
class: CommandLineTool

baseCommand: java -jar gatk HaplotypeCaller

# CWL resources
requirements:
  - class: ResourceRequirement
    coresMin: 4
    ramMin: 8192
    outdirMin: 1024

arguments:
  - -I
  - $(inputs.input.path)
  - -R
  - $(inputs.reference.path)
  - -O
  - variants.g.vcf
  - -ERC
  - GVCF

inputs:
  input: File
  reference: File
  reference_dict: File
  reference_fai: File

outputs:
  variants:
    type: File
    outputBinding:
      glob: "variants.g.vcf"