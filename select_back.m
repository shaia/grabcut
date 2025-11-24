function [im_1d, alpha, im_sub] = select_back(im_in)
%SELECT_BACK User selects foreground region with rectangle
%
% This implements the standard GrabCut initialization using rectangle selection
% as described in the original paper (Rother et al., 2004).
%
% Alternative Initialization Methods:
%   The GrabCut algorithm can be extended to support alternative initialization:
%
%   1. Trimap input: Provide a trimap with definite foreground, definite
%      background, and unknown regions (used in matting applications)
%
%   2. Scribble-based: User draws foreground/background scribbles instead
%      of a bounding box (more precise but requires more user interaction)
%
%   3. Automatic initialization: Use saliency detection, object proposals,
%      or other automatic methods to initialize the segmentation
%
%   4. Mask refinement: Start from an existing segmentation mask and refine
%      it using GrabCut iterations
%
%   To implement these, create alternative initialization functions that
%   return the same output format: [im_1d, alpha, im_sub]
%
% Inputs:
%   - im_in: HxWx3 RGB image
%
% Output:
%   - im_1d: Nx3 image in column-major 1D format
%   - alpha: Nx1 label vector (1=foreground, 0=background)
%   - im_sub: Cropped region containing foreground
%
% Author:
%   Xiuming Zhang (Original, 2015)
%   Modernized: 2025

% Get image dimensions
[im_h, im_w, ~] = size(im_in);
no_nodes = im_h * im_w;

% User selects rectangle containing foreground
imshow(im_in);
rect = round(getrect);

% Initialize labels
alpha_2d = zeros(im_h, im_w);
xmin = max(rect(1), 1);
ymin = max(rect(2), 1);
xmax = min(xmin + rect(3), im_w);
ymax = min(ymin + rect(4), im_h);

% Mark rectangle as foreground
alpha_2d(ymin:ymax, xmin:xmax) = 1;

% Extract subimage
im_sub = im_in(ymin:ymax, xmin:xmax, :);

% Convert to 1D format (column-major order)
im_1d = reshape(im_in, no_nodes, 3);
alpha = reshape(alpha_2d, no_nodes, 1);
