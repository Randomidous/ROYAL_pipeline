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
                                                                         
                                                                         
% configurations
clear all
cfg                                     = [];                            
core_cfg                                = [];                            

% folder setup
core_cfg.rootDir                        = 'C:\Users\ericw\Desktop\UHH_fNIRS\study_folder\data'; % Define study folder
core_cfg.sourceDir                      = [ core_cfg.rootDir '\0_source-data' ];                % Define source folder
core_cfg.bidsDir                        = [ core_cfg.rootDir '\1_BIDS-data' ];                  % Define bids folder

% study information
core_cfg.numSubjects                    = 29;                                                   % Define the number of subjects
core_cfg.sessions                       = { 'pre', 'post' };                                    % Define the sessions
core_cfg.tasks                          = { 'baseline', 'STwalking', 'STvisual', 'DTwalking' }; % Define the tasks

% data2bids required
cfg.method                              = 'convert';                                            % string, can be 'decorate', 'copy' or 'convert', default is automatic
cfg.writejson                           = 'replace';                                            % string, 'yes', 'replace', 'merge' or 'no' (default = 'yes')
cfg.writetsv                            = 'replace';                                            % string, 'yes', 'replace', 'merge' or 'no' (default = 'yes')

% marker streams, presentation files etc.
% cfg.presentationfile                    = '         ';
% cfg.markerstreams                       = '         ';

%% GENERAL META DATA
% general metadata shared across all modalities
% will be saved in BIDS-folder/data_description.json

generalInfo = [];

% required for dataset_description.json
generalInfo.dataset_description.Name                = 'name of your data set';
generalInfo.dataset_description.BIDSVersion         = 'version of BIDS-specification you are following'; % if sharing motion data, use "unofficial extension"

% optional for dataset_description.json
generalInfo.dataset_description.License             = 'licence type';
generalInfo.dataset_description.Authors             = {"author 1", "author 2", "author 3"};
generalInfo.dataset_description.Acknowledgements    = 'acknowledgement text';
generalInfo.dataset_description.Funding             = {"funding source 1", "funding source 2"};
generalInfo.dataset_description.ReferencesAndLinks  = {"reference", "link to article"};
generalInfo.dataset_description.DatasetDOI          = 'DOI of your data set';


% % If you specify cfg.bidsroot, this function will also write the dataset_description.json
% % file. You can specify the following fields
% cfg.dataset_description.writesidecar        = 'This is a nice description of the recoreded data. We did an experiment';
% cfg.dataset_description.Name                = '23-channel NIRS measured during visual discrimination task';
% cfg.dataset_description.BIDSVersion         = 'v1.9.0';
% cfg.dataset_description.License             = 'possible license';
% cfg.dataset_description.Authors             = 'Roy Eric Wieske';
% cfg.dataset_description.Acknowledgements    = 'I am thankful for the people I live and work with';
% cfg.dataset_description.HowToAcknowledge    = 'a hand-written letter will suffice';
% cfg.dataset_description.Funding             = 'string or cell-array of strings';
% cfg.dataset_description.ReferencesAndLinks  = {'https://www.fieldtriptoolbox.org/tutorial/nirs_multichannel/'};
% cfg.dataset_description.DatasetDOI          = 'string';

% general information shared across modality specific json files 
generalInfo.InstitutionName                         = 'name of your institute';
generalInfo.InstitutionalDepartmentName             = 'name of your department';
generalInfo.InstitutionAddress                      = 'address of your institute';
generalInfo.TaskDescription                         = 'text describing your task';


% % General BIDS options that apply to all data types are
% cfg.InstitutionName                         = 'Universität Hamburg';
% cfg.InstitutionAddress                      = 'Turmweg 2, 20148 Hamburg';
% cfg.InstitutionalDepartmentName             = 'Bewegungs- und Trainingswissenschaft';
% cfg.Manufacturer                            = 'NirX';
% cfg.ManufacturersModelName                  = 'NIRSport2';
% cfg.DeviceSerialNumber                      = '2320/0631';
% cfg.SoftwareVersions                        = 'Aurora';
% cfg.TaskName                                = cfg.task; % must be identical to cfg.task
% cfg.TaskDescription                         = 'Participants complete a visual discrimination task in various conditions';
% cfg.Instructions                            = 'essen, trinken, extra kauen';
% cfg.CogAtlasID                              = 'tsk_4a57abb9499b8/';
% cfg.CogPOID                                 = 'string';


