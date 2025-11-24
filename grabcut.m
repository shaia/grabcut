function im_out = grabcut(im_in, gamma, options)
%GRABCUT Foreground extraction with GrabCut
%
% This is a modernized version that uses MATLAB's built-in graph/maxflow
% instead of external MEX files. Requires MATLAB R2015b or later.
%
% Syntax:
%   im_out = grabcut(im_in, gamma)
%   im_out = grabcut(im_in, gamma, options)
%
% Inputs:
%   im_in  - Input RGB image (H×W×3 matrix)
%   gamma  - Smoothness parameter (typically 20-50)
%   options - Optional struct with fields:
%       .n_gaussians (default: 5) - Number of Gaussians in GMM
%       .convergence_threshold (default: 0.0001) - Convergence criterion
%       .max_iterations (default: 10) - Maximum iterations
%       .verbose (default: true) - Display progress
%       .show_progress (default: true) - Show intermediate results
%
% Output:
%   im_out - Extracted foreground (background set to white)
%
% Example:
%   im = imread('test.jpg');
%   result = grabcut(im, 20);
%
% Author:
%   Xiuming Zhang (Original, 2015)
%   Modernized: 2025
%   - Uses built-in maxflow instead of MEX files
%   - Vectorized operations
%   - Configurable parameters
%   - Better documentation
%   - Input validation with arguments block

arguments
    im_in (:,:,3) {mustBeNumeric}
    gamma (1,1) double {mustBePositive, mustBeFinite}
    options.n_gaussians (1,1) {mustBePositive, mustBeInteger} = 5
    options.convergence_threshold (1,1) double {mustBePositive} = 0.0001
    options.max_iterations (1,1) {mustBePositive, mustBeInteger} = 10
    options.verbose (1,1) logical = true
    options.show_progress (1,1) logical = true
end

% Get image dimensions
[im_h, ~, ~] = size(im_in);

% Step 1: User selection and data preparation
if options.verbose
    fprintf('=== GrabCut Initialization ===\n');
end

[im_1d, alpha, im_sub] = select_back(im_in);
[pix_U, pix_B] = prepare_pixel_masks(alpha, im_1d, options.verbose, im_sub);

% Step 2: Initialize GMMs
[gmm_U, gmm_B] = initialize_gmms(im_1d, pix_U, pix_B, options.n_gaussians, options.verbose);

% Step 3: Compute pairwise terms
pairwise = compute_pairwise(im_sub, gamma);
if options.verbose
    fprintf('Pairwise terms computed: %d edges\n', size(pairwise, 1));
end

% Step 4: Run iterative optimization
[pix_U, final_energy, num_iterations] = run_iterative_optimization(...
    im_1d, im_sub, alpha, pix_U, gmm_U, gmm_B, pairwise, im_h, options);

% Step 5: Generate output
pix_B = ~pix_U;
im_out = create_output_image(im_1d, pix_B, im_h);

% Final statistics
if options.verbose
    fprintf('\n=== GrabCut Complete ===\n');
    fprintf('Total iterations: %d\n', num_iterations);
    fprintf('Final energy: %.2f\n', final_energy);
    fprintf('Foreground pixels: %d (%.1f%%)\n', sum(pix_U), 100 * sum(pix_U) / numel(pix_U));
end

end


%% Helper Functions

function [pix_U, pix_B] = prepare_pixel_masks(alpha, im_1d, verbose, im_sub)
%PREPARE_PIXEL_MASKS Create foreground/background pixel masks

pix_U = alpha == 1;
pix_B = ~pix_U;

if verbose
    fprintf('Image size: %dx%d\n', size(im_sub, 1), size(im_sub, 2));
    fprintf('Foreground pixels: %d\n', sum(pix_U));
    fprintf('Background pixels: %d\n', sum(pix_B));
end

end


function [gmm_U, gmm_B] = initialize_gmms(im_1d, pix_U, pix_B, n_gaussians, verbose)
%INITIALIZE_GMMS Initialize foreground and background GMMs using k-means

if verbose
    fprintf('Initializing GMMs with %d Gaussians each...\n', n_gaussians);
end

% Extract foreground and background pixels
foreground_pixels = im_1d(pix_U, :);
background_pixels = im_1d(pix_B, :);

% K-means clustering and GMM fitting for background
labels_B = kmeans(background_pixels, n_gaussians, 'Distance', 'cityblock', ...
                  'Replicates', 5, 'Display', 'off');
gmm_B = fit_gmm(background_pixels, labels_B);

% K-means clustering and GMM fitting for foreground
labels_U = kmeans(foreground_pixels, n_gaussians, 'Distance', 'cityblock', ...
                  'Replicates', 5, 'Display', 'off');
gmm_U = fit_gmm(foreground_pixels, labels_U);

if verbose
    fprintf('GMMs initialized\n');
end

end


function [pix_U, final_energy, num_iterations] = run_iterative_optimization(...
    im_1d, im_sub, alpha, pix_U, gmm_U, gmm_B, pairwise, im_h, options)
%RUN_ITERATIVE_OPTIMIZATION Main GrabCut optimization loop

if options.verbose
    fprintf('\n=== Starting Iterative Optimization ===\n');
end

is_converged = false;
energy_prev = inf;
iter = 0;

while ~is_converged && iter < options.max_iterations

    % Assign pixels to GMM components
    pix_B = ~pix_U;
    [labels_U, labels_B] = assign_gauss(im_1d, pix_U, gmm_U, pix_B, gmm_B);

    % Update GMM parameters
    [gmm_U, gmm_B] = update_gmm(im_1d, pix_U, labels_U, pix_B, labels_B);

    % Graph cut optimization
    [pix_U, energy] = cut_Tu(pix_U, im_sub, alpha, gmm_U, gmm_B, pairwise);

    % Check convergence
    energy_change = (energy_prev - energy) / energy_prev;
    iter = iter + 1;

    if options.verbose
        fprintf('\n');
        fprintf('Iteration %d: E = %.2f, ΔE = %.4f%% (threshold: %.4f%%)\n', ...
            iter, energy, energy_change * 100, options.convergence_threshold * 100);
    end

    if energy_change < options.convergence_threshold
        is_converged = true;
        if options.verbose
            fprintf('✓ Converged!\n');
        end
    end

    % Display progress
    if options.show_progress
        display_progress(im_1d, pix_U, im_h, iter, energy);
    end

    energy_prev = energy;
end

if ~is_converged && options.verbose
    fprintf('⚠ Maximum iterations (%d) reached without convergence\n', options.max_iterations);
end

num_iterations = iter;
final_energy = energy;

end


function display_progress(im_1d, pix_U, im_h, iteration, energy)
%DISPLAY_PROGRESS Show intermediate segmentation result

pix_B = ~pix_U;
im_out_1d = im_1d;
im_out_1d(pix_B, :) = 255;
im_out = reshape(im_out_1d, im_h, [], 3);

imshow(im_out);
title(sprintf('GrabCut Iteration %d - Energy: %.2f', iteration, energy));
drawnow;

end


function im_out = create_output_image(im_1d, pix_B, im_h)
%CREATE_OUTPUT_IMAGE Generate final segmentation with white background

im_out_1d = im_1d;
im_out_1d(pix_B, :) = 255;
im_out = reshape(im_out_1d, im_h, [], 3);

end
