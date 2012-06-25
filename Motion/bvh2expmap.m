function [skel, expmapchannels] = bvh2expmap(skel,eulerchannels)


% This is a function for converting from Euler BVH data to exponential maps
% It assumes that Neil Lawrence's MOCAP toolbox has been used to create a 
% skeleton structure "skel" and matrix of channels "eulerchannels".
% This function proceeds through the skeleton, replacing the Euler angles
% for rotational dimensions with the expmap dof
%
% Usage: [skel, expmapchannels] = bvh2expmap(skel,eulerchannels)


for ii=1:length(skel.tree)
  if ~isempty(skel.tree(ii).posInd)
    %don't touch translational dimensions
    expmapchannels(skel.tree(ii).posInd) = eulerchannels(skel.tree(ii).posInd);   
  end

  if ~isempty(skel.tree(ii).rotInd)
    xangle = deg2rad(eulerchannels(skel.tree(ii).rotInd(1)));
    yangle = deg2rad(eulerchannels(skel.tree(ii).rotInd(2)));
    zangle = deg2rad(eulerchannels(skel.tree(ii).rotInd(3)));

    %3x3 Rotation Matrix
    thisRotation = rotationMatrix(xangle, yangle, zangle, skel.tree(ii).order);
    
    r = rotmat2expmap(thisRotation);
    
    %Conversion to Exponential Map
    %Overwriting roational channels
    expmapchannels(:,skel.tree(ii).rotInd) = r;    
    
  end
end
    
    
