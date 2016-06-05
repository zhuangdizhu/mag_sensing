%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Yi-Chao Chen @ UT Austin
%%
%%
%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [confusionMatrix, correlationMatrix] = classifyEventSelf(filename,frequency_cnt)
    if nargin < 1
        filename = '20160528.exp01'; 
        frequency_cnt = 30; %maximum frequency domain 
    end
    
    input_dir  = '../preprocess_mag/data/';
    fig_idx = 0;
    FontSize = 20;
    if_corr_mtx = 1;
    
    
    training_set = 2; 
    %1: use lazy classification to compare every training sample.
    %2: pick center of each class by DBA

    feature_domain = 1;
    %1: time-domain feature
    %2: frequency domain feature
    
    distance_measure = 3;
    %1: correlation coefficient
    %2: dtw
    %3: maximal ratio combine
   
    if_smooth = 0;
    %0 no smooth
    %1 moving average
    %2 weighted moving average
    %3 exponential moving average
    
    if_cross_correlation = 1;
    %when classify, use cross-correlation to fix the shift in time.
    if_resample = 0;
    %0 no resample
    %1 resample
    %2 interpolation.
    
    
    
    [mags, ~] = read_single_mat_input(input_dir,filename);  
 
    if training_set == 1                %Lazy select by comparing testing sample with each training sample
        [confusionMatrix, correlationMatrix] = classifynoDBA(mags, feature_domain, distance_measure, if_smooth, if_cross_correlation, if_resample, frequency_cnt);
    elseif training_set == 2           %using DBA to pick a center of each training class   
        [confusionMatrix, correlationMatrix] = classifyByDBA(mags, feature_domain, distance_measure, if_cross_correlation, if_resample, frequency_cnt);   
    end
    
    fig_idx = fig_idx + 1;
    figure(fig_idx); clf;
    if if_corr_mtx == 1
        subplot(1,2,1)
        imagesc(correlationMatrix);
        colorbar;
        title('Correlation Matrix','FontSize',FontSize);
    
        subplot(1,2,2)
        imagesc(confusionMatrix);
        colorbar;
        title('Confusion Matrix','FontSize',FontSize); 
    else
        imagesc(confusionMatrix);
        colorbar;
        title('Confusion Matrix','FontSize',FontSize); 
    end
 accuracy = retMeasure(confusionMatrix)       
end


function [confusionMatrix, correlationMatrix] = classifyByDBA(mags, feature_domain, distance_measure, if_cross_correlation, if_resample, frequency_cnt)

%% For training set, find Center of each class
averageTrainMags = cell(1,length(mags));
averageTrainTms = cell(1,length(mags));

correlationMatrix = zeros(length(mags));
confusionMatrix = zeros(length(mags));

for i = 1:length(mags)
    tmpMags = cell(1,length(mags{i}));
    for j = 1:length(mags{i})
    tmpMags{j}= mags{i}{j}(:,2);
    %numel(tmpMags{i})
    end
    [averageTrainMags{i},idx] = DBA(tmpMags);
    averageTrainTms{i} = mags{i}{idx}(:,1);
end

