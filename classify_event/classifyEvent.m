function classifyEvent(testFile, trainFile)
    input_dir  = '../preprocess_mag/data/';
    %DEBUG = 0;  %use default
    %DEBUG = 1;  %use DTW
    DEBUG = 2;  %use FFT
    
    
    %when using DTW
    if_resample = 0;
    if_cc = 0;
    
    %when using FFT
    if_average = 1;
    test_frequency = 100;
    train_frequency = 100;
    
    %when default
    DEBUG01 = 0; %resample by reduce the higher rate
    DEBUG02 = 1; %resample by interpolation
    
    FontSize = 20;
    fig_idx = 0;


    %% --------------------
    %% Main starts
    %% --------------------
    if nargin == 1 
        [confusionMatrix, correlationMatrix] = classifyEventSelf(testFile);
    elseif nargin < 1
        testFile = '20160528.exp03';
        trainFile = '20160529.exp01';
    end
    [test_mags, test_app_types] = read_single_mat_input(input_dir,testFile);  
    [train_mags,train_app_types ] = read_single_mat_input(input_dir,trainFile);         
    if DEBUG == 0       %Default
        [confusionMatrix, correlationMatrix] = defaultClassify(test_mags, train_mags,DEBUG01, DEBUG02);
    elseif DEBUG == 1   %DTW
        [confusionMatrix, correlationMatrix] = classifyByDBA(test_mags, train_mags, if_resample, if_cc);   
    elseif DEBUG == 2   %FFT
        [confusionMatrix, correlationMatrix] = classifyByFFT(test_mags, train_mags,train_app_types, test_frequency, train_frequency, if_average);         
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
function [appMags, appTypes] = read_single_mat_input(input_dir, filename)
    load([input_dir filename '_single_app.mat'], '-mat');
    appMags  = appMags;
    appTypes = appTypes;
end
function [confusionMatrix, correlationMatrix]= classifyByDBA(testMags, trainMags, if_resample, if_cc)
confusionMatrix = zeros(length(testMags));
correlationMatrix = zeros(length(testMags));

%find average
averageMags = cell(1,length(trainMags));
averageTms = cell(1,length(trainMags));
for i = 1:length(trainMags)
    tmpMags = cell(1,length(trainMags{i}));
    for j = 1:length(trainMags{i})
    tmpMags{j}= trainMags{i}{j}(:,2);
    %numel(tmpMags{i})
    end
    [averageMags{i},idx] = DBA(tmpMags);
    averageTms{i} = trainMags{i}{idx}(:,1);
end
    
%classify use 1-NN; metric: DTW        
for ti = 1:length(testMags)
    for ii = 1:length(testMags{ti})
        event_type1 = ti;
        index = -1;
        highestInertia = -1;
        for tj = 1:length(averageMags)  
            ts1 = testMags{ti}{ii}(:,2);
            ts2 = averageMags{tj};
            event_type2 = tj;
            
            
            %resample
            if if_resample == 1
                
            f1 = floor(length(ts1)/max(testMags{ti}{ii}(:,1)));
            f2 = floor(length(ts2)/max(averageTms{tj}(:,1)));
            fs = min(f1,f2);
            [p1,q1] = rat(fs/f1);
            [p2,q2] = rat(fs/f2);   
                                        
            ts1 = resample(ts1,p1,q1);
            ts2 = resample(ts2,p2,q2);
            length(ts1);
            length(ts2);
            end
            
            %cross correlation
            if if_cc == 1
                [C,~] = xcorr(ts1,ts2);
                [~,I] = max(abs(C));
                I = I -length(ts1);
                ts2 = circshift(ts2,I);
                if I < 0                  
                    for yy =length(ts2)-I+1:length(ts2)
                        ts2(yy) = ts2(length(ts2)-I);
                    end    
                end
                len = min(length(ts1), length(ts2));
                ts1 = ts1(1:len);
                ts2 = ts2(1:len); 
                r = corrcoef(ts1, ts2);
                dist = r(1,2);            
                if isnan(r) , disp 'wrong';continue;end  
            else
                dist = 1/dtw(ts1,ts2);
            end
            
            dist = dist * dist;
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
function [confusionMatrix, correlationMatrix] = defaultClassify(test_mags, train_mags,DEBUG1,DEBUG2)
cnt_mat = zeros(length(train_mags));
confusionMatrix = zeros(length(train_mags));
correlationMatrix = zeros(length(train_mags));

