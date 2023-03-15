#!/usr/bin/env bash
#
# EMMA content download script
#

#set -x

# source common helpers
SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <input directory> <output directory>"
}

# ensure correct usage
if [ $# -lt 2 ]; then
   show_use_and_exit
fi

# input parameters for clarity
INPUT_DIR=${1}
shift
OUTPUT_DIR=${1}
shift

# check the input and output directories exists
ensure_dir_exists ${INPUT_DIR}
ensure_dir_exists ${OUTPUT_DIR}

# check the tools are available
AWS_TOOL=aws
ensure_tool_available ${AWS_TOOL}
JQ_TOOL=jq
ensure_tool_available ${JQ_TOOL}

# other definitions
DIR_LIST=/tmp/emma-dirlist.$$
ls -l ${INPUT_DIR} | awk '{print $9}' | sort > ${DIR_LIST}

# track our progress
SUCCESS_COUNT=0
ERROR_COUNT=0

# process each directory...
for dname in $(<${DIR_LIST}); do

   submission_id=${dname}
   in_dir=${INPUT_DIR}/${dname}
   out_dir=${OUTPUT_DIR}/export-${submission_id}
   mkdir ${out_dir}
   res=$?
   if [ ${res} -ne 0 ]; then
      ((ERROR_COUNT=ERROR_COUNT+1))
      continue
   fi

   # check the content files exists
   if [ ! -s ${in_dir}/file-data.json -o ! -s ${in_dir}/file-url.txt ]; then
      echo "${submission_id}: missing export file"
      ((ERROR_COUNT=ERROR_COUNT+1))
      continue
   fi

   # extract the info we need
   file_url=$(cat ${in_dir}/file-url.txt)
   file_name=$(cat ${in_dir}/file-data.json | ${JQ_TOOL} -r ".metadata .filename")
   if [ -z "${file_url}" -o -z "${file_name}" ]; then
      echo "${submission_id}: missing metadata"
      ((ERROR_COUNT=ERROR_COUNT+1))
      continue
   fi

   # download the file
   echo "downloading ${file_url} -> ${file_name}"

   # making lots of assumptions   
   bucket=$(echo ${file_url} | awk -F'/' '{print $3}' | awk -F. '{print $1}')
   key=$(echo ${file_url} | awk -F'/' '{printf "%s/%s", $4, $5}')
   
   ${AWS_TOOL} s3 cp s3://${bucket}/${key} "${out_dir}/${file_name}" --quiet
   #touch "${out_dir}/${file_name}"
   res=$?
   if [ ${res} -ne 0 ]; then
      # error message from failed command
      ((ERROR_COUNT=ERROR_COUNT+1))
      continue
   fi

   # copy the metadata
   cat ${in_dir}/emma-data.json | ${JQ_TOOL} . > ${out_dir}/metadata.json
   res=$?
   if [ ${res} -ne 0 ]; then
      echo "${submission_id}: missing metadata file"
      ((ERROR_COUNT=ERROR_COUNT+1))
      continue
   fi

   ((SUCCESS_COUNT=SUCCESS_COUNT+1))
done

rm ${DIR_LIST}

# status message
echo "done... ${SUCCESS_COUNT} successful, ${ERROR_COUNT} error(s)"

# its all over
exit 0

#
# end of file
#
