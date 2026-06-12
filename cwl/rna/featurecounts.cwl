cwlVersion: v1.0
class: CommandLineTool
requirements:
  InlineJavascriptRequirement: {}
  DockerRequirement:
    dockerPull: quay.io/biocontainers/subread:2.0.1--hed695b0_0
  ResourceRequirement:
    coresMin: 4
    ramMin: 8192
    diskMb: 5120
inputs:
  sample_name: string
  alignment: File
  annotation: File
  strandedness:
    type: string
    default: "NONE"
outputs:
  counts:
    type: File
    outputBinding:
      glob: "*_counts.txt"
  summary:
    type: File
    outputBinding:
      glob: "*_counts.txt.summary"
baseCommand: [featureCounts]
arguments:
  - -T
  - valueFrom: $(runtime.cores)
  - -a
  - valueFrom: $(inputs.annotation)
  - -s
  - valueFrom: '${ return inputs.strandedness === "YES" ? 1 : inputs.strandedness === "REVERSE" ? 2 : 0; }'
  - -o
  - valueFrom: $(inputs.sample_name)_counts.txt
  - valueFrom: $(inputs.alignment)
