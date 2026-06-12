#@ FastQC quality control
# in
#   sample_name str
#   reads [file]
# out
#   reports [file] = fastqc_${sample_name}/*.html
# run
#   cpu = 2
#   memory = 4096
#   disk = 2048
#   image = quay.io/biocontainers/fastqc:0.11.9--0

set -e
mkdir -p fastqc_${sample_name}
fastqc --outdir fastqc_${sample_name} --threads ${cpu} ${reads[0]} ${reads[1]}
