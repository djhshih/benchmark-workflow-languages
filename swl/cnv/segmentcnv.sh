#? Segment CNV
#
# in  denoised_cr file | denoised copy ratios
# in  intervals    file | target intervals
#
# out segments file = segments.tsv | segments
#
# run cpu    = 2
# run memory = 4096
# run disk   = 1024

gatk SegmentDenoisedCopyRatios --denoised-copy-ratios ${denoised_cr} -O segments.tsv