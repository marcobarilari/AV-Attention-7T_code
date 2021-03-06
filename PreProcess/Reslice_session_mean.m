% Reslice to .4mm the each session mean image

clear; clc;

% StartDirectory = fullfile(pwd, '..','..', '..');
StartDirectory = '/media/rxg243/BackUp2/AV_Integration_7T_2';

SubjectList = [...
    '02';...
    '03';...
    '04';...
    '06';...
    '07';...
    '08';...
    '09';...
    '11';...
    '12';...
    '13';...
    '14';...
    '15';...
    '16'
    ];

FoldersNames = {...
    1:4;...
    1:4;...
    1:4;...
    1:2;...
    1:4;...
    1:4;...
    1:4;...
    1:4;...
    1:4;...
    1:4;...
    1:2;...
    1:4;...
    1:4;...
    };

DateFormat = 'yyyy_mm_dd_HH_MM';

for SubjInd = 1:size(SubjectList,1)
    
    SubjID = SubjectList(SubjInd,:);
    
    SubjectFolder = fullfile(StartDirectory, 'Subjects_Data', ['Subject_' SubjID]);
    
    NiftiSourceFolder = fullfile(SubjectFolder, 'Nifti', 'NoMoCo');
    
    NbRuns = length(FoldersNames{SubjInd});
    
    AnalysisFolder = fullfile(StartDirectory, 'Subjects_Data', ['Subject_' SubjID] ...
        , 'Transfer');
    
    matlabbatch = {};
    Files2Reslice = {};
    
    % List the mean images from each run
    for RunInd=1:NbRuns
        cd(fullfile(NiftiSourceFolder, sprintf('%2.2d', FoldersNames{SubjInd}(RunInd))))
        MeanFile = dir('mean_session*.nii');
        Files2Reslice{end+1,1} = fullfile(pwd, [MeanFile(1).name ',1']); %#ok<SAGROW>
    end

    matlabbatch{1}.spm.spatial.coreg.write.ref = {fullfile(StartDirectory, 'Subjects_Data', ['Subject_' SubjID], 'Structural', ...
        'CBS', ['T1_' SubjID '_thresh_clone_transform_strip_clone_transform_bound.nii'])};
    matlabbatch{1}.spm.spatial.coreg.write.source = Files2Reslice;
    matlabbatch{1}.spm.spatial.coreg.write.roptions.interp = 4;
    matlabbatch{1}.spm.spatial.coreg.write.roptions.wrap = [0 0 0];
    matlabbatch{1}.spm.spatial.coreg.write.roptions.mask = 0;
    matlabbatch{1}.spm.spatial.coreg.write.roptions.prefix = 'r';
    
    cd(AnalysisFolder)
    save (strcat('Reslice_sesssion_mean_Subject_', SubjID, '_jobs.mat'));

    spm_jobman('run', matlabbatch)


end