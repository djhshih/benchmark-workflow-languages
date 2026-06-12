#@ Denoise Read Counts
# in
#   counts file
#   reference_panel [file]
#   sample_name str
# out
#   denoised_cr file = ${sample_name}.denoisedCR.tsv
#   denoised_std file = ${sample_name}.standardizedCR.tsv
# run
#   cpu = 2
#   memory = 8192
#   disk = 2048
#   image = quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0

set -e
mkdir -p ${sample_name}
gatk --java-options "-Xmx7168M" DenoiseReadCounts -I ${counts} --count-panel-of-normals ${reference_panel[0]} --standardized-copy-ratios ${sample_name}.standardizedCR.tsv --denoised-copy-ratios ${sample_name}.denoisedCR.tsv
