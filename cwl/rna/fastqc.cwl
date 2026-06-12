cwlVersion: v1.0
class: CommandLineTool
requirements:
  InlineJavascriptRequirement: {}
  DockerRequirement:
    dockerPull: quay.io/biocontainers/fastqc:0.11.9--0
  ResourceRequirement:
    coresMin: 2
    ramMin: 4096
    diskMb: 2048
inputs:
  sample_name: string
  reads:
    type: array
    items: File
outputs:
  reports:
    type: array
    items: File
    outputBinding:
      glob: "fastqc_*/*.html"
  zip_reports:
    type: array
    items: File
    outputBinding:
      glob: "*_fastqc.zip"
baseCommand: [fastqc]
arguments:
  - valueFrom: --outdir=fastqc_$(inputs.sample_name)
  - valueFrom: --threads=$(runtime.cores)
  - valueFrom: $(inputs.reads[0])
  - valueFrom: $(inputs.reads[1])