%% NIRS META DATA
% will be saved in BIDS-folder/sub-XX/[ses-XX]/eeg/*_eeg.json and *_coordsystem.json

nirsInfo     = [];
nirsInfo.coordsystem.NIRSCoordinateSystem           = 'CapTrak';    
nirsInfo.coordsystem.NIRSCoordinateUnits            = 'mm';                                             % only needed when you share eloc
nirsInfo.coordsystem.EEGCoordinateSystemDescription = 'Chose CapTrak because it is RAS with origin between LPA and RPA';    % only needed when you share eloc
nirsInfo.CapManufacturer                   = 'NirX';
nirsInfo.CapManufacturersModelName         = 'NIRSport2';

nirsInfo.nirs.SamplingFrequency                      = 10.172526298127810;                               % nominal sampling frequency  
% nirsInfo.nirs.NIRSChannelCount                  = ft_getopt(cfg.nirs, 'NIRSChannelCount'                  );
% nirsInfo.nirs.NIRSSourceOptodeCount             = ft_getopt(cfg.nirs, 'NIRSSourceOptodeCount'             );
% nirsInfo.nirs.NIRSDetectorOptodeCount           = ft_getopt(cfg.nirs, 'NIRSDetectorOptodeCount'           );
% nirsInfo.nirs.ACCELChannelCount                 = ft_getopt(cfg.nirs, 'ACCELChannelCount'                 );
% nirsInfo.nirs.GYROChannelCount                  = ft_getopt(cfg.nirs, 'GYROChannelCount'                  );
% nirsInfo.nirs.MAGNChannelCount                  = ft_getopt(cfg.nirs, 'MAGNChannelCount'                  );
% nirsInfo.nirs.SourceType                        = ft_getopt(cfg.nirs, 'SourceType'                        );
% nirsInfo.nirs.DetectorType                      = ft_getopt(cfg.nirs, 'DetectorType'                      );
% nirsInfo.nirs.ShortChannelCount                 = ft_getopt(cfg.nirs, 'ShortChannelCount'                 );
% nirsInfo.nirs.NIRSPlacementScheme               = ft_getopt(cfg.nirs, 'NIRSPlacementScheme'               );
% nirsInfo.nirs.RecordingDuration                 = ft_getopt(cfg.nirs, 'RecordingDuration'                 );
% nirsInfo.nirs.DCOffsetCorrection                = ft_getopt(cfg.nirs, 'DCOffsetCorrection'                );
% nirsInfo.nirs.HeadCircumference                 = ft_getopt(cfg.nirs, 'HeadCircumference'                 );
% nirsInfo.nirs.HardwareFilters                   = ft_getopt(cfg.nirs, 'HardwareFilters'                   );
% nirsInfo.nirs.SoftwareFilters                   = ft_getopt(cfg.nirs, 'SoftwareFilters'                   );
% nirsInfo.nirs.SubjectArtefactDescription        = ft_getopt(cfg.nirs, 'SubjectArtefactDescription'        );


%% SUBJECT META DATA

% here describe the fields in the participant file
% see "https://bids-specification.readthedocs.io/en/stable/03-modality-agnostic-files.html#participants-file:~:text=UTF%2D8%20encoding.-,Participants%20file,-Template%3A"
% for numerical values  : 
%       subjectData.fields.[insert your field name here].Description    = 'describe what the field contains';
%       subjectData.fields.[insert your field name here].Unit           = 'write the unit of the quantity';
% for values with discrete levels :
%       subjectData.fields.[insert your field name here].Description    = 'describe what the field contains';
%       subjectData.fields.[insert your field name here].Levels.[insert the name of the first level] = 'describe what the level means';
%       subjectData.fields.[insert your field name here].Levels.[insert the name of the Nth level]   = 'describe what the level means';
%--------------------------------------------------------------------------

% subjectInfo = [];
% subjectInfo.fields.nr.Description       = 'numerical ID of the participant'; 
% subjectInfo.fields.age.Description      = 'age of the participant'; 
% subjectInfo.fields.age.Unit             = 'years'; 
% subjectInfo.fields.sex.Description      = 'sex of the participant'; 
% subjectInfo.fields.sex.Levels.M         = 'male'; 
% subjectInfo.fields.sex.Levels.F         = 'female'; 
% subjectInfo.fields.handedness.Description    = 'handedness of the participant';
% subjectInfo.fields.handedness.Levels.R       = 'right-handed';
% subjectInfo.fields.handedness.Levels.L       = 'left-handed';

% names of the columns - 'nr' column is just the numerical IDs of subjects
%                         do not change the name of this column
% subjectInfo.cols = {'nr',   'age',  'sex',  'handedness'};
% subjectInfo.data = {1,     30,     'F',     'R' ; ...
%                     2,     22,     'M',     'R'; ...
%                     3,     23,     'F',     'R'; ...
%                     4,     34,     'M',     'R'; ...
%                     5,     25,     'F',     'R'; ...
%                     6,     21,     'F',     'R' ; ...
%                     7,     28,     'M',     'R'; ...
%                     8,     28,     'M',     'R'; ...
%                     9,     24,     'F',     'R'; ...
%                     10,    25,     'F',     'L'; ...
%                     11,    30,     'F',     'R'; ...
%                     12,    22,     'M',     'R'; ...
%                     13,    23,     'F',     'R'; ...
%                     14,    34,     'M',     'R'; ...
%                     15,    25,     'F',     'R'; ...
%                     16,    21,     'F',     'R' ; ...
%                     17,    28,     'M',     'R'; ...
%                     18,    28,     'M',     'R'; ...
%                     19,    24,     'F',     'R'; ...
%                     20,    25,     'F',     'L';};


%% MOTION META DATA

%% PHYSIO META DATA



%% data2bids specifications
for subj                                = 1:core_cfg.numSubjects

    cfg.subject                         = subj;
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


            xdffilename                 = [subjectID '_' sessionID '_' taskID '.xdf'];
            cfg.dataset                 = xdffilename;
            cfg.filename                = [ directory '\' xdffilename ];

            % skip if file doesn't exist
            if ~exist(xdffilename)  
                continue
            end

            % the following settings relate to the directory structure and file names
            cfg.bidsroot                = core_cfg.bidsDir;
            cfg.sub                     = num2str(subj);
            cfg.session                 = core_cfg.sessions{sess};
            cfg.task                    = taskID;
            cfg.datatype                = 'nirs';
            % cfg.run                   = [1];
            % cfg.events                = trial definition (see FT_DEFINETRIAL) or event structure (see FT_READ_EVENT)

            % For NIRS data you can specify an optode definition according to
            % FT_DATATYPE_SENS as an "opto" field in the input data, or you can specify
            % it as cfg.opto or you can specify a filename with optode information.



            % nirs metadata
            cfg.nirs                                    = [];
            cfg.nirs.stream_name                        = 'Aurora';



            % get opto
            opto_cfg                                                = ROYAL_getOpto( core_cfg );
            if isempty(opto_cfg) || opto_cfg.skip
                continue
            end

            opto_cfg.data.trial{1, 1}(1, :)                         = [];
            data                                                    = opto_cfg.data;
            data.hdr.chanunit(1,:)                                  = [];   % I do not like that this is hardcoded
            data.hdr.chantype(1,:)                                  = [];   % I do not like that this is hardcoded
            opto_cfg.opto.chanunit                                  = data.hdr.chanunit;
            opto_cfg.opto.chantype                                  = data.hdr.chantype; 
            cfg.opto_cfg                                            = opto_cfg;


            % create header
            data.trial{1, 1}(1,:)                                   = [];                   % why is that annoying stream even there
            data.label(1,:)                                         = [];                   % I do not like that this is hardcoded
            data.hdr.nChans                                         = data.hdr.nChans  -1;  % I do not like that this is hardcoded
            data.hdr.label(1,:)                                     = [];                   % I do not like that this is hardcoded
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

            BIDS_config                                 = cfg;
            BIDS_config.bids_target_folder              = fullfile( core_cfg.bidsDir ); % , subjectID, sessionID );
            
            ROYAL_xdf2bids(BIDS_config, ...
                'nirs_metadata', nirsInfo, ...
                'general_metadata', generalInfo)
        end
    end
end