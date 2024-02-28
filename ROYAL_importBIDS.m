%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Greetings fellow human!
%
%   ROYAL_importBIDS is a pipeline tailored for import of NIRS data and
%   subsequent saving in the current BIDS format (v1.9.0). This is a script
%   in which you call this function multiple times, once for each
%   individually recorded data file (or data set). It will write the
%   corresponding sidecar JSON and TSV files for each data file.
%
%   To execute this script, please specify all necessary data information,
%   BIDS specifications and press run.
%
%
%   Dependencies are:
%
%   - ROYAL_* scripts:
%       - *data2bids
%       - *getOpto
%       - *write_data
%
%   - Toolboxes:
%       - NIRS Toolbox
%       - Homer3 with dependencies
%       - SNIRF
%       - FieldTrip
%
%   See also:
%   - ROYAL_data2bids
%   - ROYAL_getOpto
%   - ROYAL_write_data
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%
% confirgurations                                                        %
cfg                                     = [];                            %
core_cfg                                = [];                            %

% folder setup
core_cfg.rootDir                        = 'C:\Users\ericw\Desktop\UHH_fNIRS\study_folder\data'; % Define study folder
core_cfg.sourceDir                      = [ core_cfg.rootDir '\0_source-data' ];                % Define source folder
core_cfg.bidsDir                        = [ core_cfg.rootDir '\1_BIDS-data' ];                  % Define bids folder

% study information
core_cfg.numSubjects                    = 29;                                                   % Define the number of subjects
core_cfg.sessions                       = { 'pre', 'post' };                                    % Define the sessions
core_cfg.tasks                          = { 'baseline', 'STwalking', 'STvisual', 'DTwalking' }; % Define the tasks

% data2bids required

cfg.method                              = 'convert';
cfg.writejson                           = 'replace';
cfg.writetsv                            = 'replace';

