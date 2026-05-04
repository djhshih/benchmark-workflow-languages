cwlVersion: v1.0
class: CommandLineTool

baseCommand: java -jar gatk VariantRecalibrator

# CWL resources
requirements:
  - class: ResourceRequirement
    coresMin: 4
    ramMin: 8192
    outdirMin: 1024

arguments:
  - -V
  - $(inputs.variants.path)
  - -R
  - $(inputs.reference.path)
  - -O
  - filtered.vcf
  - --tranche
  - 100.0
  - --tranche
  - 99.9
  - --tranche
  - 99.0
  - --tranche
  - 90.0

inputs:
  variants: File
  reference: File

outputs:
  filtered_variants:
    type: File
    outputBinding:
      glob: "filtered.vcf"