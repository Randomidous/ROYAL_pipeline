% Clear workspace
clear all; close all; clc;

% Configurations
rootDir = 'C:\Users\ericw\Desktop\UHH_fNIRS\study_folder\data\1_BIDS-data';
numSubjects = 29;
sessions = {'pre'}; % {'pre', 'post'};
tasks = {'STvisual', 'DTwalking'}; % Only interested in STvisual and DTwalking
data_path = 'C:\Users\ericw\Desktop\UHH_fNIRS\study_folder\data\1_BIDS-data';


% Initialize a structure to store the filtered events data and analysis results
filteredEventsData = struct();
analysisResults = struct();

% Loop through each subject, session, and task to load and filter events files
for subj = 1:numSubjects
    subjectID = sprintf('sub-%02d', subj);
    valid_subject = strrep(subjectID, '-', '_');

    for sessIdx = 1:length(sessions)
        sessionID = sessions{sessIdx};
        valid_session = strrep(sessionID, '-', '_');

        for taskIdx = 1:length(tasks)
            taskID = tasks{taskIdx};

            % Construct the filename for the events file
            eventsFilename = fullfile(rootDir, subjectID, ['ses-' sessionID], 'nirs', ...
                                      [subjectID '_ses-' sessionID '_task-' taskID '_events.tsv']);

            % Check if the events file exists
            if exist(eventsFilename, 'file')
                % Read the events file
                eventsTable = readtable(eventsFilename, 'FileType', 'text', 'Delimiter', '\t');

                % Filter the events to include only 'stimulus' or 'response'
                filteredEventsTable = eventsTable(startsWith(eventsTable.value, {'stimulus', 'response'}), :);

                % Store the filtered events data in the new structure
                filteredEventsData.(valid_subject).(valid_session).(taskID) = filteredEventsTable;

                % Display the loaded and filtered data for verification (optional)
                fprintf('Loaded and filtered events data for %s, %s session, %s task.\n', subjectID, sessionID, taskID);

                % Analysis: Initialize variables for storing results
                correctResponses = 0;
                totalResponses = 0;
                totalStimuli = 0;
                responseTimes = [];

                % Loop through the filtered events to calculate response metrics
                for i = 2:height(filteredEventsTable) % start from 2 to avoid out-of-bounds error
                    event = filteredEventsTable.value{i};

                    if startsWith(event, 'response')
                        % Check if the event is a response time over
                        if contains(event, 'time over')
                            fprintf('Response time over for %s, %s session, %s task.\n', subjectID, sessionID, taskID);
                            continue;
                        end

                        totalResponses = totalResponses + 1;

                        % Extract response side using regexp
                        responseSide = regexp(event, 'response:(left|right)', 'tokens', 'once');

                        if ~isempty(responseSide)
                            responseSide = responseSide{1};  % Convert cell to char
                        end

                        % Find the corresponding stimulus
                        prevEvent = filteredEventsTable.value{i-1};
                        if startsWith(prevEvent, 'stimulus:visual')
                            totalStimuli = totalStimuli + 1;  % Increment total stimuli count
                            stimulusColor = regexp(prevEvent, 'color:(cyan|purple)', 'tokens', 'once');
                            stimulusSide = regexp(prevEvent, 'side:(left|right)', 'tokens', 'once');

                            if ~isempty(stimulusColor)
                                stimulusColor = stimulusColor{1};  % Convert cell to char
                            end
                            if ~isempty(stimulusSide)
                                stimulusSide = stimulusSide{1};  % Convert cell to char
                            end

                            % Calculate response time based on onset times
                            responseTime = filteredEventsTable.onset(i) - filteredEventsTable.onset(i-1);
                            responseTimes = [responseTimes; responseTime];

                            % Define correct response condition (example: left for cyan, right for purple)
                            if (strcmp(stimulusColor, 'cyan') && strcmp(responseSide, 'right')) || ...
                               (strcmp(stimulusColor, 'purple') && strcmp(responseSide, 'left'))
                                correctResponses = correctResponses + 1;
                            end
                        end
                    end
                end

                % Calculate average response time
                avgResponseTime = mean(responseTimes);

                % Calculate total duration
                totalTime = filteredEventsTable.onset(end) - filteredEventsTable.onset(1);

                % Calculate corrected response rate
                correctResponsePercentage = (correctResponses / totalResponses) * 100;
                correctResponseRatePerSecond = (correctResponses / totalTime) * correctResponsePercentage;

                % Store analysis results
                analysisResults.(valid_subject).(valid_session).(taskID).correctResponses = correctResponses;
                analysisResults.(valid_subject).(valid_session).(taskID).totalResponses = totalResponses;
                analysisResults.(valid_subject).(valid_session).(taskID).avgResponseTime = avgResponseTime;
                analysisResults.(valid_subject).(valid_session).(taskID).correctResponseRatePerSecond = correctResponseRatePerSecond;
            else
                fprintf('Events file not found for %s, %s session, %s task.\n', subjectID, sessionID, taskID);
            end
        end
    end
end

% Save the filtered results and analysis results to files for further analysis
save(fullfile(rootDir, 'derivatives', 'filteredEventsData.mat'), 'filteredEventsData');
save(fullfile(rootDir, 'derivatives', 'analysisResults.mat'), 'analysisResults');


