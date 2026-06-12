cwlVersion: v1.0
class: CommandLineTool
requirements:
  InlineJavascriptRequirement: {}
  DockerRequirement:
    dockerPull: quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0
  ResourceRequirement:
    coresMin: 2
    ramMin: 4096
    diskMb: 2048
inputs:
  sample_name: string
  read_counts:
    type: File
    inputBinding:
      prefix: -I
  pon:
    type:
      - "null"
      - File
    inputBinding:
      prefix: --count-panel-of-normals
  annotated_intervals:
    type:
      - "null"
      - File
    inputBinding:
      prefix: --annotated-intervals
outputs:
  denoised_copy_ratios:
    type: File
    outputBinding:
      glob: "*.denoisedCR.tsv"
  standardized_copy_ratios:
    type: File
    outputBinding:
      glob: "*.standardizedCR.tsv"
baseCommand: [gatk]
arguments:
  - --java-options
  - -Xmx4G
  - -XX:ParallelGCThreads=1
  - DenoiseReadCounts
  - valueFrom: --standardized-copy-ratios=$(inputs.sample_name).standardizedCR.tsv
  - valueFrom: --denoised-copy-ratios=$(inputs.sample_name).denoisedCR.tsv
