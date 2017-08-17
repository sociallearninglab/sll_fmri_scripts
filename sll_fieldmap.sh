# Useful directories
HOME_DIR=/share/PI/hyo
STUDY_DIR=$HOME_DIR/$1
SUBJ_DIR=$STUDY_DIR/$2
FMAP_DIR=$SUBJ_DIR/fieldmap
BOLD_DIR=$SUBJ_DIR/bold

# Get fieldmap sequences
FMAP_SEQ=`printf %03d $3`
FMAP_IN=$FMAP_DIR/$FMAP_SEQ/fieldmap-$FMAP_SEQ.nii
echo $FMAP_IN

# Get BOLD sequences
echo $4
