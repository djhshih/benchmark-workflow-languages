#@ Collect Allelic Counts
# in
#   input_bam file
#   input_bam_index file
#   reference file
#   sites file
#   sample_name str
# out
#   allelic_counts file = ${sample_name}.allelic_counts.tsv
# run
#   cpu = 2
#   memory = 8192
#   disk = 5120
#   image = quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0

set -e
gatk --java-options "-Xmx10G -XX:ParallelGCThreads=1" CollectAllelicCounts -L ${sites} -I ${input_bam} -R ${reference} -O ${sample_name}.allelic_counts.tsv
