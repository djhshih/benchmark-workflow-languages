#? Call CNV
# in
#   segments file | segments
#   sample_name str | sample name
# out
#   cnv_calls file = ${sample_name}_cnv.vcf | CNV calls
# run
#   cpu = 2
#   memory = 4096
#   disk = 1024

gatk ModelSegments --denoised-copy-ratios ${segments} -O ${sample_name}_cnv.vcf
