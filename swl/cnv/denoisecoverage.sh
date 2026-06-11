#@ Denoise Coverage
# in
#   counts file
#   gc_file file
#   reference_panel [file]
#   sample_name str
# out
#   denoised_cr file = ${sample_name}_denoised.tsv
# run
#   cpu = 2
#   memory = 4096
#   disk = 1024

gatk DenoiseReadCounts --count-table ${counts} --gc-curve-file ${gc_file} --reference-panel ${reference_panel[0]} -O ${sample_name}_denoised