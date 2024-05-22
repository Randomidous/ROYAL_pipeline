%% THIS IS THE PREPROCESSING SCRIPT

% BIDS-validate data set
bids_dir = 'C:\Users\ericw\Desktop\UHH_fNIRS\study_folder\data\1_BIDS-data';
% validate_bids(bids_dir)

%% set specifications 

% Define paths
data_path = 'C:\Users\ericw\Desktop\UHH_fNIRS\study_folder\data\1_BIDS-data';

% List of subjects
subjects = dir(fullfile(data_path, 'sub-*'));

% Define filters
fs = 10.172526298127810; % Sampling frequency (adjust as necessary)
low_cutoff = 0.14; % Low-pass cutoff frequency
band_pass = [0.1 0.4]; % Band-pass frequencies

% Initialize results container
results = struct();

% Define constants for MBLL
ext_coeff = [1.486, 3.843]; % Extinction coefficients for HbO and HbR at specific wavelengths
DPF = 6; % Differential pathlength factor (adjust as necessary)
L = 3; % Source-detector distance in cm (adjust as necessary)
pathlength = DPF * L;

for i = 1:length(subjects)
    subject = subjects(i).name;

    % Replace hyphens with underscores in subject names for valid field names
    valid_subject = strrep(subject, '-', '_');

    % Load sessions for each subject
    sessions = {'ses-pre', 'ses-post'};
    % since we are only interested in pre right now change this:
    % sessions = {'ses-pre'};

    for j = 1:length(sessions)
        session = sessions{j};

        % Replace hyphens with underscores in session names for valid field names
        valid_session = strrep(session, '-', '_');

        session_path = fullfile(data_path, subject, session, 'nirs');

        if ~exist(session_path, 'dir')
            % print that session folder does not exist
            fprintf('Session folder does not exist for Subject: %s, Session: %s\n', subject, session);
            continue;
        end

        % Load task files
        tasks = {'baseline', 'STwalking', 'DTwalking', 'STvisual'};
        for k = 1:length(tasks)
            task = tasks{k};
            task_pattern = fullfile(session_path, sprintf('%s_%s_task-%s_nirs.snirf', subject, session, task));
            task_files = dir(task_pattern);

            if isempty(task_files)
                % print that no task files
                fprintf('No task files found for Subject: %s, Session: %s, Task: %s\n', subject, session, task);
                continue;
            end

            for t = 1:length(task_files)
                task_file = fullfile(session_path, task_files(t).name);

                % Load SNIRF file
                snirf_data = nirs.io.loadSNIRF(task_file);

                % Extract amplitude data
                amplitude_data = snirf_data.data;

                % Convert NIRSCWAMPLITUDE to HbO2 using MBLL
                delta_OD = -log(amplitude_data); % Optical density change
                delta_OD = delta_OD - mean(delta_OD, 1); % Remove mean to get baseline

                % Initialize HbO2 matrix
                HbO2 = zeros(size(delta_OD, 1), size(delta_OD, 2) / 2);

                % Calculate HbO2 using the MBLL
                for ch = 1:30
                    delta_OD_750 = delta_OD(:, ch);          % 750nm data
                    delta_OD_860 = delta_OD(:, ch + 30);     % 860nm data

                    % Apply MBLL to calculate changes in HbO2
                    HbO2(:, ch) = (delta_OD_750 * ext_coeff(2) - delta_OD_860 * ext_coeff(1)) / (ext_coeff(1) * ext_coeff(2) * pathlength);
                end

                % Preprocessing

                % for tasks STvisual, STwalking, and DTwalking choose middle 4000 samples. For baseline choose only middle 1500 samples
                if strcmp(task, 'baseline')
                    if size(HbO2, 1) < 1500
                        fprintf('Skipping task %s for Subject: %s, Session: %s due to insufficient data length.\n', task, subject, session);
                        continue;
                    end
                    HbO2 = HbO2(round(size(HbO2, 1)/2)-750 : round(size(HbO2, 1)/2)+749, :);
                else
                    if size(HbO2, 1) < 3000
                        fprintf('Skipping task %s for Subject: %s, Session: %s due to insufficient data length.\n', task, subject, session);
                        continue;
                    end
                    HbO2 = HbO2(round(size(HbO2, 1)/2)-1500 : round(size(HbO2, 1)/2)+1499, :);
                end

                % Low-pass filter
                HbO2 = lowpass(HbO2, low_cutoff, fs);

                % Smoothing
                HbO2 = smoothdata(HbO2, 'movmean', 5); % Adjust window size

                % Motion artifact correction using wavelet denoising
                for ch = 1:size(HbO2, 2)
                    HbO2(:, ch) = wdenoise(HbO2(:, ch), 'Wavelet', 'sym4'); % Adjust wavelet type and parameters if necessary
                end

                % Averaging over all channels
                avg_HbO2 = mean(HbO2, 2);

                % Continuous Wavelet Transform for each channel
                wt = cell(size(avg_HbO2, 2), 1);
                f = cell(size(avg_HbO2, 2), 1);
                for ch = 1:size(avg_HbO2, 2)
                    [wt{ch}, f{ch}] = cwt(avg_HbO2(:, ch), 'amor', fs);
                end

                % Store results for each task
                if ~isfield(results, valid_subject)
                    results.(valid_subject) = struct();
                end
                if ~isfield(results.(valid_subject), valid_session)
                    results.(valid_subject).(valid_session) = struct();
                end
                results.(valid_subject).(valid_session).(task).HbO2 = HbO2;
                results.(valid_subject).(valid_session).(task).avg_HbO2 = avg_HbO2;
                results.(valid_subject).(valid_session).(task).wt = wt;
                results.(valid_subject).(valid_session).(task).f = f;

                % status update
                fprintf('Preprocessing done for Subject: %s, Session: %s, Task: %s\n', subject, session, task);
            end
        end
    end
end

%% Save results

% Define the path to the derivatives folder
derivatives_path = fullfile(data_path, 'derivatives');

% Check if the derivatives folder exists, and create it if it doesn't
if ~exist(derivatives_path, 'dir')
    mkdir(derivatives_path);
end

save(fullfile(derivatives_path, 'processed_data.mat'), 'results');
fprintf('Results saved successfully!\n');

