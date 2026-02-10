function select_set(setname)
    % select_set
    %   Selects a dataset from ALLEEG by its setname and makes it the active dataset.
    %
    % USAGE:
    %   select_set('desired_setname');
    %
    % INPUT:
    %   setname - Name of the dataset to select (must exist in ALLEEG).
    %
    % NOTES:
    %   - The variables ALLEEG, EEG, and CURRENTSET must exist in the global workspace.
    %   - This function retrieves the dataset with the given setname from ALLEEG and updates
    %     the active dataset (EEG) and CURRENTSET accordingly.
    %   - Throws an error if the dataset with the specified setname is not found.

    % In the global workspace, ensure ALLEEG, EEG, and CURRENTSET are defined.
    global ALLEEG EEG CURRENTSET;

    % Check if the required global variables exist
    if isempty(ALLEEG) || isempty(EEG) || isempty(CURRENTSET)
        error('Global variables ALLEEG, EEG, and CURRENTSET must exist in the workspace.');
    end

    % Find the dataset index with the specified setname
    get_set = find(strcmp({ALLEEG.setname}, setname), 1);

    % Check if the dataset was found
    if isempty(get_set)
        error('Dataset with setname "%s" not found in ALLEEG.', setname);
    end

    % Retrieve the dataset and update EEG and CURRENTSET
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, ...
        'retrieve', get_set, 'study', 0, 'gui', 'off');

    % Perform a consistency check on the selected dataset
    EEG = eeg_checkset(EEG);

    fprintf('Dataset "%s" successfully selected.\n', setname);
end
