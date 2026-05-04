#? Sort BAM
#
# in  alignment file | input bam
#
# out sorted_bam file = sorted.bam | sorted bam
#
# run cpu    = 2
# run memory = 4096
# run disk   = 1024

samtools sort -o sorted.bam ${alignment}