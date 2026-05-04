cwlVersion: v1.0
class: CommandLineTool

baseCommand: java -jar picard.jar MarkDuplicates

# CWL resources
requirements:
  - class: ResourceRequirement
    coresMin: 2
    ramMin: 4096
    outdirMin: 1024

arguments:
  - I=$(inputs.alignment.path)
  - O=deduped.bam
  - M=metrics.txt
  - CREATE_INDEX=true

inputs:
  alignment: File
  sample_name: string

outputs:
  deduped_bam:
    type: File
    outputBinding:
      glob: "deduped.bam"
  metrics:
    type: File
    outputBinding:
      glob: "metrics.txt"