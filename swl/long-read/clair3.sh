#@ Clair3 variant calling for long reads
# in
#   sample_name str
#   bam file
#   bam_index file
#   reference_fasta file
#   reference_fasta_fai file
#   platform str = "ont"
#   model str = "r941_prom_sup_g5014"
# out
#   output_vcf file = ${sample_name}.clair3.vcf.gz
#   output_vcf_index file = ${sample_name}.clair3.vcf.gz.tbi
# run
#   cpu = 8
#   memory = 24576
#   disk = 20480
#   image = quay.io/biocontainers/clair3:1.1.0--py39hd649744_0

set -e
run_clair3.sh --model=${model} --ref_fn=${reference_fasta} --bam_fn=${bam} --output=clair3_out --threads=${cpu} --platform=${platform} --sample_name=${sample_name} && mv clair3_out/merge_output.vcf.gz ${sample_name}.clair3.vcf.gz && mv clair3_out/merge_output.vcf.gz.tbi ${sample_name}.clair3.vcf.gz.tbi && rm -rf clair3_out
