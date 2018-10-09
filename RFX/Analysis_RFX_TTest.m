clc
clear


StartDirectory = pwd;

[~,~,~] = mkdir('RFX');

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


for SubjInd = 1:size(SubjectList,1)
    Struct{SubjInd,1} = fullfile(pwd, 'Subjects_Data', ['Subject_' SubjectList(SubjInd,:)], ...
        'FFX', 'Structural', 'wmUNI.nii');
end

temp = spm_vol(char(Struct))

vol = mean(spm_read_vols(temp),4);

hdr = temp(1);

hdr.fname = fullfile(StartDirectory, 'RFX', 'AvgStruct.nii');

spm_write_vol(hdr, vol);

%%
spm_jobman('initcfg')
spm_get_defaults;
global defaults %#ok<NUSED>

ContrastsNames = {
    'A Stim - A Att > A Stim - V Att';...
    'A Stim - V Att > A Stim - A Att';...
    'V Stim - A Att > V Stim - V Att';...
    'V Stim - V Att > V Stim - A Att';...
    'AV Stim - A Att > AV Stim - V Att';...
    'AV Stim - V Att > AV Stim - A Att';...
    '(AV > A + V) - A Att';...
    '(AV < A + V) - A Att';...
    '(AV > A + V) - V Att';...
    '(AV < A + V) - V Att';...
    };

matlabbatch = {};

for iTest = 1:size(ContrastsNames,1)
    
    mkdir(fullfile(StartDirectory, 'RFX', ContrastsNames{iTest}));
    delete(fullfile(StartDirectory, 'RFX', ContrastsNames{iTest}, 'SPM.mat'));
    
    % Design
    matlabbatch{end+1}.spm.stats.factorial_design.dir = {fullfile(StartDirectory, 'RFX', ContrastsNames{iTest})};
    
    matlabbatch{end}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
    matlabbatch{end}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
    matlabbatch{end}.spm.stats.factorial_design.masking.tm.tm_none = 1;
    matlabbatch{end}.spm.stats.factorial_design.masking.im = 1;
    matlabbatch{end}.spm.stats.factorial_design.masking.em = {''};
    matlabbatch{end}.spm.stats.factorial_design.globalc.g_omit = 1;
    matlabbatch{end}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
    matlabbatch{end}.spm.stats.factorial_design.globalm.glonorm = 1;
    
    for SubjInd = 1:size(SubjectList,1)
        matlabbatch{end}.spm.stats.factorial_design.des.t1.scans{SubjInd,1} = fullfile(pwd, 'Subjects_Data', ['Subject_' SubjectList(SubjInd,:)], ...
            'FFX', sprintf('con_%4.4i.nii', iTest));
    end
    
    % Estimate
    matlabbatch{end+1}={};
    matlabbatch{end}.spm.stats.fmri_est.spmmat{1} = fullfile(StartDirectory, ...
        'RFX', ContrastsNames{iTest}, 'SPM.mat');
    matlabbatch{end}.spm.stats.fmri_est.method.Classical = 1;
    
    % Contrast
    matlabbatch{end+1}.spm.stats.con.spmmat{1} = fullfile(StartDirectory, ...
        'RFX', ContrastsNames{iTest}, 'SPM.mat');
    matlabbatch{end}.spm.stats.con.consess{1}.tcon.name = ContrastsNames{iTest};
    matlabbatch{end}.spm.stats.con.consess{1}.tcon.weights = 1;
    matlabbatch{end}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
    matlabbatch{end}.spm.stats.con.delete = 1;
    
end

cd(StartDirectory)
save 'RFX.mat'

spm_jobman('run', matlabbatch)