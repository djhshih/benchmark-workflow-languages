#? Sort BAM
# in
#   sam file | input SAM
#   sample_name str | sample name
# out
#   bam file = ${sample_name}_sorted.bam | sorted bam
# run
#   cpu = 2
#   memory = 4096
#   disk = 1024

samtools sort -o ${sample_name}_sorted.bam ${sam}