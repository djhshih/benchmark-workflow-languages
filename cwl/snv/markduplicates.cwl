cwlVersion: v1.0
class: CommandLineTool
requirements:
  DockerRequirement:
    dockerPull: quay.io/biocontainers/picard:3.3.0--hdfd78af_0
  ResourceRequirement:
    coresMin: 2
    ramMin: 7168
    diskMb: 10240
inputs:
  input_bam: File
  input_bam_index: File
  sample_name: string
outputs:
  deduped_bam:
    type: File
    outputBinding:
      glob: "*.deduped.bam"
  deduped_bam_index:
    type: File
    outputBinding:
      glob: "*.deduped.bai"
  metrics:
    type: File
    outputBinding:
      glob: "*.metrics.txt"
baseCommand: [picard]
arguments:
  - position: 0
    valueFrom: MarkDuplicates
  - prefix: "INPUT="
    valueFrom: $(inputs.input_bam)
  - prefix: "OUTPUT="
    valueFrom: $(inputs.sample_name).deduped.bam
  - prefix: "METRICS_FILE="
    valueFrom: $(inputs.sample_name).deduped.metrics.txt
  - valueFrom: CREATE_INDEX=true
  - valueFrom: VALIDATION_STRINGENCY=SILENT
  - valueFrom: OPTICAL_DUPLICATE_PIXEL_DISTANCE=2500
  - valueFrom: CLEAR_DT=false
