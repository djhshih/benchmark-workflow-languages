#? Denoise Coverage
# in
#   counts file | read counts
#   gc_file file | GC curve file
#   reference_panel array file | reference panel
#   sample_name str | sample name
# out
#   denoised_cr file = ${sample_name}_denoised.tsv | denoised copy ratios
# run
#   cpu = 2
#   memory = 4096
#   disk = 1024

gatk DenoiseReadCounts --count-table ${counts} --gc-curve-file ${gc_file} --reference-panel ${reference_panel[0]} -O ${sample_name}_denoised