#? Collect Read Counts
# in
#   bam file | input bam
#   reference file | reference sequence
#   intervals file | target intervals
# out
#   counts file = counts.tsv | read counts
# run
#   cpu = 2
#   memory = 4096
#   disk = 1024

gatk CollectReadCounts -I ${bam} -R ${reference} -L ${intervals} -O counts.tsv
