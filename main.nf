params.genome     = "/data/khanlab/projects/ngs_pipeline_testing/References_4.0/GRCh38"
params.reads      = "/data/khanlab/projects/DATA/Sample_NCI0439_T1D_E_HTNCJBGX9/Sample_NCI0439_T1D_E_HTNCJBGX9_{R1,R2}.fastq.gz" 
params.results    = "/data/khanlab/projects/Nextflow_test/results" 
reads_ch = Channel.fromFilePairs(params.reads).view()


process fastqc {

	input:
	tuple sample_id, file(reads_file) from reads_ch

	output:
	file("fastqc_${sample_id}_logs") into fastqc_ch

	container 'docker://nciccbr/ccbr_fastqc_0.11.9:v1.1'

	script:
	"""
	mkdir fastqc_${sample_id}_logs
	fastqc -o fastqc_${sample_id}_logs -f fastqc -q ${reads_file}
	"""
}
