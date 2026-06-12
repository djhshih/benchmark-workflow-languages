cwlVersion: v1.0
class: CommandLineTool
requirements:
  InlineJavascriptRequirement: {}
  DockerRequirement:
    dockerPull: quay.io/biocontainers/trimmomatic:0.39--hdfd78af_7
  ResourceRequirement:
    coresMin: 2
    ramMin: 4096
    diskMb: 5120
inputs:
  sample_name: string
  reads:
    type: array
    items: File
  adapters: File
outputs:
  trimmed_reads:
    type: array
    items: File
    outputBinding:
      glob: "*.trimmed.fastq.gz"
  unpaired_reads:
    type: array
    items: File
    outputBinding:
      glob: "*.unpaired.fastq.gz"
baseCommand: [trimmomatic]
arguments:
  - PE
  - -threads
  - valueFrom: $(runtime.cores)
  - valueFrom: $(inputs.reads[0])
  - valueFrom: $(inputs.reads[1])
  - valueFrom: $(inputs.sample_name)_R1.trimmed.fastq.gz
  - valueFrom: $(inputs.sample_name)_R1.unpaired.fastq.gz
  - valueFrom: $(inputs.sample_name)_R2.trimmed.fastq.gz
  - valueFrom: $(inputs.sample_name)_R2.unpaired.fastq.gz
  - valueFrom: ILLUMINACLIP:$(inputs.adapters):2:30:10
  - LEADING:3
  - TRAILING:3
  - SLIDINGWINDOW:4:15
  - MINLEN:36
