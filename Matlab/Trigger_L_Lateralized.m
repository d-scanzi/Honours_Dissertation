%% Select triggers (dataset must be loaded manually)

% Save in
save_wd = 'C:\\Users\\Daniele\\Desktop\\FinalProcessing\\Processed_EEGData\\PipeLine\\TEST\\icREMOVED\\LAItask\\HighWMC_LAI\\Lateralized_L';


% Indicate type of block to extract. Either "test" of 'cont'
select_block = 'test';

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
L_codes = {'E', 'F', 'G', 'H', 'I', 'L', 'M', 'N'};
% Select all trigger in which the target is a L and lateralized
L_triggers = {};

%% Set names
% Extract EEG name
current_name = EEG.setname(1:3);

% New Name
new_name = strcat(current_name, '_L_lateralized');
% Save As
save_name = strcat(current_name, '_L_Lateralized.set');

%% Extract L triggers lateralized
for tri = 1:length(all_triggers)
    
    current_trig = all_triggers{tri};
    
    %% Check if trigger is from a LAI trial
    if strcmp(current_trig(1:4), select_block)
    
        % Check if trigger has length of 4
        if length(current_trig) == 8
            % Check if the second to last letter is a code for "L" and if the
            % trigger is not on the midline
            if (any(strcmp(L_codes, current_trig(7)))) && (current_trig(end) ~= '1' && current_trig(end) ~= '9') 
                % If so, add the trigger to list
                L_triggers{end+1} = current_trig;

            end

        else

            % Check if there is a code for L in 3rd position. If a L code is in
            % 4th position then the L must be in position 1 or 9, so no need to
            % include that condition as before
            if any(strcmp(L_codes, current_trig(7)))

                % If so, add the trigger to list
                L_triggers{end+1} = current_trig;
            end

        end 
        
    end

end

L_triggers = unique(L_triggers);
%% Select epochs with distractor on the side

EEG = pop_epoch( EEG, L_triggers, [-0.2         0.8], 'newname', new_name, 'epochinfo', 'yes');
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off'); 
EEG = eeg_checkset( EEG );
EEG = pop_rmbase( EEG, [-200 0] ,[]);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'gui','off'); 
EEG = eeg_checkset( EEG );

eeglab redraw

%% Save dataset
EEG = pop_saveset( EEG, 'filename',save_name,'filepath',save_wd);
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);