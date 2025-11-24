function [gmm_U, gmm_B] = update_gmm(im_1d, pix_U, k_U, pix_B, k_B)
%UPDATE_GMM Update GMM parameters with newly assigned data
%
% Inputs:
%   - im_1d: Nx3 RGB image (1D representation)
%   - pix_U: Logical indices for foreground
%   - k_U: Gaussian memberships for foreground
%   - pix_B: Logical indices for background
%   - k_B: Gaussian memberships for background
%
% Output:
%   - gmm_U: updated GMM for foreground pixels (struct array)
%   - gmm_B: updated GMM for background pixels (struct array)
%
% Author:
%   Xiuming Zhang (Original, 2015)
%   Modernized: 2025
%   - Refactored to eliminate duplicate code
%   - Replaced cell array with struct for GMM parameters
%   - Added input validation with arguments block

arguments
    im_1d (:,3) double {mustBeReal, mustBeFinite}
    pix_U (:,1) logical
    k_U (:,1) {mustBePositive, mustBeInteger}
    pix_B (:,1) logical
    k_B (:,1) {mustBePositive, mustBeInteger}
end

% Update foreground GMM
gmm_U = fit_gmm(im_1d(pix_U, :), k_U);

% Update background GMM
gmm_B = fit_gmm(im_1d(pix_B, :), k_B);

