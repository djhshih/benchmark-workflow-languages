#@ Haplotype Caller
# in
#   bam file
#   reference file
#   sample_name str
# out
#   variants file = ${sample_name}_variants.g.vcf
# run
#   cpu = 4
#   memory = 8192
#   disk = 1024

java -jar gatk HaplotypeCaller -I ${bam} -R ${reference} -O ${sample_name}_variants.g.vcf -ERC GVCF