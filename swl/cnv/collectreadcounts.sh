#@ Collect Read Counts
# in
#   bam file
#   reference file
#   intervals file
#   sample_name str
# out
#   counts file = ${sample_name}_readcounts.tsv
# run
#   cpu = 2
#   memory = 4096
#   disk = 1024

gatk CollectReadCounts -I ${bam} -R ${reference} -L ${intervals} -O ${sample_name}_readcounts.tsv