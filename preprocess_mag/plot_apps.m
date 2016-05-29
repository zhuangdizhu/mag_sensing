function plot_apps(filename1, filename2)

    DEBUG0 = 0; 
    DEBUG1 = 0; %resample
    DEBUG2 = 0; %average smooth
    DEBUG3 = 1; %Average DTW
    DEBUG4 = 0; %FFT
    
    input_dir  = '../preprocess_mag/data/';
    fig_idx = 0;
    FontSize = 20;
    LineWidth = 3;
    frequency_cnt = 50;
    
    %% --------------------
    %% Main starts
    %% --------------------
    colors = ['r', 'g', 'b', 'c', 'k'];
    
    if nargin < 1
        filename1 = '20160527.exp01';
        filename2 = '20160527.exp02';
    end     
        [app_mags1, app_types1] = read_single_mat_input(input_dir,filename1);

        [app_mags2, app_types2] = read_single_mat_input(input_dir,filename2);
        
        % default 
        if DEBUG0 == 1                
        for i=1:length(app_types1)
            fig_idx = fig_idx + 1;
            fh = figure(fig_idx); clf;
            tmp1 = [];
            tmp2 = [];
            for j = 1:length(app_mags1{i})
                tmp1 = [tmp1; length(app_mags1{i}{j})];        
                tmp2 = [tmp2; length(app_mags2{i}{j})];   
            end 
            len1 = min(tmp1);
            len2 = min(tmp2);
            
            for j = 1:length(app_mags1{i})
                app1 = app_mags1{i}{j}(1:len1,2);
                app2 = app_mags2{i}{j}(1:len2,2);
                
                subplot(1,2,1)
                plot(app1,'color', colors(j));
                hold on;
                
                subplot(1,2,2)
                plot(app2,'color', colors(j));
                hold on;
            end
        end            
        end
        
        if DEBUG3 == 1
        %find average
        averageMags1 = cell(1,length(app_mags1));
        averageMags2 = cell(1,length(app_mags2));
        
        for i = 1:length(app_mags1)
            tmpMags1 = cell(1,length(app_mags1{i}));
            tmpMags2 = cell(1,length(app_mags2{i}));
            
            for j = 1:length(app_mags1{i})
                tmpMags1{j}= app_mags1{i}{j}(:,2);
                tmpMags2{j}= app_mags2{i}{j}(:,2);
            end
            [averageMags1{i},~] = DBA(tmpMags1);
            [averageMags2{i},~] = DBA(tmpMags2);
        end 
        
        %plot
        for i = 1:length(app_mags1)
        	fig_idx = fig_idx + 1;            
            fh = figure(fig_idx); clf; 
            %time idx
   
            subplot(1,2,1)
            plot(averageMags1{i},'Color','g','LineWidth',LineWidth);
            title('IOS Sensor','FontSize',FontSize);
            subplot(1,2,2)
            plot(averageMags2{i},'Color','y','LineWidth',LineWidth);
            title('Andorid Sensor','FontSize',FontSize);
        end     
        end
        
        %average smooth
        if DEBUG2 == 1
        nb = 3;
        for i=1:length(app_types1)
            fig_idx = fig_idx + 1;
            fh = figure(fig_idx); clf;
            len = Inf;
            tmp = [];
            for j = 1:length(app_mags1{i})
                tmp = [tmp; length(app_mags1{i}{j})];                
            end
            len = min(tmp);
            for j = 1:length(app_mags1{i})
                subplot(2,1,1)
                plot(app_mags2{i}{j}(1:len,2), 'color', colors(j));
                if j == 1, hold on; end
                subplot(2,1,2)
                tmp = medfilt1(app_mags1{i}{j}(:,2),nb);
                plot(app_mags2{i}{j}(1:len,1), tmp(1:len), 'color', colors(j));
                if j == 1, hold on; end                
            end      
        end
        end
        
        %resample
        if DEBUG1 == 1
        for i=1:length(app_types1)
            fig_idx = fig_idx + 1;
            fh = figure(fig_idx); clf;
                            
            tmp = [];
            for j = 1:length(app_mags1{i})
                tmp = [tmp; length(app_mags1{i}{j}); length(app_mags2{i}{j})];
            end
            len = min(tmp);
            
            
            for j = 1:length(app_mags1{i})
                f1 = length(app_mags1{i}{j})/max(app_mags1{i}{j}(:,1));                
                f2 = length(app_mags2{i}{j})/max(app_mags2{i}{j}(:,1));
                fs = min(f1,f2);
                [p1,q1] = rat(fs,f1);
                [p2,q2] = rat(fs,f2);   
                
                app1 = app_mags1{i}{j}(:,2);
                app2 = app_mags2{i}{j}(:,2); 
                            
                app1 = resample(app1,p1,q1);
                app2 = resample(app2,p2,q2);
                
                app1 = app1(1:len);
                app2 = app2(1:len);
                
                app1 = (app1 - min(app1))/(max(app1) - min(app1));              
                app2 = (app2 - min(app2))/(max(app2) - min(app2));
            
                subplot(1,3,1)
                plot(app1, 'color', colors(j));
               	hold on;
                
                subplot(1,3,2)
                plot(app2, 'color', colors(j));
               	hold on;
               
                subplot(1,3,3)
                plot(app1, 'color', colors(j));
                hold on;
                plot(app2, 'color', colors(j));
                hold on;
            end
        end
        end
