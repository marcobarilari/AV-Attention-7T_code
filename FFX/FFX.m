function Analysis_FFX()

clear 
clc

% Time Slicing Parameters
TR = 3;
HPF = 128;
ReferenceSlice = 1;

PrefixImages2Select = 'swURS*.nii';

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

Conditions_Names = {...
    'A Stim - Auditory Attention', ...
    'V Stim - Auditory Attention', ...
    'AV Stim - Auditory Attention', ...
    'A Stim - Visual Attention', ...
    'V Stim - Visual Attention', ...
    'AV Stim - Visual Attention', ...
    'A Targets - Auditory Attention', ...
    'A Targets - Visual Attention', ...
    'V Targets - Auditory Attention', ...
    'V Targets - Visual Attention', ...
    'Responses - Auditory Attention', ...
    'Responses - Visual Attention',...
    };

NbSlices = 48;

IndStart = 5; % first row of data points in txt file

%  Folders definitions
% StartFolder = fullfile(pwd, '..', '..');
% StartFolder = '/media/rxg243/BackUp2/AV_Integration_7T_2';

StartFolder = '/media/remi/BackUp2/AV_Integration_7T_2';
CodeFolder = '/home/remi/github/AV-Attention-7T_code';
addpath(fullfile(CodeFolder, 'SubFun'))

