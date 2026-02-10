function [ALLEEG, EEG, CURRENTSET] = bad_channels(ALLEEG, EEG, threshold)
%% Bad channel rection: Automatic detection and removal of bad channels

disp('Detect and remove bad channels')


EEG = eeg_checkset( EEG );

% Define measures and optional parameters
measures  = {'prob', 'kurt', 'spec'};
specRange = [1 125];

[~, prob] = pop_rejchan(EEG, 'threshold',threshold,'norm','on','measure','prob');
[~, kurt] = pop_rejchan(EEG,'threshold',threshold,'norm','on','measure','kurt');
[~, freq] = pop_rejchan(EEG, 'threshold',threshold,'norm','on','measure','spec','freqrange',[1 125]);

badChans = sort(unique([prob,kurt,freq]));
% if EOG has beedn flagged, remove flag
if find(~(contains({EEG.chanlocs(badChans).type}, 'EEG'))) > 0
    badChans(~(contains({EEG.chanlocs(badChans).type}, 'EEG'))) = [];
else 
end


if length(badChans) == EEG.nbchan
    error('All channels flagged as bad! Check threshold or data.');
    % return without removing any channels, or remove them all if that’s what you want.
else

    % store info about bad channels
    EEG.etc.badChannelRemoval.bad_channels_idx = badChans;
    EEG.etc.badChannelRemoval.bad_channels = {EEG.chanlocs(badChans).labels};
    EEG.etc.badChannelRemoval.threshold = threshold;
    EEG.etc.badChannelRemoval.measures  = measures;
    EEG.etc.badChannelRemoval.badChans  = badChans;

    EEG = pop_select( EEG, 'nochannel',{EEG.chanlocs(badChans).labels});
    

    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, length(ALLEEG),'setname',...
        'remove_bad_channels','gui','off');
end






