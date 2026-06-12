cwlVersion: v1.0
class: CommandLineTool
requirements:
  InlineJavascriptRequirement: {}
  DockerRequirement:
    dockerPull: quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0
  ResourceRequirement:
    coresMin: 4
    ramMin: 7680
    diskMb: 5120
inputs:
  sample_name: string
  bam:
    type: File
  bam_index: File
  reference: File
  reference_fai: File
  intervals: File
outputs:
  read_counts:
    type: File
    outputBinding:
      glob: "*.read_counts.hdf5"
baseCommand: ["bash"]
arguments:
  - valueFrom: >-
      gatk --java-options '-Xmx7G -XX:ParallelGCThreads=1'
      CollectReadCounts
      -L $(inputs.intervals)
      -I $(inputs.bam)
      -R $(inputs.reference)
      --format HDF5
      --interval-merging-rule OVERLAPPING_ONLY
      -O $(inputs.sample_name).read_counts.hdf5
    shellQuote: false
