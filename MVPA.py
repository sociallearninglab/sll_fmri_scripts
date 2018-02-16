import os
from os import listdir
from os.path import isfile, join
import mvpa2
import nipy
import operator

from mvpa2.suite import *

root = '/Volumes/sll-members/fmri/'
project = 'SwiSt'

conditions_to_classify = ['advisor_none', 'advisor_both', 'advisor_hidden']

path = root + project
os.chdir(path)

first_subj = 23
last_subj = 23

#raw 4D data of each subject has the correct TR information (can be checked by looking at pixdim4 using fslinfo)
# but we take 3D volumes out of 4D files, place them in "bold" folders, and then merge them again for MVPA purposes
# this way, we lose the correct TR information, and it will equal 1.000000 in the new 4D data
# so we need to take care of that here in the code
TR = 2

#looping through subjects:
for subjects in range(first_subj,last_subj+1):
    if subjects < 10:
        subj_name = 'SLL_' + project + '_0' + str(subjects)
    else:
        subj_name = 'SLL_' + project + '_' + str(subjects)

    all_runs_bold_fname = os.path.join(path,subj_name,'MVPAdata','all_runs','all_runs.nii.gz')

    # importing events' information including onsets and durations which are originally extracted from behavioral files
    ctr = 1
    with open(os.path.join(path, subj_name, 'MVPAdata', 'all_runs', subj_name + "." + 'txt')) as f:
        for line in f:
            if ctr == 1:
                chunks = map(int, line.split(','))
            elif ctr == 2:
                duration = map(float, line.split(','))
            elif ctr == 3:
                onset = map(float, line.split(','))
            elif ctr == 4:
                targets = line.split(',')
            ctr += 1


    scan_ips_list = []
    chunks_labels = [] # will be used for labeling samples
    chunk_counter = 0 # labeling starts from zero
    with open(os.path.join(path, subj_name, 'MVPAdata', 'all_runs', subj_name + ".scan.ips." + 'txt')) as sips:
        for line in sips:
            scan_ips_list.append(int(line))
            for i in range(0, int(line)):
                chunks_labels.append(chunk_counter)
            chunk_counter += 1

    ips_list = []
    ctr = 1
    with open(os.path.join(path, subj_name, 'MVPAdata', 'all_runs', subj_name + ".ips." + 'txt')) as fips:
        for line in fips:
            if ctr == 1:
                number_of_runs = int(line)
                ctr += 1
            else:
                ips_list.append(int(line))
    offsets = []
    for i in range(0, number_of_runs-1): #exp: for 5 runs, we need 4 offsets - we can also use len(ips_list) rather than number_of_runs
        if i == 0:
            offsets.append(ips_list[i]*TR) #ips_list[i] is the number of volumes in chunk i
        else:
            offsets.append(offsets[-1] + ips_list[i]*TR) #some_list[-1] is the shortest and most Pythonic way of getting
                                                         # the last element of a list

    sub = map(operator.sub, scan_ips_list, ips_list)

    # generating a list of dictionaries
    original_events = []
    for i in range(0, len(chunks)):  # we could instead use len(duration), len(onset), or len(targets)
        current_event = {}
        current_event['chunks'] = chunks[i]
        current_event['duration'] = duration[i]
        current_event['onset'] = onset[i]
        if chunks[i] != 0: #no offset for the first chunk
            current_event['onset'] = current_event['onset'] + offsets[chunks[i] - 1]
        current_event['targets'] = targets[i]
        original_events.append(current_event)

    for e in original_events[:4]:
        print e

    #in this general script, we do classification both in individual ROIs and also in a network containing all of them
    ROIs = [] #a list containing all ROIs
    ROIs = os.listdir(os.path.join(path, subj_name, 'MVPAdata', 'ROI_masks'))

    #looping through all ROIs in each subject
    for ROIloop in range(0, len(ROIs)):
        mask_fname = os.path.join(path,subj_name,'MVPAdata','ROI_masks', ROIs[ROIloop])
        fds = fmri_dataset(samples=all_runs_bold_fname,
                           mask=mask_fname)

        fds.sa.time_coords = fds.sa.time_coords * TR

        # chunks_labels = events2sample_attr(original_events, fds.sa.time_coords, condition_attr='chunks')
        # rather than using events2sample_attr (or assign_conditionlabels) to attribute chunks labels to samples which
        # would be tricky because of noinfolabel, we do:
        fds.sa['chnks'] = chunks_labels # we call this sample attribute 'chnks' so later it is not mistaken for 'chunks' in events

        targets_labels = events2sample_attr(original_events, fds.sa.time_coords, noinfolabel='rest', condition_attr='targets')
        fds.sa['trgts'] = targets_labels
        # we can do intensity normalization here using samples with 'rest' targets

        # notice that we will be using 'chnks' and 'trgts' sample attributes for detrending and intensity normalization purposes,
        # and not for cross-validation because with jittering, a lot of information will be lost that way -> events will be used

        # since our data usually stems from several different runs, the assumption of a continuous linear trend
        # across all runs is not appropriate:
        # poly_detrend(fds, polyord=1)
        # therefore, we do:
        poly_detrend(fds, polyord=1, chunks_attr='chnks')  # Event-related Pre-processing Is Not Event-related
                                                            # some preprocessing is only meaningful when performed on the
                                                            # full time series and not on the segmented event samples. An
                                                            # example is detrending that typically needs to be done on the
                                                            # original, continuous time series
        # orig_ds = fds.copy()

        # INTENSITY NORMALIZATION:
        zscore(fds, chunks_attr='chnks', param_est=('trgts', 'rest'))

        # removing extra scanned volumes from each run:
        # in each iteration, we keep two ranges of the list which come just before and after the extra scanned volumes,
        # thus, those extra volumes will be removed
        acc = 0
        for i in range(0, number_of_runs):
            nd = len(fds)
            acc = acc + ips_list[i]
            fds = fds[range(0, acc) + range(acc + sub[i], nd),]
        # removing the last trials (297th) from runs 006 and 011 (second and fifth run)
        # fds = fds[range(0,2*296) + range(2*296+1,5*296+1) , ]
        print fds.shape

        # conditions to keep:
        events = [ev for ev in original_events if ev['targets'] in conditions_to_classify]
        print len(events)
        for e in events[:4]:
            print e

        # find_events won't work for us because we have jitter and labeled events rather than samples
        # events = find_events(targets=fds.sa.targets, chunks=fds.sa.chunks)

        # simple average-sample approach is limited to block-designs with a clear
        # temporal separation of all signals of interest, whereas the HRF modeling is more suitable
        # for experiments with fast stimulation alternation.
        evds = fit_event_hrf_model(fds,
                                   events, # it is perfectly fine to have events that are not synchronized with the TR
                                   # the labeling of events is taken from the 'events' list. Any attribute(s) that are
                                   # also in the dicts will be assigned as condition labels in the output dataset
                                   time_attr='time_coords', # identify at which timepoints each BOLD volume was acquired
                                   # name of the event attribute with the condition labels. Can be a list of those (e.g.
                                   # ['targets', 'chunks']) combination of which would constitute a condition:
                                   condition_attr=('onset','targets','chunks'))
                                   #condition_attr=('targets', 'chunks')) #one estimate per condition (target) per run (chunk)
                                   # one estimate per condition per run is not much for classification purposes. My alternative
                                   # (one parameter estimate sample for each individual event - each target value for each chunk)
                                   # produces more estimates, but they are likely to be noisier, because I am basing the estimate
                                   # on a lot less variance in my model (it will be mostly zero, except for one event). This is
                                   # one example of the general trade off between number of training samples and noise reduction.
                                   # I don't think anyone can tell what is best, as the optimal selection will heavily depend on
                                   # the context and quality of data

        # This function behaves identical to ZScoreMapper.
        # The only difference is that the actual Z-scoring is done in-place
        # potentially causing a significant reduction of memory demands
        zscore(evds, chunks_attr=None) # THIS NORMALIZES EACH FEATURE (GLM PARAMETERS ESTIMATES FOR EACH VOXEL AT THIS POINT)

        clf = LinearCSVMC() #SVMs come with sensitivity analyzers!
        #clf = kNN(k=5, dfx=one_minus_correlation, voting='majority')

        fsel_1 = SensitivityBasedFeatureSelection(
            OneWayAnova(),
            FixedNElementTailSelector(100, mode='select', tail='upper') # 100 features with the highest F-scores
        )
        fsel_2 = SensitivityBasedFeatureSelection(
            OneWayAnova(),
            FractionTailSelector(0.05, mode='select', tail='upper') # the top 5% of F-scores
        )
        # the following approach uses the full dataset to determine which features show category differences in the whole dataset,
        # including our supposed-to-be independent testing data (precisely constitutes the double-dipping procedure):
        #fsel_1.train(evds)
        #evds_p = fsel_1(evds)
        # to implement an ANOVA-based feature selection properly we have to do it on the training dataset only:
        fclf_1 = FeatureSelectionClassifier(clf, fsel_1)
        fclf_2 = FeatureSelectionClassifier(clf, fsel_2)

        cv = CrossValidation(clf, NFoldPartitioner(cvtype=2), # we can use fclf instead of clf if we want to apply feature selection
                             enable_ca=['stats'])
        #double_dipping = cv(evds_p)
        cv_glm = cv(evds)

        #print '%.2f' % np.mean(cv_glm)
        print np.round(cv.ca.stats.stats['ACC%'], 1)
        print cv.ca.stats.matrix

        ####################From Timeseries To Spatio-temporal Samples:####################

        # remember, each feature is now voxel-at-time-point, so we get a chance of looking at the spatio-temporal profile of
        # classification-relevant information in the data

        ##########APPROACH1##########
        sensana = clf.get_sensitivity_analyzer(postproc=maxofabs_sample()) # post-processing step (I) combines the sensitivity maps for all partial
                                                                            # classifications (takes the per feature maximum of absolute sensitivities
                                                                            # in any of the maps)
        cv_sensana = RepeatedMeasure(sensana,
                                     ChainNode((NFoldPartitioner(),
                                               Splitter('partitions',
                                               attr_values=(1,)))))
        sens = cv_sensana(evds)
        print sens.shape # first element = number of sensitivity maps -> for example, if we have 5 runs and 8-way classification:
                         # with (I) -> a sensitivity map per each cross-validation split = 5 maps
                         # without (I) -> a sensitivity map per each partial binary classification per each cross-validation split = C(8,2)*5 maps
        #print cv_sensana.clf.ca.stats.matrix # we cannot do this here

        #ov = MapOverlap() # With this helper we can easily compute the fraction of features that have non-zero sensitivities in all dataset splits
        #overlap_fraction = ov(sens.samples > 0)

        ##########APPROACH2##########
        # by using the meta measure above to compute the sensitivity maps we have lost a convenient way to access the total performance
        # of the underlying classifier. To again gain access to it, and get the sensitivities at the same time:
        sclf = SplitClassifier(clf, enable_ca=['stats']) # can effectively perform a cross-validation analysis internally
        cv_sensana = sclf.get_sensitivity_analyzer() # no post-processing here -> obtaining sensitivity maps from all internally trained
                                                     # classifiers = C(8,2)*5 maps
        sens = cv_sensana(evds)
        print sens.shape
        print np.round(cv_sensana.clf.ca.stats.stats['ACC%'], 1)
        print cv_sensana.clf.ca.stats.matrix

        sens_comb = sens.get_mapped(maxofabs_sample()) # another way to combine the sensitivity maps -> into a single map
        #print ('imghdr' in fds.a)
        print ('imghdr' in evds.a)
        #nimg = map2nifti(fds, sens_comb)
        #nimg.to_filename('pattern.nii.gz')

        #it is not only possible to run spatial searchlights, but multiple spaces can be considered simultaneously -> Multi-dimensional Searchlights

    #searchlight analysis
    #fds = fmri_dataset(samples=all_runs_bold_fname)