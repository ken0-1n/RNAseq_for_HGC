#! /bin/bash
#
# Copyright Human Genome Center, Institute of Medical Science, the University of Tokyo
# @since 2012
#

write_usage() {
  echo ""
  echo "Usage: `basename $0` <output directory> <tag> [<rna.env>]"
  echo ""
}

readonly OUTPUTDIR=$1
readonly TAG=$2
rna_env=$3

readonly DIR=`dirname ${0}`

if [ $# -le 1 -o $# -ge 4 ]; then
  echo "wrong number of arguments"
  write_usage
  exit 1
fi

if [ $# -eq 2 ]; then
  rna_env=${DIR}/../conf/rna.env
fi

if [ $# -eq 3 ]; then
  if [ ! -f ${rna_env} ]; then
    echo "${rna_env} dose not exists"
    write_usage
    exit 1
  fi
fi


source ${rna_env}
source ${UTIL}

readonly OUTPUTDATADIR_PREPRO=${OUTPUTDIR}/sequence/preprocess
readonly OUTPUTDATADIR_BOWTIE=${OUTPUTDIR}/sequence/map_bowtie

readonly CURLOGDIR=${LOGDIR}/${TAG}
check_mkdir ${CURLOGDIR}
readonly LOGSTR=-e\ ${CURLOGDIR}\ -o\ ${CURLOGDIR}

# input file check
file_count_check=`find ${OUTPUTDATADIR_PREPRO}/split/sequence1.txt.*`
check_error $?

readonly FILECOUNT=`find ${OUTPUTDATADIR_PREPRO}/split/sequence1.txt.* | wc -l`
  

readonly JOB_BOWTIE1=run_bowtie.${TAG}.1
readonly JOB_BOWTIE2=run_bowtie.${TAG}.2
readonly JOB_CGENOME1=convert2GenomicCoordinate.${TAG}.1
readonly JOB_CGENOME2=convert2GenomicCoordinate.${TAG}.2


echo "qsub -v RNA_ENV=${rna_env} -t 1-${FILECOUNT}:1 -l s_vmem=8G,mem_req=8 -N ${JOB_BOWTIE1} ${LOGSTR} ${COMMAND_MAPPING}/run_bowtie.sh ${OUTPUTDATADIR_PREPRO}/split/sequence1.txt ${OUTPUTDATADIR_BOWTIE}/aligned/sequence1.sam"
qsub -v RNA_ENV=${rna_env} -t 1-${FILECOUNT}:1 -l s_vmem=8G,mem_req=8 -N ${JOB_BOWTIE1} ${LOGSTR} ${COMMAND_MAPPING}/run_bowtie.sh ${OUTPUTDATADIR_PREPRO}/split/sequence1.txt ${OUTPUTDATADIR_BOWTIE}/aligned/sequence1.sam

echo "qsub -v RNA_ENV=${rna_env} -t 1-${FILECOUNT}:1 -l s_vmem=8G,mem_req=8 -N ${JOB_BOWTIE2} ${LOGSTR} ${COMMAND_MAPPING}/run_bowtie.sh ${OUTPUTDATADIR_PREPRO}/split/sequence2.txt ${OUTPUTDATADIR_BOWTIE}/aligned/sequence2.sam"
qsub -v RNA_ENV=${rna_env} -t 1-${FILECOUNT}:1 -l s_vmem=8G,mem_req=8 -N ${JOB_BOWTIE2} ${LOGSTR} ${COMMAND_MAPPING}/run_bowtie.sh ${OUTPUTDATADIR_PREPRO}/split/sequence2.txt ${OUTPUTDATADIR_BOWTIE}/aligned/sequence2.sam


echo "qsub -v RNA_ENV=${rna_env} -t 1-${FILECOUNT}:1 -l s_vmem=4G,mem_req=4 -N ${JOB_CGENOME1} -hold_jid ${JOB_BOWTIE1} ${LOGSTR} ${COMMAND_MAPPING}/convert2GenomicCoordinate.sh ${OUTPUTDATADIR_BOWTIE}/aligned/sequence1.sam ${OUTPUTDATADIR_BOWTIE}/genome/sequence1.sam"
qsub -v RNA_ENV=${rna_env} -t 1-${FILECOUNT}:1 -l s_vmem=4G,mem_req=4 -N ${JOB_CGENOME1} -hold_jid ${JOB_BOWTIE1} ${LOGSTR} ${COMMAND_MAPPING}/convert2GenomicCoordinate.sh ${OUTPUTDATADIR_BOWTIE}/aligned/sequence1.sam ${OUTPUTDATADIR_BOWTIE}/genome/sequence1.sam

echo "qsub -v RNA_ENV=${rna_env} -t 1-${FILECOUNT}:1 -l s_vmem=4G,mem_req=4 -N ${JOB_CGENOME2} -hold_jid ${JOB_BOWTIE2} ${LOGSTR} ${COMMAND_MAPPING}/convert2GenomicCoordinate.sh ${OUTPUTDATADIR_BOWTIE}/aligned/sequence2.sam ${OUTPUTDATADIR_BOWTIE}/genome/sequence2.sam"
qsub -v RNA_ENV=${rna_env} -t 1-${FILECOUNT}:1 -l s_vmem=4G,mem_req=4 -N ${JOB_CGENOME2} -hold_jid ${JOB_BOWTIE2} ${LOGSTR} ${COMMAND_MAPPING}/convert2GenomicCoordinate.sh ${OUTPUTDATADIR_BOWTIE}/aligned/sequence2.sam ${OUTPUTDATADIR_BOWTIE}/genome/sequence2.sam


