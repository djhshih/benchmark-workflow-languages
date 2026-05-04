#? Denoise Coverage
#
# in  counts          file        | read counts
# in  gc_file         file        | GC curve file
# in  reference_panel array file | reference panel
#
# out denoised_cr file = denoised_cr.tsv | denoised copy ratios
#
# run cpu    = 2
# run memory = 4096
# run disk   = 1024

gatk DenoiseReadCounts --count-table ${counts} --gc-curve-file ${gc_file} --reference-panel ${reference_panel[0]} -O denoised_cr