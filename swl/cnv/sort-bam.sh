#? Sort BAM
# in
#   bam file | input bam
#   sample_name str | sample name
# out
#   sorted_bam file = ${sample_name}_sorted.bam | sorted bam
# run
#   cpu = 2
#   memory = 4096
#   disk = 1024

samtools sort -o ${sample_name}_sorted.bam ${bam}