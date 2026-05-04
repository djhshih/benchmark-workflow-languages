#? Mark Duplicates
# in
#   alignment file | input BAM
#   sample_name str | sample name
# out
#   deduped_bam file = deduped.bam | deduplicated BAM
#   metrics file = metrics.txt | duplicate metrics
# run
#   cpu = 2
#   memory = 4096
#   disk = 1024

java -jar picard.jar MarkDuplicates I=${alignment} O=deduped.bam M=metrics.txt CREATE_INDEX=true