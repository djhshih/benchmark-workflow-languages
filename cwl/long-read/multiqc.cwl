cwlVersion: v1.0
class: CommandLineTool
requirements:
  InlineJavascriptRequirement: {}
  DockerRequirement:
    dockerPull: quay.io/biocontainers/multiqc:1.28--pyhdfd78af_0
  ResourceRequirement:
    coresMin: 1
    ramMin: 2048
    diskMb: 512
inputs:
  sample_name: string
  reports: File[]
outputs:
  report:
    type: File
    outputBinding:
      glob: "*_multiqc/multiqc_report.html"
baseCommand: ["multiqc"]
arguments:
  - "--force"
  - "--outdir"
  - valueFrom: $(inputs.sample_name)_multiqc
  - valueFrom: $(inputs.reports)
