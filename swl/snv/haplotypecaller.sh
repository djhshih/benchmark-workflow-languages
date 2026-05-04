#? Haplotype Caller
# in
#   input file | input BAM
#   reference file | reference genome
# out
#   variants file = variants.g.vcf | called variants
# run
#   cpu = 4
#   memory = 8192
#   disk = 1024

java -jar gatk HaplotypeCaller -I ${input} -R ${reference} -O variants.g.vcf -ERC GVCF