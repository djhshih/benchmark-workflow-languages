#@ bcftools VCF statistics
# in
#   sample_name str
#   input_vcf file
#   input_vcf_index file
# out
#   stats file = ${sample_name}.vcf.stats
# run
#   cpu = 1
#   memory = 256
#   disk = 512
#   image = quay.io/biocontainers/bcftools:1.10.2--h4f4756c_2

set -e
mkdir -p ${sample_name}
bcftools stats ${input_vcf} > ${sample_name}.vcf.stats
