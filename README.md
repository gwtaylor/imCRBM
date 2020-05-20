# imCRBM

Matlab implementation of Implicit mixtures of Conditional Restricted Boltzmann Machines.
Code provided by Graham Taylor

For more information, see [this cached copy of http://www.uoguelph.ca/~gwtaylor/publications/cvpr2010/](https://uoguelphca-my.sharepoint.com/:f:/g/personal/gwtaylor_uoguelph_ca/EtgEYrzrVCtPj1DFcrVE2AsBeiTIgxGgx4xyJCRd89F3NQ?e=zhYQ97). Note I do not intend to maintain this page. 

Permission is granted for anyone to copy, use, modify, or distribute this
program and accompanying programs and documents for any purpose, provided
this copyright notice is retained and prominently displayed, along with
a note saying that the original programs are available from our
web page.
The programs and documents are distributed without any warranty, express or
implied.  As the programs were written for research purposes only, they have
not been tested to the degree that would be advisable in any important
application.  All use of these programs is entirely at the user's own risk.

## External dependencies

`sample_vector.m` (Sample from multiple categorical distributions) is a
requirement. This also depends on `col_sum.m`.
They can both be obtained from Tom Minka's lightspeed toolbox: 
     http://research.microsoft.com/en-us/um/people/minka/software/lightspeed/

## Sample data
You will need to move the sample data, [Normal1_M.mat](https://uoguelphca-my.sharepoint.com/:u:/r/personal/gwtaylor_uoguelph_ca/Documents/Sharing/publications/cvpr2010/data/Normal1_M.mat?csf=1&e=mpjv5C) and [Jog1_M.mat](https://uoguelphca-my.sharepoint.com/:u:/r/personal/gwtaylor_uoguelph_ca/Documents/Sharing/publications/cvpr2010/data/Jog1_M.mat?csf=1&e=ep0GO2) to
the `data/` subdirectory or change the respective paths in the scripts.

## Usage
This subdirectory contains files related to learning and generation:

```
demo_imcrbm_mit.m		         Main file for learning (unsupervised) 
                                 and generation
demo_imcrbm_mit_labels.m         Main file for learning (supervised)
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
```

Note that there are two entry points, depending on whether you want to
train the model completely unsupervised (i.e. assuming no category
labels) or supervised (i.e. with category labels corresponding to
motion style). 

The Motion subdirectory contains files related to motion capture data: 
preprocessing/postprocessing, playback, etc ...

## Parameters
There are a number of parameters (number of discrete components,
number of hidden units, etc.) that can be changed. Most are at the
top of `demo_imcrbm_mit.m` and `demo_imcrbm_mit_labels.m`. But there
are also some parameters (learning rates, sparsity settings, etc.) 
defined in `mixgaussiancrbm.m` and `mixgaussiancrbm_labels.m`. 
The default parameters should work; however, if `/tmp` is not writeable, 
then the definition of `snapshot_root` must be changed in `demo_imcrbm_mit.m` 
and `demo_imcrbm_mit_labels.m`.

## Acknowledgements
The sample data we have included has been provided by Eugene Hsu:
http://people.csail.mit.edu/ehsu/work/sig05stf/

Several subroutines related to motion playback are adapted from Neil 
Lawrence's Motion Capture Toolbox:
http://www.cs.man.ac.uk/~neill/mocap/

Several subroutines related to conversion to/from exponential map
representation are provided by Hao Zhang:
http://www.cs.berkeley.edu/~nhz/software/rotations/

*NOTE: I do not plan on extending this code. I have, for the most part,
moved away from Matlab and am developing in Python. Of course, if
there are major bugs reported, I will fix them.*
