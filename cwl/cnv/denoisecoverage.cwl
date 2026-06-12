cwlVersion: v1.0
class: CommandLineTool
requirements:
  InlineJavascriptRequirement: {}
  DockerRequirement:
    dockerPull: quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0
  ResourceRequirement:
    coresMin: 2
    ramMin: 5120
    diskMb: 2048
inputs:
  sample_name: string
  read_counts:
    type: File
  pon:
    type:
      - "null"
      - File
outputs:
  denoised_copy_ratios:
    type: File
    outputBinding:
      glob: "*.denoisedCR.tsv"
  standardized_copy_ratios:
    type: File
    outputBinding:
      glob: "*.standardizedCR.tsv"
baseCommand: ["bash"]
arguments:
  - valueFrom: >-
      gatk --java-options '-Xmx4G -XX:ParallelGCThreads=1'
      DenoiseReadCounts
      -I $(inputs.read_counts)
      $(inputs.pon ? '--count-panel-of-normals ' + inputs.pon.path : '')
      --standardized-copy-ratios $(inputs.sample_name).standardizedCR.tsv
      --denoised-copy-ratios $(inputs.sample_name).denoisedCR.tsv
    shellQuote: false
