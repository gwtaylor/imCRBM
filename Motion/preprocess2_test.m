%just like preprocess2
%but now the Motion represents test data
%we want to scale it identically to the way that the training data was
%scaled
%assume data_mean, data_std are already set
%don't break into minibatches
%just return testdata and testdataindex

clear testdata minitestdata testdataindex
batchsize = 100;        %size of minibatches

clear seqlengths;

if strcmp(skel.type,'acclaim')
 %CMU-style data
 %No offsets, but several dimensions are constant 
 indx = [ 1:6 ...        %root (special representation)
   10:12 13 16:18 19 ... %lfemur ltibia lfoot ltoes
   25:27 28 31:33 34 ... %rfemur rtibia rfoot rtoes
   37:39 40:42 43:45 46:48 49:51 52:54 ... %lowerback upperback thorax lowerneck upperneck %head
   58:60 61 65 67:69 73:75 ... %(lclavicle ignored) lhumerus lradius lwrist lhand (fingers are constant) lthumb
   79:81 82 86 88:90 94:96 ];  %(rclavicle ignored) rhumerus rradius rwrist rhand (fingers are constant) rthumb    

elseif strcmp(skel.type,'mit')
  %MIT-style data
%   indx = [   1:6 7:9 14 19:21 26 31:33 38 43:45 50 55:57 61 63 67:69 ...
%     73:75 79:80 85 87 91:93 97:99 103:104 ];
  indx = [   1:6 7:9 14 19:21 26 31:33 38 43:45 50 55:57 61:63 67:69 ...
    73:75 79:81 85:87 91:93 97:99 103:105 ]; %old style

  %Save the offsets, they will be inserted later
  offsets = [  Motion{1}(1,10:12); Motion{1}(1,16:18); ...
    Motion{1}(1,22:24); Motion{1}(1,28:30); Motion{1}(1,34:36); ...
    Motion{1}(1,40:42); Motion{1}(1,46:48); Motion{1}(1,52:54); ...
    Motion{1}(1,58:60); Motion{1}(1,64:66); Motion{1}(1,70:72); ...
    Motion{1}(1,76:78); Motion{1}(1,82:84); Motion{1}(1,88:90); ...
    Motion{1}(1,94:96); Motion{1}(1,100:102); Motion{1}(1,106:108)];
elseif strcmp(skel.type,'bvh')
  %some dimensions are constant (don't model)
  BVH_NUM_DIMS = 75;
  BVH_CONST_DIMS = [10:12 16:24 34:39 49:51 61:63 73:75];
  indx = setdiff(1:BVH_NUM_DIMS,BVH_CONST_DIMS);  
elseif strcmp(skel.type,'cmubvh')
  %some dimensions are constant (don't model)
  BVH_NUM_DIMS = 96;
  %We don't need to get rid of toes, but we do to make our space smaller
  %This means dimensions 20:21, 35:36 (19,34 are constant anyway)
  BVH_CONST_DIMS = [7:9 13 19:21 22:24 28 34:36 55:57 62 64 66 70:75 76:78 83 85 87 91:96];
  indx = setdiff(1:BVH_NUM_DIMS,BVH_CONST_DIMS); 
else
  error('Unknown skeleton type');
end

%combine the data into a large batch
testdata = cell2mat(Motion'); %flatten it into a standard 2d array
testdata = testdata(:,indx);
numcases = size(testdata,1);

%Normalize the data
testdata =( testdata - repmat(data_mean,numcases,1) ) ./ ...
  repmat( data_std, numcases,1);

%Index the valid cases (we don't want to mix sequences)
%This depends on the order of our model
for jj=1:length(Motion)
  seqlengths(jj) = size(Motion{jj},1);
  if jj==1 %first sequence
    testdataindex = n1+1:seqlengths(jj);
  else
    testdataindex = [testdataindex testdataindex(end)+n1+1: ...
      testdataindex(end)+seqlengths(jj)];
  end
end



