cwlVersion: v1.0
class: CommandLineTool

baseCommand: STAR

requirements:
  - class: ResourceRequirement
    coresMin: 8
    ramMin: 32768
    outdirMin: 10240

arguments:
  - "--runMode"
  - alignReads
  - "--runThreadN"
  - $(runtime.cores)
  - "--genomeDir"
  - $(inputs.reference_index.dir)
  - "--readFilesIn"
  - $(inputs.reads[0])
  - $(inputs.reads[1])
  - "--outFileNamePrefix"
  - $(outputs.alignment.dir)/

inputs:
  reads:
    type:
      type: array
      items: File
  reference_index: Directory
  genome: File

outputs:
  alignment:
    type: File
    outputBinding:
      glob: "*.bam"
  alignment_log:
    type: File
    outputBinding:
      glob: "*.log"