%% THIS IS THE ANALYSIS SCRIPT

% Load the processed data from the .mat file
data_path = 'C:\Users\ericw\Desktop\UHH_fNIRS\study_folder\data\1_BIDS-data';
derivatives_path = fullfile(data_path, 'derivatives');
load(fullfile(derivatives_path, 'processed_data.mat'), 'results');
fprintf('Results loaded successfully!\n');

% List of subjects
subjects = dir(fullfile(data_path, 'sub-*'));

% Define tasks and sessions
tasks = {'baseline', 'STwalking', 'DTwalking', 'STvisual'};
sessions = {'ses-pre', 'ses-post'};

% Initialize variables to store HbO values for ANOVA
num_subjects = length(subjects);
num_tasks = length(tasks);
anova_data = nan(num_subjects, num_tasks);

for i = 1:num_subjects
    subject = subjects(i).name;
    valid_subject = strrep(subject, '-', '_');

    for k = 1:num_tasks
        task = tasks{k};
        task_data = [];

        for j = 1:length(sessions)
            session = sessions{j};
            valid_session = strrep(session, '-', '_');

            if isfield(results, valid_subject) && isfield(results.(valid_subject), valid_session) && isfield(results.(valid_subject).(valid_session), task)
                avg_HbO2 = results.(valid_subject).(valid_session).(task).avg_HbO2;

                % Collect task data for averaging
                task_data = [task_data; mean(avg_HbO2)];
            end
        end

        % Store the average task data in the matrix, ignoring NaNs
        if ~isempty(task_data)
            anova_data(i, k) = nanmean(task_data);
        end
    end
end

%% With Outliers 

% Remove subjects with any NaN values across any task
valid_subjects = all(~isnan(anova_data), 2);
anova_data_withOutlier = anova_data(valid_subjects, :);
subject_ids1 = find(valid_subjects);

data_table_with = array2table(anova_data_withOutlier, 'VariableNames', tasks);
data_table_with.Subject = subject_ids1;

