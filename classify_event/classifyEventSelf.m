%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Yi-Chao Chen @ UT Austin
%%
%%
%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [confusionMatrix, correlationMatrix] = classifyEventSelf(filename,frequency_cnt)
    if nargin < 1
        filename = '20160528.exp03'; 
        frequency_cnt = 20; %maximum frequency domain 
    elseif nargin == 1
        frequency_cnt = 100;
    end
    
    input_dir  = '../preprocess_mag/data/';
    fig_idx = 0;
    FontSize = 20;
    
    %DEBUG = 0;  % Raw Data + 1NN
    %DEBUG = 1;  % Average DTW + 1NN
    DEBUG = 2;  % FFT + 1NN

        
    %Average DTW + 1NN
    IF_CC = 1;
    IF_DTW = 1;
    
    %FFT + 1NN
    IF_AVERAGE = 1;
    
    
    %Raw Data + 1NN    
    %DEBUG01 = 0; %Default
    %DEBUG01 = 1; %cross correlation
    %DEBUG01 = 2; % moving average smooth
    %DEBUG01 = 3; %weighted moving average smooth
    %DEBUG01 = 4; %Exponential Moving Average filter 
    %% --------------------
    %% Main starts
    %% --------------------
    
    [appMags, appTypes] = read_single_mat_input(input_dir,filename);  
    if DEBUG == 0
        [confusionMatrix, correlationMatrix] = defaultClassify(appMags, appTypes, fig_idx,FontSize, DEBUG01);
    elseif DEBUG == 1
        [confusionMatrix, correlationMatrix] = classifyByDBA(appMags, appTypes, IF_CC, IF_DTW, fig_idx, FontSize);
    elseif DEBUG == 2
        [confusionMatrix, correlationMatrix] = classifyByFFT(appMags, appTypes, frequency_cnt, IF_AVERAGE, fig_idx,FontSize);
    end
end
function [confusionMatrix, correlationMatrix] = defaultClassify(mags, appTypes, fig_idx, FontSize, DEBUG01)
    
    FontSize = 20;
    
cnt_mat = zeros(length(appTypes));
confusionMatrix = zeros(length(appTypes));
correlationMatrix = zeros(length(appTypes));
for ti = 1:length(mags)
    for ii = 1:length(mags{ti})
        ts1 = mags{ti}{ii}(:,2);
        
        event_type1 = ti;
        tmp_corr = zeros(1, length(appTypes));
        tmp_cnt  = zeros(1, length(appTypes));       
        for tj = 1:length(mags)
            for jj = 1:length(mags{tj})
            if ti == tj && ii == jj; continue; end
        
            event_type2 = tj;
            ts2 = mags{tj}{jj}(:,2);
            
            if DEBUG01 == 1
                [C,Lags] = xcorr(ts1,ts2);
                [~,I] = max(abs(C));
                I = I - length(ts1);
                ts2 = circshift(ts2,I);
                if I < 0                  
                    for yy =length(ts2)-I+1:length(ts2)
                        ts2(yy) = ts2(length(ts2)-I);
                    end    
                end
            end
            
            
           
            if DEBUG01 == 2
                coeefMtx = ones(1,10)/10; 
                ts1 = filter(coeefMtx, 1, ts1);
                ts2 = filter(coeefMtx, 1, ts2);
            end
            
            if DEBUG01 == 3
            h = [1/2 1/2];
            binomialCoeff = conv(h,h);
            for n = 1:4
                binomialCoeff = conv(binomialCoeff,h);
            end
            ts1 = filter(binomialCoeff, 1, ts1);
            ts2 = filter(binomialCoeff, 1, ts2);
            end
            
            if DEBUG01 == 4
                alpha = 0.25;
                ts1 = filter(alpha, [1 alpha-1], ts1);
                ts2 = filter(alpha, [1 alpha-1], ts2);
            end
              
            len = min(length(ts1), length(ts2));
            ts1 = ts1(1:len);
            ts2 = ts2(1:len); 
            
            r = corrcoef(ts1, ts2);
            r = r(1,2);
            
            if isnan(r) , disp 'wrong';continue;end
            
            correlationMatrix(event_type1, event_type2) = correlationMatrix(event_type1, event_type2) + r;
            cnt_mat(event_type1, event_type2) = cnt_mat(event_type1, event_type2) + 1;

            tmp_corr(event_type2) = tmp_corr(event_type2) + r;
            tmp_cnt(event_type2)  = tmp_cnt(event_type2) + 1;       
            end
        end
        
        tmp_corr = tmp_corr ./ tmp_cnt;      
        [~,cate_idx] = max(tmp_corr);
        confusionMatrix(event_type1, cate_idx) = confusionMatrix(event_type1, cate_idx) + 1;
        
    end
