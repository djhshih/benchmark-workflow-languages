#? Haplotype Caller
# in
#   bam file | input BAM
#   reference file | reference genome
#   sample_name str | sample name
# out
#   variants file = ${sample_name}_variants.g.vcf | called variants
# run
#   cpu = 4
#   memory = 8192
#   disk = 1024

java -jar gatk HaplotypeCaller -I ${bam} -R ${reference} -O ${sample_name}_variants.g.vcf -ERC GVCF