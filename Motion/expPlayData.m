function [xlim, ylim, zlim] = ...
    expPlayData(skel, channels, frameLength, xlim, ylim, zlim)

% Version 1.000 
%
% Code provided by Graham Taylor, Geoff Hinton and Sam Roweis 
%
% For more information, see:
%     http://www.cs.toronto.edu/~gwtaylor/publications/nips2006mhmublv
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
% Based on skelPlayData.m version 1.1
% Copyright (c) 2006 Neil D. Lawrence
%
% We support two types of skeletons:
%  1) Those built from the CMU database (acclaim)
%     http://mocap.cs.cmu.edu/
%  2) Those built from data from Eugene Hsu (mit)
%     http://people.csail.mit.edu/ehsu/work/sig05stf/
% EXPPLAYDATA Play skel motion capture data.
% Data is in exponential map representation
%
% Usage: [xlim, ylim, zlim] = expPlayData(skel, channels, frameLength)

if nargin < 3
    frameLength = 1/120;
end
cla

handle = expVisualise(channels(1, :), skel);

%it makes no sense to call exp2xyz twice for each frame
%we should calculate the xyz values once, and cache them
%so that they can be used for both determining limits
%and in expModify
numFrames = size(channels,1);
fprintf('Computing marker values ...\n');
markerCache = zeros(length(skel.tree),3,numFrames);
for ii=1:numFrames
  markerCache(:,:,ii) = exp2xyz(skel,channels(ii,:));
end

if nargin < 6
    %We didn't specify the limits of the motion
    %So calculate the limits

        xlim = get(gca, 'xlim');
        minY1 = xlim(1);
        maxY1 = xlim(2);
        ylim = get(gca, 'ylim');
        minY3 = ylim(1);
        maxY3 = ylim(2);
        zlim = get(gca, 'zlim');
        minY2 = zlim(1);
        maxY2 = zlim(2);
        
        %Only need to change if data is outside the current axis limits
        %(outer max/min)
        %we need to take max over dim 1 (segments)
        %then over dim 3 (frames)
        %while we hold dim 2 (x,y, or z) fixed
        minY1 = min([min(min(markerCache(:,1,:),[],1),[],3);minY1]);
        maxY1 = max([max(max(markerCache(:,1,:),[],1),[],3);maxY1]);
        
        minY3 = min([min(min(markerCache(:,3,:),[],1),[],3);minY3]);
        maxY3 = max([max(max(markerCache(:,3,:),[],1),[],3);maxY3]);        
        
        minY2 = min([min(min(markerCache(:,2,:),[],1),[],3);minY2]);
        maxY2 = max([max(max(markerCache(:,2,:),[],1),[],3);maxY2]);
        
%         for ii = 1:size(channels, 1)
%             Y = exp2xyz(skel, channels(ii, :));
%             minY1 = min([Y(:, 1); minY1]);
%             minY2 = min([Y(:, 2); minY2]);
%             minY3 = min([Y(:, 3); minY3]);
%             maxY1 = max([Y(:, 1); maxY1]);
%             maxY2 = max([Y(:, 2); maxY2]);
%             maxY3 = max([Y(:, 3); maxY3]);
%         end
        xlim = [minY1 maxY1];
        ylim = [minY3 maxY3];
        zlim = [minY2 maxY2];
end

set(gca, 'xlim', xlim, ...
    'ylim', ylim, ...
    'zlim', zlim);

fprintf('Playing...\n')

% Play the motion
for jj = 1:size(channels, 1)
    pause(frameLength)
    %fprintf('frame %i\n',j);
    %pause;
    expModify(handle, markerCache(:,:,jj), skel);
end