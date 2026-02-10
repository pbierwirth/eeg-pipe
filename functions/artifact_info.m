function artifacts = artifact_info(ALLEEG, bad_channel_set, asr_set, ica_set)
% artifact_info
%   Collects artifact-related information from specified datasets in ALLEEG.
%
% USAGE:
%       artifacts = artifact_info(ALLEEG, bad_channel_set, asr_set, ica_set)
%
% INPUTS:
%       ALLEEG            - EEGLAB ALLEEG structure containing all datasets.
%       bad_channel_set   - Name of the dataset with bad channel information.
%       asr_set           - Name of the dataset with ASR artifact information.
%       ica_set           - Name of the dataset with ICA artifact information.
%
% OUTPUTS:
%       artifacts         - A structure containing the following fields (if available):
%                           * `channels`: Bad channel information from `bad_channel_set`.
%                           * `asr`: ASR artifact information from `asr_set`.
%                           * `ica`: ICA artifact information from `ica_set`.
%
% NOTES:
%       - If any of the specified datasets or fields are missing, the corresponding
%         artifact field in the output structure will be empty.

% Initialize artifacts structure
artifacts = struct('channels', [], 'asr', [], 'ica', []);

% Check and retrieve bad channel information
set_idx = find(strcmp({ALLEEG.setname}, bad_channel_set), 1);
if ~isempty(set_idx) && isfield(ALLEEG(set_idx).etc, 'badChannelRemoval')
    artifacts.channels = ALLEEG(set_idx).etc.badChannelRemoval;
else
    warning('Bad channel information not found in dataset "%s".', bad_channel_set);
end

% Check and retrieve ASR artifact information
set_idx = find(strcmp({ALLEEG.setname}, asr_set), 1);
if ~isempty(set_idx) && isfield(ALLEEG(set_idx).etc, 'artifacts')
    artifacts.asr = ALLEEG(set_idx).etc.artifacts;
else
    warning('ASR artifact information not found in dataset "%s".', asr_set);
end

% Check and retrieve ICA artifact information
set_idx = find(strcmp({ALLEEG.setname}, ica_set), 1);
if ~isempty(set_idx) && isfield(ALLEEG(set_idx).etc, 'ICA')
    artifacts.ica = ALLEEG(set_idx).etc.ICA;
else
    warning('ICA artifact information not found in dataset "%s".', ica_set);
end
end
