function classifyEvent(testFile, trainFile)
    input_dir  = '../preprocess_mag/data/';

    frequency_cnt = 20;
    FontSize = 20;
    fig_idx = 0;

    if_corr_mtx = 1;
   
    training_set = 2;  
    %1: use lazy classification to compare every training sample.
    %2: pick center of each class by DBA
    
    feature_domain = 2;
    %1: time-domain
    %2: frequency domain
    
    distance_measure = 1;
    %1: correlation coefficient
    %2: dtw
    %3: maximal ratio combine
   
    if_cross_correlation = 1;
    %when classify, use cross-correlation to fix the shift in time.
    if_resample = 2;
    %1 resample
    %2 interpolation.

    %% --------------------
    %% Main starts
    %% --------------------
    if nargin == 1 
        [confusionMatrix, correlationMatrix] = classifyEventSelf(testFile);
        return;
    elseif nargin < 1
        testFile = '20160528.exp01';
        trainFile = '20160528.exp02';
    end
    [test_mags, test_app_types] = read_single_mat_input(input_dir,testFile);  
    [train_mags,train_app_types ] = read_single_mat_input(input_dir,trainFile);         

    if training_set == 1                %Lazy select
        [confusionMatrix, correlationMatrix] = classifynoDBA(test_mags, train_mags, feature_domain, distance_measure, if_cross_correlation, if_resample, frequency_cnt);
    elseif training_set == 2           %using DBA to pick a center of each training class   
        [confusionMatrix, correlationMatrix] = classifyByDBA(test_mags, train_mags, feature_domain, distance_measure, if_cross_correlation, if_resample, frequency_cnt);   
    end
    
    accuracy = retMeasure(confusionMatrix)
    fig_idx = fig_idx + 1;
    fh = figure(fig_idx); clf;
    if if_corr_mtx == 1
    subplot(1,2,1)
    imagesc(correlationMatrix);
    colorbar;
    title('correlationMatrix','FontSize',FontSize);

    subplot(1,2,2)
    imagesc(confusionMatrix);
    colorbar;
    title('confusionMatrix','FontSize',FontSize);
    else
    imagesc(confusionMatrix);
    colorbar;
    title('confusionMatrix','FontSize',FontSize);  
    end
end

function [confusionMatrix, correlationMatrix]= classifyByDBA(testMags, trainMags, feature_domain, distance_measure, if_cross_correlation, if_resample, frequency_cnt)
confusionMatrix = zeros(length(testMags));
correlationMatrix = zeros(length(testMags));

%% For training set, find Center of each class
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
    
      
for ti = 1:length(testMags)
    for ii = 1:length(testMags{ti})
        index = -1;
        highestInertia = -1;
        for tj = 1:length(averageMags)  
            ts1 = testMags{ti}{ii}(:,2);
            ts2 = averageMags{tj};
            event_type1 = ti;
            event_type2 = tj;
            %% Feature Selection 
            if feature_domain == 1              %Time-domain
            	if if_resample == 1             %Resample by downgrade the higher one
                	f1 = length(ts1)/max(testMags{ti}{ii}(:,1));
                    f2 = length(ts2)/max(averageTms{tj});
                    fs = min(f1,f2);
                        [p1,q1] = rat(fs,f1);
                        [p2,q2] = rat(fs,f2);   
                                        
                        ts1 = resample(ts1,p1,q1);
                        ts2 = resample(ts2,p2,q2);                        
                elseif if_resample == 2         %Resample by interpolation
                        timIdx = [testMags{ti}{ii}(:,1);averageTms{tj}(:,1)];
                        timIdx = unique(sort(timIdx));
                        [t1, index1] = unique(testMags{ti}{ii}(:,1));
                        [t2, index2] = unique(averageTms{tj}(:,1));
                        
                        ts1 = interp1(t1, ts1(index1), timIdx);
                        [idx,~] = find(isnan(ts1));
                        if length(idx) > 0
                            len = min(idx)-1;
                            ts1 = ts1(1:len);
                        end
                        ts2 = interp1(t2, ts2(index2), timIdx);
                        [idx,~] = find(isnan(ts2));
                        if length(idx) > 0
                            len = min(idx)-1;
                            ts2 = ts2(1:len);
                        end 
                 end
                    
                if if_cross_correlation == 1    %fix the shift in time
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
                    
                elseif feature_domain == 2      %frequency-domain
                	fft_ret1 = abs(fft(ts1));
                    ts1 = fft_ret1(1:frequency_cnt);
                    fft_ret2 = abs(fft(ts2));
                    ts2 = fft_ret2(1:frequency_cnt);
            end
            
            %% Distance Metric Selection
            len = min(length(ts1),length(ts2));
            ts1 = ts1(1:len);
            ts2 = ts2(1:len); 
            ts1 = (ts1 - min(ts1))/(max(ts1) - min(ts1));              
            ts2 = (ts2 - min(ts2))/(max(ts2) - min(ts2));
            if distance_measure == 1%correlation coefficient
                r = corrcoef(ts1,ts2);                
                r = r(1,2);
                r = r*r;
            elseif distance_measure == 2%dtw
            	r = dtw(ts1,ts2);
                r = 1/(r*r);
            %elseif distance_measure == 3%MRC
            end

            if (r > highestInertia)
                index = tj;
                highestInertia = r;
            end
            correlationMatrix(event_type1, event_type2) = correlationMatrix(event_type1, event_type2) + r;
        end
        confusionMatrix(event_type1, index) = confusionMatrix(event_type1, index) + 1;    
    end
