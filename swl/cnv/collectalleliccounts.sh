#@ Collect Allelic Counts
# in
#   input_bam file
#   input_bam_index file
#   reference file
#   intervals file
#   sample_name str
# out
#   allelic_counts file = ${sample_name}.allelic_counts.tsv
# run
#   cpu = 2
#   memory = 8192
#   disk = 5120
#   image = quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0

set -e
mkdir -p ${sample_name}
gatk --java-options "-Xmx7168M" CollectAllelicCounts -I ${input_bam} -L ${intervals} -R ${reference} -O ${sample_name}.allelic_counts.tsv
