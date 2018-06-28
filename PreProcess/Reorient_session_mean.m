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

for SubjInd = 2:size(SubjectList,1)
    
    SubjID = SubjectList(SubjInd,:);
    
    SubjectFolder = fullfile(StartDirectory, 'Subjects_Data', ['Subject_' SubjID]);
    
    NiftiSourceFolder = fullfile(SubjectFolder, 'Nifti', 'NoMoCo');
    
    NbRuns = length(FoldersNames{SubjInd});
    
    AnalysisFolder = fullfile(StartDirectory, 'Subjects_Data', ['Subject_' SubjID] ...
        , 'Transfer');
    
    matlabbatch = {};
    Files2Reorient = {};
    
    for RunInd=1:NbRuns
        cd(fullfile(NiftiSourceFolder, sprintf('%2.2d', FoldersNames{SubjInd}(RunInd))))
        MeanFile = dir('mean_session*.nii');
        Files2Reorient{end+1,1} = fullfile(pwd, [MeanFile(1).name ',1']); %#ok<SAGROW>
    end
    
    cd(AnalysisFolder)
    ReorientFiles = dir('ReorientMatrix_*.mat');
    for iFile = 1:numel(ReorientFiles)
        load(fullfile(AnalysisFolder, ReorientFiles(iFile).name))
        matlabbatch{end+1}.spm.util.reorient.srcfiles = Files2Reorient;
        matlabbatch{end}.spm.util.reorient.transform.transM = M;
        matlabbatch{end}.spm.util.reorient.prefix = '';
    end
    
    CoregFiles = dir('CoregMatrix_*.mat');
    for iFile = 1:numel(CoregFiles)
        load(fullfile(AnalysisFolder, CoregFiles(iFile).name))
        matlabbatch{end+1}.spm.util.reorient.srcfiles = Files2Reorient;
        matlabbatch{end}.spm.util.reorient.transform.transM = M;
        matlabbatch{end}.spm.util.reorient.prefix = '';
    end
    
    save (strcat('Reorient_sesssion_mean_Subject_', SubjID, '_', datestr(now, DateFormat), '_jobs.mat'));
    
    spm_jobman('run', matlabbatch)
    
end