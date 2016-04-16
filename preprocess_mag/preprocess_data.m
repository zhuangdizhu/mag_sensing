
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Yi-Chao Chen @ UT Austin
%%
%% - Input:
%%
%%
%% - Output:
%%
%%
%% example:
%%   separate_events('20160327.exp2')
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function preprocess_data(filename)
    % addpath('../utils');

    %% --------------------
    %% DEBUG
    %% --------------------
    DEBUG0 = 0;
    DEBUG1 = 1;
    DEBUG2 = 1;  %% progress
    DEBUG3 = 1;  %% verbose
    DEBUG4 = 1;  %% results


    %% --------------------
    %% Constant
    %% --------------------
    input_dir  = '../collect/gen/';
    output_dir = '../preprocess_mag/data/';
    appInterval = 6;

    %% --------------------
    %% Variable
    %% --------------------
    fig_idx = 0;
    app_mag_s    = {};
    app_time_s   = {};
    frequency = [];
    %% --------------------
    %% Check input
    %% --------------------
    if nargin < 1
        filename = '0414'; 
    end


    %% --------------------
    %% Main starts
    %% --------------------

    %% --------------------
    %% Read Event Time
    %% --------------------
    if DEBUG2, fprintf('Read Event Time\n'); end
    
    event_logs = load([input_dir filename '.app_time_processed.txt']);
    event_types = unique(sort(event_logs(:,1)));

    fprintf('  sample events: %dx%d\n', size(event_logs,1));
    fprintf('  # event types: %d\n', length(event_types));
    
    %In future, the appName and related class label shoud be written into
    % a configuration file, and both the preprocess_data.py &
    % preprocess_data.m read the configuration info.
    valueSet =   {'PowerPoint', 'Word', 'Excel', 'Chrome', 'Skype','QuickTimePlayer'};
    keySet = 0:5;
    
    AppObj = containers.Map(keySet,valueSet);
    fprintf('Paused. Press any button to continue, or Ctr+C to stop\n');
    pause
    
    %% --------------------
    %% Read Mag
    %% --------------------
    if DEBUG2, fprintf('Read Mag\n'); end
   
    
    for idx = 1:length(event_types) % elments in event_types start from 0
        key = event_types(idx);
        appName = AppObj(key);
        id = sort(find(event_logs(:,1) == key));
        event_indexs = event_logs(id,2);
        
        mags = load([input_dir filename '_' appName '.mag_processed.txt']);
        %event_logs
       
        %%tmp variables
        tmp_app_mags    = {};
        tmp_app_times   = {};
        %event_begin_idx = 1;

        for i = 1:length(event_indexs)
            
            if i>1
                startIndex = event_indexs(i-1)+1;
            else
                startIndex = 1;
            end
            endIndex = event_indexs(i);
            timeInterval = mags(endIndex,1) - mags(startIndex,1);
            if timeInterval > appInterval
                stdEndTime = mags(startIndex,1) + appInterval;
                endIndex = find(abs(mags(:,1) - stdEndTime) == min(abs(mags(:,1) - stdEndTime)));
            end
            app_mag = mags(startIndex:endIndex,:);
            app_mag(:,1) = app_mag(:,1) - min(app_mag(:,1)); 
            frequency(end+1) = size(app_mag,1)/app_mag(end,1);
            
            %disp('normalize the log info')                
            for mi = 2:4
                app_mag(:,mi) = app_mag(:,mi) - min(app_mag(:,mi));
            end                    
            app_mag(:,6) = sqrt(app_mag(:,2).^2 + app_mag(:,3).^2 + app_mag(:,4).^2);
            app_mag(:,6) =  app_mag(:,6)- min(app_mag(:,6));
            app_mag(:,6) = app_mag(:,6) / max(app_mag(:,6));
                    
           %add this sequence to the collected set
            tmp_app_mags{end+1} = app_mag(:,6);
            tmp_app_times{end+1} = app_mag(:,1);
        end
        
        
        app_mag_s{key+1}     = tmp_app_mags; %key starts from 0
        app_time_s{key+1}    = tmp_app_times;        
    end
    app_type_s = event_types;
    
    save ([output_dir filename '.mat'], 'app_mag_s','app_time_s', 'app_type_s','-mat');
    
    if DEBUG2
        fprintf('Read Mag Finished\n'); 
        fprintf('Collected from Apps:\n ');
        for i = 1:length(event_types)
            fprintf('%s\t',AppObj(event_types(i)));
        end
        frequency = mean(frequency);
        fprintf('\nSensor Frequency:\t%f\n',frequency);
    end
end