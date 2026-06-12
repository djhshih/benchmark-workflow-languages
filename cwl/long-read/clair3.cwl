cwlVersion: v1.0
class: CommandLineTool
requirements:
  InlineJavascriptRequirement: {}
  DockerRequirement:
    dockerPull: quay.io/biocontainers/clair3:1.1.0--py39hd649744_0
  ResourceRequirement:
    coresMin: 8
    ramMin: 24576
    diskMb: 20480
inputs:
  sample_name: string
  bam: File
  bam_index: File
  reference_fasta: File
  reference_fasta_fai: File
  platform:
    type: string
    default: "ont"
  model:
    type: string
    default: "r941_prom_sup_g5014"
outputs:
  output_vcf:
    type: File
    outputBinding:
      glob: "*.clair3.vcf.gz"
  output_vcf_index:
    type: File
    outputBinding:
      glob: "*.clair3.vcf.gz.tbi"
baseCommand: ["bash"]
arguments:
  - valueFrom: >-
      set -e &&
      run_clair3.sh
      --model=$(inputs.model)
      --ref_fn=$(inputs.reference_fasta)
      --bam_fn=$(inputs.bam)
      --output=clair3_out
      --threads=$(runtime.cores)
      --platform=$(inputs.platform)
      --sample_name=$(inputs.sample_name) &&
      mv clair3_out/merge_output.vcf.gz $(inputs.sample_name).clair3.vcf.gz &&
      mv clair3_out/merge_output.vcf.gz.tbi $(inputs.sample_name).clair3.vcf.gz.tbi &&
      rm -rf clair3_out
    shellQuote: false