% data2bids specifications
for subj                                = 1:core_cfg.numSubjects

    subjectID                           = sprintf( 'sub-%02d', subj );                          % format: 'sub-XX'

    for sess                            = 1:length(core_cfg.sessions)                           % iterate over all sessions (pre, post)

        sessionID                       = [ 'ses-' core_cfg.sessions{sess} ];                   % define sessionID
        directory                       = fullfile( core_cfg.sourceDir, subjectID, sessionID ); % navigate to respective folder
        cd(directory)

        for task                        = 1:length(core_cfg.tasks)                              % iterate over all tasks (pre, post)

            taskID                      = core_cfg.tasks{task};                                 % define taskID

            % add info to cfg
            core_cfg.subjectID          = subjectID;
            core_cfg.sessionID          = sessionID;
            core_cfg.taskID             = taskID;
            core_cfg.subj               = subj;


            filename                    = [subjectID '_' sessionID '_' taskID '.xdf'];
            cfg.dataset                 = filename;

            % skip if file doesn't exist
            if ~exist(filename)
                continue
            end

            % the following settings relate to the directory structure and file names
            cfg.bidsroot                = core_cfg.bidsDir;
            cfg.sub                     = num2str(subj);
            cfg.ses                     = core_cfg.sessions{sess};
            cfg.task                    = taskID;
            cfg.datatype                = 'nirs';
            % cfg.run                   = [1];

            % cfg.coordsystem           = still NEEDED
            % cfg.events                = trial definition (see FT_DEFINETRIAL) or event structure (see FT_READ_EVENT)

            % For NIRS data you can specify an optode definition according to
            % FT_DATATYPE_SENS as an "opto" field in the input data, or you can specify
            % it as cfg.opto or you can specify a filename with optode information.


            % If you specify cfg.bidsroot, this function will also write the dataset_description.json
            % file. You can specify the following fields
            cfg.dataset_description.writesidecar        = 'This is a nice description of the recoreded data. We did an experiment';
            cfg.dataset_description.Name                = '23-channel NIRS measured during visual discrimination task';
            cfg.dataset_description.BIDSVersion         = 'v1.9.0';
            cfg.dataset_description.License             = 'possible license';
            cfg.dataset_description.Authors             = 'Roy Eric Wieske';
            cfg.dataset_description.Acknowledgements    = 'I am thankful for the people I live and work with';
            cfg.dataset_description.HowToAcknowledge    = 'a hand-written letter will suffice';
            cfg.dataset_description.Funding             = 'string or cell-array of strings';
            cfg.dataset_description.ReferencesAndLinks  = {'https://www.fieldtriptoolbox.org/tutorial/nirs_multichannel/'};
            cfg.dataset_description.DatasetDOI          = 'string';


            % General BIDS options that apply to all data types are
            cfg.InstitutionName                         = 'Universität Hamburg';
            cfg.InstitutionAddress                      = 'Turmweg 2, 20148 Hamburg';
            cfg.InstitutionalDepartmentName             = 'Bewegungs- und Trainingswissenschaft';
            cfg.Manufacturer                            = 'NirX';
            cfg.ManufacturersModelName                  = 'NIRSport2';
            cfg.DeviceSerialNumber                      = '2320/0631';
            cfg.SoftwareVersions                        = 'Aurora';
            cfg.TaskName                                = cfg.task; % must be identical to cfg.task
            cfg.TaskDescription                         = 'Participants complete a visual discrimination task in various conditions';
            cfg.Instructions                            = 'essen, trinken, extra kauen';
            cfg.CogAtlasID                              = 'tsk_4a57abb9499b8/';
            cfg.CogPOID                                 = 'string';

            % nirs specific fields

            % cfg.nirs.CapManufacturer                   = ft_getopt(cfg.nirs, 'CapManufacturer'                   );
            % cfg.nirs.CapManufacturersModelName         = ft_getopt(cfg.nirs, 'CapManufacturersModelName'         );
            % cfg.nirs.SamplingFrequency                 = ft_getopt(cfg.nirs, 'SamplingFrequency'                 );
            % cfg.nirs.NIRSChannelCount                  = ft_getopt(cfg.nirs, 'NIRSChannelCount'                  );
            % cfg.nirs.NIRSSourceOptodeCount             = ft_getopt(cfg.nirs, 'NIRSSourceOptodeCount'             );
            % cfg.nirs.NIRSDetectorOptodeCount           = ft_getopt(cfg.nirs, 'NIRSDetectorOptodeCount'           );
            % cfg.nirs.ACCELChannelCount                 = ft_getopt(cfg.nirs, 'ACCELChannelCount'                 );
            % cfg.nirs.GYROChannelCount                  = ft_getopt(cfg.nirs, 'GYROChannelCount'                  );
            % cfg.nirs.MAGNChannelCount                  = ft_getopt(cfg.nirs, 'MAGNChannelCount'                  );
            % cfg.nirs.SourceType                        = ft_getopt(cfg.nirs, 'SourceType'                        );
            % cfg.nirs.DetectorType                      = ft_getopt(cfg.nirs, 'DetectorType'                      );
            % cfg.nirs.ShortChannelCount                 = ft_getopt(cfg.nirs, 'ShortChannelCount'                 );
            % cfg.nirs.NIRSPlacementScheme               = ft_getopt(cfg.nirs, 'NIRSPlacementScheme'               );
            % cfg.nirs.RecordingDuration                 = ft_getopt(cfg.nirs, 'RecordingDuration'                 );
            % cfg.nirs.DCOffsetCorrection                = ft_getopt(cfg.nirs, 'DCOffsetCorrection'                );
            % cfg.nirs.HeadCircumference                 = ft_getopt(cfg.nirs, 'HeadCircumference'                 );
            % cfg.nirs.HardwareFilters                   = ft_getopt(cfg.nirs, 'HardwareFilters'                   );
            % cfg.nirs.SoftwareFilters                   = ft_getopt(cfg.nirs, 'SoftwareFilters'                   );
            % cfg.nirs.SubjectArtefactDescription        = ft_getopt(cfg.nirs, 'SubjectArtefactDescription'        );

            % cfg.coordsystem.NIRSCoordinateSystem                            = ft_getopt(cfg.coordsystem, 'NIRSCoordinateSystem'                           ); % REQUIRED. Defines the coordinate system for the optodes. See Appendix VIII for a list of restricted keywords. If positions correspond to pixel indices in a 2D image (of either a volume-rendering, surface-rendering, operative photo, or operative drawing), this must be "Pixels". For more information, see the section on 2D coordinate systems
            % cfg.coordsystem.NIRSCoordinateUnits                             = ft_getopt(cfg.coordsystem, 'NIRSCoordinateUnits'                            ); % REQUIRED. Units of the _optodes.tsv, MUST be "m", "mm", "cm" or "pixels".
            % cfg.coordsystem.NIRSCoordinateSystemDescription                 = ft_getopt(cfg.coordsystem, 'NIRSCoordinateSystemDescription'                ); % RECOMMENDED. Freeform text description or link to document describing the NIRS coordinate system system in detail (e.g., "Coordinate system with the origin at anterior commissure (AC), negative y-axis going through the posterior commissure (PC), z-axis going to a mid-hemisperic point which lies superior to the AC-PC line, x-axis going to the right").
            % cfg.coordsystem.NIRSCoordinateProcessingDescription             = ft_getopt(cfg.coordsystem, 'NIRSCoordinateProcessingDescription'            ); % RECOMMENDED. Has any post-processing (such as projection) been done on the optode positions (e.g., "surface_projection", "none").



            % get opto
            opto_cfg                                                = ROYAL_getOpto( core_cfg );
            if opto_cfg.skip
                continue
            end
            data                                                    = opto_cfg.data;
            opto_cfg.opto.chantype                                  = data.hdr.chanunit;
            opto_cfg.opto.chanunit                                  = data.hdr.chanunit;
            % opto                                                  = opto_cfg.opto;
            cfg.opto_cfg                                            = opto_cfg;


            % create header
            data.trial{1, 1}(1,:)                                   = []; % why is that annoying stream even there
            data.label(1,:)                                         = [];
            data.hdr.nChans                                         = data.hdr.nChans  -1;
            data.hdr.label(1,:)                                     = [];
            data.hdr.chantype(1,:)                                  = [];
            data.hdr.chanunit(1,:)                                  = [];
            data.hdr.chantype(contains(data.hdr.chantype, 'raw'))   = {   'NIRSCWAMPLITUDE'   };
            data.hdr.chantype(contains(data.hdr.chantype, 'hbo'))   = {   'NIRSCWHBO'         };
            data.hdr.chantype(contains(data.hdr.chantype, 'hbr'))   = {   'NIRSCWHBR'         };
            cfg.hdr                                                 = data.hdr;
 


            % general channel information
            cfg.channels                                = [];
            cfg.channels.name                           = data.hdr.label;                % REQUIRED. Channel name (e.g., MRT012, MEG023)
            cfg.channels.type                           = data.hdr.chantype;             % REQUIRED. Type of channel; MUST use the channel types listed below.
            cfg.channels.units                          = data.hdr.chanunit;             % REQUIRED. Physical unit of the data values recorded by this channel in SI (see Appendix V: Units for allowed symbols).


            % nirs specific channel information
            cfg.channels.source                         = opto_cfg.source;
            cfg.channels.detector                       = opto_cfg.detector;
            cfg.channels.wavelength_nominal             = opto_cfg.wavelength;
            cfg.channels.wavelength_actual              = opto_cfg.wavelength;
            cfg.channels.sampling_frequency             = opto_cfg.sampling_frequency;
            % cfg.channels.wavelength_emission_actual   = ...
            % cfg.channels.short_channel                = ...


            cfg.core_cfg                                = core_cfg;


            ROYAL_data2bids(cfg, data)
        end
    end
end