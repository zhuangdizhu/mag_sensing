%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Yi-Chao Chen @ UT Austin
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function preprocess_app(filename)

    input_dir  = '../collect/gen/';
    output_dir = '../preprocess_mag/data/';


    %% --------------------
    %% Variable
    %% --------------------
     DEBUG2 = 1;
    fig_idx = 0;
    appMags = {};
    app_type_s = {};
    appInterval = 4;
    endInterval = 8;

    %% --------------------
    %% Check input
    %% --------------------
    if nargin < 1, filename = '20160529.exp01';end

    %% --------------------
    %% Main starts
    %% --------------------

    %% --------------------
    %% Read Event Time
    %% --------------------
    if DEBUG2, fprintf('Read Event Time\n'); end

    event_time = load([input_dir filename '.app_time_processed.txt']);
    event_time(:,1) = event_time(:,1) - event_time(1,1);    
    events = unique(sort(event_time(:,2)));

    fprintf('  size: %dx%d\n', size(event_time));
    fprintf('  # events: %d\n', length(events));
    fprintf('  duration: %fs\n', event_time(end,1));


    %% --------------------
    %% Read Mag
    %% --------------------
    if DEBUG2, fprintf('Read Mag\n'); end

    mags = load([input_dir filename '.mag_processed.txt']);
    
    if size(mags,1) < 1
        fprintf('Vacant File.\n');
        return
    end
    %time shift
    mags(:,1) = mags(:,1) - mags(1,1);
    fs = size(mags,1) / mags(end,1);    
    
    %sythesized signal
    mags(:,5) = sqrt(mags(:,2).^2 + mags(:,3).^2 + mags(:,4).^2);
    fprintf('  size: %dx%d\n', size(mags));
    fprintf('  duration: %fs\n', mags(end,1));
    fprintf('  freq: %fHz\n', fs);
    fprintf('Magnetic data loaded, press any key to continue or use Ctrl-C to stop\n');
    pause;
    %%%%%%
    
    %% PLOT
    fig_idx = fig_idx + 1;
    fh = figure(fig_idx); clf;
    plot(mags(:,1), mags(:,5), '-r.');
    hold on;
    plot(mags(:,1), mags(:,2), '-b.');
    plot(mags(:,1), mags(:,3), '-g.');
    plot(mags(:,1), mags(:,4), '-y.');
    xlabel('Sample points');
    ylabel('Magnitude');
    legend('Red: Synthesize Signal', 'Blue: M-X','Green:M-Y','Yellow::M-Z');
    title('EM Magnitued of Raw Data');
    %%%%%%
    fprintf('Raw data ploted, press any key to continue or use Ctrl-C to stop\n');
    pause;
    
    %% Prepocess
    if DEBUG2, fprintf('Preprocess Mag\n'); end
    new_mags = mags;
    for mi = 2:4
        new_mags(:,mi) = new_mags(:,mi) - min(new_mags(:,mi));
    end
    new_mags(:,5) = sqrt(new_mags(:,2).^2 + new_mags(:,3).^2 + new_mags(:,4).^2);

    %% --------------------
    %% Find Start Event
    %% --------------------
    if DEBUG2, fprintf('Find Start Event\n'); end
    ts = new_mags(:,5) - min(new_mags(:,5));
    ts = ts / max(ts);
    std_event_idx = find_first_event(ts, fs, 1);
    std_event_time = mags(std_event_idx);

    tmp = event_time;
    event_time(:, 2:3) = tmp;
    event_time(:, 2) = event_time(:, 2) + std_event_time;
    
    %% --------------------
    %% Interpolation
    %% --------------------
    if DEBUG2, fprintf('Interpolation\n'); end
    tmp = [];
    
    tmp(:,1)= unique(sort([event_time(:,2); new_mags(:,1)])); 
    
    [t, index] = unique(new_mags(:,1));
    %[t, index] = unique(sort(new_mags(:,1)),'first');
    for mi=2:4
    tmp(:,mi) = interp1(new_mags(index,1), new_mags(index,mi), tmp(:,1));
    end
    tmp(:,5) = sqrt(tmp(:,2).^2 + tmp(:,3).^2 + tmp(:,4).^2);

    tmp(:,6) = tmp(:,5)-min(tmp(:,5));
    tmp(:,6) = tmp(:,5)/max(tmp(:,5));
    new_mags = tmp;
    
    %% --------------------
    %% Find Event Index
    %% --------------------
    if DEBUG2, fprintf('Find Event Index\n'); end

    for ti = 1:size(event_time,1)
        idx = find(new_mags(:,1) == event_time(ti, 2));
        event_time(ti, 1) = idx;
    end
    
    %% --------------------
    %% Plot Mag
    %% --------------------
    if DEBUG2, fprintf('Preprocess Mag\n'); end
    
    fig_idx = fig_idx + 1;
    fh = figure(fig_idx); clf;
    plot(new_mags(:,1), new_mags(:,5), '-.');
    hold on;
    plot(event_time(:,2), new_mags(event_time(:,1), 5), 'ko');    
    xlabel('Sample points');
    ylabel('Magnitude');
    legend('Synthesize Signal', 'Event Start Time');
    title('EM Magnitued of Normalized Data');
    
    fprintf('Interploated and normalized data, press any key to continue or use Ctrl-C to stop\n');
    pause;
    
    %% --------
    %% Seperate Start Events
    %% --------
    for i = 1:size(events,1)
        appMags{i} = {};
    end
    
    for ti = 1:size(event_time,1)
        
        curr_time = event_time(ti, 2);
        event_type = event_time(ti, 3)+1;
        range_idx = find(new_mags(:,1) >= curr_time & new_mags(:,1) <= (curr_time + appInterval));

        mag_traces = new_mags(range_idx,[1,6]); 
        for mi = 1:2
            mag_traces(:,mi)=mag_traces(:,mi)-min(mag_traces(:,mi));
        end
        mag_traces(:,2)=mag_traces(:,2)/max(mag_traces(:,2));
        
        appMags{event_type}{end+1} = mag_traces;
        %length(mag_traces)
        %mag_traces(end,1)
    end
    appTypes = events;
    save ([output_dir filename '_single_app.mat'], 'appMags', 'appTypes','-mat');
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
        score(idx) = max(a1/a2,a2/a1);
    end

    score = score - min(score);
    score = score / max(score);

    % [~,idx] = max(score);
    idx = find(score > 0.45);
    idx = idx(1);

    idx = idx + manual_offset();


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
function [offset] = manual_offset()
    offset = 0;
end