%% Select triggers (dataset must be loaded manually)

% Save in
save_wd = 'C:\\Users\\Daniele\\Desktop\\FinalProcessing\\Processed_EEGData\\PipeLine\\TEST\\icREMOVED\\LAItask\\HighWMC_LAI\\Lateralized_T';

% Indicate type of block to extract. Either "test" of 'cont'
select_block = 'test';

%% Set names
% Extract EEG name
current_name = EEG.setname(1:3);

% New Name
new_name = strcat(current_name, '_T_lateralized');
% Save As
save_name = strcat(current_name, '_T_Lateralized.set');

%% Modify triggers so to distinguish between LAI tasks and Control Tasks
for row = 1:length(EEG.event)
    
    % Check if the trial is a LAI task
    if strcmp(EEG.event(row).Block, 'BlockLAI')
        
        % If so, add 'test' to onset of the trigger
        EEG.event(row).type = strcat('test', EEG.event(row).type);
        
    else
        
       % Otherwise add 'cont' for control (central task)
        EEG.event(row).type = strcat('cont', EEG.event(row).type); 
        
    end
    
end

%% Extract all triggers in the current eeg datafile
all_triggers = {EEG.event.type};
trig_numb = {'0', '1', '2', '3', '4', '5', '6'};
% Select all trigger in which the target lateralized
T_triggers = {};


%% Extract T triggers lateralized
for tri = 1:length(all_triggers)
    
    current_trig = all_triggers{tri};
    
    %% Check if trigger is from a LAI trial
    if strcmp(current_trig(1:4), select_block)
        
        %% If so, continue the process to select only triggers in which the
        % Target is lateralized
    
        % Check if trigger has length of 8
        if length(current_trig) == 8
            % Check if the second value is different from 0 and 9 which means
            % that the target was not on the midline
            if current_trig(6) ~= '1' && current_trig(6) ~= '9' 
                % If so, add the trigger to list
                T_triggers{end+1} = current_trig;

            end

        else

            % Check if the third value of the trigger is a number between 0 and
            % 6. This means that the target was in position 10 to 11
            if any(strcmp(trig_numb, current_trig(7)))

                % If so, add the trigger to list
                T_triggers{end+1} = current_trig;
            end

        end 
    end

end

T_triggers = unique(T_triggers);
%% Select epochs with distractor on the side

EEG = pop_epoch( EEG, T_triggers, [-0.2         0.8], 'newname', new_name, 'epochinfo', 'yes');
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off'); 
EEG = eeg_checkset( EEG );
EEG = pop_rmbase( EEG, [-200 0] ,[]);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'gui','off'); 
EEG = eeg_checkset( EEG );

eeglab redraw

%% Save dataset
EEG = pop_saveset( EEG, 'filename',save_name,'filepath', save_wd);
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);