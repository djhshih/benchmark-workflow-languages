#? Mark Duplicates
#
# in  alignment    file | input bam
# in  sample_name str  | sample name
#
# out deduped_bam file = deduped.bam | output bam
# out metrics     file = metrics.txt | metrics file
#
# run cpu    = 2
# run memory = 4096
# run disk   = 1024

java -jar picard.jar MarkDuplicates I=${alignment} O=deduped.bam M=metrics.txt CREATE_INDEX=true