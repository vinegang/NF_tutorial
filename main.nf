
//params.genome     = "/data/khanlab/projects/ngs_pipeline_testing/References_4.0/GRCh38"
//params.star_Ref    = "/data/khanlab/projects/ngs_pipeline_testing/References_4.0/New_GRCh37/Index/STAR_2.7.8a"
genomeIndex = Channel.fromPath("/data/khanlab/projects/ngs_pipeline_testing/References_4.0/New_GRCh37/Index/STAR_2.7.8a")
rsemIndex = Channel.fromPath("/data/khanlab/projects/ngs_pipeline_testing/References_4.0/New_GRCh37/Index/rsem_1.3.2")
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

	container 'docker://nciccbr/ncigb_cutadapt_v1.18:latest'

	script:
	"""
	cutadapt  -o trim_${sample_id}_R1.fastq -p trim_${sample_id}_R2.fastq ${reads[0]} ${reads[1]}
	"""

}


process fastqc {

//	publishDir "$params.out/$sample_id", mode: 'move'

	input:
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

//	publishDir "$params.out/", mode: 'move'

	input:
	path(pairs) from trim_ch2
	file(STARgenome) from genomeIndex

	output:
	path "*Aligned.toTranscriptome.out.bam" into bam1
	path "*Aligned.sortedByCoord.out.bam" into bam2
//	path("STAR_out") into bam_ch


	container 'docker://nciccbr/ncigb_star_v2.7.10a:latest'

	script:
	"""
	STAR --genomeDir ${STARgenome} \
		--readFilesIn  ${pairs} \
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
	
#	mkdir STAR_out
#	mv *bam ./STAR_out
	"""
}



process rsem {

	publishDir "$params.out/", mode: 'move'
	input:
	path("bamfile") from bam1
	file(rsemindex) from rsemIndex

	output:
	path("rsem_out") into expr
	
	container 'docker://nciccbr/ccbr_rsem_1.3.3:v1.0'

	script:
	"""
	rsem-calculate-expression --no-bam-output --paired-end -p ${task.cpus}  --estimate-rspd  --bam ${bamfile} ${rsemindex}/rsem_1.3.2 test
	mkdir rsem_out
	mv *results ./rsem_out
	"""

}