% Define the repeated measures model
within_design = table(tasks', 'VariableNames', {'Tasks'});
rm_with = fitrm(data_table_with, 'baseline-STvisual ~ 1', 'WithinDesign', within_design);

% Perform repeated measures ANOVA
ranova_results_withOutliers = ranova(rm_with);

%% Without Outliers

% Remove subjects with any NaN values across any task
valid_subjects2 = all(~isnan(anova_data), 2);
anova_data_cleaned = anova_data(valid_subjects2, :);
subject_ids = find(valid_subjects2);

% Outlier removal using the IQR method
anova_data_withoutOutliers = anova_data_cleaned;
for k = 1:num_tasks
    task_data = anova_data_cleaned(:, k);
    Q1 = quantile(task_data, 0.25);
    Q3 = quantile(task_data, 0.75);
    IQR = Q3 - Q1;
    lower_bound = Q1 - 1.5 * IQR;
    upper_bound = Q3 + 1.5 * IQR;
    outliers = (task_data < lower_bound) | (task_data > upper_bound);
    anova_data_withoutOutliers(outliers, k) = NaN; % Set outliers to NaN
end

% Remove subjects with any NaN values after outlier removal
valid_subjects_cleaned = all(~isnan(anova_data_withoutOutliers), 2);
anova_data_withoutOutliers = anova_data_withoutOutliers(valid_subjects_cleaned, :);
subject_ids2 = subject_ids(valid_subjects_cleaned);

% Convert data to table
data_table_without = array2table(anova_data_withoutOutliers, 'VariableNames', tasks);
data_table_without.Subject = subject_ids2;

% Define the repeated measures model
within_design = table(tasks', 'VariableNames', {'Tasks'});
rm_without = fitrm(data_table_without, 'baseline-STvisual ~ 1', 'WithinDesign', within_design);

% Perform repeated measures ANOVA
ranova_results_withoutOutliers = ranova(rm_without);

%% Display the results

% Display
disp('Repeated Measures ANOVA results with outliers:');
disp(ranova_results_withOutliers);

% Perform multiple comparisons if needed
multcomp_results_with = multcompare(rm_with, 'Tasks');
disp('Multiple Comparisons with outliers:');
disp(multcomp_results_with);

% Display
disp('Repeated Measures ANOVA results without outliers:');
disp(ranova_results_withoutOutliers);

% Perform multiple comparisons if needed
multcomp_results_without = multcompare(rm_without, 'Tasks');
disp('Multiple Comparisons without outliers:');
disp(multcomp_results_without);

%% Export the results

% Define the output directory
output_directory = 'C:\Users\ericw\Desktop\UHH_fNIRS\study_folder\data\1_BIDS-data\derivatives\tables\';

% Export results with outliers
filename_with_outliers = fullfile(output_directory, 'anova_results_with_outliers.txt');
write_anova_results_to_file(filename_with_outliers, ranova_results_withOutliers, multcomp_results_with);

% Export results without outliers
filename_without_outliers = fullfile(output_directory, 'anova_results_without_outliers.txt');
write_anova_results_to_file(filename_without_outliers, ranova_results_withoutOutliers, multcomp_results_without);


%% Plot the results
% 
% % Determine the y-axis limits based on the combined data
% combined_data = [anova_data_withOutlier(:); anova_data_withoutOutliers(:)];
% y_limits = [min(combined_data) - 0.00001, max(combined_data) + 0.00001];
% 
% % With outliers
% figure('Units', 'normalized', 'OuterPosition', [0 0 1 1]);
% subplot(1, 2, 1);
% boxchart(anova_data_withOutlier, 'LineWidth', 1.5, 'notch', 'off');
% set(gca, 'XTickLabel', tasks);
% ylabel('HbO Value');
% title('HbO Value Distribution per Task (With Outliers)');
% ylim(y_limits); % Set y-axis limits
% 
% % Calculate and plot the means
% hold on;
% mean_values_with = mean(anova_data_withOutlier, 'omitnan');
% plot(1:length(tasks), mean_values_with, 'black.', 'MarkerSize', 10);
% hold off;

% Without outliers
figure('Units', 'normalized', 'OuterPosition', [0 0 1 1]);

% subplot(1, 2, 2);
boxchart(anova_data_withoutOutliers, 'LineWidth', 1.5, 'notch', 'off');
set(gca, 'XTickLabel', tasks);
ylabel('HbO Value');
title('HbO Value Distribution per Task (Without Outliers)');
% ylim(y_limits); % Set y-axis limits

% Calculate and plot the means
hold on;
mean_values_without = mean(anova_data_withoutOutliers, 'omitnan');
plot(1:length(tasks), mean_values_without, 'black.', 'MarkerSize', 10);
hold off;
tightfig;

% Save the figure according to BIDS specifications
output_path = fullfile(data_path, 'derivatives', 'figures');
if ~exist(output_path, 'dir')
    mkdir(output_path);
end
saveas(gcf, fullfile(output_path, 'hbo_values_boxplots__withoutOutlier_anova_big.png'));
close gcf
   
%% Export data to CSV for use in R

% Define the output directory for the CSV file
output_directory = 'C:\Users\ericw\Desktop\UHH_fNIRS\study_folder\data\1_BIDS-data\derivatives\tables';

% Ensure the directory exists
if ~exist(output_directory, 'dir')
    mkdir(output_directory);
end

% Save the with outliers data
anova_data_withOutliers_table = array2table(anova_data_withOutlier, 'VariableNames', tasks);
anova_data_withOutliers_table.Subject = subject_ids1; % Add Subject IDs
writetable(anova_data_withOutliers_table, fullfile(output_directory, 'anova_data_withOutliers.csv'));

% Save the without outliers data
anova_data_withoutOutliers_table = array2table(anova_data_withoutOutliers, 'VariableNames', tasks);
anova_data_withoutOutliers_table.Subject = subject_ids2; % Add Subject IDs
writetable(anova_data_withoutOutliers_table, fullfile(output_directory, 'anova_data_withoutOutliers.csv'));

function write_anova_results_to_file(filename, ranova_results, multcomp_results)
    % Open the file for writing
    fileID = fopen(filename, 'w');
    
    % Write the ANOVA results header
    fprintf(fileID, 'Repeated Measures ANOVA results:\n');
    fprintf(fileID, '-------------------------------------------------\n');
    fprintf(fileID, '%25s %10s %15s %10s %10s %10s %10s %10s\n', ' ', 'SumSq', 'DF', 'MeanSq', 'F', 'pValue', 'pValueGG', 'pValueHF', 'pValueLB');
    for i = 1:height(ranova_results)
        fprintf(fileID, '%25s %10.6e %10d %15.6e %10.4f %10.5f %10.5f %10.5f %10.5f\n', ...
            ranova_results.Properties.RowNames{i}, ranova_results.SumSq(i), ranova_results.DF(i), ...
            ranova_results.MeanSq(i), ranova_results.F(i), ranova_results.pValue(i), ...
            ranova_results.pValueGG(i), ranova_results.pValueHF(i), ranova_results.pValueLB(i));
    end

    % Write the multiple comparisons results header
    fprintf(fileID, '\nMultiple Comparisons:\n');
    fprintf(fileID, '-------------------------------------------------\n');
    fprintf(fileID, '%15s %15s %15s %15s %10s %15s %15s\n', 'Tasks_1', 'Tasks_2', 'Difference', 'StdErr', 'pValue', 'Lower', 'Upper');
    for i = 1:height(multcomp_results)
        fprintf(fileID, '%15s %15s %15.6e %15.6e %10.5f %15.6e %15.6e\n', ...
            multcomp_results.Tasks_1{i}, multcomp_results.Tasks_2{i}, multcomp_results.Difference(i), ...
            multcomp_results.StdErr(i), multcomp_results.pValue(i), multcomp_results.Lower(i), multcomp_results.Upper(i));
    end
    
    % Close the file
    fclose(fileID);
end