%% Correlation Matrix
for i = 1:length(averageTrainMags)
    for j = 1:length(averageTrainMags)
        ts11 = averageTrainMags{i};
        ts12 = averageTrainMags{j};
        event_type1 = i;
        event_type2 = j;
        ts21 = NaN;
        ts22 = NaN;                                 % Feature Selection 
    if feature_domain == 1                          %Time-domain
        if if_cross_correlation == 1                %fix the shift in time
            [C,~] = xcorr(ts11,ts12);
            [~,I] = max(abs(C));
            I = I -length(ts11);
        	ts12 = circshift(ts12,I);
            if I < 0                  
                for yy =length(ts12)-I+1:length(ts12)
                	ts12(yy) = ts12(length(ts12)-I);
            	end
        	end
        end
                    
     elseif feature_domain == 2          %frequency-domain
        	fft_ret1 = abs(fft(ts11));
            ts11 = fft_ret1(1:frequency_cnt);
            ts21 = ts11;
            fft_ret2 = abs(fft(ts12));
            ts12 = fft_ret2(1:frequency_cnt);
            ts22 = ts12;
    end

    
    if distance_measure == 1         % correlation coefficient  
        len = min(length(ts11),length(ts12));
        ts11 = ts11(1:len);
        ts12 = ts12(1:len); 
        ts11 = (ts11 - min(ts11))/(max(ts11) - min(ts11));              
        ts12 = (ts12 - min(ts12))/(max(ts12) - min(ts12));       
        r = corrcoef(ts11,ts12);                
        r = r(1,2);
        r = r*r;
    
    elseif distance_measure == 2    %dtw
    	r = abs(dtw(ts11,ts12))+1;
        r = 1/(r*r);
    elseif distance_measure == 3
        tmp1 = abs(dtw(ts11,ts12))+1;
        tmp1 = 1/(tmp1*tmp1);
        
        len = min(length(ts11),length(ts12));
        ts11 = ts11(1:len);
        ts12 = ts12(1:len); 
        ts11 = (ts11 - min(ts11))/(max(ts11) - min(ts11));              
        ts12 = (ts12 - min(ts12))/(max(ts12) - min(ts12));       
        tmp2 = corrcoef(ts11,ts12);                
        tmp2 = tmp2(1,2);
        tmp2 = tmp2*tmp2;  
        
        r = tmp1 + tmp2;
    end
    	correlationMatrix(event_type1, event_type2) = correlationMatrix(event_type1, event_type2) + r;

    end
end

correlationMatrix = correlationMatrix ./ repmat(sum(correlationMatrix,2),1,size(correlationMatrix,2))
   


% Classify
for ti = 1:length(mags)
    for ii = 1:length(mags{ti})
        index = -1;
        highestInertia = -1;
        tmp_f1 = zeros(1,length(mags));
        tmp_f2 = zeros(1,length(mags));
        tmp_f3 = zeros(1,length(mags));
        for tj = 1:length(averageTrainMags)  
            ts11 = mags{ti}{ii}(:,2);
            ts12 = averageTrainMags{tj};
            event_type1 = ti;
            
            %% Feature Selection 
            if feature_domain == 1              %Time-domain
            	if if_resample == 1             %Resample by downgrade the higher one
                	f1 = length(ts11)/max(mags{ti}{ii}(:,1));
                    f2 = length(ts12)/max(averageTrainTms{tj});
                    fs = min(f1,f2);
                        [p1,q1] = rat(fs,f1);
                        [p2,q2] = rat(fs,f2);   
                                        
                        ts11 = resample(ts11,p1,q1);
                        ts12 = resample(ts12,p2,q2);                        
                elseif if_resample == 2         %Resample by interpolation
                	timIdx = [mags{ti}{ii}(:,1);averageTrainTms{tj}(:,1)];
                        timIdx = unique(sort(timIdx));
                        [t1, index1] = unique(mags{ti}{ii}(:,1));
                        [t2, index2] = unique(averageTrainTms{tj}(:,1));
                        
                        ts11 = interp1(t1, ts11(index1), timIdx);
                        ts11 = ts11(1:end-2);
                        ts12 = interp1(t2, ts12(index2), timIdx);
                        ts12 = ts12(1:end-2); 
                 end
                    
                if if_cross_correlation == 1    %fix the shift in time
                        [C,~] = xcorr(ts11,ts12);
                        [~,I] = max(abs(C));
                        I = I -length(ts11);
                        ts12 = circshift(ts12,I);
                        if I < 0                  
                            for yy =length(ts12)-I+1:length(ts12)
                                ts12(yy) = ts12(length(ts12)-I);
                            end
                        end
                end
                    
                elseif feature_domain == 2      %frequency-domain
                	fft_ret1 = abs(fft(ts11));
                    ts11 = fft_ret1(1:frequency_cnt);
                    fft_ret2 = abs(fft(ts12));
                    ts12 = fft_ret2(1:frequency_cnt);
            end
            
            %% Distance Metric Selection
            len = min(length(ts11),length(ts12));
            ts11 = ts11(1:len);
            ts12 = ts12(1:len); 
            ts11 = (ts11 - min(ts11))/(max(ts11) - min(ts11));              
            ts12 = (ts12 - min(ts12))/(max(ts12) - min(ts12));
            if distance_measure == 1%correlation coefficient               
                r = corrcoef(ts11,ts12);                
                r = r(1,2);
                r = r*r;
                tmp_f1(event_type1,event_type2) = tmp_f1(event_type1,event_type2) + r;
            elseif distance_measure == 2%dtw
            	r = dtw(ts11,ts12)+1;
                r = 1/(r*r);
                tmp_f1(event_type1,event_type2) = tmp_f1(event_type1,event_type2) + r;
            elseif distance_measure == 3%MRC
                tmp = dtw(ts11,ts12)+1;
                tmp = 1/(tmp*tmp);   
                
                r = corrcoef(ts11,ts12);                
                r = r(1,2);
                r = r*r;
                r = r + tmp;
            end

            if (r > highestInertia)
                index = tj;
                highestInertia = r;
            end
        end
        confusionMatrix(event_type1, index) = confusionMatrix(event_type1, index) + 1;    

    end
    
    
