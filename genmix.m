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
% Generate from an implicit mixture of CRBMs
%
% The program assumes that the following variables are set externally:
% numframes    -- number of frames to generate
% fr           -- a starting frame from initdata (for initialization)

numGibbs = 30; %number of alternating Gibbs iterations 
samptemp = 1;  %temperature in computing responsibilities
%binotries=10;

numdims = size(initdata,2);

%initialize visible layer
visible = zeros(numframes,numdims,'single');
visible(1:n1,:) = initdata(fr:fr+n1-1,:);
%initialize hidden layer
hidden1 = ones(numframes,numhid1,'single');
hposteriors = zeros(numframes,numhid1,'single');

probcomp = zeros(numframes,numcomp);

past = zeros(1,nt*numdims,'single');

%Note that we will re-use the effective visible, hidden biases several
%times so we compute them here (per-component) and keep them around
effvisbiases = zeros(numcomp,numdims,'single');
effhidbiases = zeros(numcomp,numhid,'single');

for tt=n1+1:numframes
  
  %initialize using the last frame + noise
  visible(tt,:) = visible(tt-1,:) + 0.01*randn(1,numdims);
  
  for hh=nt:-1:1
    past(1,numdims*(nt-hh)+1:numdims*(nt-hh+1)) = visible(tt-hh,:);
  end 
    
  for cc=1:numcomp
    bistar = past*pastvis(:,:,cc);
    bjstar = past*pasthid(:,:,cc);
    
    effvisbiases(cc,:) = visbiases(cc,:) + bistar;
    effhidbiases(cc,:) = hidbiases(cc,:) + bjstar;    
  end  
 
  %Gibbs sampling
  for gg = 1:numGibbs
    
    %calculate assignments
    %we calculate free-energy per-point, per-component
    fe = zeros(1,numcomp); %let fe be double
    
    for cc=1:numcomp
      fe(cc) = crbmfe(visible(tt,:),vishid(:,:,cc), ...
        effhidbiases(cc,:),effvisbiases(cc,:));
    end
    
    %note that adding a constant to all terms
    %does not change the distribution (this prevents overflow)
    fe = fe - min(fe);    
    
    expfe = exp(-fe/samptemp);                 
    
    probcomp(tt,:) = bsxfun(@rdivide,expfe,sum(expfe,2)); %normalize
    
    if any(isnan(probcomp(tt,:)))
      fprintf('detected NaN\n')
      pause(0)
    end
    
    %sample a component
    asm = sample_vector(probcomp(tt,:)'); %returns row vector of assignments   
    
    %compute posterior using assigned component
    bottomup =  (visible(tt,:)./gsd)*vishid(:,:,asm);
    
    eta = bottomup + ...                   %bottom-up connections
      effhidbiases(asm,:);
    
    hposteriors(tt,:) = 1./(1 + exp(-eta));      %logistic
    
    hidden1(tt,:) = single(hposteriors(tt,:) > rand(1,numhid1));
    
    %Downward pass; visibles are Gaussian units
    %So find the mean of the Gaussian
    topdown = gsd.*(hidden1(tt,:)*vishid(:,:,asm)');
    
    %Mean-field approx
    visible(tt,:) = topdown + ...            %top down connections
      effvisbiases(asm,:);
  end

  %If we are done Gibbs sampling, then do a mean-field sample
  %(otherwise very noisy)  
  topdown = gsd.*(hposteriors(tt,:)*vishid(:,:,asm)');               
  
  visible(tt,:) = topdown + ...            %top down connections
    effvisbiases(asm,:); 

end


  

