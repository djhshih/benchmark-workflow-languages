cwlVersion: v1.0
class: CommandLineTool
requirements:
  InlineJavascriptRequirement: {}
  DockerRequirement:
    dockerPull: quay.io/biocontainers/mosdepth:0.3.10--h4e814b3_1
  ResourceRequirement:
    coresMin: 4
    ramMin: 4096
    diskMb: 2048
inputs:
  sample_name: string
  bam: File
  bam_index: File
outputs:
  summary:
    type: File
    outputBinding:
      glob: "*.mosdepth.summary.txt"
  global_dist:
    type: File
    outputBinding:
      glob: "*.mosdepth.global.dist.txt"
baseCommand: ["mosdepth"]
arguments:
  - "--threads"
  - valueFrom: $(runtime.cores)
  - "--no-per-base"
  - valueFrom: $(inputs.sample_name).mosdepth
  - valueFrom: $(inputs.bam)
