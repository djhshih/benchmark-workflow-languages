#? FastQC quality control
# in
#   reads array file | input reads
#   sample_name str | sample name
# out
#   reports array file = ${sample_name}_*.html | QC reports
# run
#   cpu = 2
#   memory = 4096
#   disk = 512

fastqc --outdir . ${reads[0]} ${reads[1]}