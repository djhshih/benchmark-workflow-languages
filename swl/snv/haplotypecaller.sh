#@ Haplotype Caller
# in
#   input_bam file
#   input_bam_index file
#   sample_name str
#   reference file
#   reference_dict file
#   reference_fai file
# out
#   output_vcf file = ${sample_name}.g.vcf.gz
#   output_vcf_index file = ${sample_name}.g.vcf.gz.tbi
# run
#   cpu = 4
#   memory = 4608
#   disk = 10240
#   image = quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0

set -e
mkdir -p ${sample_name}
gatk --java-options "-Xmx4096M -XX:ParallelGCThreads=1" HaplotypeCaller -R ${reference} -I ${input_bam} -O ${sample_name}.g.vcf.gz --emit-ref-confidence GVCF
