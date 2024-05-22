function plot_avg_HbO2(results, subjects, sessions, tasks)
% Function to plot average HbO2 for each task averaged over subjects and sessions
%
% Inputs:
%   results  - Struct containing the preprocessed data
%   subjects - List of subjects
%   sessions - List of sessions
%   tasks    - List of tasks
%
% Example usage:
%   plot_avg_HbO2(results, subjects, sessions, tasks)

% Define y-axis limits
y_limits = [-0.00035, 0.00035];

% Initialize figure
figure('Units', 'normalized', 'OuterPosition', [0 0 1 1]);

% Loop through each task
for k = 1:length(tasks)
    task = tasks{k};
    task_data = [];

    % Loop through each subject
    for i = 1:length(subjects)
        subject = subjects(i).name;
        valid_subject = strrep(subject, '-', '_');

        % Loop through each session
        for j = 1:length(sessions)
            session = sessions{j};
            valid_session = strrep(session, '-', '_');

            % Check if the required fields are present in the results struct
            if isfield(results, valid_subject) && ...
                    isfield(results.(valid_subject), valid_session) && ...
                    isfield(results.(valid_subject).(valid_session), task)

                % Extract average HbO2 data
                avg_HbO2 = results.(valid_subject).(valid_session).(task).avg_HbO2;

                % Accumulate data for averaging
                if isempty(task_data)
                    task_data = avg_HbO2;
                else
                    task_data = [task_data, avg_HbO2];
                end
            end
        end
    end

    % Calculate the average over all subjects and sessions
    avg_task_data = mean(task_data, 2);
    std_task_data = std(task_data, 0, 2);
    sem_task_data = std_task_data / sqrt(size(task_data, 2));

    % Plotting the average HbO2 data with shaded error bars
    subplot(2, 2, k);
    hold on;

    % Plot shaded error bar (2*SEM)
    x = 1:length(avg_task_data);
    upper_bound = avg_task_data + 2 * sem_task_data;
    lower_bound = avg_task_data - 2 * sem_task_data;
    fill([x, fliplr(x)], [lower_bound', fliplr(upper_bound')], 'b', 'FaceAlpha', 0.3, 'EdgeColor', 'none');

    % Plot mean HbO2
    hline = yline(0, 'Color', [0.5 0.5 0.5], 'LineWidth', 0.5, 'HandleVisibility', 'off');
    hline.Color(4) = 0.5;  % Set the opacity (alpha) to 50%
    plot(avg_task_data, 'Color', [0 0 0.5], 'LineWidth', 1.5);
    title(sprintf('HbO2 Values - Task: %s', task));
    xlabel('Time');
    ylabel('HbO2');
    ylim(y_limits);
    grid off;
    hold off;
    
end
tightfig;
