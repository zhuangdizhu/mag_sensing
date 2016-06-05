function plot_app(filename1, mode)

    DEBUG0 = 0; %default
    DEBUG1 = 0; % moving average smooth
    DEBUG2 = 0; %weighted moving average smooth
    DEBUG3 = 0; %Exponential Moving Average filter
    DEBUG4 = 0; %Average DTW
    DEBUG5 = 0; %FFT
    FontSize = 20;
    DEBUG8 = 1; %feature presentation
    DEBUG6 = 0; %Compare app 5&7, 6&8, 6&9
    LineWidth = 1.5;
    frequency_cnt = 50;
    input_dir  = '../preprocess_mag/data/';
    fig_idx = 0;
    colors = ['r', 'g', 'b', 'c', 'y'];
    nb = 3;

    %% --------------------
    %% Main starts
    %% --------------------

    if nargin < 1
        filename1 = '20160529.exp01';
        mode = '1';
    elseif nargin == 1
        disp 'please input the mode: 1 or 2';
        return;
    end  
    
    if mode == '1'
        [app_mags, app_types] = read_single_app_input(input_dir,filename1);
    elseif mode == '2'    
        [app_mags, app_types] = read_double_app_input(input_dir,filename1);
    end   
    
        if DEBUG6 == 1
            averageMags = cell(1,length(app_mags));
            for i = 1:length(app_mags)
            tmpMags = cell(1,length(app_mags{i}));
            for j = 1:length(app_mags{i})
                tmpMags{j}= app_mags{i}{j}(:,2);
            end
            [averageMags{i},~] = DBA(tmpMags);
            end
            
            fig_idx = fig_idx + 1;            
            fh = figure(fig_idx); clf; 
            len = min(length(averageMags{1}),length(averageMags{5}));
            plot(averageMags{1}(1:len),'y','LineWidth',LineWidth);
            hold on;
            plot(averageMags{5}(1:len),'g','LineWidth',LineWidth);
            legend('App1', 'App5');
            
            fig_idx = fig_idx + 1;            
            fh = figure(fig_idx); clf; 
            len = min(length(averageMags{2}),length(averageMags{6}));
            plot(averageMags{2}(1:len),'y','LineWidth',LineWidth);
            hold on;
            plot(averageMags{6}(1:len),'g','LineWidth',LineWidth);
            legend('App2', 'App6');
            
            fig_idx = fig_idx + 1;            
            fh = figure(fig_idx); clf; 
            len = min(length(averageMags{2}),length(averageMags{3}));
            plot(averageMags{2}(1:len),'y','LineWidth',LineWidth);
            hold on;
            plot(averageMags{3}(1:len),'g','LineWidth',LineWidth);
            legend('App2', 'App3');
            
            fig_idx = fig_idx + 1;            
            fh = figure(fig_idx); clf; 
            len = min(length(averageMags{7}),length(averageMags{8}));
            plot(averageMags{7}(1:len),'y','LineWidth',LineWidth);
            hold on;
            plot(averageMags{8}(1:len),'g','LineWidth',LineWidth);
            legend('App7', 'App8');
            
            fig_idx = fig_idx + 1;            
            fh = figure(fig_idx); clf; 
            len = min(length(averageMags{8}),length(averageMags{9}));
            plot(averageMags{8}(1:len),'y','LineWidth',LineWidth);
            hold on;
            plot(averageMags{9}(1:len),'g','LineWidth',LineWidth);
            legend('App8', 'App9');
        end
    
        %FFT Frequency               
        if DEBUG5 == 1
            averageMags = cell(1,length(app_mags));
            for i = 1:length(app_mags)
            tmpMags = cell(1,length(app_mags{i}));
            for j = 1:length(app_mags{i})
                tmpMags{j}= app_mags{i}{j}(:,2);
            end
            [averageMags{i},~] = DBA(tmpMags);
            end
  
            for i = 1:length(averageMags)
                curr_mag = averageMags{i};
                fig_idx = fig_idx + 1;            
                fh = figure(fig_idx); clf; 
                fft_ret = abs(fft(curr_mag));
                fft_ret = fft_ret(1:frequency_cnt); 
                
                bar(fft_ret);
                title('App Frequencies');
            end
        end
        
        if DEBUG8 == 1
            averageMags = cell(1,length(app_mags));
            for i = 1:length(app_mags)
            tmpMags = cell(1,length(app_mags{i}));
            for j = 1:length(app_mags{i})
                tmpMags{j}= app_mags{i}{j}(:,2);
            end
            [averageMags{i},~] = DBA(tmpMags);
            end
            
             for i = 1:length(averageMags)
                curr_mag = averageMags{i};
                fig_idx = fig_idx + 1;            
                fh = figure(fig_idx); clf; 
                fft_ret = abs(fft(curr_mag));
                fft_ret = fft_ret(1:frequency_cnt); 
                
                subplot(1,2,1)
                bar(fft_ret);
                title('Frequencies','FontSize',FontSize);
                subplot(1,2,2)
                plot(averageMags{i},'LineWidth',LineWidth);  
                title('Time Series','FontSize',FontSize);
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
                plot(app_mags{i}{j}(1:len,2),'Color',colors(j),'LineWidth',LineWidth);
                hold on;
                title('Raw Signals','FontSize',FontSize);
            end
            subplot(1,2,2)
            plot(averageMags{i},'LineWidth',LineWidth);
            title('Averaged center using DBA','FontSize',FontSize);
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
        len = [];
        averageMags = cell(1,length(app_mags));
        for i = 1:length(app_mags)
            tmpMags = cell(1,length(app_mags{i}));
            for j = 1:length(app_mags{i})
                tmpMags{j}= app_mags{i}{j}(:,2);
            end
            [averageMags{i},~] = DBA(tmpMags);
            len(end+1) = length(averageMags{i});
        end          
        len = min(len); 
        coeefMtx = ones(1,10)/10;  
        
        h = [1/2 1/2];
        binomialCoeff = conv(h,h);
        
        alpha = 0.25; 
                  
        for i=1:length(app_types)
            fig_idx = fig_idx + 1;
            fh = figure(fig_idx); clf;
            
            app = averageMags{i};
            smooth_app1 = filter(coeefMtx, 1, app);
            
            smooth_app2 = filter(binomialCoeff, 1, app);
            
            smooth_app3 = filter(alpha, [1 alpha-1], app);
            
            plot(app(1:len), 'y','LineWidth',LineWidth);
            hold on;
            plot(smooth_app1(1:len),'r','LineWidth',LineWidth);
            hold on;
            plot(smooth_app2(1:len),'g','LineWidth',LineWidth);            
            hold on;
            plot(smooth_app3(1:len),'b','LineWidth',LineWidth);
            legend({'Original Signal', 'Moving Avg Filter', 'Weighted Moving Avg Filter', 'Exponential Moving Avg Filter'},'Fontsize',FontSize);
        end
        end       
                
        %DEBUG2 weighted moving average smooth
        if DEBUG2 == 1
        len = [];
        averageMags = cell(1,length(app_mags));
        for i = 1:length(app_mags)
            tmpMags = cell(1,length(app_mags{i}));
            for j = 1:length(app_mags{i})
                tmpMags{j}= app_mags{i}{j}(:,2);
            end
            [averageMags{i},~] = DBA(tmpMags);
            len(end+1) = length(averageMags{i});
        end          
        len = min(len);   
        
            h = [1/2 1/2];
            binomialCoeff = conv(h,h);
            for n = 1:4
                binomialCoeff = conv(binomialCoeff,h);
            end
            
            for i=1:length(averageMags)
            fig_idx = fig_idx + 1;
            fh = figure(fig_idx); clf;
            app = averageMags{i};
            smooth_app = filter(binomialCoeff, 1, app);
            plot(app, 'b','LineWidth',LineWidth);
            hold on;
            plot(smooth_app,'y','LineWidth',LineWidth);
            
            legend({'Original Signal', 'Smoothed Signal'},'Fontsize',FontSize);        
            end
        end
        
        
        %DEBUG3 Exponential Moving Average filter 
        if DEBUG3 == 1
        len = [];
        averageMags = cell(1,length(app_mags));
        for i = 1:length(app_mags)
            tmpMags = cell(1,length(app_mags{i}));
            for j = 1:length(app_mags{i})
                tmpMags{j}= app_mags{i}{j}(:,2);
            end
            [averageMags{i},~] = DBA(tmpMags);
            len(end+1) = length(averageMags{i});
        end          
        len = min(len); 
        
            alpha = 0.25;            
           for i=1:length(averageMags)
             fig_idx = fig_idx + 1;
            fh = figure(fig_idx); clf;
            app = averageMags{i};
            smooth_app = filter(alpha, [1 alpha-1], app);
            plot(app, 'b','LineWidth',LineWidth);
            hold on;
            plot(smooth_app,'y','LineWidth',LineWidth);
            
            legend({'Original Signal', 'Smoothed Signal'},'Fontsize',FontSize);          
           end            
        end
end
function [app_mags, app_types] = read_single_app_input(input_dir, filename)
    load([input_dir filename '_single_app.mat'], '-mat');
    app_mags  = appMags;
    app_types = appTypes;
end


function [app_mags, app_types] = read_double_app_input(input_dir, filename)
    load([input_dir filename '_multi_app.mat'], '-mat');
    app_mags  = multiAppMags;
    app_types = multiAppTypes;
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