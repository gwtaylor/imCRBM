function [f,exphidinp] = crbmfe(data,vishid,effhidbias,effvisbias)

%data is the current setting of the visible variables
%if there are multiple rows, we return free energy for each row
%returns free energy (negative log probability)
%also returns exphidinp so we don't need to call exp again
%(e.g. for computing sigmoid)
[numcases,numdims] = size(data);

mismatch = data - effvisbias;
visterm = sum(mismatch.^2,2)/2; %sum over dimensions assume sd is 1

%Term calculated by summing over hiddens
hidinp = data*vishid + effhidbias;
exphidinp = exp(hidinp); %cache this computation
hidterm = log(1 + exphidinp);
hidterm = sum(hidterm,2); %sum over hiddens

f = visterm - hidterm;

% %now for the gradients with respect to each dim of visible
% 
% poshidprobs = 1./(1 + exp(-hidinp));
% topdown = w'*poshidprobs; %total input from hiddens to each unit
% 
% df = mismatch - topdown;