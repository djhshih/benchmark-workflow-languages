#? Segment CNV
# in
#   denoised_cr file | denoised copy ratios
#   intervals file | target intervals
#   sample_name str | sample name
# out
#   segments file = ${sample_name}_segments.tsv | segments
# run
#   cpu = 2
#   memory = 4096
#   disk = 1024

gatk SegmentDenoisedCopyRatios --denoised-copy-ratios ${denoised_cr} -O ${sample_name}_segments.tsv