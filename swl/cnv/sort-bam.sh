#@ Sort BAM
# in
#   input_bam file
#   sample_name str
# out
#   sorted_bam file = ${sample_name}.coordinate_sorted.bam
#   sorted_bam_index file = ${sample_name}.coordinate_sorted.bam.bai
# run
#   cpu = 4
#   memory = 4096
#   disk = 10240
#   image = quay.io/biocontainers/samtools:1.21--h96c455f_1

set -e
samtools sort -@ ${cpu} -m 4G -o ${sample_name}.coordinate_sorted.bam -T ${sample_name}.tmp ${input_bam} && samtools index ${sample_name}.coordinate_sorted.bam
