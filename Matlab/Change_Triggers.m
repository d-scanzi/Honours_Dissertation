%%% Remove usless triggers

%% Remove triggers that are not going to be used

% Triggers to be removed
to_remove = {'boundary','bgin', 'SRs1', 'SRs2'};

for row = 1:length(to_remove)
    
    % Create mask 
    to_remove_mask = strcmp({EEG.event.type}, to_remove{row});
    
    % Remove triggers
    EEG.event(to_remove_mask) = [];
    
end

[EEG.event(:).TargetPosition] = deal('');
[EEG.event(:).TargetOrientation] = deal('');  
[EEG.event(:).TargetColour] = deal('');   
[EEG.event(:).DistractorPosition] = deal('');
[EEG.event(:).DistractorType] = deal('');
[EEG.event(:).DistractorColour] = deal('');
[EEG.event(:).DistractorOrientation] = deal('');
[EEG.event(:).TargetDistractorDistance] = deal('');


[EEG.event(:).Block] = deal('');