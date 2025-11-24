function [k_U, k_B] = assign_gauss(im_1d, pix_U, gmm_U, pix_B, gmm_B)
%ASSIGN_GAUSS Assign pixels to the most probable Gaussians
%
% Inputs:
%   - im_1d: Nx3 RGB points
%   - pix_U: Logical indices for foreground
%   - gmm_U: GMM for foreground (struct array with fields: pi, mu, sigma)
%   - pix_B: Logical indices for background
%   - gmm_B: GMM for background (struct array with fields: pi, mu, sigma)
%
% Output:
%   - k_U: new label assignments for the T_U pixels
%   - k_B: new label assignments for the T_B pixels
%
% Author:
%   Xiuming Zhang (Original, 2015)
%   Modernized: 2025
%   - Refactored to eliminate duplicate code
%   - Replaced cell array with struct for GMM parameters

% Assign foreground pixels
k_U = assign_to_gmm(im_1d(pix_U, :), gmm_U);

% Assign background pixels
k_B = assign_to_gmm(im_1d(pix_B, :), gmm_B);

end


function labels = assign_to_gmm(rgb_pts, gmm)
%ASSIGN_TO_GMM Assign pixels to most probable Gaussian component
%
% Inputs:
%   - rgb_pts: Nx3 matrix of RGB values
%   - gmm: GMM parameters (struct array with fields: pi, mu, sigma)
%
% Output:
%   - labels: Nx1 vector of component assignments

n_gaussians = numel(gmm);
n_pixels = size(rgb_pts, 1);

% Compute negative log-likelihood for each Gaussian
nll = zeros(n_pixels, n_gaussians);

for k = 1:n_gaussians
    % Negative log-likelihood: -log(p(x|k)) - log(pi_k)
    nll(:, k) = -log(mvnpdf(rgb_pts, gmm(k).mu, gmm(k).sigma)) - ...
                 log(gmm(k).pi) - 1.5*log(2*pi);
end

% Assign to Gaussian with minimum negative log-likelihood
[~, labels] = min(nll, [], 2);

end

