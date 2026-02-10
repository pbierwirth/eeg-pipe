function [ALLEEG, EEG, CURRENTSET, badIC] = automatedICA(ALLEEG, EEG, percent)

%   Runs Independent Component Analysis (ICA) on an EEG dataset, identifies eye-related artifacts 
%   using ICLabel, and selects components for removal based on their probabilities of being 
%   eye artifacts and brain components.
%
%   USAGE:
%       [ALLEEG, EEG, CURRENTSET, badIC] = automatedICA(ALLEEG, EEG, percent)
%
%   INPUTS:
%       ALLEEG  - EEGLAB ALLEEG structure containing all datasets.
%       EEG     - Current EEG dataset structure.
%       percent - Threshold percentage (0–1) used for identifying components with high eye 
%                 artifact probability (> percent) and low brain probability (< percent).
%
%   OUTPUTS:
%       ALLEEG  - Updated ALLEEG structure with the new ICA-processed dataset added.
%       EEG     - EEG dataset after ICA decomposition.
%       CURRENTSET - Index of the newly created dataset in ALLEEG.
%       badIC   - Indices of independent components identified as eye-related artifacts.
%
%   FUNCTION DETAILS:
%       1. Runs ICA using EEGLAB's `pop_runica` function (extended ICA with the `runica` algorithm).
%       2. Saves the ICA-processed dataset to the ALLEEG structure with the name 'ICAweigths'.
%       3. Uses ICLabel to classify independent components based on their source probabilities.
%       4. Identifies bad components based on the following criteria:
%          - Components classified as > `percent` eye probability (ICLabel class 3: Eye) AND 
%            < `percent` brain probability (ICLabel class 1: Brain).
%          - If no components meet these thresholds, selects up to 3 components with the highest 
%            eye artifact probabilities that still have brain probabilities < `percent`.
%
%   NOTES:
%       - The `percent` parameter controls the sensitivity of the component selection. A typical 
%         value is `0.7` (70% threshold).
%       - This function relies on the ICLabel plugin to classify components.
%       - If no components meet the threshold, this function ensures at least the most likely 
%         eye artifact components are identified (up to 3).
%       - The function does not remove the identified components; you must remove them manually 
%         or use another function after calling this one.
%
%   REQUIREMENTS:
%       - EEGLAB and ICLabel plugin installed and properly configured.
%
%   EXAMPLE:
%       [ALLEEG, EEG, CURRENTSET, badIC] = automatedICA(ALLEEG, EEG, 0.7);
%       % Removes the identified bad ICs
%       EEG = pop_subcomp(EEG, badIC, 0);

EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'interrupt','on');


% IClabel will detect eye-erelated artifacts (> 70%)
Temp = iclabel(EEG, 'default');
badIC_Info = Temp.etc.ic_classification.ICLabel;
% Find Components that are probably (x%) Eye and not Brain
badIC = find(badIC_Info.classifications(:,3)>percent & badIC_Info.classifications(:,1)<percent);
% If no component has a prob of >x% the 3 components with the
% highest eye prob are chosen
if isempty(badIC)
    [~, possiblybad] = maxk(badIC_Info.classifications(:,3),3);
    badIC = possiblybad(badIC_Info.classifications(possiblybad,1) < percent);
end

% store ICA and IClabel info
EEG.etc.ICA.ICinfo = badIC_Info;
EEG.etc.ICA.badComponents = badIC; 

% stroe data in new set
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, length(ALLEEG),'setname',...
    'ICAweigths','gui','off');