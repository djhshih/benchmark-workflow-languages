cwlVersion: v1.0
class: CommandLineTool

baseCommand: java -jar trimmomatic.jar

requirements:
  - class: ResourceRequirement
    coresMin: 2
    ramMin: 4096
  - class: InitialWorkDirRequirement
    listing:
      - $(inputs.adapters)

arguments:
  - valueFrom: PE
  - valueFrom: $(inputs.reads[0])
  - valueFrom: $(inputs.reads[1])
  - valueFrom: trimmed_R1.fastq.gz
  - valueFrom: trimmed_R2.fastq.gz
  - valueFrom: ILLUMINACLIP:adapters.fa:2:30:10
  - valueFrom: LEADING:3
  - valueFrom: TRAILING:3
  - valueFrom: SLIDINGWINDOW:4:15
  - valueFrom: MINLEN:36

inputs:
  reads:
    type: array
    items: File
  adapters:
    type: File

outputs:
  trimmed_reads:
    type: array
    items: File
    outputBinding:
      glob: "*.fastq.gz"
  step_log:
    type: File
    outputBinding:
      glob: "*_log.txt"