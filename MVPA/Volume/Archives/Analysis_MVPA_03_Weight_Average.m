clc; clear; close all;

% Options for the SVM
opt.fs.do = 0; % feature selection
opt.rfe.do = 0; % recursive feature elimination
opt.permutation.test = 0;  % do permutation test
opt.session.curve = 0; % learning curves on a subsample of all the sessions

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

FoldersNames = {...
    1:4;...
    1:4;...
    1:4;...
    %     1:2;...
    1:4;...
    1:4;...
    1:4;...
    1:4;...
    1:4;...
    1:4;...
    %     1:2;...
    1:4;...
    1:4;...
    };


StartDirectory = pwd;

Analysis = struct('name', 'A Stim VS V Stim');
Analysis(end+1) = struct('name', 'A Stim VS AV Stim');
Analysis(end+1) = struct('name', 'V Stim VS AV Stim');
Analysis(end+1) = struct('name', 'A Att VS V Att');
Analysis(end+1) = struct('name', 'A Stim(A Att VS V Att)');
Analysis(end+1) = struct('name', 'V Stim(A Att VS V Att)');
Analysis(end+1) = struct('name', 'AV Stim(A Att VS V Att)');


ROIs = { ...
    'A_lh', 1:5; ...
    'V_lh', 10; ... %6:12
    'A_rh', 13:17; ...
    'V_rh', 18:24; ...
    };


SubROIs = {...
    'A1L'; ... 1
    'TE1.0L'; ...
    'TE1.1L'; ...
    'TE1.2L'; ...
    'PTL'; ...
    
    'V1L'; ... 6
    'V2L'; ...
    'V3dL'; ...
    'V3vL'; ...
    'V4dL'; ...
    'V4vL'; ...
    'V5L'; ...
    
    'A1R'; ... 13
    'TE1.0R'; ...
    'TE1.1R'; ...
    'TE1.2R'; ...
    'PTR'; ...
    
    'V1R'; ... 18
    'V2R'; ...
    'V3dR'; ...
    'V3vR'; ...
    'V4dR'; ...
    'V4vR'; ...
    'V5vR'};

Layers = [4 6 10];


