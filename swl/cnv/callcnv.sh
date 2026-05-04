#? Call CNV
#
# in  segments    file | segments
# in  sample_name str  | sample name
#
# out cnv_calls file = ${sample_name}_cnv.vcf | CNV calls
#
# run cpu    = 2
# run memory = 4096
# run disk   = 1024

gatk ModelSegments --denoised-copy-ratios ${segments} -O ${sample_name}_cnv.vcf