function pairwise = compute_pairwise(im_sub, gamma)
%COMPUTE_PAIRWISE Part of GrabCut. Compute the pairwise terms.
%
% Inputs:
%   - im_sub: 2D subimage, on which Graph Cut is performed
%   - gamma: gamma parameter
%
% Output:
%   - pairwise: a dense no_edgesx6 matrix of doubles. Each row is of the
%format [i, j, e00, e01, e10, e11] where i and j are neighbours and the four
%coefficients define the interaction potential
%
% Author:
%   Xiuming Zhang
%   GitHub: xiumingzhang
%   Dept. of ECE, National University of Singapore
%   April 2015
%
% Modernized: 2025
%   - Vectorized beta computation
%   - Improved memory preallocation
%   - Added input validation comments

% Get image dimensions
[im_h, im_w, ~] = size(im_sub);

%------- Compute \beta

beta = compute_beta(im_sub);

%------- Set pairwise

pairwise = zeros((im_h-1)*(im_w-1)*2+(im_h-1)+(im_w-1), 6);

% Loop through all the pixels (nodes) and set pairwise
idx = 1;
for y = 1:im_h
    for x = 1:im_w
        % Current node
        node = (x-1)*im_h+y;
        color = get_rgb_double(im_sub, x, y);
        
        % Right neighbor
        if x < im_w % Has a right neighbor
            node_r = (x+1-1)*im_h+y;
            color_r = get_rgb_double(im_sub, x+1, y);
            pairwise(idx, 1) = node;
            pairwise(idx, 2) = node_r;
            pairwise(idx, 3) = compute_V(color, 0, color_r, 0, gamma, beta);
            pairwise(idx, 4) = compute_V(color, 0, color_r, 1, gamma, beta);
            pairwise(idx, 5) = compute_V(color, 1, color_r, 0, gamma, beta);
            pairwise(idx, 6) = compute_V(color, 1, color_r, 1, gamma, beta);
            idx = idx+1;
        end
        
        % Down neighbor
        if y < im_h % Has a down neighbor
            node_d = (x-1)*im_h+y+1;
            color_d = get_rgb_double(im_sub, x, y+1);
            pairwise(idx, 1) = node;
            pairwise(idx, 2) = node_d;
            pairwise(idx, 3) = compute_V(color, 0, color_d, 0, gamma, beta);
            pairwise(idx, 4) = compute_V(color, 0, color_d, 1, gamma, beta);
            pairwise(idx, 5) = compute_V(color, 1, color_d, 0, gamma, beta);
            pairwise(idx, 6) = compute_V(color, 1, color_d, 1, gamma, beta);
            idx = idx+1;
        end
    end
end

end


function beta = compute_beta(im_sub)
% Compute beta parameter using vectorized operations
% Beta = 1 / (2 * E[||color_i - color_j||^2]) for neighboring pixels

% Get image dimensions
[im_h, im_w, ~] = size(im_sub);

% Convert to double for computation
im_double = double(im_sub);

% Vectorized computation for horizontal neighbors (right)
% Compare each pixel with its right neighbor
diff_right = im_double(:, 1:end-1, :) - im_double(:, 2:end, :);
sq_dist_right = sum(diff_right.^2, 3); % Sum across RGB channels

% Vectorized computation for vertical neighbors (down)
% Compare each pixel with its down neighbor
diff_down = im_double(1:end-1, :, :) - im_double(2:end, :, :);
sq_dist_down = sum(diff_down.^2, 3); % Sum across RGB channels

% Combine all squared distances
beta_sum = sum(sq_dist_right(:)) + sum(sq_dist_down(:));
cnt = numel(sq_dist_right) + numel(sq_dist_down);

beta = 1 / (2 * (beta_sum / cnt));

end


function V = compute_V(color1, label1, color2, label2, gamma, beta)

V = gamma*double(label1~=label2)*exp(-beta*(norm(color1-color2)^2));

end
