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
% Training an implicit mixture of Gaussian-Binary CRBMs
% using labeled training data
% labeldata is the same # rows as batchdata
% labels are just integers
% positive phase: use the crbm corresponding to label
% negative phase: compute free energies under each component crbm and sample
% a component
%

%batchdata is a big matrix of all the frames
%we index it with "minibatch", a cell array of mini-batch indices
numbatches = length(minibatch); 

numdims = size(batchdata,2); %visible dimension

%Setting learning rates
epsilonvishid=single(1e-3);  %undirected
epsilonvisbias=single(1e-3); %visibles
epsilonhidbias=single(1e-3); %hidden units
epsilonpastvis=single(1e-5);  %autoregressive
epsilonpasthid=single(1e-3);  %prev visibles to hidden

wdecay = single(0.0002); %currently we use the same weight decay for w, A, B
mom = single(0.9);       %momentum used only after 5 epochs of training
temp = 100;              %temperature in computing resp

sparsehid=0;
if sparsehid
  %Parameters for sparse hidden units
  sparsetarget = single(.2);
  sparsecost = 0;
  sparsecost_late = single(.05);
  sparseon = 100; %after this epoch, we switch to sparsecost_late
  sparsedamping = single(.9);
else
  sparsecost=0;
end

if restart==1,  
  restart=0;
  epoch=1;
  
  %Randomly initialize weights
  vishid = single(0.01*randn(numdims,numhid,numcomp));
  visbiases = single(0.01*randn(numcomp,numdims));
  hidbiases = single(0.01*randn(numcomp,numhid));
  
  %The autoregressive weights; third index is for component
  %[ [weights for t-N]; ... [weights for t-1] ] 
  pastvis = single(0.01*randn(nt*numdims,numdims,numcomp));
 
  %The weights from previous time-steps to the hiddens; third index is for
  %component
  %[ [weights for t-N]; ... [weights for t-1] ]
  pasthid = single(0.01*randn(nt*numdims,numhid,numcomp));
    
  %statistics used for weight updates
  posprods = zeros(size(vishid),'single');
  posvisact = zeros(size(visbiases),'single');
  poshidact = zeros(size(hidbiases),'single');
  poscondprodsvis = zeros(size(pastvis),'single');
  poscondprodshid = zeros(size(pasthid),'single');
  negprods = zeros(size(vishid),'single');
  negvisact = zeros(size(visbiases),'single');
  neghidact = zeros(size(hidbiases),'single');
  negcondprodsvis = zeros(size(pastvis),'single');
  negcondprodshid = zeros(size(pasthid),'single');
  
  %keep previous updates around for momentum
  vishidinc = zeros(size(vishid),'single');
  visbiasinc = zeros(size(visbiases),'single');
  hidbiasinc = zeros(size(hidbiases),'single');
  pastvisinc = zeros(size(pastvis),'single');
  pasthidinc = zeros(size(pasthid),'single');
  
  if sparsehid
    %keep a row of hidmeans for every component
    hidmeans = sparsetarget*ones(numcomp,numhid,'single'); %initialize  
  end    
end

