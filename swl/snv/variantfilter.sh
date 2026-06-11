#@ Variant Filter
# in
#   variants file
#   reference file
#   sample_name str
# out
#   filtered_variants file = ${sample_name}_filtered.vcf
# run
#   cpu = 4
#   memory = 8192
#   disk = 1024

java -jar gatk VariantRecalibrator -V ${variants} -R ${reference} -O ${sample_name}_filtered.vcf --tranche 100.0 --tranche 99.9 --tranche 99.0 --tranche 90.0