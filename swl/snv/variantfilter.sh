#@ Variant Filter
# in
#   input_vcf file
#   input_vcf_index file
#   sample_name str
#   reference file
#   reference_dict file
#   reference_fai file
#   dbsnp_vcf file
# out
#   filtered_vcf file = ${sample_name}.variant_filter.vcf.gz
#   filtered_vcf_index file = ${sample_name}.variant_filter.vcf.gz.tbi
#   tranches file = ${sample_name}.tranches
#   r_script file = ${sample_name}.plots.R
# run
#   cpu = 4
#   memory = 8704
#   disk = 5120
#   image = quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0

set -e
mkdir -p ${sample_name}
gatk --java-options "-Xmx8192M -XX:ParallelGCThreads=1" VariantRecalibrator -R ${reference} -V ${input_vcf} --resource:dbsnp,known=false,training=true,truth=true,prior=15.0 ${dbsnp_vcf} -O ${sample_name}.variant_filter.vcf.gz --tranches-file ${sample_name}.tranches --rscript-file ${sample_name}.plots.R --tranche 100.0 --tranche 99.9 --tranche 99.0 --tranche 90.0 --max-gaussians 4
