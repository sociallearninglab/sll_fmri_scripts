HOME_DIR=/share/PI/hyo
STUDY_DIR=$HOME_DIR/$1
SUBJ_DIR=$STUDY_DIR/$2
DATA_DIR=`find $SUBJ_DIR$'/2'* -maxdepth 1 -print -quit`

echo $'Working on subject: '$2

mkdir $SUBJ_DIR$'/3danat'
mkdir $SUBJ_DIR$'/fieldmap'
mkdir $SUBJ_DIR$'/bold'
mkdir $SUBJ_DIR$'/roi'
mkdir $SUBJ_DIR$'/results'
mkdir $SUBJ_DIR$'/report'

echo '===== Working on anatomical image ====='
# Move anatomical image to anat folder
echo 'Step 1: Copying anatomical image...'
ANAT_FROM=`eval ls $DATA_DIR$'/*T1w*/*.nii.gz'`
ANAT_TO=$SUBJ_DIR$'/3danat/s0-T1w_original.nii.gz'
cp $ANAT_FROM $ANAT_TO

# Reorient
echo 'Step 2: Reorienting...'
fslreorient2std $ANAT_TO $ANAT_TO

# BET
echo 'Step 3: Brain extraction...'
ANAT_BET=${ANAT_TO/original/bet}
bet $ANAT_TO $ANAT_BET -f ${2-0.3} -B

# Unzip
echo 'Step 4: Gunzip...'
GUNZIP_FILES=$SUBJ_DIR$'/3danat/*nii.gz'
gunzip $GUNZIP_FILES

echo '===== Working on functional image ====='
BOLD_FROM=`eval ls $DATA_DIR$'/*BOLD*/*.nii.gz'`
for BOLD in $BOLD_FROM
do
	# Make new bold dir
	echo 'Step 1: Copying BOLD image...'
	BOLD_FNAME=`basename $BOLD`
	BOLD_INFO=`echo $BOLD_FNAME | egrep -o [0-9]+`
	SEQ_NO=`echo $BOLD_INFO | awk '{print $2}'`
	BOLD_DIR=`printf $SUBJ_DIR$'/bold/%03d' $SEQ_NO`

	mkdir $BOLD_DIR

	# Copy over bold image
	BOLD_TO=`printf $BOLD_DIR$'/f0-%03d.nii.gz' $SEQ_NO`
	echo $BOLD_TO

	cp $BOLD $BOLD_TO

	# Reorient
	echo 'Step 2: Reorienting...'
	fslreorient2std $BOLD_TO $BOLD_TO

	# Unzip
	echo 'Step 3: Gunzip...'
	gunzip $BOLD_TO
done

echo '===== Preparing fieldmaps ====='
FMAP_FROM=`eval ls $DATA_DIR$'/*fieldmap*/*fieldmap.nii.gz'`

for FMAP in $FMAP_FROM
do
	FMAP_FNAME=`basename $FMAP`
	echo $'Working on image: '$FMAP_FNAME

	# Extract sequence number from folder name
	FMAP_INFO=`echo $FMAP_FNAME | egrep -o [0-9]+`
	SEQ_NO=`echo $FMAP_INFO | awk '{print $2}'`
	FMAP_DIR=`printf $SUBJ_DIR$'/fieldmap/%03d' $SEQ_NO`
	mkdir $FMAP_DIR

	# Target file name
	FMAP_TO=`printf $FMAP_DIR$'/fieldmap-%03d.nii.gz' $SEQ_NO`

	# Get scan parameters
	PARAMS_FROM=${FMAP%.nii.gz}.json
	PARAMS_TO=`printf $FMAP_DIR$'/fieldmap-%03d.json' $SEQ_NO`

	# Get magnitude image (for masking)
	MASK_FROM=${FMAP/1fieldmap/1}
	MASK_TO=$FMAP_DIR/magnitude.nii.gz

	# Copy original fieldmap to target
	echo 'Step 1: Copying fieldmap'
	cp $FMAP $FMAP_TO
	cp $PARAMS_FROM $PARAMS_TO
	cp $MASK_FROM $MASK_TO

	# Convert to radians/s
	echo 'Step 2: Converting to radians/s'
	fslmaths $FMAP_TO -mul 6.28 $FMAP_TO

	echo 'Step 3: Masking fieldmap'
	MASK_IN=${MASK_TO/.nii.gz/_mask.nii.gz}
	bet $MASK_TO $MASK_TO -m -n
	fslmaths $FMAP_TO -mul $MASK_IN $FMAP_TO
	fugue --loadfmap=$FMAP_TO --despike --savefmap=$FMAP_TO
	fugue --loadfmap=$FMAP_TO -m --savefmap=$FMAP_TO
	fugue --loadfmap=$FMAP_TO -s 1 --savefmap=$FMAP_TO

	echo 'Step 4: Cleaning up fieldmap folder'
	rm -f $FMAP_DIR/magnitude*.nii.gz
	gunzip $FMAP_DIR/*.nii.gz
	
done

echo '===== Unpacking done! ====='
