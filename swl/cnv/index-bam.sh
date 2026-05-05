#? Index BAM
# in
#   sorted_bam file | input bam
# out
#   bam file = ${sorted_bam}.bai | indexed bam
# run
#   cpu = 1
#   memory = 2048
#   disk = 1024

samtools index ${sorted_bam}
