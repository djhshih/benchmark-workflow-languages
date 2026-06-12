#@ Collect Read Counts
# in
#   input_bam file
#   input_bam_index file
#   reference file
#   intervals file
#   sample_name str
# out
#   counts file = ${sample_name}.read_counts.hdf5
# run
#   cpu = 2
#   memory = 8192
#   disk = 5120
#   image = quay.io/biocontainers/gatk4:4.1.8.0--py38h37ae868_0

set -e
mkdir -p ${sample_name}
gatk --java-options "-Xmx7168M" CollectReadCounts -I ${input_bam} -L ${intervals} --interval-merging-rule OVERLAPPING_ONLY -O ${sample_name}.read_counts.hdf5 --format HDF5