end

    correlationMatrix = correlationMatrix ./ cnt_mat;
    
    confusionMatrix = confusionMatrix ./ repmat(sum(confusionMatrix,2), 1, size(confusionMatrix,2));
    
    fig_idx = fig_idx + 1;
    fh = figure(fig_idx); clf;
    
    subplot(1,2,1)
    imagesc(correlationMatrix);
    colorbar;
    title('Correlation Matrix','FontSize',FontSize);
    
    subplot(1,2,2)
    imagesc(confusionMatrix);
    colorbar;
    title('Confusion Matrix','FontSize',FontSize);
end
function [confusionMatrix, correlationMatrix]= classifyByDBA(mags, appTypes, IF_CC, IF_DTW, fig_idx, FontSize)
FontSize = 20;
confusionMatrix = zeros(length(appTypes));
correlationMatrix = zeros(length(appTypes));

%find average
averageMags = cell(1,length(mags));
for i = 1:length(mags)
    tmpMags = cell(1,length(mags{i}));
    for j = 1:length(mags{i})
    tmpMags{j}= mags{i}{j}(:,2);
    end
    [averageMags{i},~] = DBA(tmpMags);
end
    
%classify use 1-NN; metric: DTW       
for ti = 1:length(mags)
    for ii = 1:length(mags{ti})
        ts1 = mags{ti}{ii}(:,2);
        event_type1 = ti;
        index = -1;
        highestInertia = -1;
        for tj = 1:length(averageMags)           
            ts2 = averageMags{tj};
            event_type2 = tj;            
            dist = -1;
            
            if IF_CC == 1                
                [C,~] = xcorr(ts1,ts2);
                [~,I] = max(abs(C));
                I = I -length(ts1);
                ts2 = circshift(ts2,I);
                if I < 0                  
                    for yy =length(ts2)-I+1:length(ts2)
                        ts2(yy) = ts2(length(ts2)-I);
                    end    
                end
            end
                
            if IF_DTW == 1
                len = min(length(ts1), length(ts2));
                ts1 = ts1(1:len);
                ts2 = ts2(1:len); 
                r = corrcoef(ts1, ts2);
                dist = r(1,2)*r(1,2);
                if isnan(r) , disp 'wrong';continue;end
            else
                dist = dtw(ts1,ts2);
                dist = 1/(dist*dist);
            end
            
            
            if (dist > highestInertia)
                index = tj;
                highestInertia = dist;
            end
            correlationMatrix(event_type1, event_type2) = correlationMatrix(event_type1, event_type2) + dist;
        end


    confusionMatrix(event_type1, index) = confusionMatrix(event_type1, index) + 1;    
    end
end
%correlationMatrix = 1./correlationMatrix;
confusionMatrix = confusionMatrix ./ repmat(sum(confusionMatrix,2), 1, size(confusionMatrix,2));
correlationMatrix = correlationMatrix ./ repmat(sum(correlationMatrix,2),1,size(correlationMatrix,2));
    fig_idx = fig_idx + 1;
    fh = figure(fig_idx); clf;
    
    subplot(1,2,1)
    imagesc(correlationMatrix);
    colorbar;
    title('Correlation Matrix','FontSize',FontSize);
    
    subplot(1,2,2)
    imagesc(confusionMatrix);
    colorbar;
    title('Confusion Matrix','FontSize',FontSize);        
end
function [confusionMatrix, correlationMatrix] = classifyByFFT(appMags, appTypes, frequency_cnt, IF_AVERAGE, fig_idx,FontSize)

confusionMatrix = zeros(length(appTypes));
correlationMatrix = zeros(length(appTypes));

[featureMatrix, labelMatrix] = extractFrequency(appMags, appTypes, frequency_cnt);

if IF_AVERAGE == 0
    [confusionMatrix, correlationMatrix]= tradtionalClassify(featureMatrix,labelMatrix,appTypes, fig_idx,FontSize);
