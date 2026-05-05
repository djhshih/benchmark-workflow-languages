#? Collect Read Counts
# in
#   bam file | input bam
#   reference file | reference sequence
#   intervals file | target intervals
#   sample_name str | sample name
# out
#   counts file = ${sample_name}_readcounts.tsv | read counts
# run
#   cpu = 2
#   memory = 4096
#   disk = 1024

gatk CollectReadCounts -I ${bam} -R ${reference} -L ${intervals} -O ${sample_name}_readcounts.tsv