#!/bin/bash
#SLL_ANONYMIZE
#Anonymizes NIMS data using pydeface 
#Usage: bash sll_anonymize.sh [PROJECT_NAME]

#################
#set a job name  
#SBATCH --job-name=anonymize
#################  
#a file for job output, you can check job progress, append the job ID with %j to make it unique
#SBATCH --output=anonymize.%j.out
#################
# a file for errors from the job
#SBATCH --error=anonymize.%j.err
#################
#time you think you need; default is 2 hours
#format could be dd-hh:mm:ss, hh:mm:ss, mm:ss, or mm
#SBATCH --time=0:45
#################
# Quality of Service (QOS); think of it as sending your job into a special queue; --qos=long for with a max job length of 7 days.
#SBATCH -p normal
#################
#number of nodes you are requesting, the more you ask for the longer you wait
#SBATCH --nodes=1
#################
# --mem is memory per node; default is 4000 MB per CPU, remember to ask for enough mem to match your CPU request, since 
# sherlock automatically allocates 4 Gigs of RAM/CPU, if you ask for 8 CPUs you will get 32 Gigs of RAM, so either 
# leave --mem commented out or request >= to the RAM needed for your CPU request.  It will also accept mem. in units, ie "--mem=4G"
#SBATCH --mem=4000
# to request multiple threads/CPUs use the -c option, on Sherlock we use 1 thread/CPU, 16 CPUs on each normal compute node 4Gigs RAM per CPU.  Here we will request just 1.
#SBATCH -c 1
#################
# Have SLURM send you an email when the job ends or fails, careful, the email could end up in your clutter folder
# Also, if you submit hundreds of jobs at once you will get hundreds of emails.
#SBATCH --mail-type=END,FAIL # notifications for job done & fail
# Remember to change this to your email
##SBATCH --mail-user=YourSUNetID@stanford.edu

ml load singularity
ml load fsl

# Get input and output directories
PROJECT_NAME=$1
PROJECT_DIR=$PI_SCRATCH/$PROJECT_NAME
IN_DIR=$PROJECT_DIR/NIMS_data
OUT_DIR=$PROJECT_DIR/NIMS_data_anonymized

# Copy original NIMS data to a new "anonymized" folder
cp -r $IN_DIR $OUT_DIR

# Reorient all images in OUT_DIR
echo '====== REORIENTING IMAGES ======'
ANON_IMG=$(find $OUT_DIR -name *.nii.gz)
for img in $ANON_IMG; do
	printf 'Reorienting: %s' $img
	fslreorient2std $img $img
done

# Deface
# NOTE: pydeface must be installed in your home directory. You can install it by running the following lines:
# cd $PI_HOME/sll_scripts/pydeface
# python setup.py install --user
echo '====== DEFACING ======'
NIPYPE_IMG=$PI_HOME/singularity_images/nipype*.img
PYDEFACE=$HOME/.local/bin/pydeface.py
singularity run $NIPYPE_IMG
for img in $ANON_IMG; do
	printf 'Anonymizing: %s' $img
	$PYDEFACE $img $img
done

printf 'Anonymization done! Anonymized files can be found at: %s' $OUT_DIR