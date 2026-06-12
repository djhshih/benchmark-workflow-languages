cwlVersion: v1.0
class: CommandLineTool
requirements:
  InlineJavascriptRequirement: {}
  DockerRequirement:
    dockerPull: quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0
  ResourceRequirement:
    coresMin: 2
    ramMin: 2560
    diskMb: 10240
inputs:
  input_bam:
    type: File
    inputBinding:
      prefix: -I
  input_bam_index: File
  sample_name: string
  recal_table: File
  reference:
    type: File
    inputBinding:
      prefix: -R
  reference_dict: File
  reference_fai: File
outputs:
  recalibrated_bam:
    type: File
    outputBinding:
      glob: "*.recalibrated.bam"
  recalibrated_bam_index:
    type: File
    outputBinding:
      glob: "*.recalibrated.bai"
  recalibrated_bam_md5:
    type: File
    outputBinding:
      glob: "*.md5"
baseCommand: [gatk]
arguments:
  - --java-options
  - -Xmx2048M
  - -XX:ParallelGCThreads=1
  - ApplyBQSR
  - --create-output-bam-md5
  - --add-output-sam-program-record
  - --use-original-qualities
  - -O
  - valueFrom: $(inputs.sample_name).recalibrated.bam
  - -bqsr
  - valueFrom: $(inputs.recal_table)
  - --static-quantized-quals
  - "10"
  - --static-quantized-quals
  - "20"
  - --static-quantized-quals
  - "30"
