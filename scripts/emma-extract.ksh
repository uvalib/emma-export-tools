#!/usr/bin/env bash
#
# EMMA extract script
#

#set -x

# source common helpers
SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <output directory>"
}

# ensure correct usage
if [ $# -lt 1 ]; then
   show_use_and_exit
fi

# input parameters for clarity
OUTPUT_DIR=${1}

# check the output directory exists
ensure_dir_exists ${OUTPUT_DIR}

# check endpoint variable
ensure_var_defined "${EMMA_METADATA_ENDPOINT}" "EMMA_METADATA_ENDPOINT"

# tools for extract
METADATA_EXTRACT=${SCRIPT_DIR}/extract-metadata.ksh
ensure_file_exists ${METADATA_EXTRACT}
CONTENT_EXTRACT=${SCRIPT_DIR}/download-content.ksh
ensure_file_exists ${CONTENT_EXTRACT}

METADATA_DIR=/tmp/emma-extract-$$
mkdir ${METADATA_DIR}

${METADATA_EXTRACT} ${METADATA_DIR} ${EMMA_METADATA_ENDPOINT}
exit_on_error $? "extracting metadata"

${CONTENT_EXTRACT} ${METADATA_DIR} ${OUTPUT_DIR}
exit_on_error $? "extracting content"

# its all over
exit 0

#
# end of file
#
