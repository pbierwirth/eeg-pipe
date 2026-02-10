function [ALLEEG, EEG, CURRENTSET] = ASR_before_ICA(ALLEEG, EEG, remove_frontal)

% ASR_before_ICA
%   Applies Artifact Subspace Reconstruction (ASR) to clean EEG data by detecting and removing
%   high-artifact time segments prior to Independent Component Analysis (ICA). This function also
%   provides the option to temporarily exclude frontal electrodes during artifact detection,
%   reducing the likelihood of ASR marking blink-related intervals as artifacts.
%
%   USAGE:
%       [ALLEEG, EEG, CURRENTSET] = ASR_before_ICA(ALLEEG, EEG, remove_frontal)
%
%   INPUTS:
%       ALLEEG          - EEGLAB ALLEEG structure containing all datasets.
%       EEG             - Current EEG dataset structure.
%       remove_frontal  - Boolean (1 or 0):
%                         * If 1: Temporarily removes frontal channels (X > 0.8 in chanlocs)
%                                 during ASR artifact detection.
%                         * If 0: Uses the entire dataset for ASR artifact detection.
%
%   OUTPUTS:
%       ALLEEG          - Updated ALLEEG structure with the cleaned dataset added.
%       EEG             - Cleaned EEG dataset with only the artifact-free time segments.
%       CURRENTSET      - Index of the newly created dataset in the ALLEEG structure.
%
%   FUNCTION DETAILS:
%       1. If `remove_frontal` is enabled:
%          - Identifies and temporarily removes frontal electrodes (X > 0.8) to prevent blink
%            artifacts from being treated as global artifacts by ASR.
%          - ASR is applied to the reduced dataset to identify bad time segments.
%          - The clean sample mask is extracted and used to select artifact-free time ranges.
%       2. If `remove_frontal` is disabled:
%          - ASR is applied directly to the full dataset to detect bad time segments.
%          - The clean sample mask is extracted and used to select artifact-free time ranges.
%       3. The artifact-free time segments are retained in the original EEG dataset.
%       4. The cleaned dataset is added to the ALLEEG structure with the name 'ArtifactDetection'.
%
%   PARAMETERS USED IN ASR (via pop_clean_rawdata):
%       - FlatlineCriterion: 'off' (flatline channels are ignored)
%       - ChannelCriterion: 'off' (bad channels are not rejected)
%       - LineNoiseCriterion: 'off' (line noise is not evaluated)
%       - Highpass: 'off' (high-pass filtering is not applied)
%       - BurstCriterion: 50 (default ASR burst rejection threshold in standard deviations)
%       - WindowCriterion: 'off' (windowed artifact detection is not used)
%       - BurstRejection: 'on' (removes bad data bursts)
%       - Distance: 'Euclidian' (default distance metric for ASR)
%
%   NOTES:
%       - Frontal channel coordinates are identified via chanlocs.X. Ensure your dataset includes
%         properly scaled channel location coordinates before using `remove_frontal`.
%       - The final cleaned dataset retains all original channels, including frontal electrodes,
%         but only artifact-free time segments are preserved.
%       - This function should be used before running ICA to improve decomposition quality by
%         reducing the impact of high-artifact time segments.

% get all non EEG channels
non_eeg_elecs = find(~strcmp({EEG.chanlocs.type},'EEG'));

if remove_frontal == 1
    % temporarily remove frontal electrodes (X coordinate > 0.8) that
    % might contain strong blinkartifacts. This is primarily done to
    % prevent ASR from marking blink intervals as artifacts

    % get frontal electrodes
    frontal_electrodes = {EEG.chanlocs([EEG.chanlocs.X] > 0.8).labels};
    front_idx=find(ismember({EEG.chanlocs.labels}, frontal_electrodes));

    remove_idx = [front_idx non_eeg_elecs];

else
    remove_idx = [non_eeg_elecs];
end

% remporarily remove frontal electrodes and detect artifacts via ASR
EEGtmp = pop_select( EEG, 'nochannel',remove_idx);
EEGtmp = pop_clean_rawdata(EEGtmp, 'FlatlineCriterion','off','ChannelCriterion','off',...
    'LineNoiseCriterion','off','Highpass','off','BurstCriterion',50,'WindowCriterion',...
    'off','BurstRejection','on','Distance','Euclidian');
Clean_Segment_Mask = EEGtmp.etc.clean_sample_mask';


% Reshape artifact indices for the pop_select function
clean_data = reshape(find(diff([false Clean_Segment_Mask' false])),2,[])';
clean_data(:,2) = clean_data(:,2)-1;

% keep only clean range
EEG = pop_select(EEG, 'point', clean_data);

% store artifact infos
EEG.etc.artifacts.clean_pnts = Clean_Segment_Mask;

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, length(ALLEEG),'setname',...
    'ArtifactDetection','gui','off');

EEG = eeg_checkset( EEG );