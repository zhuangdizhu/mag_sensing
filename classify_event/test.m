%*******************************************************************************
 % Copyright (C) 2013 Francois PETITJEAN, Ioannis PAPARRIZOS
 % This program is free software: you can redistribute it and/or modify
 % it under the terms of the GNU General Public License as published by
 % the Free Software Foundation, version 3 of the License.
 % 
 % This program is distributed in the hope that it will be useful,
 % but WITHOUT ANY WARRANTY; without even the implied warranty of
 % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 % GNU General Public License for more details.well
 % 
 % You should have received a copy of the GNU General Public License
 % along with this program.  If not, see <http://www.gnu.org/licenses/>.
 %*****************************************************************************/ 

% function average = DBA(sequences)
% 	index=randi(length(sequences),1);
% 	average=repmat(sequences{index},1);
% 	for i=1:15
% 		average=DBA_one_iteration(average,sequences);
% 	end
% end
function test(filename)
    % addpath('../utils');
    % Read seperate signals from filename.mat file without handling the 
    %shiftting problem. Use corrcoef as the alignment metric.
    %% --------------------
    %% DEBUG
    %% --------------------
    DEBUG0 = 0;
    DEBUG1 = 1;
    DEBUG2 = 1;  %% progress
    DEBUG3 = 1;  %% verbose
    DEBUG4 = 1;  %% results
    DEBUG5 = 1;  %% DBA


    %% --------------------
    %% Constant
    %% --------------------
    input_dir  = '../preprocess_mag/data/';
    output_dir = './tmp/';
    fig_dir = './fig/';

    font_size = 28;

    %% --------------------
    %% Variable
    %% --------------------
    fig_idx     = 0;
    self_train  = 0;  
    DBA_iteration = 10;
    
    [app_mags, app_times, app_types] = read_mat_input(input_dir,filename);
    %[app_mags, app_times, app_types] = read_traditional_input(input_dir, filename);
     
    confusionMatrix     = zeros(max(app_types)+1);
    corrMatrix          = zeros(max(app_types)+1);
    countMatrix         = zeros(max(app_types)+1);
    
    
    %% --------------------
    %% Check input
    %% --------------------
    if nargin < 1
        filename = '0414'; 
    end
    
    
    %% --------------------
    %% Main starts
    %% --------------------
    fig_idx = plot_pics(app_mags, app_times, app_types, fig_idx);
    
    app_num = max(app_types)+1;
    
    %app_features = {};
    %for i = 1:app_num
     %   if DEBUG5 == 1
      %      break;
      %  end
       % if length(app_mags{i}) > 0
       %     current_app = app_mags{i};
       %     app_features{i}= DBA(current_app, DBA_iteration);
       % end
   % end
    
    for i=1:app_num
        i_event_num = length(app_mags{i});
        if i_event_num > 0
            for x=1:i_event_num
                test_sample = app_mags{i}{x};              
                tmp_score = zeros(1, app_num);
                tmp_cnt  = zeros(1, app_num);
                
                for j=1:app_num
                    j_event_num = length(app_mags{j});
                    if j_event_num > 0
                        for y=1:j_event_num
                            train_sample = app_mags{j}{y};
                            %score = dtw(test_sample, train_sample);
                            len = min(length(test_sample),length(train_sample));
                            tmp_test    = test_sample(1:len);
                            tmp_train   = train_sample(1:len);
                            r = corrcoef(tmp_test, tmp_train);
                            score = r(1,2);
                            
                            tmp_score(j) = tmp_score(j) + score;
                            tmp_cnt(j)  = tmp_cnt(j) + 1;
                            
                            corrMatrix(i, j) = corrMatrix(i, j) + score;
                            countMatrix(i,j) = countMatrix(i, j) + 1;    
                        end
                    end
                end
                tmp_score = tmp_score ./ tmp_cnt;
                [~,match_label] = max(tmp_score);
                
                confusionMatrix(i, match_label) = confusionMatrix(i, match_label) + 1;
            end
            
        end
    end
    corrMatrix = corrMatrix ./ countMatrix;
    confusionMatrix = confusionMatrix ./ repmat(sum(confusionMatrix,2), 1, size(confusionMatrix,2));
    fig_idx = fig_idx + 1;
    fh = figure(fig_idx); clf;
    imagesc(confusionMatrix);
    colorbar;
    set(gca, 'FontSize', font_size);
    title('Confusion Matrix');
    
    fig_idx = fig_idx + 1;
    fh = figure(fig_idx); clf;
    imagesc(corrMatrix);
    colorbar;
    set(gca, 'FontSize', font_size);
    title('Correlation Matrix');
end

