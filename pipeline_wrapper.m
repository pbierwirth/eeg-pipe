function EEG = pipeline_wrapper(filename, filepath, chanlocs)

% pipeline_wrapper
%   A wrapper function for preprocessing EEG data in EEGLAB. The pipeline includes:
%   filtering, bad channel rejection, ASR, ICA, interpolation of bad channels, and
%   final cleanup. The results are stored in the EEG structure and the ALLEEG array.
%
%   USAGE:
%       EEG = pipeline_wrapper(ALLEEG, EEG, CURRENTSET)
%
%   INPUTS:
%       ALLEEG     - EEGLAB ALLEEG structure containing all datasets.
%       EEG        - Current EEG dataset structure for preprocessing.
%       CURRENTSET - Index of the active dataset in ALLEEG.
%
%   OUTPUTS:
%       EEG        - Preprocessed EEG structure with annotations and cleaned data.
%
%   FUNCTION DETAILS:
%       1. Filters the raw data (0.1 Hz high-pass and 50 Hz line noise removal).
%       2. Automatically detects and removes bad channels based on statistical thresholds.
%       3. Applies a strict high-pass filter (1 Hz) to prepare data for ASR and ICA.
%       4. Runs ASR (Artifact Subspace Reconstruction) to remove artifacts in the data.
%       5. Performs ICA and identifies bad ICs using ICLabel.
%       6. Transfers ICA weights to lightly filtered (0.1 Hz) data and removes bad ICs.
%       7. Interpolates bad channels and sorts electrodes to match a predefined template.
%       8. Deletes ICA results (e.g., weights and activations) to reduce file size.
%       9. Adds artifact-related metadata to the EEG structure for tracking preprocessing steps.
%
%   REQUIREMENTS:
%       - Ensure functions like `hp_notch_filter`, `bad_channels`, `ASR_before_ICA`,
%         `automatedICA`, `transfer_remove_ICA`, `spline_interpolation`, and `artifact_info` are
%         correctly implemented and available.
%       - The dataset labeled 'RawData' and 'remove_bad_channels' must exist in ALLEEG.
%       - The variable `chanlocs` must be defined or passed into the function for interpolation.
%
%   NOTES:
%       - This pipeline assumes the use of EEGLAB and specific preprocessing functions.
%       - The ICA results are removed to reduce file size, so ensure they are not required later.
%
%   EXAMPLE:
%       EEG = pipeline_wrapper(ALLEEG, EEG, CURRENTSET);

global ALLEEG EEG CURRENTSET; % Declare globals in the wrapper

%% load raw eeg data into EEGlab
% Clear existing variables and initalize eeglab
ALLEEG = []; EEG = []; CURRENTSET = 0; 
[ALLEEG, EEG, CURRENTSET] = eeglab('nogui');

% Load eeg data
EEG = pop_loadset(filename, filepath);
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','RawData','gui','off');

%% Filter data
% apply high-pass filter 0.1 Hz and remove 50 Hz line noise
[ALLEEG, EEG, CURRENTSET] = hp_notch_filter(ALLEEG, ...
    EEG, CURRENTSET, 0.1, 50);

%% Bad channel rection: Automatic removal of bad EEG channels
% get EEG channels
eeg_elecs = find(strcmp({EEG.chanlocs.type},'EEG'));
% detect and remove bad channels
[ALLEEG, EEG, CURRENTSET] = bad_channels(ALLEEG, EEG, 3.29);
% retrieve bad channels
badChans = EEG.etc.badChannelRemoval.bad_channels;

%% Apply strict high-pass filter [1 Hz] for ASR and ICA to unfiltered raw signal
% get raw data, remove bad channels and apply strict HP filter
% for ASR and subsequent ICA
select_set('RawData');

% remove previously found bad channels
EEG = pop_select( EEG, 'nochannel',badChans);
% Apply a strict HP filter
[ALLEEG, EEG, CURRENTSET] = hp_notch_filter(ALLEEG, EEG, CURRENTSET, 1);

%% Automatic artifact rejection via ASR
[ALLEEG, EEG, CURRENTSET] = ASR_before_ICA(ALLEEG, EEG, 1);

%% Run ICA on hp filtered data
[ALLEEG, EEG, CURRENTSET, badIC] = automatedICA(ALLEEG, EEG, 0.7);

%% Add ICA weights to "light filtered" (0.1 Hz) data
% get signal before strict high-pass filter
select_set('remove_bad_channels');
% Transfer weights, remove eye-related components and store in new set
[ALLEEG, EEG, CURRENTSET] = transfer_remove_ICA('ICAweigths', badIC, ALLEEG, EEG);

%% Interpolate artifact-laden channels
% interpolate bad electrodes and sort to standard chanloc template
[ALLEEG, EEG, CURRENTSET] = spline_interpolation(ALLEEG, EEG, chanlocs);


%% Delete ICA results to reduce file size
EEG.icaact=[]; EEG.icawinv=[]; EEG.icasphere=[]; EEG.icaweights=[];
EEG.icachansind=[];
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, length(ALLEEG),'setname',...
    'DeleteICA','gui','off');
EEG = eeg_checkset(EEG);

%% Add artifact info to EEG structure
EEG.etc.artifact_info  = artifact_info(ALLEEG, 'remove_bad_channels', ...
    'ArtifactDetection', ...
    'ICAweigths');
EEG = eeg_checkset(EEG);

end