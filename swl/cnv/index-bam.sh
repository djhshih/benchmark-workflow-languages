#? Index BAM
#
# in  bam file | input bam
#
# out indexed_bam file = ${bam}.bai | indexed bam
#
# run cpu    = 1
# run memory = 2048
# run disk   = 1024

samtools index ${bam}