function test3(filename)
    % addpath('../utils');
    % similar to Yichao's method, but replace the metric of 'corrcoef' by
    % 'dtw' instead.
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

    output_dir = './tmp/';
    fig_dir = './fig/';

    font_size = 28;
    colors   = {'r', 'b', [0 0.8 0], 'm', [1 0.85 0], [0 0 0.47], [0.45 0.17 0.48], 'k'};
    lines    = {'-', '--', '-.', ':'};
    markers  = {'+', 'o', '*', '.', 'x', 's', 'd', '^', '>', '<', 'p', 'h'};


    %% --------------------
    %% Variable
    %% --------------------
    fig_idx     = 0;
    self_train  = 0;  
    DBA_iteration = 10;
    
    %[app_mags, app_types] = read_mat_input(filename);
    [app_mags, app_times, app_types] = read_traditional_input(input_dir, filename);
     
    confusionMatrix     = zeros(max(app_types)+1);
    %corrMatrix          = zeros(max(app_types)+1);
    %countMatrix         = zeros(max(app_types)+1);
    
    %% --------------------
    %% Check input
    %% --------------------
    if nargin < 1, filename = '20160328.exp1'; end


    %% --------------------
    %% Main starts
    %% --------------------
    fig_idx = plot_pics(app_mags, app_times, app_types, fig_idx);
    
    app_num = max(app_types)+1;
    
    app_features = {};
    for i = 1:app_num
        if length(app_mags{i}) > 0
            current_app = app_mags{i};
            app_features{i}= DBA(current_app, DBA_iteration);
        end
    end
    
    for i=1:app_num
        i_event_num = length(app_mags{i});
        if i_event_num > 0
            for x=1:i_event_num
                test_sample = app_mags{i}{x};
                real_label = i;
                
                tmp_dtw = zeros(1, app_num);
                tmp_cnt  = zeros(1, app_num);
                
                for j=1:app_num
                    j_event_num = length(app_mags{j});
                    if j_event_num > 0
                        for y=1:j_event_num
                            train_sample = app_mags{j}{y};
                            score = dtw(test_sample, train_sample);
                            tmp_dtw(j) = tmp_dtw(j) + score;
                            tmp_cnt(j)  = tmp_cnt(j) + 1;
                        end
                    end
                end
                tmp_dtw = tmp_dtw ./ tmp_cnt;
                [~,cate_idx] = min(tmp_dtw);
                
                confusionMatrix(real_label, cate_idx) = confusionMatrix(real_label, cate_idx) + 1;
            end
            %corrMatrix = corrMatrix ./ countMatrix;
        end
    end

    confusionMatrix = confusionMatrix ./ repmat(sum(confusionMatrix,2), 1, size(confusionMatrix,2));
    fig_idx = fig_idx + 1;
    fh = figure(fig_idx); clf;
    
    imagesc(confusionMatrix);
    colorbar;
    set(gca, 'FontSize', font_size);
    title('Confusion Matrix');
end

function test2(filename)
    % find the center of a cluster using DBA, then using N-N method to classify
    % each test sample
    % the metric adopted here is 'corrcoef'(compare the distance of two
    % samples)

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
    input_dir  = '../preprocess_mag/data/';
    output_dir = './tmp/';
    fig_dir = './fig/';

    font_size = 28;
    colors   = {'r', 'b', [0 0.8 0], 'm', [1 0.85 0], [0 0 0.47], [0.45 0.17 0.48], 'k'};
    lines    = {'-', '--', '-.', ':'};
    markers  = {'+', 'o', '*', '.', 'x', 's', 'd', '^', '>', '<', 'p', 'h'};


    %% --------------------
    %% Variable
    %% --------------------
    fig_idx = 0;
    self_train = 0;


    %% --------------------
    %% Check input
    %% --------------------
    if nargin < 1, filename = '20160328.exp1'; end


    %% --------------------
    %% Main starts
    %% --------------------
  
    mag_ts = load([input_dir filename '.mag.txt']);
    event_ts = load([input_dir filename '.app_time.txt']);
    
    events = unique(sort(event_ts(:,3)));
    

    confusion_mat = zeros(length(events));
    corr_mat      = zeros(length(events));
    cnt_mat       = zeros(length(events));
    
    app_mags = {};
    for i=1:length(events)
        app_mags{i} ={};
    end
    
    for ti = 1:size(event_ts,1)
        event_time = event_ts(ti, 2);
        event_type = event_ts(ti, 3);
        range_idx = find(mag_ts(:,1) >= event_time & mag_ts(:,1) <= (event_time+8));
       
        magTraces = mag_ts(range_idx, 2);
        %app_mags{event_type+1}
        app_mags{event_type+1}{end+1} = magTraces;
    end
    
    app_features = {};
    app_num = length(events);
    
    %correlationMatrix = zeros(app_num);
    confusionMatrix = zeros(app_num);
    
    corr_mat      = zeros(app_num);
    cnt_mat       = zeros(app_num);
    
    
    for i = 1:app_num
        if length(app_mags{i}) > 0
            %app_num = app_num + 1;
            current_app = app_mags{i};
            %app_event_num = length(current_app);
            app_features{i}= DBA(current_app, 10);
        end
    end
    for i=1:app_num
        app_event_num = length(app_mags{i});
        if app_event_num > 0
            for j=1:app_event_num
                curr_event = app_mags{i}{j};
                real_label = i;
                tmp_corr = zeros(1, app_num);
                tmp_cnt  = zeros(1, app_num);
                for k=1:app_num
                    len = min(length(curr_event), length(app_features{k}));
                    curr_event = curr_event(1:len);
                    curr_feature = app_features{k}(1:len);
                    
                    r = corrcoef(curr_event, curr_feature);
                    if numel(r) > 1
                        r = r(1,2);
                    
                        corr_mat(real_label, k) = corr_mat(real_label, k) + r;
                        cnt_mat(real_label, k) = cnt_mat(real_label,k)+1;
                    
                        tmp_corr(k) = tmp_corr(k) + r;
                        tmp_cnt(k)  = tmp_cnt(k) + 1;
                    end
                    %if score < lowest_score
                        %curr_label = k;
                        %lowest_score = score;
                    %end
                end
                tmp_corr = tmp_corr ./ tmp_cnt;
                [~,cate_idx] = max(tmp_corr);
                confusionMatrix(real_label, cate_idx) = confusionMatrix(real_label, cate_idx) + 1;
            end
        corr_mat = corr_mat ./ cnt_mat;
        end
    end

    confusionMatrix = confusionMatrix ./ repmat(sum(confusionMatrix,2), 1, size(confusionMatrix,2));
    imagesc(confusionMatrix);
    colorbar;
    set(gca, 'FontSize', font_size);
    title('Confusion Matrix');
