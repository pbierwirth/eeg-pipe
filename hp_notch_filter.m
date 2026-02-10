function [ALLEEG, EEG, CURRENTSET] = hp_notch_filter(ALLEEG, EEG, CURRENTSET, HP, notch)
% hp_notch_filter
%   Applies an optional high-pass filter and an optional notch (line) filter.
%   USAGE:
%       [ALLEEG, EEG, CURRENTSET] = hp_notch_filter(ALLEEG, EEG, CURRENTSET, HP, notch)
%
%   INPUT:
%       ALLEEG, EEG, CURRENTSET - EEGLAB variables
%       HP      - If numeric and > 0, apply a high-pass filter at 'HP' Hz
%                 If empty or 0, skip high-pass.
%       notch   - If numeric (e.g., 50 or 60), remove that line noise frequency
%                 If empty or 0, skip notch.
%
%   OUTPUT:
%       [ALLEEG, EEG, CURRENTSET] - Updated dataset after filtering

% Check the input
if nargin < 5, notch = []; end
if nargin < 4, HP = []; end

EEG = eeg_checkset(EEG);

% Apply high-pass filter only if 'HP' was selected
if ~isempty(HP) && HP > 0
    fprintf('Applying high-pass filter at %g Hz...\n', HP);
    EEG = pop_eegfiltnew(EEG, 'locutoff', HP);
    EEG = eeg_checkset(EEG);
else
    fprintf('Skipping high-pass filter...\n');
end

% Apply notch CleanLine only if 'notch' was selected
if ~isempty(notch) && notch > 0
    fprintf('Applying notch filter at %g Hz...\n', notch);
    % Adjust lineFrequencies if you want to remove harmonics
    EEG = pop_cleanline(EEG, 'LineFrequencies', notch);
    EEG = eeg_checkset(EEG);
else
    fprintf('Skipping notch filter...\n');
end

% What filters were applied
filterName = '';
if ~isempty(HP) && HP > 0
    filterName = [filterName sprintf('HP_%g_', HP)];
end
if ~isempty(notch) && notch > 0
    filterName = [filterName sprintf('Notch_%g_', notch)];
end

% Create a new dataset
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, ...
    'setname', filterName, 'gui','off');

end
