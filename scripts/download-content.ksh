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

# ensure our environment definitions are available
ensure_var_defined "${EMMA_CONTENT_BUCKET}" "EMMA_CONTENT_BUCKET"

# other definitions
FILE_LIST=/tmp/emma-filelist.$$
find ${INPUT_DIR} -maxdepth 1 -name submission-id.* | sort > ${FILE_LIST}

# track our progress
SUCCESS_COUNT=0
ERROR_COUNT=0

# process each file...
for fname in $(<${FILE_LIST}); do

   id=$(echo ${fname} | awk -F. '{print $2}')

   sub_id=$(cat ${fname})

   out_dir=${OUTPUT_DIR}/export-${sub_id}
   mkdir ${out_dir}
   res=$?
   if [ ${res} -ne 0 ]; then
      ((ERROR_COUNT=ERROR_COUNT+1))
      continue
   fi

   # check the content file exists
   if [ ! -s ${INPUT_DIR}/file-data.${id} ]; then
      ((ERROR_COUNT=ERROR_COUNT+1))
      continue
   fi

   # extract the info we need
   file_id=$(cat ${INPUT_DIR}/file-data.${id} | ${JQ_TOOL} -r ".id")
   file_name=$(cat ${INPUT_DIR}/file-data.${id} | ${JQ_TOOL} -r ".metadata .filename")
   if [ -z "${file_id}" -o -z "${file_name}" ]; then
      ((ERROR_COUNT=ERROR_COUNT+1))
      continue
   fi

   # download the file from the S3 bucket
   echo "${sub_id} downloading ${file_id} -> ${file_name}"
   ${AWS_TOOL} s3 cp s3://${EMMA_CONTENT_BUCKET}/upload/${file_id} "${out_dir}/${file_name}" --quiet
   #touch "${out_dir}/${file_name}"
   res=$?
   if [ ${res} -ne 0 ]; then
      ((ERROR_COUNT=ERROR_COUNT+1))
      continue
   fi

   # copy the metadata
   cat ${INPUT_DIR}/emma-data.${id} | ${JQ_TOOL} . > ${out_dir}/metadata.json
   res=$?
   if [ ${res} -ne 0 ]; then
      ((ERROR_COUNT=ERROR_COUNT+1))
      continue
   fi

   ((SUCCESS_COUNT=SUCCESS_COUNT+1))
done

rm ${FILE_LIST}

# status message
echo "done... ${SUCCESS_COUNT} successful, ${ERROR_COUNT} error(s)"

# its all over
exit 0

#
# end of file
#
