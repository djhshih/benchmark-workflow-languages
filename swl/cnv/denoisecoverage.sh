#@ Denoise Read Counts
# in
#   read_counts file
#   pon file
#   sample_name str
# out
#   denoised_cr file = ${sample_name}.denoisedCR.tsv
#   standardized_cr file = ${sample_name}.standardizedCR.tsv
# run
#   cpu = 2
#   memory = 8192
#   disk = 2048
#   image = quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0

set -e
gatk --java-options "-Xmx4G -XX:ParallelGCThreads=1" DenoiseReadCounts -I ${read_counts} ${pon:+--count-panel-of-normals ${pon}} --standardized-copy-ratios ${sample_name}.standardizedCR.tsv --denoised-copy-ratios ${sample_name}.denoisedCR.tsv
