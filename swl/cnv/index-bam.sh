#? Index BAM
# in
#   bam file | input bam
#   sample_name str | sample name
# out
#   bai file = ${sample_name}_sorted.bam.bai | indexed bam
# run
#   cpu = 1
#   memory = 2048
#   disk = 1024

samtools index ${bam}