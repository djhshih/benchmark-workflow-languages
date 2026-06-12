#@ Model Segments
# in
#   denoised_cr file
#   allelic_counts file
#   sample_name str
# out
#   segments file = ${sample_name}.modelFinal.seg
#   model_segments file = ${sample_name}.modelFinal.detail.tsv
#   cr_segments file = ${sample_name}.cr.seg
#   af_segments file = ${sample_name}.af.seg
# run
#   cpu = 2
#   memory = 8192
#   disk = 5120
#   image = quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0

set -e
gatk --java-options "-Xmx4G -XX:ParallelGCThreads=1" ModelSegments --denoised-copy-ratios ${denoised_cr} --allelic-counts ${allelic_counts} --output-prefix ${sample_name}. -O .
