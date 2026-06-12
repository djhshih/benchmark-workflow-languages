cwlVersion: v1.0
class: CommandLineTool
requirements:
  InlineJavascriptRequirement: {}
  DockerRequirement:
    dockerPull: quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0
  ResourceRequirement:
    coresMin: 4
    ramMin: 5120
    diskMb: 5120
inputs:
  sample_name: string
  denoised_copy_ratios:
    type: File
    inputBinding:
      prefix: --denoised-copy-ratios
  allelic_counts:
    type: File
    inputBinding:
      prefix: --allelic-counts
outputs:
  copy_ratio_segments:
    type: File
    outputBinding:
      glob: "*.cr.seg"
  model_segments:
    type: File
    outputBinding:
      glob: "*.modelFinal.seg"
  allele_fraction_segments:
    type: File
    outputBinding:
      glob: "*.af.seg"
baseCommand: [gatk]
arguments:
  - --java-options
  - -Xmx4G
  - -XX:ParallelGCThreads=1
  - ModelSegments
  - valueFrom: --output-prefix=$(inputs.sample_name)
  - -O
  - ./
