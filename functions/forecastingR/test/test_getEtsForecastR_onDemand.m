%% Train and test 'R forecast' and plot performance VS NP forecast

clearvars; close all; clc;

% Start the clock!
tic;

% === RUNNING OPTIONS ===
nCustomers = [100, 1000];
nAggregates = 3;
dataFile = '../../../data/demand_3639.csv';
trainControl.horizon = 48;
nIndTrain = 48*200;
nIndFcast = 48*7*4;


% === Seed for repeatability ===
rng(42);

% === READ IN DATA ===
demandData = csvread(dataFile);
nReads = size(demandData, 1);
nMeters = size(demandData, 2);

% === Train & Test Indexes ===
firstTrainIndex = nReads - nIndFcast - nIndTrain + 1;
trainInd = firstTrainIndex + (0:(nIndTrain-1));
testInd = max(trainInd) + (1:nIndFcast);

if(max(testInd) > nReads || firstTrainIndex < 1)
    warning('Test index out of bounds');
end

% Pre-allocate matrices of results
MSE_NP = zeros(length(nCustomers), nAggregates);
MSE_Rets = zeros(length(nCustomers), nAggregates);

MAPE_NP = zeros(length(nCustomers), nAggregates);
MAPE_Rets = zeros(length(nCustomers), nAggregates);

% Loop through each aggregate, in each number of customers of interest:
for ii =  1:length(nCustomers)
    
    nCust = nCustomers(ii);
    
%     for eachAgg = 1:nAggregates
    parfor eachAgg = 1:nAggregates
        
        % === SELECT & SUM RANDOM SUBSET OF CUSTOMERS ===
        customerIndexes = randsample(nMeters, nCust, false);
        demandSignal_full = sum(demandData(:, customerIndexes), 2);
        demandSignalTrain = demandSignal_full(trainInd);
        
        % Produce forecasts, one horizon at a time, add new data to time-series
        nFcasts = nIndFcast - trainControl.horizon + 1;
        MSEs_NP = zeros(nFcasts, 1);
        MSEs_Rets = zeros(nFcasts, 1);
        
        MAPEs_NP = zeros(nFcasts, 1);
        MAPEs_Rets = zeros(nFcasts, 1);
        
        origin = max(trainInd);
        dataSoFarTS = demandSignalTrain;
        
        for eachHorizon = 1:nFcasts
            
            fcastRets = getEtsForecastR(dataSoFarTS, trainControl);
            actual = demandSignal_full(origin + (1:trainControl.horizon));
            NP = dataSoFarTS((end-trainControl.horizon+1):end);
            
            MSEs_NP(eachHorizon) = mean((actual - NP).^2);
            MSEs_Rets(eachHorizon) = mean((actual - fcastRets).^2);
            
            MAPEs_NP(eachHorizon) = mean(abs(((actual-NP)./actual).*100));
            MAPEs_Rets(eachHorizon) = mean(abs(((actual-fcastRets)...
                ./actual).*100));
            
            if (eachHorizon==1)
                
                % === Plot forecast point VS actuals ===
                figure();
                plot(actual, fcastRets, '.');
                hold on; grid on;
                refline(1, 0);
                xlabel('Actual');
                ylabel('Predicted');
                hold off;
                
                % === Plot the forecast to show how it looks compared to historic, actual, NP
                figure();
                hold on; grid on;
                plot((1:trainControl.horizon)+trainControl.horizon, actual);
                plot((1:trainControl.horizon)+trainControl.horizon, NP);
                plot((1:trainControl.horizon)+trainControl.horizon, fcastRets);
                legend({'Actual', 'NP', 'ETS'});
            end
            
            dataSoFarTS = [dataSoFarTS; demandSignal_full(origin+1)]; %#ok<AGROW>
            origin = origin + 1;
        end
        
        MSE_NP(ii, eachAgg) = mean(MSEs_NP);
        MSE_Rets(ii, eachAgg) = mean(MSEs_Rets);
        
        MAPE_NP(ii, eachAgg) = mean(MAPEs_NP);
        MAPE_Rets(ii, eachAgg) = mean(MAPEs_Rets);
        
        figure(); hold on; grid on;
        plot(MSEs_NP);
        plot(MSEs_Rets);
        legend({'NP, mean MSEs', 'ETS, mean MSEs'});
        disp(['nCust: ', num2str(nCust), ', eachAgg: ',...
            num2str(eachAgg), ', DONE!']);
    end
end

disp('MSE_NP');
disp(MSE_NP);

disp('MSE_Rets');
disp(MSE_Rets);

disp('MAPE_NP');
disp(MAPE_NP);

disp('MAPE_Rets');
disp(MAPE_Rets);


% Print MAPE of automated forecast method and NP over aggregation level:
MAPE_NP_mean = mean(MAPE_NP, 2);
MAPE_NP_std = std(MAPE_NP, [], 2);

MAPE_Rets_mean = mean(MAPE_Rets, 2);
MAPE_Rets_std = std(MAPE_Rets, [], 2);

figure();
errorbar(nCustomers, MAPE_NP_mean, MAPE_NP_std);
hold on; grid on;
plot(nCustomers, MAPE_Rets_mean);
legend({'NP', 'ETS'});
xlabel('No. of Customers');
ylabel('MAPE [%] with std deviation shown');
hold off;

% Repeat for MSE: which is what auto-method most-likely seeks to minimise:
MSE_NP_mean = mean(MSE_NP, 2);
MSE_NP_std = std(MSE_NP, [], 2);

MSE_Rets_mean = mean(MSE_Rets, 2);
MSE_Rets_std = std(MSE_Rets, [], 2);

figure();
errorbar(nCustomers, MSE_NP_mean, MSE_NP_std);
hold on; grid on;
plot(nCustomers, MSE_Rets_mean);
legend({'NP', 'ETS'});
xlabel('No. of Customers');
ylabel('MSE [kWh/interval] with std deviation shown');
hold off;

toc;