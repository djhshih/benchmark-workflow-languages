#? Sort BAM
# in
#   bam file | input bam
# out
#   sorted_bam file = sorted.bam | sorted bam
# run
#   cpu = 2
#   memory = 4096
#   disk = 1024

samtools sort -o sorted.bam ${bam}
