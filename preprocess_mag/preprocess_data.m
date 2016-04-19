
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
    
    event_logs = load([input_dir filename '.app_time_processed.txt']);%time, label
    event_types = unique(sort(event_logs(:,2)));

    fprintf('  sample events: %dx%d\n', size(event_logs,1));
    fprintf('  # event types: %d\n', length(event_types));
    
    
    %% --------------------
    %% Read Event Label
    %% --------------------
    valueSet =   {'PowerPoint', 'Word', 'Excel', 'Chrome', 'Skype','QuickTimePlayer'};
    keySet = 0:5;
    
    AppObj = containers.Map(keySet,valueSet);
    fprintf('Paused. Press any button to continue, or Ctr+C to stop\n');
    pause
    
    %% --------------------
    %% Read Mag
    %% --------------------
    if DEBUG2, fprintf('Read Mag\n'); end   
    for app_id = 1:length(event_types) % elments in event_types start from 0
        key = event_types(app_id);
        appName = AppObj(key);
        id = sort(find(event_logs(:,2) == key));%event_logs: open_time, label
        open_times = event_logs(id,1);
        open_times(:,1) = open_times(:,1) - open_times(1,1);
        
        mags = load([input_dir filename '_' appName '.mag_processed.txt']);
        
        mags(1,1)
        mags(end,1)
        pause
        
        mags(:,1) = mags(:,1) - mags(1,1);
        frequency(end+1) = size(mags,1) / mags(end,1);
       
        %%tmp variables
        tmp_app_mags    = {};
        tmp_app_times   = {};
        
        %% -----------------
        %% Find Start Index
        %% -----------------
        
        std_start_id = get_start_id(mags);
        std_event_time = mags(std_start_id);
        open_times(:, 1) = open_times(:, 1) + std_event_time;
            
        tmp_mag_time = [];
        tmp_mag_time(:,1) = unique(sort([open_times(:,1); mags(:,1)]));%interpolated time
            
        %% -----------------
        %% Interpolation
        %% ------------------
        
        [t, index] = unique(sort(mags(:,1)),'first');
        
        for mi = 2:4       
            tmp_mag_time(:,mi) = interp1(mags(index,1), mags(index,mi), tmp_mag_time(:,1));
        end            
        new_mags = tmp_mag_time;
        %size(new_mags)
                       
        %% ----------------
        %% Find Event
        %% ----------------
            
        for ti = 1:size(open_times,1)
            open_time = open_times(ti, 1);
            range_idx = find(new_mags(:,1) >= open_time & new_mags(:,1) <= (open_time+appInterval));
            
    
            %fprintf('Paused, press any key to continue or use Ctrl-C to stop\n');
            %pause;
            
                app_mag = new_mags(range_idx,:);
            
                app_mag(:,1) = app_mag(:,1) - app_mag(1,1); 
            
                %disp('normalize the log info')                
                for mi = 2:4
                    app_mag(:,mi) = app_mag(:,mi) - min(app_mag(:,mi));
                end   
            
                app_mag(:,5) = sqrt(app_mag(:,2).^2 + app_mag(:,3).^2 + app_mag(:,4).^2);
                app_mag(:,5) =  app_mag(:,5)- min(app_mag(:,5));
                app_mag(:,5) = app_mag(:,5) / max(app_mag(:,5));
 
                   
               %add this sequence to the collected set
                tmp_app_mags{end+1} = app_mag(:,5);
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
        frequency
        frequency = mean(frequency);
        fprintf('\nSensor Frequency:\t%f\n',frequency);
    end
end
function start_id =  get_start_id(stuff)
    start_id = 1;
end