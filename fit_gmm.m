function gmm_param = fit_gmm(rgb_pts, labels)
%FIT_GMM Fit a Gaussian Mixture Model with K components
%
% Inputs:
%   - rgb_pts: Nx3 matrix of RGB values
%   - labels: Nx1 label vector (component assignments)
%
% Output:
%   - gmm_param: Struct array with K elements where K = number of unique labels
%                Each element has fields:
%                  .pi - mixture weight (scalar)
%                  .mu - mean vector (1x3)
%                  .sigma - covariance matrix (3x3)
%
% Author:
%   Xiuming Zhang (Original, 2015)
%   Modernized: 2025
%   - Added input validation with arguments block
%   - Added numerical stability for covariance computation
%   - Improved documentation

arguments
    rgb_pts (:,3) double {mustBeReal, mustBeFinite}
    labels (:,1) {mustBePositive, mustBeInteger}
end

% Get unique labels (sorted)
unique_labels = unique(labels);
n_gaussians = numel(unique_labels);
n_total = size(rgb_pts, 1);

% Preallocate output as struct array
gmm_param = struct('pi', cell(n_gaussians, 1), ...
                   'mu', cell(n_gaussians, 1), ...
                   'sigma', cell(n_gaussians, 1));

% Fit each Gaussian component
for idx = 1:n_gaussians
    % Get points belonging to this component
    mask = (labels == unique_labels(idx));
    pts = rgb_pts(mask, :);
    n_pts = size(pts, 1);

    % Compute mixture weight (pi)
    gmm_param(idx).pi = n_pts / n_total;

    % Compute mean (mu)
    gmm_param(idx).mu = mean(pts, 1);

    % Compute covariance (sigma) with numerical stability
    if n_pts > 1
        sigma = cov(pts);

        % Add small regularization to diagonal for numerical stability
        % Prevents singular covariance matrices
        min_variance = 1e-6;
        sigma = sigma + min_variance * eye(3);
    else
        % Single point: use identity matrix with small variance
        sigma = 1e-3 * eye(3);
    end

    gmm_param(idx).sigma = sigma;
end

end
