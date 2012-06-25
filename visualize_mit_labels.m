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
%
% visualization for learning an implicit mixture of crbms
% on the mit walk & jog data
% show hiddens

%Use test data instead
plotindex = [n1+1:413 413+n1+1:639];
plottemp = 1;
nc = length(plotindex);

data = single(testdata(plotindex,:));
past = zeros(nc,nt*numdims,'single');
labels = testlabeldata(plotindex,:);
                       
%Easiest way to build past is by a loop
%Past looks like [ [data time t-nt] ... [data time t-1] ] 
for hh=nt:-1:1 %note reverse order
  past(:,numdims*(nt-hh)+1:numdims*(nt-hh+1)) = testdata(plotindex-hh,:);
end

%Note that we will re-use the effective visible, hidden biases several
%times so we compute them here (per-component) and keep them around
effvisbiases = zeros(nc,numdims,numcomp,'single');
effhidbiases = zeros(nc,numhid,numcomp,'single');

%we calculate free-energy per-point, per-component    
fe = zeros(nc,numcomp); %let fe be double

for cc=1:numcomp      
  bistar = past*pastvis(:,:,cc);
  bjstar = past*pasthid(:,:,cc);
  
  effvisbiases(:,:,cc) = repmat(visbiases(cc,:),nc,1) + bistar;
  effhidbiases(:,:,cc) = repmat(hidbiases(cc,:),nc,1) + bjstar;
  
  fe(:,cc) = crbmfe(data,vishid(:,:,cc), ...
                    effhidbiases(:,:,cc),effvisbiases(:,:,cc));      
end

%note that adding a constant to all terms
%does not change the distribution (this prevents overflow)
fe = bsxfun(@minus,fe,min(fe,[],2)); %careful to take min over cols

expfe = exp(-fe/plottemp);
probcomp = bsxfun(@rdivide,expfe,sum(expfe,2)); %normalize

%sample a component
% sample_vector comes from Tom Minka's lightspeed toolbox:
%     http://research.microsoft.com/en-us/um/people/minka/software/lightspeed/
asm = sample_vector(probcomp'); %returns row vector of assignments

sfigure(32); clf
imagesc(probcomp'); colormap gray; %axis off
title('discrete component posterior')
xlabel('frame')
ylabel('component')

%Posteriors/recon under each component
sfigure(33); clf; sfigure(34); clf

%this will hold the posteriors
%where we have selected different assignments
%for different frames
poshidprobs = zeros(nc,numhid,'single');
segnegdata = zeros(nc,numdims,'single');
for cc=1:numcomp    
  
  %ALL DATA%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  eta = (data./gsd)*vishid(:,:,cc) + ...
        effhidbiases(:,:,cc);
  
  hposteriors = 1./(1 + exp(-eta));    %logistic      
  
  sfigure(33);
  subplot(numcomp,1,cc);
  imagesc(hposteriors'); colormap gray; %axis off      
  ylabel('hidden unit')
  xlabel('frame')
  title(sprintf('component %d', cc))
  
  topdown = gsd.*(hposteriors*vishid(:,:,cc)');
  
  %This is the mean of the Gaussian
  %Instead of properly sampling, negdata is just the mean
  %If we want to sample from the Gaussian, we would add in
  %gsd.*randn(numcases,numdims);
  negdata =  topdown + ...            %top down connections
      effvisbiases(:,:,cc);

  % arbitrarily select dimensions 7, 18 to show recon
  sfigure(34);
  subplot(numcomp,2,2*(cc-1)+1);
  plot(data(:,7,1)); hold on; plot(negdata(:,7),'r');
  title(sprintf('component %d reconstruction (red) vs. true (blue)', cc))
  subplot(numcomp,2,2*(cc-1)+2);
  plot(data(:,18,1)); hold on; plot(negdata(:,18),'r');
  title(sprintf('component %d reconstruction (red) vs. true (blue)', cc))
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %SEGMENTED DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  idx = find(asm==cc); %indexes cases assigned to component cc

  %pass through logistic       
  poshidprobs(idx,:) = 1./(1 + exp(-(data(idx,:)./gsd)*vishid(:,:,cc) ...
                                   - effhidbiases(idx,:,cc))); 
  
  topdown = gsd.*(poshidprobs(idx,:)*vishid(:,:,cc)');
  %reconstruct mean-field using the selected component
  segnegdata(idx,:) = topdown + ...
      effvisbiases(idx,:,cc);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

sfigure(35); clf
imagesc(poshidprobs'); colormap gray; axis off
ylabel('hidden')
xlabel('frame')
title('hidden posteriors using selected component')

sfigure(36); clf
subplot(2,1,1);
plot(data(:,7,1)); hold on; plot(segnegdata(:,7),'r');
title('mixture reconstruction (red) vs. true (blue)')
subplot(2,1,2);
plot(data(:,18,1)); hold on; plot(segnegdata(:,18),'r');
title('mixture reconstruction (red) vs. true (blue)')

drawnow;

