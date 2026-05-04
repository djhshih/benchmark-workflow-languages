#? Collect Read Counts
#
# in  bam        file | input bam
# in  reference  file | reference sequence
# in  intervals  file | target intervals
#
# out counts file = counts.tsv | read counts
#
# run cpu    = 2
# run memory = 4096
# run disk   = 1024

gatk CollectReadCounts -I ${bam} -R ${reference} -L ${intervals} -O counts.tsv
