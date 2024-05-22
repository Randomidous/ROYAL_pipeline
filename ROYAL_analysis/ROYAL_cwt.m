%% Load processed data
data_path = 'C:\Users\ericw\Desktop\UHH_fNIRS\study_folder\data\1_BIDS-data';
derivatives_path = fullfile(data_path, 'derivatives');
load(fullfile(derivatives_path, 'processed_data.mat'), 'results');
fprintf('Results loaded successfully!\n');

% List of subjects
subjects = dir(fullfile(data_path, 'sub-*'));
sessions = {'ses-pre', 'ses-post'};
tasks = {'STwalking', 'DTwalking'};

% Define constants
fs = 10.172526298127810; % Sampling frequency

%% Initialize variables to store HbO values for STwalking and DTwalking
HbO_STwalking = [];
HbO_DTwalking = [];

for i = 1:length(subjects)
    subject = subjects(i).name;
    valid_subject = strrep(subject, '-', '_');

    for j = 1:length(sessions)
        session = sessions{j};
        valid_session = strrep(session, '-', '_');

        if isfield(results, valid_subject) && isfield(results.(valid_subject), valid_session)
            % Check if both tasks are available for the session
            if isfield(results.(valid_subject).(valid_session), 'STwalking') && isfield(results.(valid_subject).(valid_session), 'DTwalking')
                % Extract HbO2 data for STwalking and DTwalking
                HbO_STwalking = [HbO_STwalking, results.(valid_subject).(valid_session).STwalking.avg_HbO2];
                HbO_DTwalking = [HbO_DTwalking, results.(valid_subject).(valid_session).DTwalking.avg_HbO2];
            end
        end
    end
end

% Check if we have the same number of samples for both tasks
if size(HbO_STwalking, 2) ~= size(HbO_DTwalking, 2)
    error('Mismatch in the number of samples between STwalking and DTwalking.');
end

%% Perform Wilcoxon signed-rank test

[p, h, stats] = signrank(HbO_STwalking(:), HbO_DTwalking(:));

% Display the results
fprintf('Wilcoxon signed-rank test:\n');
fprintf('p-value: %.5f\n', p);
fprintf('z-value: %.5f\n', stats.zval);
fprintf('Signed rank: %.5f\n', stats.signedrank);

%%

% Define the output directory and file name
output_directory = 'C:\Users\ericw\Desktop\UHH_fNIRS\study_folder\data\1_BIDS-data\derivatives\tables';
if ~exist(output_directory, 'dir')
    mkdir(output_directory);
end
filename_txt = fullfile(output_directory, 'wilcoxon_results.txt');

% Open the file for writing
fileID = fopen(filename_txt, 'w');

% Write the results to the text file
fprintf(fileID, 'Wilcoxon signed-rank test:\n');
fprintf(fileID, 'p-value: %.5f\n', p);
fprintf(fileID, 'z-value: %.5f\n', stats.zval);
fprintf(fileID, 'Signed rank: %.5f\n', stats.signedrank);

% Close the file
fclose(fileID);

fprintf('Results saved to %s\n', filename_txt);


%% Coherence Wavelet Transform Analysis
% Compute and plot the wavelet coherence between STwalking and DTwalking

% Define the desired frequency range
freq_range = [0.01, 2]; % From 0.01 Hz to 2 Hz

% Calculate wavelet coherence
[wtc, wcs, freq, coi] = wcoherence(mean(HbO_STwalking, 2), mean(HbO_DTwalking, 2), fs, ...
                                   'FrequencyLimits', freq_range, 'VoicesPerOctave', 12);

% Define a time vector for plotting purposes
time_vector = (1:size(wtc, 2)) / fs;

% Plot wavelet coherence
figure;
imagesc(time_vector, freq, abs(wtc));
axis xy;
xlabel('Time (s)');
ylabel('Frequency (Hz)');
title('Wavelet Coherence between STwalking and DTwalking');
colorbar;

% Limit frequency axis to the range of interest
ylim(freq_range);

% Save the plot
output_dir_cwt = fullfile(data_path, 'derivatives', 'figures');
if ~exist(output_dir_cwt, 'dir')
    mkdir(output_dir_cwt);
end
saveas(gcf, fullfile(output_dir_cwt, 'wavelet_coherence_STwalking_vs_DTwalking.png'));
close gcf;

fprintf('Wavelet coherence analysis and plot saved successfully!\n');
