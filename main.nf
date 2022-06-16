//params.genome     = "/data/khanlab/projects/ngs_pipeline_testing/References_4.0/GRCh38"
//params.reads      = "/data/khanlab/projects/DATA/Sample_NCI0439_T1D_E_HTNCJBGX9/Sample_NCI0439_T1D_E_HTNCJBGX9_{R1,R2}.fastq.gz" 
params.reads      = "/data/khanlab/projects/Nextflow_test/test_data/Sample_NCI0439_T1D_E_HTNCJBGX9_{R1,R2}.fastq"
params.results    = "/data/khanlab/projects/Nextflow_test/results" 
reads_ch = Channel.fromFilePairs(params.reads)
reads1_ch = Channel.fromFilePairs(params.reads)
params.out = "/data/khanlab/projects/Nextflow_test/results"


process cutadapt {

	input:
	tuple val(sample_id), path(reads) from reads_ch

	output:
	path "trim*" into trim_ch

	container 'docker://nciccbr/ccbr_cutadapt_1.18:v032219'

	script:
	"""
	cutadapt  -o trim_${sample_id}_R1.fastq -p trim_${sample_id}_R2.fastq ${reads[0]} ${reads[1]}
	"""

}


process fastqc {

	publishDir "$params.out/$sample_id", mode: 'move'

	input:
//	tuple sample_id, file(reads_file) from reads_ch
	tuple val(sample_id), path(reads) from reads1_ch
	path(pairs) from trim_ch

	output:
	path("fastqc_${sample_id}_logs") into fastqc_ch

	container 'docker://nciccbr/ccbr_fastqc_0.11.9:v1.1'

	script:
	"""
	
	mkdir fastqc_${sample_id}_logs
	fastqc -o fastqc_${sample_id}_logs -q ${reads}
	fastqc -o fastqc_${sample_id}_logs -q ${pairs}
	"""
}