%% Plotting comparison illustrations 

% Initialize variables for storing aggregated results
subjects = {};
correctResponseRatesSTvisual = [];
correctResponseRatesDTwalking = [];
avgResponseTimesSTvisual = [];
avgResponseTimesDTwalking = [];

for subj = 1:numSubjects
    subjectID = sprintf('sub-%02d', subj);
    valid_subject = strrep(subjectID, '-', '_');

    if isfield(analysisResults, valid_subject) && isfield(analysisResults.(valid_subject), 'pre')
        if isfield(analysisResults.(valid_subject).pre, 'STvisual')
            correctResponseRatesSTvisual = [correctResponseRatesSTvisual; analysisResults.(valid_subject).pre.STvisual.correctResponseRatePerSecond];
            avgResponseTimesSTvisual = [avgResponseTimesSTvisual; analysisResults.(valid_subject).pre.STvisual.avgResponseTime];
        end
        if isfield(analysisResults.(valid_subject).pre, 'DTwalking')
            correctResponseRatesDTwalking = [correctResponseRatesDTwalking; analysisResults.(valid_subject).pre.DTwalking.correctResponseRatePerSecond];
            avgResponseTimesDTwalking = [avgResponseTimesDTwalking; analysisResults.(valid_subject).pre.DTwalking.avgResponseTime];
        end
    end
    subjects = [subjects; {subjectID}];
end

% Align data for box plots
maxLength = max(length(correctResponseRatesSTvisual), length(correctResponseRatesDTwalking));
correctResponseRatesSTvisual = [correctResponseRatesSTvisual; NaN(maxLength - length(correctResponseRatesSTvisual), 1)];
correctResponseRatesDTwalking = [correctResponseRatesDTwalking; NaN(maxLength - length(correctResponseRatesDTwalking), 1)];

maxLength = max(length(avgResponseTimesSTvisual), length(avgResponseTimesDTwalking));
avgResponseTimesSTvisual = [avgResponseTimesSTvisual; NaN(maxLength - length(avgResponseTimesSTvisual), 1)];
avgResponseTimesDTwalking = [avgResponseTimesDTwalking; NaN(maxLength - length(avgResponseTimesDTwalking), 1)];

% Create box plots to compare average response times and corrected response rates
figure; 
% figure('Units', 'normalized', 'OuterPosition', [0 0 1 1]);

% Plot for Corrected Response Rate per Second
subplot(1,2,1);
hold on;
boxchart([ones(size(correctResponseRatesSTvisual)); 2*ones(size(correctResponseRatesDTwalking))], ...
         [correctResponseRatesSTvisual; correctResponseRatesDTwalking], ...
         'LineWidth', 1.5, 'Notch', 'off');

% Calculate and plot mean values
mean_correctResponseRates = [mean(correctResponseRatesSTvisual, 'omitnan'), mean(correctResponseRatesDTwalking, 'omitnan')];
plot(1:2, mean_correctResponseRates, 'black.', 'MarkerSize', 10);
hold off;

title('Corrected Response Rate');
ylabel('Corrected Response Rate');
set(gca, 'XTick', [1, 2], 'XTickLabel', {'STvisual', 'DTvisual'});

% Plot for Average Response Time
subplot(1,2,2);
hold on;
boxchart([ones(size(avgResponseTimesSTvisual)); 2*ones(size(avgResponseTimesDTwalking))], ...
         [avgResponseTimesSTvisual; avgResponseTimesDTwalking], ...
         'LineWidth', 1.5, 'Notch', 'off');

% Calculate and plot mean values
mean_avgResponseTimes = [mean(avgResponseTimesSTvisual, 'omitnan'), mean(avgResponseTimesDTwalking, 'omitnan')];
plot(1:2, mean_avgResponseTimes, 'black.', 'MarkerSize', 10);
hold off;

title('Average Response Time');
ylabel('Average Response Time (seconds)');
set(gca, 'XTick', [1, 2], 'XTickLabel', {'STvisual', 'DTvisual'});

tightfig;

% Save the figure according to BIDS specifications
output_path = fullfile(data_path, 'derivatives', 'figures');
if ~exist(output_path, 'dir')
    mkdir(output_path);
end
saveas(gcf, fullfile(output_path, 'behav_response_analysis.png'));
close gcf

%% Conduct t-tests on the STvisual and DTwalking values for Corrected Response Rate and Average Response Time

% Corrected Response Rate t-test
[~, p_correctedRate, ~, stats_correctedRate] = ttest(correctResponseRatesSTvisual, correctResponseRatesDTwalking);
fprintf('Corrected Response Rate t-test: t(%d) = %.2f, p = %.4f\n', stats_correctedRate.df, stats_correctedRate.tstat, p_correctedRate);

% Average Response Time t-test
[~, p_avgResponseTime, ~, stats_avgResponseTime] = ttest(avgResponseTimesSTvisual, avgResponseTimesDTwalking);
fprintf('Average Response Time t-test: t(%d) = %.2f, p = %.4f\n', stats_avgResponseTime.df, stats_avgResponseTime.tstat, p_avgResponseTime);

