cwlVersion: v1.0
class: CommandLineTool

baseCommand: java

stdin: null

requirements:
  - class: ResourceRequirement
    coresMin: 2
    ramMin: 4096
    outdirMin: 1024

arguments:
  - "-jar"
  - trimmomatic.jar
  - "PE"
  - $(inputs.reads[0])
  - $(inputs.reads[1])
  - $(outputs.trimmed_reads[0].path)
  - $(outputs.step_log[0].path)
  - $(outputs.trimmed_reads[1].path)
  - $(outputs.step_log[1].path)
  - "ILLUMINACLIP:$(inputs.adapters.path):2:30:10"
  - "LEADING:3"
  - "TRAILING:3"
  - "SLIDINGWINDOW:4:15"
  - "MINLEN:36"

inputs:
  reads:
    type:
      type: array
      items: File
  adapters: File

outputs:
  trimmed_reads:
    type:
      type: array
      items: File
    outputBinding:
      glob: "*.fastq.gz"
  step_log:
    type:
      type: array
      items: File
    outputBinding:
      glob: "*_log.txt"