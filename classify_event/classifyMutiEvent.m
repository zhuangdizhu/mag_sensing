%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Yi-Chao Chen @ UT Austin
%%
%% - Input:
%%
%% - Output:
%%
%%
%% example:
%%  classify_multi_app('0418')
%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [confusion_mat, corr_mat] = classify_multi_app(filename)
    %% --------------------
    %% DEBUG
    %% --------------------
    DEBUG0 = 0;
    DEBUG1 = 1;
    DEBUG2 = 1;  %% progress
    DEBUG3 = 1;  %% verbose
    DEBUG4 = 1;  %% results
    DEBUG5 = 1;
    DEBUG6 = 1;  %% endTime trace
    DEBUG7 = 1;

    %% --------------------
    %% Constant
    %% --------------------
    input_dir  = '../preprocess_mag/data/';
    output_dir = './tmp/';
    fig_dir = './fig/';
    fig_idx = 0;
    font_size = 28;
    subplot_title = {'Mag-X', 'Mag-Y', 'Mag-Z', 'Sythesized Mag'}


    %% --------------------
    %% Check input
    %% --------------------
    if nargin < 1, filename = '20160328.exp1'; end


    %% --------------------
    %% Main starts
    %% --------------------
    disp('Main Starts---------------------------')
    multi_mags = {};
    avg_multi_mags = {};
    
    single_mags = {};
    avg_single_mags = {};
    
    %[multi_app_mags, multi_app_types] = read_multi_mat_input(input_dir,filename);
    [single_app_mags, single_end_mags, single_app_types] = read_single_mat_input(input_dir,filename);
    
    
    %[multi_mags, avg_multi_mags, fig_idx] = plot_events(multi_app_types, multi_app_mags, 'multiple', fig_idx, DEBUG3, DEBUG4);
    
    [single_mags, avg_single_mags, fig_idx] = plot_events(single_app_types, single_app_mags, 'single', fig_idx, DEBUG3, DEBUG4);
    
    pause
    [end_mags,avg_end_mags, fig_idx] = plot_events(single_app_types, single_end_mags, 'endApp', fig_idx, DEBUG3, DEBUG4);
    
    fprintf('Seperation complete. Press any button to continue, or Ctr+C to exit\n');
    pause
    if DEBUG7 == 1
        return;
    end
    %% -------------------
    %% Time Interpolation
    %% -------------------
    if DEBUG2, fprintf('Time Interpolation\n'); end
    timeIdx = [];
    for app_idx = 1:length(multi_app_types)-1
        timeIdx = [timeIdx; avg_multi_mags{app_idx}{1}];
    end
    
    for app_idx = 1:length(single_app_types)
        timeIdx = [timeIdx; avg_single_mags{app_idx}{1}];
    end
    
    timeIdx = unique(sort(timeIdx));
    
    for app_idx = 1:length(multi_app_types)-1
        currMultiMags = [];
        [t, Index] = unique(sort(avg_multi_mags{app_idx}{1}),'first');
        currMultiMags(:,1) = timeIdx;
        for mi=2:4
            currMultiMags(:,mi) = interp1(avg_multi_mags{app_idx}{1}(Index,1),avg_multi_mags{app_idx}{mi}(Index,1),timeIdx(:,1));
        end
        avg_multi_mags{app_idx} = currMultiMags;
    end
    
    for app_idx = 1:length(single_app_types)
        currSingleMags = [];
        [t, Index] = unique(sort(avg_single_mags{app_idx}{1}),'first');
        currSingleMags(:,1) = timeIdx;
        for mi=2:4
            currSingleMags(:,mi) = interp1(avg_single_mags{app_idx}{1}(Index,1),avg_single_mags{app_idx}{mi}(Index,1),timeIdx(:,1));
        end
        avg_single_mags{app_idx} = currSingleMags;

    end
    
     %% -------------------------------------------------------------------     
     %% ---PLOT the Relation Between Multiple App and Its Single Components
     %% -------------------------------------------------------------------
     for app_idx = 1:length(multi_app_types)-1
        if DEBUG5 == 1
            %plot MagX, MagY, and MagZ
            currSingleMags1     =  avg_single_mags{app_idx};
            currSingleMags2    = avg_single_mags{app_idx+1};
            currMultiMags       = avg_multi_mags{app_idx};
            fig_idx = fig_idx + 1;
            fh = figure(fig_idx); clf;
            for mi=2:4
                subplot(2,2,mi-1);
                plot(timeIdx(:,1),currSingleMags1(:,mi), 'r.');
                hold on;
                plot(timeIdx(:,1),currSingleMags2(:,mi), 'b.');
                plot(timeIdx(:,1),currMultiMags(:,mi), 'g.');
                xlabel('Sample points');
                ylabel('Magnitude');
                str = [subplot_title(mi-1), ' of App ', num2str(app_idx), ' & ', num2str(app_idx+1)];
                title(str);
                legend('Fisrt App - Yellow','Second App - Blue', 'Merged App - Green');
            end
            
            %plot & compare sythesized signal
            merged_sig = [];
            merged_sig(:,1) = timeIdx(:,1);
            for mi=2:4
                merged_sig(:,mi) = sum([currSingleMags1(:,mi) currSingleMags2(:,mi)],2);
            end
            merged_sig(:,5) = sqrt(merged_sig(:,2).^2 + merged_sig(:,3).^2 + merged_sig(:,4).^2);
            merged_sig(:,6) = merged_sig(:,5) - min(merged_sig(:,5));
            merged_sig(:,6) = merged_sig(:,6)/max(merged_sig(:,6));
            
            
            avg_multi_mags{app_idx}(:,5) = sqrt(avg_multi_mags{app_idx}(:,2).^2 + avg_multi_mags{app_idx}(:,3).^2 + avg_multi_mags{app_idx}(:,4).^2);
            avg_multi_mags{app_idx}(:,6) = avg_multi_mags{app_idx}(:,5) - min(avg_multi_mags{app_idx}(:,5));
            avg_multi_mags{app_idx}(:,6) = avg_multi_mags{app_idx}(:,6)/max(avg_multi_mags{app_idx}(:,6));
            
            subplot(2,2,4)
            plot(timeIdx(:,1),merged_sig(:,6),'r.');
            hold on;
            plot(timeIdx(:,1),avg_multi_mags{app_idx}(:,6),'g.');
            xlabel('Sample points');
            ylabel('Magnitude');
            str = [subplot_title(4), ' of App ', num2str(app_idx), '&', num2str(app_idx+1)];
            title(str);
            legend('Calculated Sum - Red', 'Real Merged App - Green');
            fprintf('Plot complete. Press any button to continue, or Ctr+C to exit\n');
            pause 
        end
        
     end
       
