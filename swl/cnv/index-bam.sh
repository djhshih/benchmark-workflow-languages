#@ Index BAM
# in
#   bam file
#   sample_name str
# out
#   bai file = ${sample_name}_sorted.bam.bai
# run
#   cpu = 1
#   memory = 2048
#   disk = 1024

samtools index ${bam}