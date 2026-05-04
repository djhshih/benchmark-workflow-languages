#? Haplotype Caller
#
# in  input     file | input bam
# in  reference file | reference sequence
#
# out variants file = variants.g.vcf | output variants
#
# run cpu    = 4
# run memory = 8192
# run disk   = 1024

java -jar gatk HaplotypeCaller -I ${input} -R ${reference} -O variants.g.vcf -ERC GVCF