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
% Creates a simple walk/jog dataset
% Data is originally from Eugene Hsu
% http://people.csail.mit.edu/ehsu/work/sig05stf/

numlabels = 2;

% walking
% put Normal1_M.mat in data/
% or change this path
load data/Normal1_M.mat

counter = 0;

style = 1;
for ii=1:length(Motion)-1 %last sequence is held for test
  counter = counter+1;
  BigMotion{counter} = Motion{ii};
%   Labels{counter} = zeros(size(BigMotion{counter},1),numlabels);
%   Labels{counter}(:,style)=1;
  Labels{counter} = repmat(style,size(BigMotion{counter},1),1);
end

ii=ii+1;
BigMotionTest{1} = Motion{ii};
TestLabels{1} = repmat(style,size(BigMotionTest{1},1),1);

% jogging
% put Jog1_M.mat in data/
% or change this path
load data/Jog1_M.mat

style = 2;
for ii=1:length(Motion) -1 %last sequence is held for test
  counter = counter+1;
  BigMotion{counter} = Motion{ii};
%   Labels{counter} = zeros(size(BigMotion{counter},1),numlabels);
%   Labels{counter}(:,style)=1;
  Labels{counter} = repmat(style,size(BigMotion{counter},1),1);
end

ii=ii+1;
BigMotionTest{2} = Motion{ii};
TestLabels{2} = repmat(style,size(BigMotionTest{2},1),1);


Motion = BigMotion; TestMotion = BigMotionTest;
clear BigMotion BigMotionTest;