end

confusionMatrix = confusionMatrix ./ repmat(sum(confusionMatrix,2), 1, size(confusionMatrix,2));
end
function [confusionMatrix, correlationMatrix] = classifynoDBA(mags,feature_domain, distance_measure, if_smooth, if_cross_correlation, if_resample, frequency_cnt)
cnt_mat = zeros(length(mags));
confusionMatrix = zeros(length(mags));
correlationMatrix = zeros(length(mags));

for ti = 1:length(mags)
	for ii = 1:length(mags{ti})                
        tmp_corr = zeros(1, length(mags));
        tmp_cnt  = zeros(1, length(mags));                    
        for tj = 1:length(mags)
        	for jj=1:length(mags{tj})
                if ti == tj && ii == jj, continue; end
                
            	ts1 = mags{ti}{ii}(:,2);
                ts2 = mags{tj}{jj}(:,2);
                event_type1 = ti;
                event_type2 = tj;                        
                %% Feature Selection     
                if feature_domain == 1              %Time-domain
                	if if_resample == 1             %Resample by downgrade the higher one
                        f1 = length(ts1)/max(mags{ti}{ii}(:,1));
                        f2 = length(ts2)/max(mags{tj}{jj}(:,1));
                        fs = min(f1,f2);
                        [p1,q1] = rat(fs,f1);
                        [p2,q2] = rat(fs,f2);   
                                        
                        ts1 = resample(ts1,p1,q1);
                        ts2 = resample(ts2,p2,q2);                        
                    elseif if_resample == 2         %Resample by interpolation
                        timIdx = [mags{ti}{ii}(:,1);mags{tj}{jj}(:,1)];
                        timIdx = unique(sort(timIdx));
                        [t1, index1] = unique(mags{ti}{ii}(:,1));
                        [t2, index2] = unique(mags{tj}{jj}(:,1));
                        
                        ts1 = interp1(t1, ts1(index1), timIdx);
                        ts1 = ts1(1:end-2);
                        ts2 = interp1(t2, ts2(index2), timIdx);
                        ts2 = ts2(1:end-2); 
                    end
                    
                    if if_smooth == 1
                        coeefMtx = ones(1,10)/10;
                        ts1 = filter(coeefMtx, 1, ts1);
                        ts2 = filter(coeefMtx, 1, ts2);
                    elseif if_smooth == 2
                        h = [1/2 1/2];
                        binomialCoeff = conv(h,h);
                        for n = 1:4
                            binomialCoeff = conv(binomialCoeff,h);
                        end
                        ts1 = filter(binomialCoeff, 1, ts1);
                        ts2 = filter(binomialCoeff, 1, ts2);
                    elseif if_smooth == 3
                        alpha = 0.25;            
                        ts1 = filter(alpha, [1 alpha-1], ts1);
                        ts2 = filter(alpha, [1 alpha-1], ts2);
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
                
                if distance_measure == 1 %correlation coefficient

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
function accuracy = retMeasure(confusionMatrix)
app_cnt = length(confusionMatrix);
accuracy = trace(confusionMatrix)/app_cnt*100;
end