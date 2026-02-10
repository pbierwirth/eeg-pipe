function [ALLEEG, EEG, CURRENTSET] = transfer_remove_ICA(ic_set_name, badIC, ALLEEG, EEG)

% transfer_remove_ICA
%   Transfers ICA weights from a previously computed dataset, applies them to the current EEG
%   dataset, and removes components associated with specified artifact-related indices.
%
%   USAGE:
%       [ALLEEG, EEG, CURRENTSET] = transfer_remove_ICA(ic_set_name, badIC, ALLEEG, EEG)
%
%   INPUTS:
%       ic_set_name - Name of the dataset in ALLEEG that contains the ICA weights to be transferred.
%       badIC       - Indices of independent components (ICs) to remove from the data.
%       ALLEEG      - EEGLAB ALLEEG structure containing all datasets.
%       EEG         - Current EEG dataset structure where ICA weights are applied and ICs removed.
%
%   OUTPUTS:
%       ALLEEG      - Updated ALLEEG structure with the processed dataset added.
%       EEG         - Updated EEG dataset with ICA weights transferred and specified ICs removed.
%       CURRENTSET  - Index of the newly created dataset in the ALLEEG structure.
%
%   FUNCTION DETAILS:
%       1. Locates the dataset with the specified `ic_set_name` in ALLEEG.
%       2. Transfers ICA weights, ICA sphere, and channel indices (`icachansind`) from the specified
%          ICA dataset to the current EEG dataset.
%       3. Removes specified components (`badIC`) from the data using EEGLAB's `pop_subcomp`.
%       4. Stores the updated dataset in ALLEEG with the name 'ICA_rejection'.
%
%   NOTES:
%       - Ensure that `ic_set_name` matches the name of an existing dataset in ALLEEG that contains
%         valid ICA weights, sphere, and channel indices.
%       - The removed components (`badIC`) are assumed to correspond to artifact-related activity,
%         such as eye movements or muscle artifacts.
%       - This function appends the new dataset to ALLEEG but does not overwrite the original.
%
%   REQUIREMENTS:
%       - The ICA weights must have been previously computed and stored in the specified dataset.
%       - Ensure that ALLEEG, EEG, and CURRENTSET are initialized in the global workspace.


% Locate the specified ICA dataset in ALLEEG
ic_set = find(strcmp(ic_set_name, {ALLEEG.setname}), 1);
if isempty(ic_set)
    error('Dataset with name "%s" not found in ALLEEG.', ic_set_name);
end

% Transfer ICA weights, sphere, and channel indices
EEG = eeg_checkset(EEG);
EEG = pop_editset(EEG, 'run', [], ...
    'icaweights', ALLEEG(ic_set).icaweights, ...
    'icasphere', ALLEEG(ic_set).icasphere, ...
    'icachansind', ALLEEG(ic_set).icachansind);
%[ALLEEG, EEG] = eeg_store(ALLEEG, EEG);

% Remove artifact-related components (badIC)
if ~isempty(badIC)
    EEG = eeg_checkset(EEG);
    EEG.icaact = eeg_getica(EEG); % Compute ICA activations
    EEG = pop_subcomp(EEG, badIC, 0); % Remove specified components
else
    warning('No components specified for removal (badIC is empty).');
end

% Store the cleaned dataset in ALLEEG with a unique name
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, length(ALLEEG), ...
    'setname', ['ICA_rejection_' ic_set_name], 'gui', 'off');

% Perform a consistency check on the final dataset
EEG = eeg_checkset(EEG);
end