end
function [appMags, appTypes] = read_single_mat_input(input_dir, filename)
    load([input_dir filename '_single_app.mat'], '-mat');
    appMags  = appMags;
    appTypes = appTypes;
end
function [mags, avg_mags, fig_idx] =plot_signal_in_seperate(app_types, app_mags, appPattern, fig_idx, DEBUG0, DEBUG1, DEBUG2)
    subplot_color = {'-b.', '-g.', '-y.', '-b.', '-g.', '-y.'};
    subplot_title = {'Mag-X', 'Mag-Y', 'Mag-Z', 'Sythesized Mag','Original Sythesized','MF'};
    mags = {};
    avg_mags = {};
    
    for ti = 1:length(app_types)
        mags{end+1} = {};
        avg_new_mags = {};
        time_idxs = [];
        
        for ii = 1:length(app_mags{ti})
            time_i = app_mags{ti}{ii}(:,1);
            time_idxs = [time_idxs;time_i];
        end
        
        time_idxs = unique(sort(time_idxs));
        %time_idxs is the common time index for all data belonging to the
        %same app
        
        
        
        for ii = 1:length(app_mags{ti})
            ii_mag = app_mags{ti}{ii};
            time_i = ii_mag(:,1);
            
            [t, index] = unique(sort(time_i),'first');
            curr_mag = [];
            curr_mag(:,1) = time_idxs;
            
            for mi = 2:6
                %tmp(:,mi) = interp1(new_mags(:,1), new_mags(:,mi), tmp(:,1));
                curr_mag(:,mi) = interp1(ii_mag(index,1), ii_mag(index,mi), time_idxs(:,1));
                curr_mag(:,mi) = curr_mag(:,mi) - mean(curr_mag(:,mi));
                avg_new_mags{end+1}=[];
            end
    
            curr_mag(:,5) = sqrt(curr_mag(:,2).^2 + curr_mag(:,3).^2 + curr_mag(:,4).^2);            
            curr_mag(:,5) = curr_mag(:,5) - min(curr_mag(:,5));
            curr_mag(:,5) = curr_mag(:,5) / max(curr_mag(:,5));
            
            mags{ti}{ii} = curr_mag;
            
            %length(curr_mag)
            for mi=1:6
                avg_new_mags{mi}(:,ii) = curr_mag(:,mi);% Sythesized EM Signal
            end
        end
        
        if DEBUG0 == 1
            fig_idx = fig_idx + 1;
            fh = figure(fig_idx); clf;
            for ii = 1:length(app_mags{ti})
                curr_mag = mags{ti}{ii};
                
                for mi=2:6
                    subplot(2,3,mi-1);                   
                    plot(curr_mag(:,1), curr_mag(:,mi), subplot_color{mi-1});
                    
                    if ii == 1
                        hold on;
                    elseif ii == length(app_mags{ti})
                        xlabel('Sample points');
                        ylabel('Magnitude');
            
                        if strcmp(appPattern, 'multiple') == 1
                            str = [' Signal of App ', num2str(ti), '&',num2str(ti+1)];
                        else
                            str = [' Signal of App ', num2str(ti)];
                        end  
                        title(str);
                        legend(subplot_title{mi-1});
                    end
                end
            end
        end
        
        for mi=2:6
            avg_new_mags{mi} = mean(avg_new_mags{mi},2);
            avg_mags{ti} = avg_new_mags;
        end            
    end
end