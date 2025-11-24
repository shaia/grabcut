function rgb = get_rgb_double(im, x, y)
%GET_RGB_DOUBLE Part of GrabCut. Obtain a RGB tuple in double
%
% NOTE: This function is kept for backward compatibility but is inefficient
% when called in loops. Consider using vectorized operations with squeeze()
% or reshape() instead.
%
% Inputs:
%   - im: 2D image
%   - x: horizontal position
%   - y: vertical position
%
% Output:
%   - rgb: double 3-vector
%
% Author:
%   Xiuming Zhang
%   GitHub: xiumingzhang
%   Dept. of ECE, National University of Singapore
%   April 2015
%
% Modernized: 2025
%   - Added deprecation warning
%   - Simplified implementation using squeeze

% Extract RGB values and convert to double in one operation
rgb = double(squeeze(im(y, x, :))');
