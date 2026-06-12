cwlVersion: v1.0
class: CommandLineTool
requirements:
  InlineJavascriptRequirement: {}
  DockerRequirement:
    dockerPull: quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0
  ResourceRequirement:
    coresMin: 2
    ramMin: 3072
    diskMb: 2048
inputs:
  sample_name: string
  segments:
    type: File
outputs:
  called_segments:
    type: File
    outputBinding:
      glob: "*.called.seg"
  called_igv_segments:
    type: File
    outputBinding:
      glob: "*.called.igv.seg"
baseCommand: ["bash"]
arguments:
  - valueFrom: >-
      gatk --java-options '-Xmx2G -XX:ParallelGCThreads=1'
      CallCopyRatioSegments
      -I $(inputs.segments)
      -O $(inputs.sample_name).called.seg
    shellQuote: false