end

confusionMatrix = confusionMatrix ./ repmat(sum(confusionMatrix,2), 1, size(confusionMatrix,2));
correlationMatrix = correlationMatrix ./ repmat(sum(correlationMatrix,2),1,size(correlationMatrix,2));
end
function accuracy = retMeasure(confusionMatrix)
app_cnt = length(confusionMatrix);
accuracy = trace(confusionMatrix)/app_cnt*100;
end
function [confusionMatrix, correlationMatrix] = classifynoDBA(test_mags, train_mags,feature_domain, distance_measure, if_cross_correlation, if_resample, frequency_cnt)
cnt_mat = zeros(length(train_mags));
confusionMatrix = zeros(length(train_mags));
correlationMatrix = zeros(length(train_mags));

for ti = 1:length(test_mags)
	for ii = 1:length(test_mags{ti})                
        tmp_corr = zeros(1, length(test_mags));
        tmp_cnt  = zeros(1, length(test_mags));                    
        for tj = 1:length(train_mags)
        	for jj=1:length(train_mags{tj})
            	ts1 = test_mags{ti}{ii}(:,2);
                ts2 = train_mags{tj}{jj}(:,2);
                event_type1 = ti;
                event_type2 = tj;                        
                %% Feature Selection     
                if feature_domain == 1              %Time-domain
                	if if_resample == 1             %Resample by downgrade the higher one
                        f1 = length(ts1)/max(test_mags{ti}{ii}(:,1));
                        f2 = length(ts2)/max(train_mags{tj}{jj}(:,1));
                        fs = min(f1,f2);
                        [p1,q1] = rat(fs,f1);
                        [p2,q2] = rat(fs,f2);   
                                        
                        ts1 = resample(ts1,p1,q1);
                        ts1 = ts1(1:end-2);
                        ts2 = resample(ts2,p2,q2);  
                        ts2 = ts2(1:end-2);
                    elseif if_resample == 2         %Resample by interpolation
                        timIdx = [test_mags{ti}{ii}(:,1);train_mags{tj}{jj}(:,1)];
                        timIdx = unique(sort(timIdx));
                        [t1, index1] = unique(test_mags{ti}{ii}(:,1));
                        [t2, index2] = unique(train_mags{tj}{jj}(:,1));
                        
                        ts1 = interp1(t1, ts1(index1), timIdx);
                        [idx,~]=find(isnan(ts1));
                        if length(idx) > 0
                            len = min(idx)-1;
                            ts1 = ts1(1:len);
                        end
                        ts2 = interp1(t2, ts2(index2), timIdx);
                        [idx,~] = find(isnan(ts2));
                        if length(idx) > 0
                            len = min(idx)-1;
                            ts2 = ts2(1:len);
                        end                       

                    end
                    
                    if if_cross_correlation == 1    %fix the shift in time
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
                    
                elseif feature_domain == 2          %frequency-domain
                	fft_ret1 = abs(fft(ts1));
                    ts1 = fft_ret1(1:frequency_cnt);
                    fft_ret2 = abs(fft(ts2));
                    ts2 = fft_ret2(1:frequency_cnt);
                end
                %% Distance Metric Selection
                
                if feature_domain == 1
                    len = min(length(ts1),length(ts2));
                    ts1 = ts1(1:len);
                    ts2 = ts2(1:len); 
                    ts1 = (ts1 - min(ts1))/(max(ts1) - min(ts1));              
                    ts2 = (ts2 - min(ts2))/(max(ts2) - min(ts2));                   
                end
                
                if distance_measure == 1%correlation coefficient
                	r = corrcoef(ts1,ts2);                
                    r = r(1,2);
                    r = r*r;
                elseif distance_measure == 2%dtw
                    r = dtw(ts1,ts2);
                    r = 1/(r*r);
                %elseif distance_measure == 3%MRC
                end
       
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