else    
    confusionMatrix = zeros(length(appTypes));
    correlationMatrix = zeros(length(appTypes));
    %find train average
    averageMags = cell(1,length(appMags));
    avgTrainFeatures = {};
    avgTrainLabels = {};

    for i = 1:length(appMags)
    tmpMags = cell(1,length(appMags{i}));
    for j = 1:length(appMags{i})
    tmpMags{j}= appMags{i}{j}(:,2);
    end
    [averageMags{i},~] = DBA(tmpMags);
    end

    %find train features
    for ti = 1:length(averageMags)
	curr_mag = averageMags{ti};
	fft_ret = abs(fft(curr_mag));
	fft_ret = fft_ret(1:frequency_cnt);
	avgTrainFeatures{ti} = fft_ret;
	avgTrainLabels{ti} = ti;
    end

    %classify
    for ti =1:length(featureMatrix)     
        index = -1;
        highestInertia = -1;
    
        for tj=1:length(avgTrainFeatures)
            ts1 = featureMatrix{ti};
            ts2 = avgTrainFeatures{tj};
            label1 = labelMatrix{ti}; 
            label2 = avgTrainLabels{tj};
            
            if length(ts2) ~= length(ts1)
            len = min(length(ts1),length(ts2));
            ts1 = ts1(1:len);
            ts2 = ts2(1:len);
            end
            
            r = corrcoef(ts1,ts2);
            dist = r(1,2)*r(1,2);
            
            if (dist > highestInertia)
                index = tj;
                highestInertia = dist;
            end
            
            correlationMatrix(label1, label2) = correlationMatrix(label1, label2) + dist;
        end
        
        confusionMatrix(label1, index) = confusionMatrix(label1, index) + 1; 
    end
    confusionMatrix = confusionMatrix ./ repmat(sum(confusionMatrix,2), 1, size(confusionMatrix,2));
    correlationMatrix = correlationMatrix ./ repmat(sum(correlationMatrix,2),1,size(correlationMatrix,2));
end
fig_idx = fig_idx + 1;
fh = figure(fig_idx); clf;

subplot(1,2,1)
imagesc(correlationMatrix);
colorbar;
title('correlationMatrix','FontSize',FontSize);

subplot(1,2,2)
imagesc(confusionMatrix);
colorbar;
title('confusionMatrix','FontSize',FontSize);

end

function [confusionMatrix, correlationMatrix]= tradtionalClassify(featureMatrix,labelMatrix,app_types, fig_idx, FontSize)
confusionMatrix = zeros(length(app_types));
correlationMatrix = zeros(length(app_types));
cntMatrix = zeros(length(app_types));
for ti =1:length(featureMatrix)
    ts1 = featureMatrix{ti};
    label1 = labelMatrix{ti};
    
    tmp_corr = zeros(1, length(app_types));
    tmp_cnt  = zeros(1, length(app_types));
    
    for tj=1:length(featureMatrix)
        if ti==tj; continue; end
        ts2 = featureMatrix{tj};
        label2 = labelMatrix{tj};
        r = corrcoef(ts1,ts2);
        r = r(1,2);
        
        correlationMatrix(label1,label2)= correlationMatrix(label1,label2)+r;
        cntMatrix(label1,label2) = cntMatrix(label1,label2)+1;
        tmp_corr(label2) = tmp_corr(label2) + r;
        tmp_cnt(label2)  = tmp_cnt(label2) + 1;
    end
    
    tmp_corr = tmp_corr ./ tmp_cnt;
    [~,cate_idx] = max(tmp_corr);
    confusionMatrix(label1, cate_idx) = confusionMatrix(label1, cate_idx) + 1;
end
correlationMatrix = correlationMatrix/cntMatrix;
end
function [featureMatrix, labelMatrix] = extractFrequency(app_mags,app_types,frequency_cnt)
featureMatrix = {};
sample_cnt = 0;

for ti = 1:length(app_types)
    curr_label = ti;   
    for ii = 1:length(app_mags{ti})
        sample_cnt = sample_cnt+1;
        
        curr_mag = app_mags{ti}{ii}(:,2);
 
        fft_ret = abs(fft(curr_mag));
        fft_ret = fft_ret(1:frequency_cnt);  
        featureMatrix{sample_cnt}=fft_ret; 
        labelMatrix{sample_cnt} = curr_label;
    end
end
end
function [appMags, appTypes] = read_single_mat_input(input_dir, filename)
    load([input_dir filename '_single_app.mat'], '-mat');
    appMags  = appMags;
    appTypes = appTypes;
end
function score = dtw(S,T)
    costM = zeros(length(S),length(T));    
    costM(1,1) = (S(1)-T(1))^2;
    
    for i=2:length(S)
        costM(i,1)= costM(i-1,1)+ (S(i)-T(1))^2;
    end
    for i=2:length(T)
        costM(1,i)= costM(1,i-1)+ (S(1)-T(i))^2;
    end
    for i=2:length(S)
        for j=2:length(T)
            costM(i,j)=min(min(costM(i-1,j-1),costM(i,j-1)),costM(i-1,j))+(S(i)-T(j))^2;
        end
    end
    score = sqrt(costM(length(S),length(T)));
end