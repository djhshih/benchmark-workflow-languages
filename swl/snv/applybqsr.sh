#@ Apply BQSR
# in
#   input_bam file
#   input_bam_index file
#   sample_name str
#   recal_table file
#   reference file
#   reference_dict file
#   reference_fai file
# out
#   recalibrated_bam file = ${sample_name}.recalibrated.bam
#   recalibrated_bam_index file = ${sample_name}.recalibrated.bai
#   recalibrated_bam_md5 file = ${sample_name}.recalibrated.bam.md5
# run
#   cpu = 2
#   memory = 2560
#   disk = 10240
#   image = quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0

gatk --java-options "-Xmx2048M -XX:ParallelGCThreads=1" ApplyBQSR --create-output-bam-md5 --add-output-sam-program-record -R ${reference} -I ${input_bam} --use-original-qualities -O ${sample_name}.recalibrated.bam -bqsr ${recal_table} --static-quantized-quals 10 --static-quantized-quals 20 --static-quantized-quals 30
