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

# check the AWS cli is available
AWS_TOOL=aws
ensure_tool_available ${AWS_TOOL}

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

   # download the file from the S3 bucket
   file_id=$(cat ${INPUT_DIR}/file-data.${id} | jq -r ".id")
   echo "${sub_id} downloading ${file_id} ..."
   ${AWS_TOOL} s3 cp s3://${EMMA_CONTENT_BUCKET}/upload/${file_id} ${out_dir}/${file_id} --quiet
   res=$?
   if [ ${res} -ne 0 ]; then
      ((ERROR_COUNT=ERROR_COUNT+1))
      continue
   fi

   # copy the metadata
   cat ${INPUT_DIR}/emma-data.${id} | jq . > ${out_dir}/metadata.json
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
