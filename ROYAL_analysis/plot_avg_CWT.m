function plot_avg_CWT(results, subjects, sessions, tasks, fs)
    % Function to plot average CWT for each task averaged over subjects and sessions
    %
    % Inputs:
    %   results  - Struct containing the preprocessed data
    %   subjects - List of subjects
    %   sessions - List of sessions
    %   tasks    - List of tasks
    %   fs       - Sampling frequency
    %
    % Example usage:
    %   plot_avg_CWT(results, subjects, sessions, tasks, fs)

    % Define a common frequency range for interpolation and zoom in on the bottom 50%
    common_freqs = linspace(0, fs / 2, 100); % Adjust the number of points as needed
    zoomed_freqs = common_freqs(1:round(0.5 * length(common_freqs))); % Bottom 50% of frequencies

    figure('Units', 'normalized', 'OuterPosition', [0 0 1 1]);

    for k = 1:length(tasks)
        task = tasks{k};
        task_data = [];

        for i = 1:length(subjects)
            subject = subjects(i).name;
            valid_subject = strrep(subject, '-', '_');

            for j = 1:length(sessions)
                session = sessions{j};
                valid_session = strrep(session, '-', '_');

                if isfield(results, valid_subject) && isfield(results.(valid_subject), valid_session) && isfield(results.(valid_subject).(valid_session), task)
                    wt = results.(valid_subject).(valid_session).(task).wt;
                    f = results.(valid_subject).(valid_session).(task).f;

                    % Accumulate data for averaging
                    for ch = 1:length(wt)
                        interpolated_wt = interp1(f{ch}, abs(wt{ch}), common_freqs, 'linear', 'extrap');
                        interpolated_wt_zoomed = interpolated_wt(1:round(0.5 * length(common_freqs)), :);

                        if isempty(task_data)
                            task_data = interpolated_wt_zoomed;
                        else
                            task_data = task_data + interpolated_wt_zoomed;
                        end
                    end
                end
            end
        end

        % Average over all subjects and channels
        avg_task_data = task_data / (length(subjects) * length(sessions));

        % Plotting
        subplot(2, 2, k);
        surf(1:size(avg_task_data, 2), zoomed_freqs, avg_task_data, 'EdgeColor', 'none');
        title(sprintf('Average CWT - Task: %s', task));
        xlabel('Time');
        ylabel('Frequency (Hz)');
        view(2);
        colorbar;
    end
end
