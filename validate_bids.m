function validate_bids(bids_dir)
    % Validate BIDS dataset and check for required files
    % bids_dir: Path to the BIDS dataset directory
    
    % Step 1: Run BIDS Validator
    fprintf('Running BIDS Validator...\n');
    validator_path = 'bids-validator'; % or provide the full path if necessary
    status = system([validator_path ' ' bids_dir]);
    if status ~= 0
        error('BIDS Validator found issues with the dataset.');
    end
    fprintf('BIDS Validator completed successfully.\n');
    
    % Step 2: Check for required files
    fprintf('Checking for required files...\n');
    required_files = {'dataset_description.json', 'participants.tsv'};
    
    % Check for required files in the root directory
    for i = 1:length(required_files)
        file_path = fullfile(bids_dir, required_files{i});
        if ~exist(file_path, 'file')
            error('Required file missing: %s', required_files{i});
        else
            fprintf('Found required file: %s\n', required_files{i});
        end
    end
    
    % Check for task events JSON files in each subject directory
    subject_dirs = dir(fullfile(bids_dir, 'sub-*'));
    for i = 1:length(subject_dirs)
        if subject_dirs(i).isdir
            session_dirs = dir(fullfile(bids_dir, subject_dirs(i).name, 'ses-*'));
            for j = 1:length(session_dirs)
                if session_dirs(j).isdir
                    nirs_dir = fullfile(bids_dir, subject_dirs(i).name, session_dirs(j).name, 'nirs');
                    if exist(nirs_dir, 'dir')
                        event_files = dir(fullfile(nirs_dir, '*_events.json'));
                        if isempty(event_files)
                            warning('No task events JSON files found in %s', nirs_dir);
                        else
                            fprintf('Found task events JSON files in %s\n', nirs_dir);
                            for k = 1:length(event_files)
                                fprintf('  %s\n', event_files(k).name);
                            end
                        end
                    else
                        warning('NIRS data directory not found for subject %s, session %s', subject_dirs(i).name, session_dirs(j).name);
                    end
                    
                    % Print directory structure for each session
                    fprintf('Directory structure for %s, session %s:\n', subject_dirs(i).name, session_dirs(j).name);
                    dir_struct = dir(fullfile(bids_dir, subject_dirs(i).name, session_dirs(j).name));
                    for l = 1:length(dir_struct)
                        fprintf('  %s\n', dir_struct(l).name);
                    end
                end
            end
        end
    end
    
    fprintf('All checks completed.\n');
end
