#!/bin/bash
#SLL_ANONYMIZE
#Anonymizes NIMS data using pydeface 
#Usage: bash sll_anonymize.sh [PROJECT_NAME]

# Get input and output directories
PROJECT_NAME=$1
PROJECT_DIR=$PI_SCRATCH/$PROJECT_NAME
IN_DIR=$PROJECT_DIR/NIMS_data
OUT_DIR=$PROJECT_DIR/NIMS_data_anonymized

# Copy original NIMS data to a new "anonymized" folder
#cp -r $IN_DIR $OUT_DIR

# Deface and reorient all images in OUT_DIR
ANON_IMG=$(find $OUT_DIR -name *.nii.gz)
for img in $ANON_IMG; do
	
done
