%% Load the processed data from the .mat file

data_path = 'C:\Users\ericw\Desktop\UHH_fNIRS\study_folder\data\1_BIDS-data';
derivatives_path = fullfile(data_path, 'derivatives');
load(fullfile(derivatives_path, 'processed_data.mat'), 'results');
fprintf('Results loaded successfully!\n');
fs = 10.172526298127810; % Sampling frequency

% List of subjects
subjects = dir(fullfile(data_path, 'sub-*'));

% Define tasks and sessions
tasks = {'baseline', 'STwalking', 'DTwalking', 'STvisual'};
sessions = {'ses-pre', 'ses-post'};

%% Plot avg HbO2 for each task averaged over subjects

% Call the function to plot
plot_avg_HbO2(results, subjects, sessions, tasks);

% Save plots
output_dir = fullfile(data_path, 'derivatives', 'figures');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end
saveas(gcf, fullfile(output_dir, sprintf('avg_HbO2.png')));
close gcf


%% Plot avg cwt for each task averaged over subjects
% probably bs

% Call the function to plot
plot_avg_CWT(results, subjects, sessions, tasks, fs);

% Save plots
output_dir_cwt = fullfile(data_path, 'derivatives', 'figures');
if ~exist(output_dir_cwt, 'dir')
    mkdir(output_dir_cwt);
end
saveas(gcf, fullfile(output_dir_cwt, sprintf('avg_CWT.png')));
close gcf



