function compare_double_apps(doubleFileName, singleFileName)

    DEBUG0 = 0; 
    DEBUG1 = 0; %resample
    DEBUG2 = 0; %average smooth
    DEBUG3 = 0; %Average DTW
    DEBUG4 = 1; %FFT
    
    input_dir  = '../preprocess_mag/data/';
    fig_idx = 0;
    FontSize = 20;
    LineWidth = 3;
    frequency_cnt = 10;
    
    %% --------------------
    %% Main starts
    %% --------------------
    colors = ['r', 'g', 'b', 'c', 'k'];
    %apps = ['PowerPoint','Word', 'Excel', 'Chrome', 'Safari', 'Skype', 'VLC', 'QuickTimePlayer'];
    apps = {'PowerPoint';'Word';'Excel'; 'Chrome';'Safari';'Skype'; 'iTunes'; 'VLC'; 'QuickTimePlayer'};
    if nargin < 1
        doubleFileName = '20160529.exp03';
        singleFileName = '20160529.exp01';
    end     
        [app_mags1, app_types1] = read_double_mat_input(input_dir,doubleFileName);

        [app_mags2, app_types2] = read_single_mat_input(input_dir,singleFileName);
        
        if DEBUG4 == 1
        averageMags1 = cell(1,length(app_mags1));
        averageMags2 = cell(1,length(app_mags2));
        
        for i = 1:length(app_mags1)
            tmpMags1 = cell(1,length(app_mags1{i}));
            for j = 1:length(app_mags1{i})
                tmpMags1{j}= app_mags1{i}{j}(:,2);
                tmpMags2{j}= app_mags2{i}{j}(:,2);
            end
            [averageMags1{i},~] = DBA(tmpMags1);
            [averageMags2{i},~] = DBA(tmpMags2);
        end
        
        for i = 1:length(app_mags2)
          	tmpMags2 = cell(1,length(app_mags2{i}));
            for j = 1:length(app_mags2{i})
                tmpMags2{j}= app_mags2{i}{j}(:,2);
            end
            [averageMags2{i},~] = DBA(tmpMags2);
        end        
        
        for i = 1:length(averageMags1)
            curr_mag = averageMags1{i};
            fig_idx = fig_idx + 1;            
            fh = figure(fig_idx); clf; 
                fft_ret_double = abs(fft(curr_mag));
                fft_ret_double = fft_ret_double(1:frequency_cnt); 
                
                if i <= 5
                    first_mag = averageMags2{i};
                    next_mag = averageMags2{i+2};
                elseif i == 6
                    first_mag = averageMags2{i};
                    next_mag = averageMags2{i+2};
                   % length(next_mag)
                elseif i == 7
                    first_mag = averageMags2{i+1};
                    next_mag = averageMags2{i+2};
                end
                
                fft_ret_1 = abs(fft(first_mag));
                %fft_ret_1 = fft_ret_1(1:frequency_cnt); 
                
                fft_ret_2 = abs(fft(next_mag));
                %fft_ret_2 = fft_ret_2(1:frequency_cnt); 
                
                fft_ret_merge = [];
                for x = 1:frequency_cnt
                    fft_ret_merge(x,1) = fft_ret_1(x);
                    fft_ret_merge(x,2) = fft_ret_2(x);
                end
                bar(fft_ret_double,0.8,'FaceColor','y');
                
                hold on;
                bar(fft_ret_merge,0.6,'stacked');
                if i <= 5
                    legend({'Double Apps', apps{i}, apps{i+1}},'FontSize',FontSize);
                elseif i == 6
                    legend({'Double Apps', apps{i}, apps{i+2}},'FontSize',FontSize);
                elseif i == 7
                    legend({'Double Apps', apps{i+1}, apps{i+2}},'FontSize',FontSize);
                end
                %legend('Double Apps', 'Fisrt App', 'Next App');
        end        
        end
        
        
        
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
            title('Double Apps','FontSize',FontSize);
            subplot(1,2,2)
            plot(averageMags2{i},'Color','y','LineWidth',LineWidth);
            title('Single App','FontSize',FontSize);
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
function [app_mags, app_types] = read_double_mat_input(input_dir, filename)
    load([input_dir filename '_multi_app.mat'], '-mat');
    app_mags  = multiAppMags;
    app_types = multiAppTypes;
end
function [app_mags, app_types] = read_single_mat_input(input_dir, filename)
    load([input_dir filename '_single_app.mat'], '-mat');
    app_mags  = appMags;
    app_types = appTypes;
end