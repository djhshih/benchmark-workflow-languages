cwlVersion: v1.0
class: CommandLineTool
requirements:
  InlineJavascriptRequirement: {}
  DockerRequirement:
    dockerPull: quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0
  ResourceRequirement:
    coresMin: 4
    ramMin: 11264
    diskMb: 5120
inputs:
  sample_name: string
  bam:
    type: File
  bam_index: File
  reference: File
  reference_fai: File
  common_variant_sites: File
  common_variant_sites_index:
    type:
      - "null"
      - File
outputs:
  allelic_counts:
    type: File
    outputBinding:
      glob: "*.allelic_counts.tsv"
baseCommand: ["bash"]
arguments:
  - valueFrom: >-
      gatk --java-options '-Xmx10G -XX:ParallelGCThreads=1'
      CollectAllelicCounts
      -L $(inputs.common_variant_sites)
      -I $(inputs.bam)
      -R $(inputs.reference)
      -O $(inputs.sample_name).allelic_counts.tsv
    shellQuote: false
