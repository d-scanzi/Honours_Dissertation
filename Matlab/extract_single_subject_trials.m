%%%%% Extract single trial data for each participant
% The EEG file for the subject needs to be open in EEG lab
% It does not loop through the folder containing all the participants data

%% Information regarding the specific data
wmcgroup    = 'low' %either hig or low
participant = EEG.filename(1:5);
savedir     = strcat('C:\\Users\\Daniele\\Desktop\\FinalProcessing\\StatAnalysis\\Subject_Single_Trials\\SingleTrial_CentralTask\\SingleTrial_Central_Low\\', participant, '_SingleTrial_Central_TARGET.csv');
%% Channel UR location (to account for variability across datasets)
chan58_ur = 61;
chan96_ur = 99;

% Find associated row number
chan58_row = find([EEG.chanlocs(:).urchan] == chan58_ur);
chan96_row = find([EEG.chanlocs(:).urchan] == chan96_ur);

% Info needed
trial_info       = {'TargetPosition', 'TargetOrientation', 'TargetColour', 'DistractorPosition', 'DistractorType', 'DistractorColour', 'block'};
tmpnts           = EEG.times;
distractor_right = [2 3 4 5 6 7 8];
distractor_left  = [10 11 12 13 14 15 16];


tmpnts_epoch      = strings(length(tmpnts) + 1, 1);
tmpnts_epoch(1,1) = 'Electrode'; 

for t = 1:length(tmpnts)
    n = int2str(tmpnts(t));
    tmpnts_epoch(t+1,1) = n;
end

%% Extract data from a single channel
chan58_data = squeeze(EEG.data(chan58_row, :, :))'; % Trials x Time
chan96_data = squeeze(EEG.data(chan96_row, :, :))'; % Trials x Time

% Add channel name
chan58_name = strings(size(chan58_data, 1), 1);
chan58_name(:) = deal('P58');

chan96_name = strings(size(chan96_data, 1), 1);
chan96_name(:) = deal('P96');

chan58_data = [chan58_name chan58_data];
chan96_data = [chan96_name chan96_data];

% Convert to table
chan58_data = array2table(chan58_data);
chan96_data = array2table(chan96_data); 

% Change time names to correct time points in epoch (ms)
chan58_data = renamevars(chan58_data, 1:width(chan58_data),  tmpnts_epoch);
chan96_data = renamevars(chan96_data, 1:width(chan96_data),  tmpnts_epoch);

%% Add trial information
trial_info_dataALL = struct2table(EEG.event);
trial_info_data    = trial_info_dataALL(:, trial_info);

%% Join tables
chan58_complete = [trial_info_data chan58_data];
chan96_complete = [trial_info_data chan96_data];

data_all = [chan58_complete; chan96_complete];

%% Add relative position of electrode to stimulus (ipsi vs contra)

% Create array to store the values
electrode_position = strings(size(data_all, 1), 1);

for row = 1:size(data_all,1)
    
    % Check if disractor is on the rigth
    if (ismember(data_all{row, 'DistractorPosition'}, distractor_right)) && (data_all{row, 'Electrode'} == 'P58')
        
        electrode_position(row, 1) = 'contra';
        
    elseif (ismember(data_all{row, 'DistractorPosition'}, distractor_left)) && (data_all{row, 'Electrode'} == 'P58')
        
        electrode_position(row, 1) = 'ipsi';
        
    elseif (ismember(data_all{row, 'DistractorPosition'}, distractor_right)) && (data_all{row, 'Electrode'} == 'P96')
        
        electrode_position(row, 1) = 'ipsi';
        
    else 
        
        electrode_position(row, 1) = 'contra';
        
    end
end

data_all = addvars(data_all, electrode_position, 'After', 'Electrode');

%% Add wmc info and particioant
wmc_column = strings(size(data_all, 1), 1);
wmc_column(:, 1) = deal(wmcgroup);

data_all = addvars(data_all, wmc_column, 'After', 'electrode_position');

part_column = strings(size(data_all, 1), 1);
part_column(:, 1) = deal(participant(1:3));

data_all = addvars(data_all, part_column, 'Before', 'TargetPosition');
    
%% Save Dataset
writetable(data_all, savedir, 'Delimiter', ',')
    
    