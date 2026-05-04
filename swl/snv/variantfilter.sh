#? Variant Filter
#
# in  variants   file | input variants
# in  reference  file | reference sequence
#
# out filtered_variants file = filtered.vcf | filtered variants
#
# run cpu    = 4
# run memory = 8192
# run disk   = 1024

java -jar gatk VariantRecalibrator -V ${variants} -R ${reference} -O filtered.vcf --tranche 100.0 --tranche 99.9 --tranche 99.0 --tranche 90.0