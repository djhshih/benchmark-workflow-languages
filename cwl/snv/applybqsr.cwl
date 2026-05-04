cwlVersion: v1.0
class: CommandLineTool

baseCommand: java -jar gatk ApplyBQSR

# CWL resources
requirements:
  - class: ResourceRequirement
    coresMin: 2
    ramMin: 4096
    outdirMin: 1024

arguments:
  - -I
  - $(inputs.input.path)
  - -R
  - $(inputs.reference.path)
  - --bqsr-recal-file
  - $(inputs.recal_table.path)
  - -O
  - recalibrated.bam

inputs:
  input: File
  recal_table: File
  reference: File

outputs:
  recalibrated_bam:
    type: File
    outputBinding:
      glob: "recalibrated.bam"