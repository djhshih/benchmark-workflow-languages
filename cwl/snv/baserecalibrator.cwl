cwlVersion: v1.0
class: CommandLineTool

baseCommand: java -jar gatk BaseRecalibrator

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
  - --known-sites
  - $(inputs.known_sites[0])
  - --known-sites
  - $(inputs.known_sites[1])
  - -O
  - recal.table
  - -BQSR
  - report.txt

inputs:
  input: File
  reference: File
  reference_dict: File
  known_sites:
    type: array
    items: File

outputs:
  recal_table:
    type: File
    outputBinding:
      glob: "recal.table"
  report:
    type: File
    outputBinding:
      glob: "report.txt"