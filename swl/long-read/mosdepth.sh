#@ Mosdepth coverage calculation
# in
#   sample_name str
#   bam file
#   bam_index file
# out
#   summary file = ${sample_name}.mosdepth.mosdepth.summary.txt
#   global_dist file = ${sample_name}.mosdepth.mosdepth.global.dist.txt
# run
#   cpu = 4
#   memory = 4096
#   disk = 2048
#   image = quay.io/biocontainers/mosdepth:0.3.10--h4e814b3_1

set -e
mkdir -p ${sample_name}
mosdepth --threads ${cpu} --no-per-base ${sample_name}.mosdepth ${bam}
