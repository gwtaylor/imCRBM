Version 1.000 

Code provided by Graham Taylor

For more information, see:
    http://www.uoguelph.ca/~gwtaylor/publications/cvpr2010/

Permission is granted for anyone to copy, use, modify, or distribute this
program and accompanying programs and documents for any purpose, provided
this copyright notice is retained and prominently displayed, along with
a note saying that the original programs are available from our
web page.
The programs and documents are distributed without any warranty, express or
implied.  As the programs were written for research purposes only, they have
not been tested to the degree that would be advisable in any important
application.  All use of these programs is entirely at the user's own risk.

External dependencies:

sample_vector.m (Sample from multiple categorical distributions) is a
requirement. This also depends on col_sum.m.
They can both be obtained from Tom Minka's lightspeed toolbox: 
     http://research.microsoft.com/en-us/um/people/minka/software/lightspeed/

This subdirectory contains files related to learning and generation:

train_mixture_mit.m              Main file for learning (unsupervised) 
                                 and generation
train_mixture_mit_withlabels.m   Main file for learning (supervised)
                                 and generation
mixgaussiancrbm.m                Trains imCRBM unsupervised
mixgaussiancrbm_labels.m         Trains imCRBM with supervision on
                                 discrete components
crbmfe.m                         Compute free energy under CRBM
genmix.m                         Generates data from an imCRBM
make_mit_walk_jog.m              Dataset loading & preprocessing
make_mit_walk_jog_withtest.m     Dataset loading & preprocessing, also
                                 creates a test set
visualize_mit.m                  Visualization of trained model (unsupervised)
visualize_mit_labels.m           Visualization of trained model (supervised)


Note that there are two entry points, depending on whether you want to
train the model completely unsupervised (i.e. assuming no category
labels) or supervised (i.e. with category labels corresponding to
motion style). 

You will need to move the sample data, Normal1_M.mat and Jog1_M.mat to
the data/ subdirectory or change the respective paths in the scripts.

The Motion subdirectory contains files related to motion capture data: 
preprocessing/postprocessing, playback, etc ...

Acknowledgments

The sample data we have included has been provided by Eugene Hsu:
http://people.csail.mit.edu/ehsu/work/sig05stf/

Several subroutines related to motion playback are adapted from Neil 
Lawrence's Motion Capture Toolbox:
http://www.cs.man.ac.uk/~neill/mocap/

Several subroutines related to conversion to/from exponential map
representation are provided by Hao Zhang:
http://www.cs.berkeley.edu/~nhz/software/rotations/

NOTE: I do not plan on extending this code. I have, for the most part,
moved away from Matlab and am developing in Python. Of course, if
there are major bugs reported, I will fix them.
