cwlVersion: v1.0
class: CommandLineTool
requirements:
  InlineJavascriptRequirement: {}
  DockerRequirement:
    dockerPull: quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0
  ResourceRequirement:
    coresMin: 2
    ramMin: 4096
    diskMb: 5120
inputs:
  sample_name: string
  bam:
    type: File
    inputBinding:
      prefix: -I
  bam_index: File
  reference:
    type: File
    inputBinding:
      prefix: -R
  reference_fai: File
  common_variant_sites:
    type: File
    inputBinding:
      prefix: -L
  common_variant_sites_index:
    type:
      - "null"
      - File
outputs:
  allelic_counts:
    type: File
    outputBinding:
      glob: "*.allelic_counts.tsv"
baseCommand: [gatk]
arguments:
  - --java-options
  - -Xmx10G
  - -XX:ParallelGCThreads=1
  - CollectAllelicCounts
  - -O
  - valueFrom: $(inputs.sample_name).allelic_counts.tsv
