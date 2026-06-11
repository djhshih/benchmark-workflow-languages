#@ Mark Duplicates
# in
#   alignment file
#   sample_name str
# out
#   deduped_bam file = deduped.bam
#   metrics file = metrics.txt
# run
#   cpu = 2
#   memory = 4096
#   disk = 1024

java -jar picard.jar MarkDuplicates I=${alignment} O=deduped.bam M=metrics.txt CREATE_INDEX=true