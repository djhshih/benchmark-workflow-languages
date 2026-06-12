#@ Call Copy Ratio Segments
# in
#   segments file = ${sample_name}.cr.seg
#   sample_name str
# out
#   cnv_calls file = ${sample_name}.called.seg
#   cnv_vcf file = ${sample_name}.called.vcf
# run
#   cpu = 2
#   memory = 4096
#   disk = 2048
#   image = quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0

set -e
mkdir -p ${sample_name}
gatk --java-options "-Xmx3072M" CallCopyRatioSegments --segments ${segments} -O ${sample_name}.called.seg