end


function [mags, avg_mags, fig_idx] = plot_events(app_types, app_mags, appPattern, fig_idx, DEBUG3, DEBUG4, DEBUG5)
    mags = {};
    avg_mags = {};
    for i = 1:length(app_types)
        mags{end+1} = {};
        avg_new_mags = {};
        time_idxs = [];
        for ii = 1:length(app_mags{i})
            time_i = app_mags{i}{ii}(:,1);
            time_idxs = [time_idxs;time_i];
        end
        
        time_idxs = unique(sort(time_idxs));
        
        for ii = 1:length(app_mags{i})
            ii_mag = app_mags{i}{ii};
            time_i = ii_mag(:,1);
            
            [t, index] = unique(sort(time_i),'first');
            curr_mag = [];
            curr_mag(:,1) = time_idxs;
            
            for mi = 2:4
                %tmp(:,mi) = interp1(new_mags(:,1), new_mags(:,mi), tmp(:,1));
                curr_mag(:,mi) = interp1(ii_mag(index,1), ii_mag(index,mi), time_idxs(:,1));
                curr_mag(:,mi) = curr_mag(:,mi) - min(curr_mag(:,mi));
                avg_new_mags{end+1}=[];
            end
    
            curr_mag(:,5) = sqrt(curr_mag(:,2).^2 + curr_mag(:,3).^2 + curr_mag(:,4).^2);
            avg_new_mags{end+1} = [];
            curr_mag(:,6) = curr_mag(:,5) - min(curr_mag(:,5));
            curr_mag(:,6) = curr_mag(:,6) / max(curr_mag(:,6));
            avg_new_mags{end+1} = [];
            
            mags{i}{ii} = curr_mag;
            
            %length(curr_mag)
            for mi=1:6
            avg_new_mags{mi}(:,ii) = curr_mag(:,mi);% Sythesized EM Signal
            end
        end
        
        if DEBUG3 == 1
            fig_idx = fig_idx + 1;
            fh = figure(fig_idx); clf;
            subplot(2,1,1);
            for ii = 1:length(app_mags{i})
                curr_mag = mags{i}{ii};
                plot(curr_mag(:,1), curr_mag(:,5), '-r.');
                if ii == 1
                    hold on;
                end
                plot(curr_mag(:,1), curr_mag(:,2), '-b.');
                plot(curr_mag(:,1), curr_mag(:,3), '-g.');
                plot(curr_mag(:,1), curr_mag(:,4), '-y.');
            end
       
            xlabel('Sample points');
            ylabel('Magnitude');
            
            if strcmp(appPattern, 'multiple') == 1
                str = [' Signal of App ', num2str(i), '&',num2str(i+1)];
            else
                str = [' Signal of App ', num2str(i)];
            end           
            title(str);
            legend('Red: Square-Root','Blue: M-X','Green:M-Y','Yellow::M-Z');
        end
        
        for mi=2:6
            avg_new_mags{mi} = mean(avg_new_mags{mi},2);
            avg_mags{i} = avg_new_mags;
        end
        
        
            %fig_idx = fig_idx + 1;
            %fh = figure(fig_idx); clf;
            subplot(2,1,2);
            plot(time_idxs, avg_new_mags{5});
            xlabel('Sample points');
            ylabel('Magnitude');
            if strcmp(appPattern, 'multiple') == 1
                str = ['Average Square-Root of App ', num2str(i), '&',num2str(i+1)];
            elseif strcmp(appPattern, 'endApp') == 1
                str = ['Average Square-Root of App End ', num2str(i)];
            else
                str = ['Average Square-Root of App ', num2str(i)];
            end
            title(str);
            legend('Avged Signal');
            
    end
end
function [single_app_mags, single_end_mags, single_app_types] = read_single_mat_input(input_dir, filename)
    load([input_dir filename '_single_app.mat'], '-mat');
    single_app_mags  = single_app_mag_s;
    single_app_types = single_app_type_s;
    single_end_mags = single_end_mag_s;
end
function [multi_app_mags, multi_app_types] = read_multi_mat_input(input_dir, filename)
    load([input_dir filename '_multi_app.mat'], '-mat');
    multi_app_mags  = multi_app_mag_s;
    multi_app_types = multi_app_type_s;
end