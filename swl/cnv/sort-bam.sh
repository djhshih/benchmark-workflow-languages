#@ Sort BAM
# in
#   sam file
#   sample_name str
# out
#   bam file = ${sample_name}_sorted.bam
# run
#   cpu = 2
#   memory = 4096
#   disk = 1024

samtools sort -o ${sample_name}_sorted.bam ${sam}