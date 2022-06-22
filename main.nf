//params.genome     = "/data/khanlab/projects/ngs_pipeline_testing/References_4.0/GRCh38"
params.star_Ref    = "/data/khanlab/projects/ngs_pipeline_testing/References_4.0/New_GRCh37/Index/STAR_2.7.8a"
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
	path "trim*" into trim_ch1, trim_ch2

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
	path(pairs) from trim_ch1

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

process star {

	publishDir "$params.out/$sample_id", mode: 'move'

	input:
	path(pairs) from trim_ch2

	output:
	path("*.bam") into bam_ch

	container 'docker://nciccbr/ccbr_star_2.7.0f'

	script:
	"""
	mkdir STAR_out
	STAR --genomeDir $star_Ref \
		--readFilesIn  ${pairs} \
		--outFileNamePrefix ${sample_id}_ENS \
		--runThreadN ${task.cpus} \
		--twopassMode Basic \
		--outSAMunmapped Within \
		--chimSegmentMin 12 \
		--chimJunctionOverhangMin 12 \
		--alignSJDBoverhangMin 10 \
		--alignMatesGapMax 100000 \
		--chimSegmentReadGapMax 3 \
		--outFilterMismatchNmax 2 \
		--outSAMtype BAM SortedByCoordinate \
		--quantMode TranscriptomeSAM \
		--outBAMsortingThreadN 6 \
		--limitBAMsortRAM 80000000000
	"""
}

