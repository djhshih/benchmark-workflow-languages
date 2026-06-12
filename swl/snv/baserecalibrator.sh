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

set -e
mkdir -p ${sample_name}
gatk --java-options "-Xmx1024M -XX:ParallelGCThreads=1" BaseRecalibrator -R ${reference} -I ${input_bam} --use-original-qualities -O ${sample_name}.recal.table --known-sites ${known_sites[0]} --known-sites ${dbsnp_vcf}