for SubjInd = 4 %1:size(SubjectList,1)
    
    SubjID = SubjectList(SubjInd,:);
    
    fprintf('\n\nAnalysing subject %s\n', SubjID)
    
    SubjectFolder = fullfile(StartDirectory, 'Subjects_Data', ['Subject_' SubjID]);
    
    SaveDir = fullfile(SubjectFolder, 'Analysis', 'ROI');
    
    NbRuns = length(FoldersNames{SubjInd});
    
    
    for i=1:size(ROIs,1)
        cd(fullfile(SubjectFolder, 'Analysis', 'ROI', ROIs{i}, 'SVM'))
        delete *.tif
    end
    
    
    for iSVM=1:numel(Analysis)
        
        fprintf(' SVM: %s.\n', Analysis(iSVM).name)
        
        for iROI=2%:size(ROIs,1)
            
            for iSubROI = 1:length(ROIs{iROI,2})
                
                fprintf('  ROI: %s\n', SubROIs{ROIs{iROI,2}(iSubROI),1})
                
                % Crosslayer MVPA weight averaging
                for iLayer = 1:length(Layers)
                    if exist(fullfile(SaveDir, ROIs{iROI}, 'SVM', ...
                            [ROIs{iROI} ': ' Analysis(iSVM).name '_' SubROIs{ROIs{iROI,2}(iSubROI),1} ...
                            '_weight_Layer_' num2str(Layers(iLayer)) '_CV_1.nii']), 'file')
                        
                        HDR = spm_vol(fullfile(SaveDir, ROIs{iROI}, 'SVM', ...
                            [ROIs{iROI} ': ' Analysis(iSVM).name '_' SubROIs{ROIs{iROI,2}(iSubROI),1} ...
                            '_weight_Layer_' num2str(Layers(iLayer)) '_CV_1.nii']));
                        
                        HDR.fname = fullfile(SaveDir, ROIs{iROI}, 'SVM', ...
                            [ROIs{iROI} ': ' Analysis(iSVM).name '_' SubROIs{ROIs{iROI,2}(iSubROI),1} ...
                            '_weight_Layer_' num2str(Layers(iLayer)) '.nii']);
                        
                        for iCV = 1:NbRuns
                            
                            tmp = spm_read_vols(spm_vol(...
                                fullfile(SaveDir, ROIs{iROI}, 'SVM', ...
                                [ROIs{iROI} ': ' Analysis(iSVM).name '_' SubROIs{ROIs{iROI,2}(iSubROI),1} ...
                                '_weight_Layer_' num2str(Layers(iLayer)) '_CV_' num2str(iCV) '.nii'])));
                            
                            tmp(isnan(tmp)) = 0;
                            Weights(:,:,:,iCV) = tmp/sum(tmp(:));
                            clear tmp
                            
                        end
                        
                        spm_write_vol(HDR,nanmean(Weights,4));
                        
                    elseif exist(fullfile(SaveDir, ROIs{iROI}, 'SVM', ...
                            [ROIs{iROI} ': ' Analysis(iSVM).name '_' SubROIs{ROIs{iROI,2}(iSubROI),1} ...
                            '_weight_Layer_' num2str(Layers(iLayer)) '.nii']), 'file')
                    else
                        warning('Not CV weight data for: \n%s',...
                            ['Layer ' num2str(Layers(iLayer)) ' ROI ' ROIs{iROI} ' SVM ' Analysis(iSVM).name ...
                            ' SubROI ' SubROIs{ROIs{iROI,2}(iSubROI),1}])
                    end
                    
                    delete(fullfile(SaveDir, ROIs{iROI}, 'SVM', [ROIs{iROI} ': ' Analysis(iSVM).name '_' SubROIs{ROIs{iROI,2}(iSubROI),1} ...
                        '_weight_Layer_' num2str(Layers(iLayer)) '*.nii']))
                    
                end
                clear Weights
                
                
                
                % Retricted MVPA weight averaging
                if exist(fullfile(SaveDir, ROIs{iROI}, 'SVM', ...
                        [ROIs{iROI} ': ' Analysis(iSVM).name '_' SubROIs{ROIs{iROI,2}(iSubROI),1} ...
                        '_Restrict_weight_1.nii']), 'file')
                    
                    HDR = spm_vol(fullfile(SaveDir, ROIs{iROI}, 'SVM', ...
                        [ROIs{iROI} ': ' Analysis(iSVM).name '_' SubROIs{ROIs{iROI,2}(iSubROI),1} ...
                        '_Restrict_weight_1.nii']));
                    
                    HDR.fname = fullfile(SaveDir, ROIs{iROI}, 'SVM', ...
                        [ROIs{iROI} ': ' Analysis(iSVM).name '_' SubROIs{ROIs{iROI,2}(iSubROI),1} ...
                        '_Restrict_weight.nii']);
                    
                    for iCV = 1:NbRuns
                        
                        tmp = spm_read_vols(spm_vol(...
                            fullfile(SaveDir, ROIs{iROI}, 'SVM', ...
                            [ROIs{iROI} ': ' Analysis(iSVM).name '_' SubROIs{ROIs{iROI,2}(iSubROI),1} ...
                            '_Restrict_weight_' num2str(iCV) '.nii'])));
                        
                        tmp(isnan(tmp)) = 0;
                        Weights(:,:,:,iCV) = tmp/sum(tmp(:));
                        clear tmp
                        
                    end
                    
                    spm_write_vol(HDR,nanmean(Weights,4));
                    
                elseif exist(fullfile(SaveDir, ROIs{iROI}, 'SVM', ...
                        [ROIs{iROI} ': ' Analysis(iSVM).name '_' SubROIs{ROIs{iROI,2}(iSubROI),1} ...
                        '_Restrict_weight.nii']), 'file')
                else
                    warning('Not CV weight data for: \n%s',...
                        ['Restricted ROI ' ROIs{iROI} ' SVM ' Analysis(iSVM).name ...
                        ' SubROI ' SubROIs{ROIs{iROI,2}(iSubROI),1}])
                end
                clear Weights
                
                delete(fullfile(SaveDir, ROIs{iROI}, 'SVM', [ROIs{iROI} ': ' Analysis(iSVM).name '_' SubROIs{ROIs{iROI,2}(iSubROI),1} ...
                    '_Restrict_weight_*.nii']))
                
                
                
                % Normal MVPA weight averaging
                if exist(fullfile(SaveDir, ROIs{iROI}, 'SVM', ...
                        [ROIs{iROI} ': ' Analysis(iSVM).name '_' SubROIs{ROIs{iROI,2}(iSubROI),1} ...
                        '_weight_1.nii']), 'file')
                    
                    HDR = spm_vol(fullfile(SaveDir, ROIs{iROI}, 'SVM', ...
                        [ROIs{iROI} ': ' Analysis(iSVM).name '_' SubROIs{ROIs{iROI,2}(iSubROI),1} ...
                        '_weight_1.nii']));
                    
                    HDR.fname = fullfile(SaveDir, ROIs{iROI}, 'SVM', ...
                        [ROIs{iROI} ': ' Analysis(iSVM).name '_' SubROIs{ROIs{iROI,2}(iSubROI),1} ...
                        '_weight.nii']);
                    
                    for iCV = 1:NbRuns
                        
                        tmp = spm_read_vols(spm_vol(...
                            fullfile(SaveDir, ROIs{iROI}, 'SVM', ...
                            [ROIs{iROI} ': ' Analysis(iSVM).name '_' SubROIs{ROIs{iROI,2}(iSubROI),1} ...
                            '_weight_' num2str(iCV) '.nii'])));
                        
                        tmp(isnan(tmp)) = 0;
                        Weights(:,:,:,iCV) = tmp/sum(tmp(:));
                        clear tmp
                        
                    end
                    spm_write_vol(HDR,nanmean(Weights,4));
                elseif exist(fullfile(SaveDir, ROIs{iROI}, 'SVM', ...
                        [ROIs{iROI} ': ' Analysis(iSVM).name '_' SubROIs{ROIs{iROI,2}(iSubROI),1} ...
                        '_weight.nii']), 'file')
                else
                    warning('Not CV weight data for: \n%s',...
                        ['ROI ' ROIs{iROI} ' SVM ' Analysis(iSVM).name ...
                        ' SubROI ' SubROIs{ROIs{iROI,2}(iSubROI),1}])
                end
                clear Weights
                
                delete(fullfile(SaveDir, ROIs{iROI}, 'SVM', [ROIs{iROI} ': ' Analysis(iSVM).name '_' SubROIs{ROIs{iROI,2}(iSubROI),1} ...
                    '_weight_1.nii']))
                delete(fullfile(SaveDir, ROIs{iROI}, 'SVM', [ROIs{iROI} ': ' Analysis(iSVM).name '_' SubROIs{ROIs{iROI,2}(iSubROI),1} ...
                    '_weight_2.nii']))
                delete(fullfile(SaveDir, ROIs{iROI}, 'SVM', [ROIs{iROI} ': ' Analysis(iSVM).name '_' SubROIs{ROIs{iROI,2}(iSubROI),1} ...
                    '_weight_3.nii']))
                delete(fullfile(SaveDir, ROIs{iROI}, 'SVM', [ROIs{iROI} ': ' Analysis(iSVM).name '_' SubROIs{ROIs{iROI,2}(iSubROI),1} ...
                    '_weight_4.nii']))
                
            end
            
        end
        
    end
    
end

