cwlVersion: v1.0
class: CommandLineTool
requirements:
  InlineJavascriptRequirement: {}
  DockerRequirement:
    dockerPull: quay.io/biocontainers/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:3161f532a5ea6f1dec9be5667c9efc2afdac6104-0
  ResourceRequirement:
    coresMin: 8
    ramMin: 24576
    diskMb: 10240
inputs:
  sample_name: string
  reads: File
  reference_fasta: File
  preset:
    type: string
    default: "map-ont"
  platform:
    type: string
    default: "ont"
outputs:
  output_bam:
    type: File
    outputBinding:
      glob: "*.sorted.bam"
  output_bam_index:
    type: File
    outputBinding:
      glob: "*.sorted.bam.bai"
baseCommand: ["bash"]
arguments:
  - valueFrom: >-
      set -e -o pipefail &&
      minimap2 -a -x $(inputs.preset) -t $(runtime.cores) -y
      -R "@RG\tID:$(inputs.sample_name)\tSM:$(inputs.sample_name)\tPL:$(inputs.platform)"
      $(inputs.reference_fasta) $(inputs.reads) |
      samtools sort --threads 2 -m 1G -o $(inputs.sample_name).sorted.bam - &&
      samtools index $(inputs.sample_name).sorted.bam
    shellQuote: false
