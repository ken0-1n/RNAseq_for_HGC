#! /bin/bash
#
# Copyright Human Genome Center, Institute of Medical Science, the University of Tokyo
# @since 2012
#

write_usage() {
  echo ""
  echo "Usage: `basename $0` [options] <input directory> <output directory> <tag> [<rna.env>]"
  echo ""
  echo "Options: -s converts solexa quality score to sanger quality score"
  echo ""
}


flg_sol2sanger="FALSE"
flg_cut_adoupt="FALSE"
while getopts s opt
do
  case ${opt} in
  s) flg_sol2sanger="TRUE";;
  \?)
    echo "invalid option"
    write_usage
    exit 1;;
  esac
done
shift `expr $OPTIND - 1`

readonly INPUTDIR=$1
readonly OUTPUTDIR=$2
readonly TAG=$3
rna_env=$4

readonly DIR=`dirname ${0}`

if [ $# -le 2 -o $# -ge 5 ]; then
  echo "wrong number of arguments"
  write_usage
  exit 1
fi

if [ $# -eq 3 ]; then
  rna_env=${DIR}/../conf/rna.env
fi

if [ $# -eq 4 ]; then
  if [ ! -f ${rna_env} ]; then
    echo "${rna_env} dose not exists"
    write_usage
    exit 1
  fi
fi

source ${rna_env}
source ${UTIL}

perl ${COMMAND_MAPPING}/checkTagParam.pl ${TAG}

# input file check
check_file_exists ${INPUTDIR}/sequence1.txt
check_file_exists ${INPUTDIR}/sequence2.txt
  

# make output directory 
check_mkdir ${OUTPUTDIR}/sequence/preprocess 
check_mkdir ${OUTPUTDIR}/sequence/preprocess/sanger
check_mkdir ${OUTPUTDIR}/sequence/preprocess/split
check_mkdir ${OUTPUTDIR}/sequence/preprocess/idchange

check_mkdir ${OUTPUTDIR}/sequence/map_bowtie/split
check_mkdir ${OUTPUTDIR}/sequence/map_bowtie/aligned
check_mkdir ${OUTPUTDIR}/sequence/map_bowtie/genome

check_mkdir ${OUTPUTDIR}/sequence/map_blat/unmapped
check_mkdir ${OUTPUTDIR}/sequence/map_blat/aligned

check_mkdir ${OUTPUTDIR}/sequence/assembly/input  
    
check_mkdir ${OUTPUTDIR}/sequence/merge/aligned 
check_mkdir ${OUTPUTDIR}/sequence/merge/paired

check_mkdir ${OUTPUTDIR}/summary


readonly OUTPUTDATADIR=${OUTPUTDIR}/sequence/preprocess

readonly CURLOGDIR=${LOGDIR}/${TAG}
check_mkdir ${CURLOGDIR}
readonly LOGSTR=-e\ ${CURLOGDIR}\ -o\ ${CURLOGDIR}

readonly JOB_FASTQ1=fastqid_change.${TAG}.1
readonly JOB_FASTQ2=fastqid_change.${TAG}.2
readonly JOB_MAQ1=maq_sol2sanger.${TAG}.1
readonly JOB_MAQ2=maq_sol2sanger.${TAG}.2
readonly JOB_SPLIT1=split.${TAG}.1
readonly JOB_SPLIT2=split.${TAG}.2



# preprocess step
echo "qsub -v RNA_ENV=${rna_env} -N ${JOB_FASTQ1} ${LOGSTR} ${COMMAND_MAPPING}/changeFastqIds.pl ${TAG} 1 ${INPUTDIR}/sequence1.txt ${OUTPUTDATADIR}/idchange/sequence1.txt"
qsub -v RNA_ENV=${rna_env} -N ${JOB_FASTQ1} ${LOGSTR} ${COMMAND_MAPPING}/changeFastqIds.pl ${TAG} 1 ${INPUTDIR}/sequence1.txt ${OUTPUTDATADIR}/idchange/sequence1.txt

echo "qsub -v RNA_ENV=${rna_env} -N ${JOB_FASTQ2} ${LOGSTR} ${COMMAND_MAPPING}/changeFastqIds.pl ${TAG} 2 ${INPUTDIR}/sequence2.txt ${OUTPUTDATADIR}/idchange/sequence2.txt"
qsub -v RNA_ENV=${rna_env} -N ${JOB_FASTQ2} ${LOGSTR} ${COMMAND_MAPPING}/changeFastqIds.pl ${TAG} 2 ${INPUTDIR}/sequence2.txt ${OUTPUTDATADIR}/idchange/sequence2.txt


if [ ${flg_sol2sanger} = "TRUE" ]; then
  echo "qsub -v RNA_ENV=${rna_env} -N ${JOB_MAQ1} -hold_jid ${JOB_FASTQ1} ${LOGSTR} ${COMMAND_MAPPING}/maq_sol2sanger.sh ${OUTPUTDATADIR}/idchange/sequence1.txt ${OUTPUTDATADIR}/sanger/sequence1.txt"
  qsub -v RNA_ENV=${rna_env} -N ${JOB_MAQ1} -hold_jid ${JOB_FASTQ1} ${LOGSTR} ${COMMAND_MAPPING}/maq_sol2sanger.sh ${OUTPUTDATADIR}/idchange/sequence1.txt ${OUTPUTDATADIR}/sanger/sequence1.txt

  echo "qsub -v RNA_ENV=${rna_env} -N ${JOB_MAQ2} -hold_jid ${JOB_FASTQ2} ${LOGSTR} ${COMMAND_MAPPING}/maq_sol2sanger.sh ${OUTPUTDATADIR}/idchange/sequence2.txt ${OUTPUTDATADIR}/sanger/sequence2.txt"
  qsub -v RNA_ENV=${rna_env} -N ${JOB_MAQ2} -hold_jid ${JOB_FASTQ2} ${LOGSTR} ${COMMAND_MAPPING}/maq_sol2sanger.sh ${OUTPUTDATADIR}/idchange/sequence2.txt ${OUTPUTDATADIR}/sanger/sequence2.txt
fi

readonly SPLITFACTOR=4000000
inputFastq1=${OUTPUTDATADIR}/idchange/sequence1.txt
inputFastq2=${OUTPUTDATADIR}/idchange/sequence2.txt

if [ ${flg_sol2sanger} = "TRUE" ]; then
  inputFastq1=${OUTPUTDATADIR}/sanger/sequence1.txt
  inputFastq2=${OUTPUTDATADIR}/sanger/sequence2.txt
fi

echo "qsub -v RNA_ENV=${rna_env} -N ${JOB_SPLIT1} -hold_jid ${JOB_FASTQ1},${JOB_MAQ1},${JOB_CUT1} ${LOGSTR} ${COMMAND_MAPPING}/split.sh ${SPLITFACTOR} 3 ${inputFastq1} ${OUTPUTDATADIR}/split/sequence1.txt."
qsub -v RNA_ENV=${rna_env} -N ${JOB_SPLIT1} -hold_jid ${JOB_FASTQ1},${JOB_MAQ1},${JOB_CUT1} ${LOGSTR} ${COMMAND_MAPPING}/split.sh ${SPLITFACTOR} 3 ${inputFastq1} ${OUTPUTDATADIR}/split/sequence1.txt.

echo "qsub -v RNA_ENV=${rna_env} -N ${JOB_SPLIT2} -hold_jid ${JOB_FASTQ2},${JOB_MAQ2},${JOB_CUT2} ${LOGSTR} ${COMMAND_MAPPING}/split.sh ${SPLITFACTOR} 3 ${inputFastq2} ${OUTPUTDATADIR}/split/sequence2.txt."
qsub -v RNA_ENV=${rna_env} -N ${JOB_SPLIT2} -hold_jid ${JOB_FASTQ2},${JOB_MAQ2},${JOB_CUT2} ${LOGSTR} ${COMMAND_MAPPING}/split.sh ${SPLITFACTOR} 3 ${inputFastq2} ${OUTPUTDATADIR}/split/sequence2.txt.


