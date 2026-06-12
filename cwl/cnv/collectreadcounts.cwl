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
  intervals:
    type: File
    inputBinding:
      prefix: -L
outputs:
  read_counts:
    type: File
    outputBinding:
      glob: "*.hdf5"
baseCommand: [gatk]
arguments:
  - --java-options
  - -Xmx7G
  - -XX:ParallelGCThreads=1
  - CollectReadCounts
  - --interval-merging-rule
  - OVERLAPPING_ONLY
  - --format
  - HDF5
  - -O
  - valueFrom: $(inputs.sample_name).counts.hdf5
