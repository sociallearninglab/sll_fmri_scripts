#Written by Sajjad
#This script gets data in shape for MVPA analysis. SaxeLab folder structure is used.
#We assume that the last two runs are theory of mind localizers, and the first 5 are the task

#!/bin/bash
root="/Users/sll-members/fmri/"
project="SwiSt"
totalruns=5

path=$root$project
cd $path

#for subjects in $path/SLL_SwiSt_04; do
for subjects in $path/SLL_$project*; do
	[ -d "${subjects}" ] || continue #lists folders only
	cd $subjects
	mkdir MVPAdata
	mkdir MVPAdata/ROI_masks
	mkdir MVPAdata/all_runs
	ROIcount=0
	#preparing masks in nifti format
	for i in autoROI/*.img;do
		j=${i%.img}
		fslchfiletype NIFTI_GZ autoROI/${j##*/} MVPAdata/ROI_masks/${j##*/}
		ROIcount=$[ROIcount+1]
	done
	cd bold
	#merging 3D functionals into one 4D image for each run
	run_cnt=1
	subj_name="SLL_$project""_""${subjects: -2}"
	for runs in *; do
		[ -d "${runs}" ] || continue #lists folders only
		mkdir $subjects/MVPAdata/$runs
		fslmerge -t "$subjects/MVPAdata/$runs/motion_corrected_normalized_""$run_cnt" $runs/wrf0*
		#copy the result to all_runs folder to make the final merging easier
		cp "$subjects/MVPAdata/$runs/motion_corrected_normalized_""$run_cnt"".nii.gz" $subjects/MVPAdata/all_runs/
		#saving dim4 (number of volumes scanned in each run) values into a new file
		fslval "$subjects/MVPAdata/$runs/motion_corrected_normalized_""$run_cnt"".nii.gz" dim4 >> "$subjects/MVPAdata/all_runs/$subj_name"".scan.ips.txt"
		#move events file from the behavioral folder
		mv "$path/behavioral/$subj_name""_""$run_cnt"".txt" $subjects/MVPAdata/$runs/
		#mv "$path/behavioral/$subj_name""_""$run_cnt""_full.txt" $subjects/MVPAdata/$runs/
		if [ "$run_cnt" -eq "$totalruns" ]
		then
			break
		fi
		run_cnt=$[run_cnt+1]
	done
	#merging all the runs (4D images generated above for each run)
	fslmerge -t $subjects/MVPAdata/all_runs/all_runs $subjects/MVPAdata/all_runs/*
	#move the events file from behavioral folder:
	mv "$path/behavioral/$subj_name"".txt" $subjects/MVPAdata/all_runs/
	#mv "$path/behavioral/$subj_name""_full.txt" $subjects/MVPAdata/all_runs/
	#also move the ips file from behavioral folder:
	mv "$path/behavioral/$subj_name"".ips.txt" $subjects/MVPAdata/all_runs/
	
	#making a network of ROIs
	if [ "$ROIcount" -eq 0 ] || [ "$ROIcount" -eq 1 ]
	then
		echo Not enough number of regions to make a network!
	else
		cd $subjects/MVPAdata/ROI_masks
		img=1
		for icnt in *; do
			if [ "$img" -eq 1 ]; then
				firstimage=$icnt
				img=$[img+1]
			elif [ "$img" -eq 2 ]; then
				fslmaths $icnt -add $firstimage network.nii.gz
				img=$[img+1]
			else
				fslmaths $icnt -add network.nii.gz network.nii.gz
			fi
		done
	fi
done
