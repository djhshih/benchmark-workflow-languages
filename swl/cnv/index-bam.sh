#@ Index BAM
# in
#   input_bam file
#   sample_name str
# out
#   bam_index file = ${sample_name}.coordinate_sorted.bam.bai
# run
#   cpu = 1
#   memory = 2048
#   disk = 2048
#   image = quay.io/biocontainers/samtools:1.21--h96c455f_1

set -e
samtools index ${input_bam}