%% Define folders, number of runs, scans per run...
for SubjInd = 2:size(SubjectList,1)
    
    tic
    
    % Subject's Identity
    SubjID = SubjectList(SubjInd,:);
    
    fprintf('\nRunning subject %s.\n\n', SubjID)
    
    SubjectFolder = fullfile(StartFolder, 'Subjects_Data', ['Subject_' SubjID]);
    
    NiftiSourceFolder = fullfile(SubjectFolder, 'Nifti', 'NoMoCo');
    
    BehavioralFolder = fullfile(SubjectFolder, 'Behavioral', 'Runs');
    
    AnalysisFolder = fullfile(SubjectFolder, 'FFX');
    mkdir(AnalysisFolder)
    
    NbRuns = length(FoldersNames{SubjInd});
    
    NbVol = nan(1,NbRuns);
    
    %% Collects the SOTs
    SOT_Blocks = cell(3,2,size(NbRuns,1));
    SOT_Targets = cell(2,2,size(NbRuns,1));
    SOT_Responses = cell(1,size(NbRuns,1));
    
    All_SOTs = cell(length(Conditions_Names),NbRuns);
    
    All_Durations = All_SOTs;
    
    fprintf('\nCollects the SOTs.\n\n')
    
    for RunInd = 1:NbRuns
        
        Block_Start = cell(3,2);
        
        Block_Duration = cell(3,2);
        
        Target_Index = cell(2,2);
        
        Response_Index = cell(1,2);
        
        
        %% Identify the relevant file and opens it
        tmp = [];
        EOF = [] ;
        fid = [];
        IndexStartExperiment =[];
        FileContent = {};
        TEMP = [];
        
        LogFileList = dir(fullfile(BehavioralFolder, strcat(...
            'Logfile_Subject_',  num2str(str2double(SubjID)), ...
            '_Run_', num2str(FoldersNames{SubjInd}(RunInd)), '*.txt')));
        disp(LogFileList.name)
        fid = fopen(fullfile (BehavioralFolder, LogFileList.name));
        FileContent = ...
            textscan(fid,'%s %s %s %s %s %s %s %s %s %s %s %s', ...
            'delimiter', '\t', 'headerlines', IndStart, 'returnOnError',0);
        fclose(fid);
        
        
        % Finds the end of the file
        EOF = find(strcmp('Final_Fixation', FileContent{1,3}));
        if isempty(EOF)
            EOF = find(strcmp('Quit', FileContent{1,1}));
        end
        
        % Identify the time of the start of the XP
        IndexStartExperiment = find(strcmp('Pulse', FileContent{1,2}));
        IndexStartExperiment = sort(IndexStartExperiment);
        IndexStartExperiment = IndexStartExperiment(1);
        
        StartTime = str2double(FileContent{1,4}(IndexStartExperiment));
        
        % Counts the number of volumes and removed triggers from list
        TEMP = find(strcmp('30', FileContent{1,3}));
        NbVol(RunInd) = length(TEMP);
        
        Stim_Time = {FileContent{1,3}(IndexStartExperiment:EOF)  ...
            char(FileContent{1,4}(IndexStartExperiment:EOF))};
        
        TEMP = [ ...
            find(strcmp('SOA_Fix', Stim_Time{1,1})) ;...
            find(strcmp('SOA_Var', Stim_Time{1,1})) ;...
            find(strcmp('30', Stim_Time{1,1})) ;...
            find(strcmp('Fixation_Onset_Fix', Stim_Time{1,1})) ;...
            find(strcmp('Long_Fixation', Stim_Time{1,1}))];
        
        Stim_Time{1,1}(TEMP,:) = [];
        Stim_Time{1,2}(TEMP,:) = [];
        
        
        for i=1:size(Stim_Time{1,2},1)
            tmp(i,1)=str2double(Stim_Time{1,2}(i,:));
        end
        
        Stim_Time{1,2} = (tmp-StartTime)/10000;
        
        
        %% Identify targets and responses
        CurrentCondition = [];
        InBlock = 0;
        BlockType = [];
        BlockEnd = [];  %#ok<*NASGU>
        
        StimCount = 0;
        
        for i = 1:size(Stim_Time{1,2},1)
            
            if strcmp(Stim_Time{1,1}(i,:), 'Attend2Audio_Fixation')
                
                InBlock = 0;
                BlockEnd = [];
                BlockType = [];
                CurrentCondition = 1;
                
            elseif strcmp(Stim_Time{1,1}(i,:), 'Attend2Visual_Fixation')
                
                InBlock = 0;
                BlockEnd = [];
                BlockType = [];
                CurrentCondition = 2;
                
                
            elseif strcmp(Stim_Time{1,1}(i,:), 'AudioOnly_Trial')
                if InBlock == 0
                    InBlock = 1;
                    BlockType = 1;
                    Block_Start{BlockType,CurrentCondition}(end+1) = Stim_Time{1,2}(i);
                    StimCount = StimCount + 1;
                else
                    StimCount = StimCount + 1;
                end
                
            elseif strcmp(Stim_Time{1,1}(i,:), 'VisualOnly_Trial')
                if InBlock == 0
                    InBlock = 1;
                    BlockType = 2;
                    Block_Start{BlockType,CurrentCondition}(end+1) = Stim_Time{1,2}(i);
                    StimCount = StimCount + 1;
                else
                    StimCount = StimCount + 1;
                end
                
            elseif strcmp(Stim_Time{1,1}(i,:), 'AudioVisual_Trial')
                if InBlock == 0
                    InBlock = 1;
                    BlockType = 3;
                    Block_Start{BlockType,CurrentCondition}(end+1) = Stim_Time{1,2}(i);
                    StimCount = StimCount + 1;
                else
                    StimCount = StimCount + 1;
                end
                
                
            elseif strcmp(Stim_Time{1,1}(i,:), 'Auditory_Target')
                Target_Index{1,CurrentCondition}(end+1)=Stim_Time{1,2}(i);
                
            elseif strcmp(Stim_Time{1,1}(i,:), 'Visual_Target')
                Target_Index{2,CurrentCondition}(end+1)=Stim_Time{1,2}(i);
                
            elseif strcmp(Stim_Time{1,1}(i,:), '1') && ~isempty(CurrentCondition)
                Response_Index{1,CurrentCondition}(end+1)=Stim_Time{1,2}(i);
                
                
            elseif strcmp(Stim_Time{1,1}(i,:), 'Stimulus_Offset')
                if StimCount == 50
                    BlockEnd = Stim_Time{1,2}(i);
                    Block_Duration{BlockType,CurrentCondition}(end+1) = ...
                        BlockEnd-Block_Start{BlockType,CurrentCondition}(end);
                    StimCount = 0;
                end
            end
            
        end
        
        %         Block_Start
        %         Block_Duration
        %
        %         Target_Index
        %         Response_Index
        
        %             'A Stim - Auditory Attention', ...
        %             'V Stim - Auditory Attention', ...
        %             'AV Stim - Auditory Attention', ...
        %             'A Stim - Visual Attention', ...
        %             'V Stim - Visual Attention', ...
        %             'AV Stim - Visual Attention', ...
        
        %             'A Targets - Auditory Attention', ...
        %             'A Targets - Visual Attention', ...
        %             'V Targets - Auditory Attention', ...
        %             'V Targets - Visual Attention', ...
        %             'Responses - Auditory Attention', ...
        %             'Responses - Visual Attention'
        
        All_SOTs{1,RunInd} = Block_Start{1,1};
        All_SOTs{2,RunInd} = Block_Start{2,1};
        All_SOTs{3,RunInd} = Block_Start{3,1};
        All_SOTs{4,RunInd} = Block_Start{1,2};
        All_SOTs{5,RunInd} = Block_Start{2,2};
        All_SOTs{6,RunInd} = Block_Start{3,2};
        
        All_SOTs{7,RunInd} = Target_Index{1,1};
        All_SOTs{8,RunInd} = Target_Index{1,2};
        All_SOTs{9,RunInd} = Target_Index{2,1};
        All_SOTs{10,RunInd} = Target_Index{2,2};
        
        All_SOTs{11,RunInd} = Response_Index{1,1};
        All_SOTs{12,RunInd} = Response_Index{1,2};
        
        All_Durations{1,RunInd} = Block_Duration{1,1};
        All_Durations{2,RunInd} = Block_Duration{2,1};
        All_Durations{3,RunInd} = Block_Duration{3,1};
        All_Durations{4,RunInd} = Block_Duration{1,2};
        All_Durations{5,RunInd} = Block_Duration{2,2};
        All_Durations{6,RunInd} = Block_Duration{3,2};
        
        All_Durations{7,RunInd} = zeros(size(Target_Index{1,1}));
        All_Durations{8,RunInd} = zeros(size(Target_Index{1,2}));
        All_Durations{9,RunInd} = zeros(size(Target_Index{2,1}));
        All_Durations{10,RunInd} = zeros(size(Target_Index{2,2}));
        
        All_Durations{11,RunInd} = zeros(size(Response_Index{1,1}));
        All_Durations{12,RunInd} = zeros(size(Response_Index{1,2}));
        
        
    end

    SaveSOT(AnalysisFolder, All_SOTs, All_Durations)
    
    fprintf('\nSOTs collected.\n\n')
    
    %% Specify the batch   
    fprintf('\nSpecifying the job\n\n')
    
    matlabbatch ={};
    
    matlabbatch{1,1}.spm.stats.fmri_spec.dir{1,1} = AnalysisFolder;
    
    matlabbatch{1,1}.spm.stats.fmri_spec.timing.units = 'secs';
    matlabbatch{1,1}.spm.stats.fmri_spec.timing.RT = TR;
    matlabbatch{1,1}.spm.stats.fmri_spec.timing.fmri_t = NbSlices;
    matlabbatch{1,1}.spm.stats.fmri_spec.timing.fmri_t0 = ReferenceSlice;
    
    matlabbatch{1,1}.spm.stats.fmri_spec.fact = struct('name',{},'levels',{});
    
    matlabbatch{1,1}.spm.stats.fmri_spec.bases.hrf.derivs = [1,0]; % First is time derivative, Second is dispersion
    
    matlabbatch{1,1}.spm.stats.fmri_spec.volt = 1;
    
    matlabbatch{1,1}.spm.stats.fmri_spec.global = 'None';
    
    matlabbatch{1,1}.spm.stats.fmri_spec.mask = {''};
    
    matlabbatch{1,1}.spm.stats.fmri_spec.mthresh = 0.5;
    
    matlabbatch{1,1}.spm.stats.fmri_spec.cvi = 'AR(1)';
    
    
    for RunInd = 1:NbRuns
        
        RunFolder =  ...
            fullfile(NiftiSourceFolder, sprintf('%2.2d', FoldersNames{SubjInd}(RunInd)));
        
        IMAGES_ls = {}; 
        Mov_Parameter_ls = {}; 
        
        matlabbatch{1,1}.spm.stats.fmri_spec.sess(1,RunInd).multi{1} = '';
        matlabbatch{1,1}.spm.stats.fmri_spec.sess(1,RunInd).regress = struct('name',{},'val',{});
        matlabbatch{1,1}.spm.stats.fmri_spec.sess(1,RunInd).hpf = HPF;
                
        % Lists the images
        IMAGES_ls = dir(fullfile(RunFolder, PrefixImages2Select));
        IMAGES_ls = spm_vol(fullfile(RunFolder, IMAGES_ls.name));
        
        % Names them with their absolute pathnames
        TEMP = {};
        for j = 1:NbVol(RunInd)
            TEMP{end+1} = [IMAGES_ls(j).fname ,',', num2str(j)];
        end
        matlabbatch{1,1}.spm.stats.fmri_spec.sess(1,RunInd).scans = TEMP';
        
        % Lists the realignement parameters file
        Mov_Parameter_ls = dir(fullfile(RunFolder, 'rp_*.txt'));
        R = load(fullfile(RunFolder, Mov_Parameter_ls.name));
        R = R(1:NbVol(RunInd),:);
        SaveRP(RunFolder, R)
        
        % Names them with its absolute pathname
        matlabbatch{1,1}.spm.stats.fmri_spec.sess(1,RunInd).multi_reg{1} = ...
        fullfile(RunFolder, 'rp.mat');
        
        ConditionNumber = 1;
        for j = 1:length(Conditions_Names)-2
            if ~isempty(All_SOTs{j,RunInd})
                
                matlabbatch{1,1}.spm.stats.fmri_spec.sess(1,RunInd).cond(1,ConditionNumber).name = Conditions_Names{j};
                matlabbatch{1,1}.spm.stats.fmri_spec.sess(1,RunInd).cond(1,ConditionNumber).duration = All_Durations{j,RunInd};
                matlabbatch{1,1}.spm.stats.fmri_spec.sess(1,RunInd).cond(1,ConditionNumber).tmod = 0;
                matlabbatch{1,1}.spm.stats.fmri_spec.sess(1,RunInd).cond(1,ConditionNumber).pmod=struct('name',{},'param',{}, 'poly', {});
                matlabbatch{1,1}.spm.stats.fmri_spec.sess(1,RunInd).cond(1,ConditionNumber).onset = All_SOTs{j,RunInd};
                
                ConditionNumber=ConditionNumber+1;
                
            end
        end
    end
    
    
    %% fMRI estimation
    fprintf('\nSpecifying and estimating model\n\n')
    matlabbatch{1,end+1}={};
    matlabbatch{1,end}.spm.stats.fmri_est.spmmat{1,1} = ...
        fullfile(AnalysisFolder, 'SPM.mat');     %set the spm file to be estimated
    matlabbatch{1,end}.spm.stats.fmri_est.method.Classical = 1;
    
    delete(fullfile(AnalysisFolder, 'SPM.mat'))
    SaveBatch(AnalysisFolder, SubjID, matlabbatch)
    
    spm_jobman('run', matlabbatch)
    fprintf('\nThe analysis of the subject %s is done.\n\n', SubjID);
    
    toc
    
    
end


end

function SaveSOT(AnalysisFolder, All_SOTs, All_Durations)  %#ok<INUSD>
save (fullfile(AnalysisFolder, 'All_SOTs.mat'), 'All_SOTs', 'All_Durations')
end

function SaveRP(RunFolder, R) %#ok<INUSD>
save(fullfile(RunFolder, 'rp.mat'), 'R')
end

function SaveBatch(AnalysisFolder, SubjID, matlabbatch) %#ok<INUSD>
save (fullfile(AnalysisFolder, strcat('FFX_Subject_', SubjID, '_jobs')), 'matlabbatch');
end


