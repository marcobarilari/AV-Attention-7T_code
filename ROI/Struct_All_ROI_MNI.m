%%
clear; clc


ROIs = {...
%     'rrwHG_STG_AAL.nii', 105; ...
    'rrwSTG_Post_AAL.nii', 104; ...
    'rrwTE_1.0_MNI.nii', 101 ; ...
    'rrwTE_1.1_MNI.nii', 102 ; ...
    'rrwTE_1.2_MNI.nii', 103 ; ...

    
    'rrwProbRet_V1v.nii', 110 ; ...
    'rrwProbRet_V1d.nii', 115 ; ...
    'rrwProbRet_V2v.nii', 120 ; ...
    'rrwProbRet_V2d.nii', 125 ; ...
    'rrwProbRet_V3v.nii', 130 ; ...
    'rrwProbRet_V3d.nii', 135 ; ...    
    'rrwProbRet_V4.nii', 140 ; ...
    'rrwProbRet_V_hMT.nii', 150 ; ...
    };

SubjectList = [...
    '02';...
    '03';...
    '04';...
%     '06';...
    '07';...
    '08';...
    '09';...
    '11';...
    '12';...
    '13';...
%     '14';...
    '15';...
    '16'
    ];
%  Root folder definition
StartDirectory = fullfile(pwd, '..', '..');

for SubjInd = 1:size(SubjectList,1)
    
    SubjID = SubjectList(SubjInd,:) %#ok<NOPTS>
    
    SubjectFolder = fullfile(StartDirectory, 'Subjects_Data', ['Subject_' SubjID]);
    
    AnalysisFolder = fullfile(SubjectFolder, 'Transfer', 'ROI');
    
    
    
    %% Creates one volume summing up all the  ROIs
    cd(AnalysisFolder);
    
    tmp = spm_vol(ROIs{1,1});
    HDR = struct(...
         'fname',   ['ALL_ROIs_Subject_' SubjID '.nii'], ... %         'fname',   ['ALL_TEs_Subject_' SubjID '.nii'], ...
        'dim',     tmp.dim,...
        'dt',      [spm_type('float32') spm_platform('bigend')],...
        'mat',     tmp.mat,...
        'pinfo',   [1 0 0]',...
        'descrip', 'All ROIs');
    
    VOL = zeros(tmp.dim);
    clear tmp
    
    for iROI = 1:size(ROIs,1)
        
        VolROI = logical(spm_read_vols(spm_vol(ROIs{iROI,1})));
        
        if any(VolROI(VolROI)==logical(VOL(VolROI)))
            tmp = VOL(VolROI);
            tmp = tmp(tmp~=0);
            warning('ROI overlap: %i voxels', length(tmp))
            
        end
        
        VOL(VolROI) = ROIs{iROI,2};
        
        clear tmp
        
    end
    
    spm_write_vol(HDR, VOL);
    
    cd (StartDirectory)
end