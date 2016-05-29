function plot_single_app(filename1)

    DEBUG0 = 0; %default
    DEBUG1 = 0; % moving average smooth
    DEBUG2 = 0; %weighted moving average smooth
    DEBUG3 = 0; %Exponential Moving Average filter
    DEBUG4 = 1; %Average DTW
    DEBUG5 = 0; %FFT
    
    
    input_dir  = '../preprocess_mag/data/';
    fig_idx = 0;
    colors = ['r', 'g', 'b', 'c', 'y'];
    nb = 3;

    %% --------------------
    %% Main starts
    %% --------------------

    if nargin < 1
        filename1 = '20160529.exp01';
    end     
        [app_mags, app_types] = read_single_mat_input(input_dir,filename1);
        
        %FFT Frequency
        if DEBUG5 == 1
            for i = 1:length(app_types)
                for j = 1:length(app_mags{i})
                end
            end
        end
        
        if DEBUG4 == 1
        %find average
        averageMags = cell(1,length(app_mags));
        for i = 1:length(app_mags)
            tmpMags = cell(1,length(app_mags{i}));
            for j = 1:length(app_mags{i})
                tmpMags{j}= app_mags{i}{j}(:,2);
            end
            [averageMags{i},~] = DBA(tmpMags);
        end         
        %plot
        for i = 1:length(app_mags)
        	fig_idx = fig_idx + 1;            
            fh = figure(fig_idx); clf; 
            
                           
            %time idx
            len = [];
            for j = 1:length(app_mags{i})
                len(end+1) = length(app_mags{i}{j});
            end
            len = min(len);
            for j = 1:length(app_mags{i})
                subplot(1,2,1)
                plot(app_mags{i}{j}(1:len,2),'Color',colors(j));
                hold on;
                title('Raw Signals');
            end
            subplot(1,2,2)
            plot(averageMags{i});
            title('Averaged center using DBA');
        end
        end
        
        
        %DEBUG0
        if DEBUG0 == 1
            for i=1:length(app_types)
                fig_idx = fig_idx + 1;
                fh = figure(fig_idx); clf;
                len = Inf;
                len = [];
            for j = 1:length(app_mags{i})
                len = [len; length(app_mags{i}{j})];                
            end
            %plot
            len = min(len);
            for j = 1:length(app_mags{i})               
                
                plot(app_mags{i}{j}(1:len,2), 'color', colors(j));
                if j == 1, hold on; end              
            end      
            end
        end

        %DEBUG1 moving average smooth
        if DEBUG1 == 1
            coeefMtx = ones(1,10)/10;       
        for i=1:length(app_types)
            fig_idx = fig_idx + 1;
            fh = figure(fig_idx); clf;
            len = [];
            
            for j = 1:length(app_mags{i})
                len = [len; length(app_mags{i}{j})];                
            end
            len = min(len);
            %timeIdx = unique(sort(tmp));
            for j = 1:length(app_mags{i})
                app = app_mags{i}{j}(1:len,:);
                smooth_app = app;
                smooth_app(:,2) = filter(coeefMtx, 1, app(:,2));
                subplot(2,3,j)
                plot(app(:,1), app(:,2), 'color', colors(1));
               	hold on;
                plot(smooth_app(:,1),smooth_app(:,2),colors(2));

                subplot(2,3,6)
                plot(smooth_app(:,1),smooth_app(:,2),colors(j));
                hold on;
            end
        end 
        end       
                
        %DEBUG2 weighted moving average smooth
        if DEBUG2 == 1
            h = [1/2 1/2];
            binomialCoeff = conv(h,h);
            for n = 1:4
                binomialCoeff = conv(binomialCoeff,h);
            end
            
            for i=1:length(app_types)
            fig_idx = fig_idx + 1;
            fh = figure(fig_idx); clf;
            len = [];
            
            for j = 1:length(app_mags{i})
                len = [len; length(app_mags{i}{j})];                
            end
            len = min(len);
            %timeIdx = unique(sort(tmp));
            for j = 1:5%length(app_mags1{i})
                %fDelay = (length(binomialCoeff)-1)/2;
                
                app = app_mags{i}{j}(1:len,:);
                smooth_app = app;
                smooth_app(:,2) = filter(binomialCoeff, 1, app(:,2));
                subplot(2,3,j)
                plot(app(:,1), app(:,2), 'color', colors(1));
                hold on;
                plot(smooth_app(:,1),smooth_app(:,2),colors(2));
                hold on;

                
                subplot(2,3,6)
                plot(smooth_app(:,1),smooth_app(:,2),colors(j));
                hold on;
                title('Smoothed Signal');
            end

            end
        end
        
        
        %DEBUG3 Exponential Moving Average filter 
        if DEBUG3 == 1
            alpha = 0.25;
            for i=1:length(app_types)
            fig_idx = fig_idx + 1;
            fh = figure(fig_idx); clf;
            len = [];
            
            for j = 1:length(app_mags{i})
                len = [len; length(app_mags{i}{j})];                
            end
            len = min(len);
            %timeIdx = unique(sort(tmp));
            for j = 1:5%length(app_mags1{i})
                %fDelay = (length(binomialCoeff)-1)/2;
                
                app = app_mags{i}{j}(1:len,:);
                smooth_app = app;
                smooth_app(:,2) = filter(alpha, [1 alpha-1], app(:,2));
                subplot(2,3,j)
                plot(app(:,1), app(:,2), 'color', colors(1));
                hold on;
                plot(smooth_app(:,1),smooth_app(:,2),colors(2));
                hold on;
                
                subplot(2,3,6)
                plot(smooth_app(:,1),smooth_app(:,2));%,colors(j));
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
function drawChangePts(app_types,app_mags,fig_idx)
%for i = 1:length(app_types)
ti = 1
    for ii = 1:length(app_mags{ti})
        for mi = 2:4
            curr_mag = app_mags{ti}{ii}(:,mi);
            curr_mag =  (curr_mag - mean(curr_mag))/(max(curr_mag) - min(curr_mag));
            fig_idx = fig_idx + 1;
            fh = figure(fig_idx); clf;
            findchangepts(curr_mag,'MaxNumChanges',5);
           
        end
    end
%end
fig_idx = fig_idx;
end