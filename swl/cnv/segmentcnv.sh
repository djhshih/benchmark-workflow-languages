#? Segment CNV
# in
#   denoised_cr file | denoised copy ratios
#   intervals file | target intervals
# out
#   segments file = segments.tsv | segments
# run
#   cpu = 2
#   memory = 4096
#   disk = 1024

gatk SegmentDenoisedCopyRatios --denoised-copy-ratios ${denoised_cr} -O segments.tsv