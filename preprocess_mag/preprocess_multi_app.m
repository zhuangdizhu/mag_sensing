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

function preprocess_multi_app(filename)
    % addpath('../utils');

    %% --------------------
    %% DEBUG
    %% --------------------
    DEBUG0 = 0;
    DEBUG1 = 0;
    DEBUG2 = 1;     %% progress
    DEBUG3 = 1;     %% verbose
    DEBUG4 = 1;     %% results
    DEBUG5 = 1;     %% PLOT

    %% --------------------
    %% Constant
    %% --------------------
    input_dir  = '../collect/gen/';
    output_dir = '../preprocess_mag/data/';


    %% --------------------
    %% Variable
    %% --------------------
    fig_idx = 0;
    appInterval = 8;
    endInterval = 2;
    multi_app_mag_s = {};
    app_type_s      = {};

    %% --------------------
    %% Check input
    %% --------------------
    if nargin < 1, filename = '20160420.exp02'; end
    %% --------------------
    %% Main starts
    %% --------------------

    %% --------------------
    %% Read Event Time
    %% --------------------
    if DEBUG2, fprintf('Read Event Time\n'); end

    event_time = load([input_dir filename '.multi_app_time_processed.txt']);
    event_time(:,1) = event_time(:,1) - event_time(1,1);

    %end_time = load([input_dir filename '.multi_app_close_time_processed.txt']);   
    %end_time(:,1) = end_time(:,1) -  end_time(1,1);
    
    
    
    first_events = unique(sort(event_time(:,2)));
    next_events = first_events+1;
    fprintf('  size: %dx%d\n', size(event_time));
    fprintf('  # events: %d\n', length(first_events));
    fprintf('  duration: %fs\n', event_time(end,1));


    %% --------------------
    %% Read Mag
    %% --------------------
    if DEBUG2, fprintf('Read Mag\n'); end

    mags = load([input_dir filename '.multi_mag_processed.txt']);
    mags(:,1) = mags(:,1) - mags(1,1);
    frequency = size(mags,1) / mags(end,1);
    mags(:,5) = sqrt(mags(:,2).^2 + mags(:,3).^2 + mags(:,4).^2);

    fprintf('  size: %dx%d\n', size(mags));
    fprintf('  duration: %fs\n', mags(end,1));
    fprintf('  freq: %fHz\n', frequency);
    fprintf('Paused, press any key to continue or use Ctrl-C to stop\n');
    pause;
    %% %%%%
    %% PLOT
    %% %%%%
    if DEBUG5 == 1
        fig_idx = fig_idx + 1;
        fh = figure(fig_idx); clf;
        plot(mags(:,1), mags(:,5), '-r.');
        hold on;
        plot(mags(:,1), mags(:,2), '-b.');
        plot(mags(:,1), mags(:,3), '-g.');
        plot(mags(:,1), mags(:,4), '-y.');
        xlabel('Sample points');
        ylabel('Magnitude');
        legend('Red: Synthesize Signal','Blue: M-X','Green:M-Y','Yellow::M-Z');
        title('EM Magnitued of Raw Data');
    end
    %%%%%%
  

    %% --------------------
    %% Preprocess Mag
    %% --------------------
    if DEBUG2, fprintf('Preprocess Mag\n'); end

    new_mags = mags;
    for mi = 2:4
        new_mags(:,mi) = new_mags(:,mi) - min(new_mags(:,mi));
    end
    new_mags(:,5) = sqrt(new_mags(:,2).^2 + new_mags(:,3).^2 + new_mags(:,4).^2);


    %% --------------------
    %% Find Start and End Event
    %% --------------------
    if DEBUG2, fprintf('Find Start Event\n'); end

    ts = new_mags(:,5) - min(new_mags(:,5));
    ts = ts / max(ts);
    
    std_event_idx = find_first_event(ts, frequency, 1);
    std_event_idx = std_event_idx + manual_offset(filename);
    std_event_time = new_mags(std_event_idx);

    event_time(:, 1) = event_time(:, 1) + std_event_time;
    %end_time(:,1) = end_time(:,1) + std_event_time + appInterval;
    

    %% --------------------
    %% Interpolation
    %% --------------------
    if DEBUG2, fprintf('Interpolation\n'); end

    tmp = [];
    tmp(:,1) = unique(sort([event_time(:,1); new_mags(:,1)]));%interpolated time
    %%%%%tmp(:,1) = unique(sort([event_time(:,1); end_time(:,1); new_mags(:,1)]));
    %Funciton "interp1" requires the first parameter to be strictly monotonic increasing.
    % find the index of the strict-increasing time 
    [t, index] = unique(sort(new_mags(:,1)),'first');
        
    for mi = 2:4
        tmp(:,mi) = interp1(new_mags(index,1), new_mags(index,mi), tmp(:,1));
        tmp(:,mi) = tmp(:,mi) - min(tmp(:,mi));%%%%%different from single mode
    end

    tmp(:,5) = sqrt(tmp(:,2).^2 + tmp(:,3).^2 + tmp(:,4).^2);
    tmp(:,6) = tmp(:,5) - min(tmp(:,5));
    tmp(:,6) = tmp(:,6) / max(tmp(:,6));
    new_mags = tmp;
    


    %% --------------------
    %% Find Event Index
    %% --------------------
    if DEBUG2, fprintf('Find Event Index\n'); end

    for ti = 1:size(event_time,1)
        idx = find(new_mags(:,1) == event_time(ti, 1));
        event_time(ti, 4) = idx;
    end
    %%%%%%
        
    %for ti = 1:size(end_time,1)
    %    idx = find(new_mags(:,1) == end_time(ti,1));
    %    end_time(ti,4) = idx;
    %end
    %%%%%%
    
    fprintf('Paused, press any key to continue or use Ctrl-C to stop\n');
    pause;
    
    
    %% PLOT
    fig_idx = fig_idx + 1;
    fh = figure(fig_idx); clf;
    plot(new_mags(:,1), new_mags(:,5), '-r.');
    hold on;
    plot(new_mags(:,1), new_mags(:,2), '-b.');
    plot(new_mags(:,1), new_mags(:,3), '-g.');
    plot(new_mags(:,1), new_mags(:,4), '-y.');

    plot(event_time(:,1), new_mags(event_time(:,4), 5), 'ko');
    xlabel('Sample points');
    ylabel('Magnitude');
    title('EM Signal of Interpolated Data');
    legend('Red: Synthesize Signal','Blue: M-X','Green:M-Y','Yellow::M-Z');

    %dlmwrite([output_dir filename '.multi_mag.txt'], [new_mags(:, [1,6])], 'delimiter', '\t');
    %dlmwrite([output_dir filename '.multi_app_time.txt'], [event_time], 'delimiter', '\t');
   
    
    %% --------
    %% Seperate Events
    %% --------
    for i = 1:size(first_events,1)
        multi_app_mag_s{i} = {};
    end
    
    for ti = 1:size(event_time,1)
        
        curr_time = event_time(ti, 1);
        first_event_type = event_time(ti, 2);
        range_idx = find(new_mags(:,1) >= curr_time & new_mags(:,1) <= (curr_time + appInterval));

        mag_traces = new_mags(range_idx,:);
        
        for mi=1:4
            mag_traces(:,mi) = mag_traces(:,mi) - min(mag_traces(:,mi));
        end

        mag_traces(:,5) = sqrt(mag_traces(:,2).^2 + mag_traces(:,3).^2 + mag_traces(:,4).^2);
        mag_traces(:,6) = mag_traces(:,5) - min(mag_traces(:,5));
        mag_traces(:,6) = mag_traces(:,6) / max(mag_traces(:,6));
        
        multi_app_mag_s{first_event_type+1}{end+1} = mag_traces;
    end
    
    %% ---------------
    %% Seperate End Events
    %% ---------------
    if DEBUG1 == 1
    for i = 1:size(first_events,1)
        multi_end_mag_s{i} = {};
    end
    
    for ti = 1:size(end_time,1)
        
        curr_time = end_time(ti, 1);
        first_event_type = end_time(ti, 2);
        
        range_idx = find(new_mags(:,1) >= curr_time & new_mags(:,1) <= (curr_time + endInterval));

        mag_traces = new_mags(range_idx,:);
        %% --normalization
        for mi=1:4
            mag_traces(:,mi) = mag_traces(:,mi) - min(mag_traces(:,mi));
        end
        mag_traces(:,5) = sqrt(mag_traces(:,2).^2 + mag_traces(:,3).^2 + mag_traces(:,4).^2);
        mag_traces(:,6) = mag_traces(:,5) - min(mag_traces(:,5));
        mag_traces(:,6) = mag_traces(:,6) / max(mag_traces(:,6));
        
        multi_end_mag_s{event_type+1}{end+1} = mag_traces;
    end
    end
    
    multi_app_type_s = first_events;
    save ([output_dir filename '_multi_app.mat'], 'multi_app_mag_s', 'multi_app_type_s','-mat');
    %save ([output_dir filename '_multi_app.mat'], 'multi_app_mag_s', 'multi_end_mag_s', 'multi_app_type_s','-mat');
end


function [idx] = find_first_event(ts, fs, fig_idx)
    if nargin < 2, fig_idx = -1; end

    win = 10;
    range = floor(5 * fs);
    score = zeros(1,range);

    a1 = sum(ts(1:win));
    a2 = sum(ts((win+1):(2*win)));
    score(win) = a2 / a1;
    for idx = win+1:range
        a1 = a1 - ts(idx-win) + ts(idx);
        a2 = a2 - ts(idx) + ts(idx+win);
        score(idx) = a2 / a1;
    end

    score = score - min(score);
    score = score / max(score);

    % [~,idx] = max(score);
    idx = find(score > 0.6);
    idx = idx(1);



    if fig_idx > 0
        fh = figure(fig_idx); clf;
        plot(ts(1:range), '-b.');
        hold on;
        plot(score, '-g.');
        plot(idx, ts(idx), 'ro');
        xlabel('Sample points');
        ylabel('Magnitude');
        title('Seperate Event');
        legend('Blue: EM Magnitude','Green:Score','RO:Start Index');
    end


end

%% manual_offset: function description
function [offset] = manual_offset(filename)
    if strcmp(filename, '041801')
        offset = 20;
    else
        offset = 0;
    end
end