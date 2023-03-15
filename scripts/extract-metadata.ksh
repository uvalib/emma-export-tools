#!/usr/bin/env bash
#
# EMMA metadata extract script
#

#set -x

# source common helpers
SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <output directory> <metadata endpoint>"
}

# ensure correct usage
if [ $# -lt 2 ]; then
   show_use_and_exit
fi

# input parameters for clarity
OUTPUT_DIR=${1}
shift
METADATA_ENDPOINT=${1}
shift

# check the output directory exists
ensure_dir_exists ${OUTPUT_DIR}

# check the tools are available
CURL_TOOL=curl
ensure_tool_available ${CURL_TOOL}
JQ_TOOL=jq
ensure_tool_available ${JQ_TOOL}

# other definitions
RAW_FILE=/tmp/emma-extract-raw.$$
DATA_FILE=/tmp/emma-extract-data.$$
TOOL_DEFAULTS="--fail -s -S"

# pull the metadata
${CURL_TOOL} ${TOOL_DEFAULTS} ${METADATA_ENDPOINT} > ${RAW_FILE}
exit_on_error $? "Getting metadata (${METADATA_ENDPOINT})"

# pull out the data we need
cat ${RAW_FILE} | ${JQ_TOOL} -r '.entries.list[] | "\(.submission_id)|\(.file_url)|\(.emma_data)|\(.file_data)"' > ${DATA_FILE}

# track our progress
SUCCESS_COUNT=0
ERROR_COUNT=0

# go through each one
IFS=$'\n'
for line in $(<${DATA_FILE}); do

   submission_id=$(echo ${line} | awk -F'|' '{print $1}' | awk '{print $1}')
   echo "Processing ${submission_id}..."
   out_dir=${OUTPUT_DIR}/${submission_id}
   mkdir ${out_dir}
   if [ $? -eq 0 ]; then

      echo ${line} | awk -F'|' '{print $2}' > ${out_dir}/file-url.txt
      echo ${line} | awk -F'|' '{print $3}' > ${out_dir}/emma-data.json
      echo ${line} | awk -F'|' '{print $4}' > ${out_dir}/file-data.json

      ((SUCCESS_COUNT=SUCCESS_COUNT+1))
   else
      # error message issued by failed command
      ((ERROR_COUNT=ERROR_COUNT+1))
   fi

done

# remove tmp files
rm ${RAW_FILE}
rm ${DATA_FILE}

# status message
echo "done... ${SUCCESS_COUNT} successful, ${ERROR_COUNT} error(s)"

# its all over
exit 0

#
# end of file
#
