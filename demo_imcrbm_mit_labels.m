% Implicit Mixture of Conditional Restricted Boltzmann Machines
% Version 1.000 
%
% Code provided by Graham Taylor
%
% For more information, see:
%    http://www.uoguelph.ca/~gwtaylor/publications/cvpr2010/
%
% Permission is granted for anyone to copy, use, modify, or distribute this
% program and accompanying programs and documents for any purpose, provided
% this copyright notice is retained and prominently displayed, along with
% a note saying that the original programs are available from our
% web page.
% The programs and documents are distributed without any warranty, express or
% implied.  As the programs were written for research purposes only, they have
% not been tested to the degree that would be advisable in any important
% application.  All use of these programs is entirely at the user's own risk.
%
% This program trains an implicit mixture of CRBMs where
% visible, Gaussian-distributed inputs are connected to
% hidden, binary, stochastic feature detectors using symmetrically
% weighted connections. Learning is done with K-step Contrastive Divergence.
% Directed connections are present, from the past nt configurations of the
% visible units to the current visible units (pastvis), and the past nt
% configurations of the visible units to the current hidden units
% (pasthid) 
% Training is supervised, using motion-style labels

%clear all; close all;
more off;   %turn off paging

%Change this to a writeable path on your system!
snapshot_root = '/tmp/Experiments/implicit/snapshots/';

% Model & training properties
% Note that additional parameters (learning rates, sparsity, etc.)
%    are set in mixgaussiancrbm.m
numhid1 = 200;     % number of hidden units
numcomp = 2;      % number of discrete mixture components
numepochs = 200;  % number of training epochs (passes through dataset)
cdsteps = 10;     % number of Gibbs steps per CD iteration
pastnoise = 1;    % std of noise to add to past inputs (for robustness)

snapshotevery=10; %write out a snapshot of the weights every xx epochs

gsd=1;          % fixed standard dev on Gaussian visibles

%how-many timesteps do we look back for directed connections
%this is what we call the "order" of the model 
n1 = 6;  % first layer

% these aliases are used in learning code
nt = n1; 
numhid = numhid1; 

%initialize RAND,RANDN to a different state
rand('state',sum(100*clock))
randn('state',sum(100*clock))

%Our important Motion routines are in a subdirectory
addpath('./Motion')

%set up training data (hold out the last sequences for testing)
make_mit_walk_jog_withtest

%downsample here to 30fps
for ii=1:length(Motion)
    Motion{ii}=Motion{ii}(1:4:end,:);
end
for ii=1:length(Labels)
    Labels{ii}=Labels{ii}(1:4:end,:);
end

fprintf(1,'Preprocessing data \n');

%Run the 1st stage of pre-processing
%This converts to body-centered coordinates, and converts to ground-plane
%differences
preprocess1

%how-many timesteps do we look back for directed connections
%this is what we call the "order" of the model 
n1 = 6; %first layer

%Run the 2nd stage of pre-processing
%This drops the zero/constant dimensions and builds mini-batches
preprocess2

%Note that Labels (matching the original data)
%have been saved in cell array "Labels"
%For each sequence, we want to discard the first n1 labels and then
%collapse the resulting label data into a matrix that corresponds to our
%visible data, batchdata
%Our minibatch pointers can now refer to the labels and the data
labeldata = [];
for jj=1:length(Labels)
  labeldata = [labeldata; Labels{jj}];
end

%model is trained; we don't need Motion, Labels any more
%run preprocessing on test data
Motion=TestMotion;
Labels=TestLabels;

%downsample here to 30fps
for ii=1:length(Motion)
    Motion{ii}=Motion{ii}(1:4:end,:);
    %remember to downsample labels too
    Labels{ii}=Labels{ii}(1:4:end,:);
end

fprintf(1,'Preprocessing test data \n');

preprocess1; %the same
preprocess2_test; %build testdata,testdataindex

testlabeldata = [];
for jj=1:length(TestLabels)
  testlabeldata = [testlabeldata; TestLabels{jj}];
end

numdims = size(batchdata,2); %data (visible) dimension

initdata = batchdata;


%every xxx epochs, write a snapshot of the model
%will be written to snapshot_path_epxxx.mat
snapshot_path = [snapshot_root ...
                 'mixcrbm_mit_walk_jog_30fps_6taps_200hid_cd10_2comp_' ...
                 'sparse_labeled'];


fprintf(1,'Training Layer 1 CRBM, order %d: %d-%d \n',nt,numdims,numhid);
restart=1;      %initialize weights

mixgaussiancrbm_labels

%
% Generate some data from the trained model
% Note that labels are not clamped during generation
%

fr=101;             % initialization from walking
numframes = 400;    % generate this many frames
genmix;

postprocess;
figure(40); expPlayData(skel, newdata, 1/30);

fr=2101;             % initialization from jogging
numframes = 400;     % generate this many frames
genmix;

postprocess;
figure(41); expPlayData(skel, newdata, 1/30);
