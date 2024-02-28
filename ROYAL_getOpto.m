function [opto_cfg] = ROYAL_getOpto(core_cfg)

% Initialize output variables
xdfNirs             = [];
auroraFound         = false;
skip                = false;
opto_cfg            = [];

% Construct XDF file path
xdfDir = fullfile( core_cfg.sourceDir, core_cfg.subjectID, core_cfg.sessionID);
xdfFile = fullfile(xdfDir, [core_cfg.subjectID '_' core_cfg.sessionID '_' core_cfg.taskID '.xdf']);


% Check if the XDF file exists

if exist(xdfFile, 'file') ~= 2
    fprintf('XDF file not found: %s\nSkipping...\n', xdfFile);
    opto_cfg.skip = true;
    return;
else

    % Load the XDF file
    try
        [xdfData, ~] = load_xdf(xdfFile);
    catch ME
        fprintf('Error loading XDF file: %s\nError: %s\nSkipping...\n', xdfFile, ME.message);
        return;
    end
end

% Look for the Aurora stream in the loaded XDF data

streamName = 'Aurora';
for i = 1:length(xdfData)
    if strcmp(xdfData{i}.info.name, streamName)
        xdfNirs = xdfData{i};
        auroraFound = true;
        break;
    end
end

if ~auroraFound
    fprintf('Aurora stream not found in %s\nSkipping...\n', xdfFile);
    opto_cfg.skip = true;
    return
else




    % get wavelengths

    numChannels                 = str2double(xdfNirs.info.channel_count);
    wavelengths                 = zeros(1, numChannels);

    % Loop through each channel to extract the wavelength
    for i = 1:numChannels
        if isfield(xdfNirs.info.desc.channels.channel{1, i}, 'wavelength') && ...
                ~isempty(xdfNirs.info.desc.channels.channel{1, i}.wavelength)
            wavelengths(i) = str2double(xdfNirs.info.desc.channels.channel{1, i}.wavelength);
        end
    end
    uniqueWavelengths           = unique(wavelengths(wavelengths ~= 0));
    wavelengths                 = wavelengths';
    wavelengths(1,:)            = []; % nicht optimal gelöst


    % get labels

    labels                      = {};

    for i = 1:numChannels-1
        if isfield(xdfNirs.info.desc.channels.channel{1, i+1}, 'label') && ...
                ~isempty(xdfNirs.info.desc.channels.channel{1, i+1}.label)
            labels{i} = xdfNirs.info.desc.channels.channel{1, i+1}.label;
        end
    end

    labels                      = labels';
    labelsRaw                   = labels(1:30,:);

    % get channel info

    numChannels                 = length(labels);
    chanLocations               = zeros(numChannels, 3); % Assuming 3D coordinates (x, y, z)
    for i = 1:numChannels
        if ~isfield(xdfNirs.info.desc.channels.channel{1,i+1}, 'location')

        else
            chanLocations(i, 1) = str2double(xdfNirs.info.desc.channels.channel{1,i+1}.location.x);
            chanLocations(i, 2) = str2double(xdfNirs.info.desc.channels.channel{1,i+1}.location.y);
            chanLocations(i, 3) = str2double(xdfNirs.info.desc.channels.channel{1,i+1}.location.z);
        end
    end


    % get source info

    numSources                  = length(xdfNirs.info.desc.montage.optodes.sources.source);
    sourceLocations             = zeros(numSources, 3); % Assuming 3D coordinates (x, y, z)
    for i = 1:numSources
        sourceLocations(i, 1)   = str2double(xdfNirs.info.desc.montage.optodes.sources.source{1, i}.location.x);
        sourceLocations(i, 2)   = str2double(xdfNirs.info.desc.montage.optodes.sources.source{1, i}.location.y);
        sourceLocations(i, 3)   = str2double(xdfNirs.info.desc.montage.optodes.sources.source{1, i}.location.z);
    end

    % get detector info

    numDetectors                = length(xdfNirs.info.desc.montage.optodes.detectors.detector);
    detectorLocations           = zeros(numDetectors, 3); % Assuming 3D coordinates (x, y, z)
    for i = 1:numDetectors
        detectorLocations(i, 1) = str2double(xdfNirs.info.desc.montage.optodes.detectors.detector{1, i}.location.x);
        detectorLocations(i, 2) = str2double(xdfNirs.info.desc.montage.optodes.detectors.detector{1, i}.location.y);
        detectorLocations(i, 3) = str2double(xdfNirs.info.desc.montage.optodes.detectors.detector{1, i}.location.z);
    end


    % combine optode information

    optodeLocations             = [sourceLocations; detectorLocations];
    optodeType                  = [repmat({'transmitter'}, numSources, 1); repmat({'receiver'}, numDetectors, 1)];


    % generate labels for sources

    sourceLabels                = cell(numSources, 1);
    for i = 1:numSources
        sourceLabels{i}         = sprintf('S%d', i);
    end


    % generate labels for detectors

    detectorLabels              = cell(numDetectors, 1);
    for i = 1:numDetectors
        detectorLabels{i}       = sprintf('D%d', i);
    end


    % generate transformation matrix

    sourceTable                 = zeros(numChannels, numSources);
    detectorTable               = zeros(numChannels, numDetectors);
    source                      = zeros(numChannels, 1);
    detector                    = zeros(numChannels, 1);

    for i = 1:length(labels)%/2
        parts = strsplit(labels{i}, ':'); % Split '1-2:3' into '1-2' and '3'
        src_det_pair = strsplit(parts{1}, '-'); % Split '1-2' into '1' and '2'

        source(i)               = str2double(src_det_pair{1});
        detector(i)             = str2double(src_det_pair{2});

        if i < 31
            sourceTable(i, str2double(src_det_pair{1})) = 1;
            detectorTable(i, str2double(src_det_pair{2})) = 1;
        elseif i < 61
            sourceTable(i, str2double(src_det_pair{1})) = 2;
            detectorTable(i, str2double(src_det_pair{2})) = 2;
        else
            sourceTable(i, str2double(src_det_pair{1})) = 0;
            detectorTable(i, str2double(src_det_pair{2})) = 0;
        end
    end

    transMatrix = [sourceTable, detectorTable];

    sens                        = struct();
    sens.label                  = labels;
    sens.chanpos                = chanLocations;
    sens.optopos                = optodeLocations;
    sens.optotype               = optodeType;
    sens.optolabel              = [sourceLabels; detectorLabels];
    sens.wavelength             = uniqueWavelengths';
    sens.tra                    = transMatrix;

    save('optode_positions.mat', 'sens');
    opto = ft_read_sens('optode_positions.mat', 'senstype', 'nirs');

    [data, ~] = xdf2fieldtrip(xdfFile,  'streamkeywords', 'Aurora');

    if ~isempty(data)

        sampling_frequency          = ones(numChannels, 1);
        sampling_frequency          = sampling_frequency * data.hdr.Fs;


        opto_cfg                    = [];
        opto_cfg.data               = data;
        opto_cfg.opto               = opto;
        opto_cfg.skip               = skip;
        opto_cfg.source             = source;
        opto_cfg.detector           = detector;
        opto_cfg.wavelength         = wavelengths;
        opto_cfg.sampling_frequency = sampling_frequency;

    end
end