end

function test1(iteration)
% load sequences from a ***.mat file, and use DBA to find the center of
% each cluster. then use N-N method to label each test sample. The metric
% adopted here is DTW score.
    input_dir  = '../preprocess_mag/data/';
    filename1 = '0414';
    load([input_dir filename1 '.mat'], '-mat');
    font_size = 28;
    app_features = {};
    app_num = length(app_mags);
    correlationMatrix = zeros(app_num);
    confusionMatrix = zeros(app_num);
    for i = 1:app_num
        if length(app_mags{i}) > 0
            %app_num = app_num + 1;
            current_app = app_mags{i};
            %app_event_num = length(current_app);
            app_features{i}= DBA(current_app, iteration);
        end
    end
    for i=1:app_num
        app_event_num = length(app_mags{i});
        if app_event_num > 0
            for j=1:app_event_num
                curr_event = app_mags{i}{j};
                real_label = i;
                curr_label = -1;
                lowest_score = Inf;
                for k=1:app_num
                    score = dtw(app_features{k}, curr_event);
                    if score < lowest_score
                        curr_label = k;
                        lowest_score = score;
                    end
                end
                confusionMatrix(real_label, curr_label) =confusionMatrix(real_label, curr_label) +1;
            end
        end
    end
    confusionMatrix = confusionMatrix ./ repmat(sum(confusionMatrix,2), 1, size(confusionMatrix,2))
    imagesc(confusionMatrix);
    colorbar;
    set(gca, 'FontSize', font_size);
    title('Confusion Matrix');
end

function [app_mags, app_times, app_types] = read_traditional_input(input_dir, filename)
% read input from /preprocess_mag/data/file_name_mag.txt, and generate a
% sequences that can be used for further training/testing
  
    mags = load([input_dir filename '.mag.txt']);
    event_ts = load([input_dir filename '.app_time.txt']);
    
    
    %%returen values    
    app_mags    = {};
    app_times   = {};
    app_types   = unique(sort(event_ts(:,3)));
    
    for i=1:max(app_types)+1
        app_mags{i}     = {};
        app_times{i}    = {};
    end
    
    for ti = 1:size(event_ts,1)
        event_time  = event_ts(ti, 2);
        app_type    = event_ts(ti, 3)+1;
        range_idx   = find(mags(:,1) >= event_time & mags(:,1) <= (event_time+8));
       
        magTraces   = mags(range_idx, 2);
        timeTraces  = mags(range_idx, 1);
        app_mags{app_type}{end+1} = magTraces;
        app_times{app_type}{end+1} = timeTraces;
    end
end

function [app_mags,app_times, app_types] = read_mat_input(input_dir, filename)
    load([input_dir filename '.mat'], '-mat');
    app_mags  = single_app_mag_s;
    app_times = app_time_s;
    app_types = single_app_type_s;
end

function fig_idx = plot_pics(app_mags, app_times, app_types, fig_idx)
    
    for i=1:length(app_types)
        app_type = app_types(i)+1;
        
        curr_event_num = length(app_mags{app_type});
        fig_idx = fig_idx + 1;
        fprintf ('will show Picture %d, press any button to continue.\n',fig_idx);
        pause
        fh = figure(fig_idx); clf;
        for j=1:curr_event_num
            %% PLOT
            plot(app_times{app_type}{j}, app_mags{app_type}{j});
           
            if j==1
                hold on;
            end
        end     
        xlabel('Sample points');
        ylabel('Magnitude');
        legend(' Synthesize Signal');
        title('EM Magnitued');
    end
end