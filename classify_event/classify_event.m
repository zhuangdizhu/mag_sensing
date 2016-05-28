%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Yi-Chao Chen @ UT Austin
%%
%% - Input:
%%
%% - Output:
%%
%%
%% example:
%%  classify_event('20160328.exp1', '20160328.exp2')
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function classify_event(filename1, filename2)
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
    %% Main starts
    %% --------------------
    if nargin < 2
        [confusion_mat, corr_mat] = classify_event_self('20160328.exp01');

    else

        mag_ts1 = load([input_dir filename1 '.mag.txt']);
        event_ts1 = load([input_dir filename1 '.app_time.txt']);
        events1 = unique(sort(event_ts1(:,3)));

        mag_ts2 = load([input_dir filename2 '.mag.txt']);
        event_ts2 = load([input_dir filename2 '.app_time.txt']);
        events2 = unique(sort(event_ts2(:,3)));


        confusion_mat = zeros(length(events1));
        corr_mat      = zeros(length(events1));
        cnt_mat       = zeros(length(events1));

        for ti = 1:size(event_ts1,1)
            event_time = event_ts1(ti, 2);
            event_type1 = event_ts1(ti, 3);
            range_idx = find(mag_ts1(:,1) >= event_time & mag_ts1(:,1) <= (event_time+8));

            ts1 = mag_ts1(range_idx, 2);

            tmp_corr = zeros(1, length(events1));
            tmp_cnt  = zeros(1, length(events1));
            for tj = 1:size(event_ts2,1)
                event_time = event_ts2(tj, 2);
                event_type2 = event_ts2(tj, 3);
                range_idx = find(mag_ts2(:,1) >= event_time & mag_ts2(:,1) <= (event_time+8));

                ts2 = mag_ts2(range_idx, 2);

                len = min(length(ts1), length(ts2));
                ts1 = ts1(1:len);
                ts2 = ts2(1:len);

                r = corrcoef(ts1, ts2)
                r = r(1,2);

                corr_mat(event_type1+1, event_type2+1) = corr_mat(event_type1+1, event_type2+1) + r;
                cnt_mat(event_type1+1, event_type2+1) = cnt_mat(event_type1+1, event_type2+1) + 1;

                tmp_corr(event_type2+1) = tmp_corr(event_type2+1) + r;
                tmp_cnt(event_type2+1)  = tmp_cnt(event_type2+1) + 1;
            end

            tmp_corr = tmp_corr ./ tmp_cnt;
            [~,cate_idx] = max(tmp_corr);
            confusion_mat(event_type1+1, cate_idx) = confusion_mat(event_type1+1, cate_idx) + 1;
        end

        corr_mat = corr_mat ./ cnt_mat;
        corr_mat
    end

    confusion_mat = confusion_mat ./ repmat(sum(confusion_mat,2), 1, size(confusion_mat,2));


    fig_idx = fig_idx + 1;
    fh = figure(fig_idx); clf;

    imagesc(corr_mat);
    colorbar;
    set(gca, 'FontSize', font_size);


    fig_idx = fig_idx + 1;
    fh = figure(fig_idx); clf;

    imagesc(confusion_mat);
    colorbar;
    set(gca, 'FontSize', font_size);

end