for ti = 1:length(test_mags)
            for ii = 1:length(test_mags{ti})
                event_type1 = ti;                
                tmp_corr = zeros(1, length(test_mags));
                tmp_cnt  = zeros(1, length(test_mags));                    
                for tj = 1:length(train_mags)
                    for jj=1:length(train_mags{tj})
                        ts1 = test_mags{ti}{ii}(:,2);
                        ts2 = train_mags{tj}{jj}(:,2);
                        event_type2 = tj;
                        
                        if DEBUG1 == 1 %Resample by downgrade the higher one                                                    
                        f1 = length(ts1)/max(test_mags{ti}{ii}(:,1));
                        f2 = length(ts2)/max(train_mags{tj}{jj}(:,1));
                        fs = min(f1,f2);
                        [p1,q1] = rat(fs,f1);
                        [p2,q2] = rat(fs,f2);   
                                        
                        ts1 = resample(ts1,p1,q1);
                        ts2 = resample(ts2,p2,q2);
                        end
                      
                        if DEBUG2 == 1 %Resample by interpolation
                        timIdx = [test_mags{ti}{ii}(:,1);train_mags{tj}{jj}(:,1)];
                        timIdx = unique(sort(timIdx));
                        [t1, index1] = unique(test_mags{ti}{ii}(:,1));
                        [t2, index2] = unique(train_mags{tj}{jj}(:,1));
                        
                        ts1 = interp1(t1, ts1(index1), timIdx);
                        ts1 = ts1(1:end-2);
                        ts2 = interp1(t2, ts2(index2), timIdx);
                        ts2 = ts2(1:end-2);                        
                        end
                        
                        ts1 = (ts1 - min(ts1))/(max(ts1) - min(ts1));              
                        ts2 = (ts2 - min(ts2))/(max(ts2) - min(ts2));
                        
                        len = min(length(ts1),length(ts2));
                        ts1 = ts1(1:len);
                        ts2 = ts2(1:len); 
                        
                        r = corrcoef(ts1, ts2); 
                        if isnan(r), disp 'wong corrcoef'; return;end
                        r = r(1,2); 
                        
                        correlationMatrix(event_type1, event_type2) = correlationMatrix(event_type1, event_type2) + r;
                        cnt_mat(event_type1, event_type2) = cnt_mat(event_type1, event_type2)+1;
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

end
function [confusionMatrix, correlationMatrix] = classifyByFFT(test_mags, train_mags,train_app_types, test_frequency, train_frequency, if_average)

[testFeatures, testLabels] = extractFrequency(test_mags,test_frequency);
if if_average == 0   
    [trainFeatures, trainLabels] = extractFrequency(train_mags,train_frequency);
    [confusionMatrix, correlationMatrix] = NNClassify(testFeatures,trainFeatures,testLabels, trainLabels,train_app_types);
else
    trainFeatures = {};
    trainLabels = {};
    averageTrainMags = cell(1,length(train_mags));
    averageTrainTms = cell(1,length(train_mags));
    %find average
    for i = 1:length(train_mags)
        tmpMags = cell(1,length(train_mags{i}));
        for j = 1:length(train_mags{i})
        tmpMags{j}= train_mags{i}{j}(:,2);
        end
        [averageTrainMags{i},idx] = DBA(tmpMags);
        averageTrainTms{i} = train_mags{i}{idx}(:,1);
    end
    %find features
    for ti = 1:length(averageTrainMags)
        curr_mag = averageTrainMags{ti};
        fft_ret = abs(fft(curr_mag));
        fft_ret = fft_ret(1:train_frequency);
        trainFeatures{ti} = fft_ret;
        trainLabels{ti} = ti;
    end
    
    %classify
    confusionMatrix = zeros(length(train_app_types));
    correlationMatrix = zeros(length(train_app_types));
    cntMatrix = zeros(length(train_app_types));

    for ti =1:length(testFeatures)     
        index = -1;
        highestInertia = -1;
    
        for tj=1:length(trainFeatures)
            ts1 = testFeatures{ti};
            ts2 = trainFeatures{tj};
            label1 = testLabels{ti}; 
            label2 = trainLabels{tj};
            
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
end
function [featureMatrix, labelMatrix] = extractFrequency(app_mags,frequency_cnt)
featureMatrix = {};
sample_cnt = 0;
for ti = 1:length(app_mags)
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
function [confusionMatrix, correlationMatrix] = NNClassify(testFeatures,trainFeatures,testLabels, trainLabels,train_app_types)
confusionMatrix = zeros(length(train_app_types));
correlationMatrix = zeros(length(train_app_types));
cntMatrix = zeros(length(train_app_types));

for ti =1:length(testFeatures)
    ts1 = testFeatures{ti};
    label1 = testLabels{ti};
    
    tmp_corr = zeros(1, length(train_app_types));
    tmp_cnt  = zeros(1, length(train_app_types));
    
    for tj=1:length(trainFeatures)
        if ti==tj; continue; end
        ts2 = trainFeatures{tj};
        label2 = trainLabels{tj};
        if length(ts2) ~= length(ts1)
            len = min(length(ts1),length(ts2));
            ts1 = ts1(1:len);
            ts2 = ts2(1:len);
        end
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
