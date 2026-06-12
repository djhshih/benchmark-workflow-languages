cwlVersion: v1.0
class: CommandLineTool
requirements:
  InlineJavascriptRequirement: {}
  DockerRequirement:
    dockerPull: quay.io/biocontainers/star:2.7.3a--0
  ResourceRequirement:
    coresMin: 8
    ramMin: 32768
    diskMb: 20480
inputs:
  sample_name: string
  reads:
    type: array
    items: File
    inputBinding:
      prefix: --readFilesIn
      itemSeparator: " "
  reference_index_dir: Directory
  reference_fasta: File
outputs:
  alignment:
    type: File
    outputBinding:
      glob: "star_*/Aligned.sortedByCoord.out.bam"
  log:
    type: File
    outputBinding:
      glob: "star_*/Log.final.out"
baseCommand: [STAR]
arguments:
  - --runMode=alignReads
  - valueFrom: --runThreadN=$(runtime.cores)
  - valueFrom: --genomeDir=$(inputs.reference_index_dir)
  - --readFilesCommand=zcat
  - valueFrom: --outFileNamePrefix=star_$(inputs.sample_name)/
  - --outSAMtype
  - BAM
  - SortedByCoordinate
  - --outBAMcompression=1
  - --outSAMunmapped=Within
  - KeepPairs
  - --twopassMode=Basic
  - valueFrom: --outSAMattrRGline=ID:$(inputs.sample_name) LB:$(inputs.sample_name) PL:ILLUMINA SM:$(inputs.sample_name)
