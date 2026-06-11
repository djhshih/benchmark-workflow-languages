#@ Call CNV
# in
#   segments file
#   sample_name str
# out
#   cnv_calls file = ${sample_name}_cnv.vcf
# run
#   cpu = 2
#   memory = 4096
#   disk = 1024

gatk ModelSegments --denoised-copy-ratios ${segments} -O ${sample_name}_cnv.vcf
