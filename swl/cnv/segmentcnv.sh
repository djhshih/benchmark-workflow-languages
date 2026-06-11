#@ Segment CNV
# in
#   denoised_cr file
#   intervals file
#   sample_name str
# out
#   segments file = ${sample_name}_segments.tsv
# run
#   cpu = 2
#   memory = 4096
#   disk = 1024

gatk SegmentDenoisedCopyRatios --denoised-copy-ratios ${denoised_cr} -O ${sample_name}_segments.tsv