%Main loop
for epoch = epoch:numepochs,
  errsum=0; %keep a running total of the difference between data and
            %recon           
  if sparsehid && epoch>sparseon
    %kick in sparsity after a certain # of epochs
    sparsecost = sparsecost_late;
  end
  
  for batch = 1:numbatches,

    %%%%%%%%% START POSITIVE PHASE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    numcases = length(minibatch{batch});
    mb = minibatch{batch}; %caches the indices

    %data is a nt+1-d array with current and delayed data
    %corresponding to this mini-batch
    data = single(batchdata(mb,:));
    past = zeros(numcases,nt*numdims,'single');
    poslabels = labeldata(mb,:);
        
    %Easiest way to build past is by a loop
    %Past looks like [ [data time t-nt] ... [data time t-1] ] 
    for hh=nt:-1:1 %note reverse order
      past(:,numdims*(nt-hh)+1:numdims*(nt-hh+1)) = batchdata(mb-hh,:) ...
          + randn(numcases,numdims);
    end
    
    if sparsecost>0
      %hold a per-component sparsity gradient
      %based on ALL the data
      sparsegrads = zeros(numcomp,numhid,'single');
    end
    
    %Note that we will re-use the effective visible, hidden biases several
    %times so we compute them here (per-component) and keep them around
    effvisbiases = zeros(numcases,numdims,numcomp,'single');
    effhidbiases = zeros(numcases,numhid,numcomp,'single');
     
    for cc=1:numcomp      
      bistar = past*pastvis(:,:,cc);
      bjstar = past*pasthid(:,:,cc);
      
      effvisbiases(:,:,cc) = repmat(visbiases(cc,:),numcases,1) + bistar;
      effhidbiases(:,:,cc) = repmat(hidbiases(cc,:),numcases,1) + bjstar;
       
      if sparsecost>0
        %new way of doing sparsity
        %doesn't depend on the actual component selected
        %depends on the average activation over all data, for each
        %component
        hidmeans(cc,:) = sparsedamping*hidmeans(cc,:) +  ...
          (1-sparsedamping)*sum(poshidprobsall(:,:,cc),1)/numcases;
        
        sparsegrads(cc,:) = sparsecost*(hidmeans(cc,:)-sparsetarget);
        
        if any(isnan(hidmeans(:)))
          fprintf('detected NaN\n')
          pause(0)
        end
      end

    end
    
    %initialize matrix to hold positive-phase posteriors
    poshidprobs = zeros(numcases,numhid,'single');
    
    %Positive phase is really simple
    %Just use the label to pick a component CRBM
    for cc=1:numcomp
      idx = find(poslabels==cc); %indexes which data cases belong to label
      nc = size(idx,1);
      poshidprobs(idx,:) =  1./( 1 + exp( -data(idx,:)*vishid(:,:,cc) - ...
        effhidbiases(idx,:,cc)));      
      
      %Calculate statistics needed for gradient update
      
      posprods(:,:,cc) = (data(idx,:)./gsd)'*poshidprobs(idx,:); %smoothed: probs, not binary
      poshidact(cc,:) = sum(poshidprobs(idx,:),1); %col vector; again smoothed
      posvisact(cc,:) = sum(data(idx,:),1)./gsd^2; %row vector
      poscondprodsvis(:,:,cc) = past(idx,:)'*(data(idx,:)./gsd^2);
      poscondprodshid(:,:,cc) = past(idx,:)'*poshidprobs(idx,:);
      
      if sparsecost>0
        %Note that sparsegrads is now a numcomp*numhid array
        %(i.e. it has not been repmatted)
        posprods(:,:,cc) = posprods(:,:,cc) - ...
          data(:,:)'*repmat(sparsegrads(cc,:),numcases,1);
        poshidact(cc,:) = poshidact(cc,:) - ...
          numcases*sparsegrads(cc,:); %ensure same units
        poscondprodshid(:,:,cc) = poscondprodshid(:,:,cc) - ...
          past'*repmat(sparsegrads(cc,:),numcases,1);
      end
        
    end
    
    %Stochastically sample the hidden units
    hidstates = single(poshidprobs > rand(numcases,numhid));            
    
    %%%%%%%%% END OF POSITIVE PHASE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %initialize negative data (to handle different batch sizes)
    negdata = zeros(numcases,numdims,'single');
    neglabels = poslabels; %initialization
    %we calculate free-energy per-point, per-component    
    %let fe by a double -- since we will take exp of a large number
    fe = zeros(numcases,numcomp); 
    
    for cdn = 1:cdsteps
      %Again, due to potentially different assignments, we must look at
      %cases assigned to each component in groups
      for cc=1:numcomp
        idx = find(neglabels==cc); %indexes cases assigned to component cc

        negdata(idx,:) =  gsd.*(hidstates(idx,:)*vishid(:,:,cc)') + ...
          effvisbiases(idx,:,cc);        
        
      end
      
      %cache the hidden probs (all cases, under each component)
      neghidprobsall = zeros(numcases,numhid,numcomp,'single');
      
      %and now we need to re-compute responsibilities using the negative data
      for cc=1:numcomp       
        [fe(:,cc),exphidinp] = crbmfe(negdata,vishid(:,:,cc), ...
          effhidbiases(:,:,cc),effvisbiases(:,:,cc));
        
        %note this is the sigmoid (just in different form)
        neghidprobsall(:,:,cc) = exphidinp./(1+exphidinp);
      end
      
      %note that adding a constant to all terms
      %does not change the distribution (this prevents overflow)
      fe = bsxfun(@minus,fe,min(fe,[],2)); %careful to take min over cols
  
      expfe = exp(-fe/temp);
      probcomp = bsxfun(@rdivide,expfe,sum(expfe,2)); %normalize      
      %we change this to a column vector for consistency
      neglabels = (sample_vector(probcomp'))';   
            
      %initialize matrix to hold positive-phase posteriors
      neghidprobs = zeros(numcases,numhid,'single');      
      
      %compute posteriors using negative phase data
      for cc=1:numcomp
        idx = find(neglabels==cc); %indexes cases assigned to component cc
        
        %here we should draw from the probs already computed
        neghidprobs(idx,:) = neghidprobsall(idx,:,cc);        
      end

      if cdn == 1
        %Calculate reconstruction error
        err= sum(sum( (data(:,:,1)-negdata).^2 ));
        errsum = err + errsum;
      end

      if cdn == cdsteps
        %last cd step -- Calculate statistics needed for gradient update
        for cc=1:numcomp
          idx = find(neglabels==cc); %indexes cases assigned to component cc
                    
          %Calculate statistics needed for gradient update

          %smoothed: probs, not binary
          negprods(:,:,cc) = (negdata(idx,:)./gsd)'*neghidprobs(idx,:); 
          neghidact(cc,:) = sum(neghidprobs(idx,:),1); %col vector; again smoothed
          negvisact(cc,:) = sum(negdata(idx,:),1)./gsd^2; %row vector
          negcondprodsvis(:,:,cc) = past(idx,:)'*(negdata(idx,:)./gsd^2);
          negcondprodshid(:,:,cc) = past(idx,:)'*neghidprobs(idx,:);
        end
      else
        %Stochastically sample the hidden units
        hidstates = single(neghidprobs > rand(numcases,numhid));
      end
    end

    %%%%%%%%% END NEGATIVE PHASE  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if epoch > 5 %use momentum
      momentum=mom;
    else %no momentum
      momentum=0;
    end

    %%%%%%%%% UPDATE WEIGHTS AND BIASES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %Update each component CRBM
    for cc=1:numcomp        
      vishidinc(:,:,cc) = momentum*vishidinc(:,:,cc) + ...
        epsilonvishid*( (posprods(:,:,cc) - ...
        negprods(:,:,cc))/numcases - wdecay*vishid(:,:,cc));
      
      visbiasinc(cc,:) = momentum*visbiasinc(cc,:) + ...
        (epsilonvisbias/numcases)*(posvisact(cc,:) - negvisact(cc,:));
      
      hidbiasinc(cc,:) = momentum*hidbiasinc(cc,:) + ...
        (epsilonhidbias/numcases)*(poshidact(cc,:) - neghidact(cc,:));
      
      pastvisinc(:,:,cc) = momentum*pastvisinc(:,:,cc) + ...
        epsilonpastvis* ( (poscondprodsvis(:,:,cc) - ...
        negcondprodsvis(:,:,cc))/numcases - ...
        wdecay*pastvis(:,:,cc));
      
      pasthidinc(:,:,cc) = momentum*pasthidinc(:,:,cc) + ...
        epsilonpasthid* ( (poscondprodshid(:,:,cc) - ...
        negcondprodshid(:,:,cc))/numcases - ...
        wdecay*pasthid(:,:,cc));
    end

    if any(isnan(vishidinc(:))) || any(isnan(hidbiasinc(:))) || ...
            any(isnan(pasthidinc(:)))
        fprintf('detected NaN\n')
        pause(0)
    end
    
    vishid = vishid +  vishidinc;
    visbiases = visbiases + visbiasinc;
    hidbiases = hidbiases + hidbiasinc;
    pastvis = pastvis + pastvisinc;
    pasthid = pasthid + pasthidinc;

    %%%%%%%%%%%%%%%% END OF UPDATES  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  end
  %mean(poshidact'/numcases)
  %every 10 epochs, show output
  if mod(epoch,10) ==0
    fprintf(1, 'epoch %4i error %6.1f  \n', epoch, errsum);
    
    if 1
      %the visualization/debugging is going to depend on the dataset
      %so we will put it in a separate script
      visualize_mit_labels
    end
  end
  if mod(epoch,snapshotevery) ==0
    snapshot_file = [snapshot_path '_ep' num2str(epoch) '.mat'];
    save(snapshot_file, 'vishid','pastvis','pasthid','hidbiases', ...
         'visbiases','cdsteps', 'numhid', 'numcomp','epoch', 'nt');
  end

end
    
