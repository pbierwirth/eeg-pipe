function [ALLEEG, EEG, CURRENTSET] = spline_interpolation(ALLEEG, EEG,  chanlocs_template)
% spline_interpolation
%   Performs spherical spline interpolation on bad channels identified in a previous step, sorts
%   the electrodes based on a provided channel locations template, and adds the interpolated 
%   dataset to the ALLEEG structure. The function assumes that the bad channels are stored in 
%   the `EEG.etc.badChannelRemoval.badChans` field.
%
%   USAGE:
%       [ALLEEG, EEG, CURRENTSET] = spline_interpolation(ALLEEG, EEG, chanlocs_template)
%
%   INPUTS:
%       ALLEEG           - EEGLAB ALLEEG structure containing all datasets.
%       EEG              - Current EEG dataset structure where interpolation will be applied.
%       chanlocs_template - Channel locations template (struct array) used to sort electrodes.
%
%   OUTPUTS:
%       ALLEEG      - Updated ALLEEG structure with the interpolated dataset added.
%       EEG         - Updated EEG dataset with bad channels interpolated and electrodes sorted.
%       CURRENTSET  - Index of the newly created dataset in the ALLEEG structure.
%
%   FUNCTION DETAILS:
%       1. Selects the dataset labeled 'remove_bad_channels' using the `select_set` function.
%       2. Checks if the field `EEG.etc.badChannelRemoval.badChans` exists:
%          - If present: Performs spherical spline interpolation on the bad channels.
%          - If absent: No action is taken.
%       3. Reorders the electrodes in the dataset to match the `chanlocs_template`.
%       4. Adds the updated dataset to the ALLEEG structure with the name 'Interpolation'.
%
%   NOTES:
%       - The function assumes that the `select_set` function is defined and can activate the
%         'remove_bad_channels' dataset from ALLEEG.
%       - Ensure that `EEG.etc.badChannelRemoval.badChans` contains the indices of the bad channels.
%       - The function checks if the length of the `chanlocs_template` matches the number of
%         channels in `EEG.chanlocs`. If not, it throws an error.
%       - Spherical spline interpolation is used as the default method for interpolation.
%
%   REQUIREMENTS:
%       - The dataset labeled 'remove_bad_channels' must exist in ALLEEG.
%       - The bad channels must be marked in `EEG.etc.badChannelRemoval.badChans`.
%       - The `chanlocs_template` must correspond to the correct channel layout and have the same
%         number of channels as the EEG dataset.
%
%   EXAMPLE:
%       [ALLEEG, EEG, CURRENTSET] = spline_interpolation(ALLEEG, EEG, chanlocs_template);

select_set('remove_bad_channels')

set = find(strcmp({ALLEEG.setname},'remove_bad_channels'));

if isfield(EEG.etc.badChannelRemoval, "badChans")

    EEG = pop_interp(EEG, ALLEEG(set-1). ...
        chanlocs(EEG.etc.badChannelRemoval.badChans),...
        'spherical');

    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, length(ALLEEG),'setname',...
        'Interpolation','gui','off');

    % sort electrodes
    if length(chanlocs_template) == length(EEG.chanlocs) & ...
            sum(ismember({chanlocs_template.labels}, {EEG.chanlocs.labels}))==length(chanlocs_template)

        [~, elec_idx] = ismember({chanlocs_template.labels}, {EEG.chanlocs.labels});
        EEG.data = EEG.data(elec_idx, :);
        EEG.chanlocs = chanlocs_template;

    else
        error('Provided chanlocs template differs from EEG template.')
    end

else
end


