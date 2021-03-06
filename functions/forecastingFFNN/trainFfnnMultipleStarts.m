% file: trainFfnnMultipleStarts.m
% auth: Khalid Abdulla
% date: 25/02/2016
% brief: run trainFfnn multiple times and return best performing model
            % based on hold-out set

function bestNet = trainFfnnMultipleStarts( demand, trainControl )

% INPUTS
% demand:       time-history of demands on which to train [nObs x 1]
% trainControl: structure of train control parameters

% OUTPUTS
% bestNet:      best NN found

%% Set default values for optional train control pars
trainControl = setDefaultValues(trainControl,...
    {'nStart', 3, 'minimiseOverFirst', trainControl.horizon,...
    'suppressOutput', true, 'nNodes', 50});

%% Parse trainControl object:
trainRatio = trainControl.trainRatio;
nStart = trainControl.nStart;
minimiseOverFirst = trainControl.minimiseOverFirst;
nLags = trainControl.nLags;
horizon = trainControl.horizon;
performanceDifferenceThreshold = ...
    trainControl.performanceDifferenceThreshold;

%% Produce data formated for NN training
[ featureVectors, responseVectors ] = ...
    computeFeatureResponseVectors( demand, nLags, horizon);

%% Divide data for training and testing
nObservations = size(featureVectors,2);
nObservationsTrain = floor(nObservations*trainRatio);
nObservationsTest = nObservations - nObservationsTrain;
idxs = randperm(nObservations);
idxsTrain = idxs(1:nObservationsTrain);
idxsTest = idxs(nObservationsTrain+(1:nObservationsTest));
featureVectorsTrain = featureVectors(:,idxsTrain);
responseVectorsTrain = responseVectors(:,idxsTrain);
featureVectorsTest = featureVectors(:,idxsTest);
responseVectorsTest = responseVectors(:,idxsTest);

%% Train multiple networks and evaluate performances
performance = zeros(1, nStart);
allNets = cell(1, nStart);
allForecasts = cell(1, nStart);

for iStart = 1:nStart
    allNets{1, iStart} = trainFfnn( featureVectorsTrain,...
        responseVectorsTrain, trainControl);
    
    allForecasts{1, iStart} = forecastFfnn(allNets{1, iStart},...
        featureVectorsTest, trainControl);
    
    performance(1, iStart) = mean(mse(responseVectorsTest( ...
        1:minimiseOverFirst, :), ....
        allForecasts{1, iStart}(1:minimiseOverFirst, :)), 2);
end

[~, idxBest] = min(performance);

%% Output performance of each model if difference is > threshold
percentageDifference = (max(performance) - min(performance)) / ...
    min(performance);

if percentageDifference > performanceDifferenceThreshold
    
    disp(['Percentage Difference: ' num2str(100*percentageDifference)...
        '. Performances: ' num2str(performance)]);
end

bestNet = allNets{1, idxBest};

end
