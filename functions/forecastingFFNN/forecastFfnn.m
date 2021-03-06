% file: forecastFfnn.m
% auth: Khalid Abdulla
% date: 21/10/2015
% brief: Given a neural network and some new inputs for a fcast origin,
%       create a new forecast.

function [ forecast ] = forecastFfnn( net, demand, trainControl )

% INPUT:
% net: MATLAB trained neural network object
% demand: input data [nInputs x nObservations]
% trainControl: structure of train controllering parameters

% OUPUT:
% forecast: output forecast [nResponses x nObservations]
trainControl; %#ok<VUNUS>
nLags = net.inputs{1}.size;
x = demand((end - nLags + 1):end, :);
forecast = net(x);

end
