function unary_terms = compute_unary_batch(rgb_pts, gmm)
%COMPUTE_UNARY_BATCH Vectorized computation of unary terms for all pixels
%
% Inputs:
%   - rgb_pts: Nx3 matrix of RGB values
%   - gmm: GMM parameters (struct array with fields: pi, mu, sigma)
%
% Output:
%   - unary_terms: 1xN vector of minimum negative log-likelihoods
%
% Author:
%   Xiuming Zhang (Original, 2015)
%   Modernized: 2025

arguments
    rgb_pts (:,3) double {mustBeReal, mustBeFinite}
    gmm struct
end

n_gaussians = numel(gmm);
n_pixels = size(rgb_pts, 1);

% Compute negative log-likelihood for each Gaussian
nll = zeros(n_pixels, n_gaussians);

for k = 1:n_gaussians
    % Negative log-likelihood: -log(p(x|k)) - log(pi_k)
    nll(:, k) = -log(mvnpdf(rgb_pts, gmm(k).mu, gmm(k).sigma)) - ...
                 log(gmm(k).pi) - 1.5*log(2*pi);
end

% Take minimum across all Gaussians for each pixel
unary_terms = min(nll, [], 2)';

end
