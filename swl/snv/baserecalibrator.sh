#@ Base Recalibrator
# in
#   input_bam file
#   input_bam_index file
#   sample_name str
#   reference file
#   reference_dict file
#   reference_fai file
#   known_sites [file]
#   dbsnp_vcf file
# out
#   recal_table file = ${sample_name}.recal.table
# run
#   cpu = 2
#   memory = 1536
#   disk = 5120
#   image = quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0

gatk --java-options "-Xmx1024M -XX:ParallelGCThreads=1" BaseRecalibrator --use-original-qualities -I ${input_bam} -R ${reference} --known-sites ${dbsnp_vcf} -O ${sample_name}.recal.table
