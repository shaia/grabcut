function [pix_U_new, E] = cut_Tu(pix_U, im_sub, alpha, gmm_U, gmm_B, pairwise)
%CUT_TU Relabel pixels using graph cut optimization
%
% Uses MATLAB's built-in maxflow function (R2015b+) for min-cut optimization.
%
% Inputs:
%   - pix_U: Logical indices for foreground
%   - im_sub: HxWx3 RGB image
%   - alpha: Initial foreground indices
%   - gmm_U: Foreground GMM (struct array with fields: pi, mu, sigma)
%   - gmm_B: Background GMM (struct array with fields: pi, mu, sigma)
%   - pairwise: Pairwise terms (no_edges × 6 matrix)
%
% Output:
%   - pix_U_new: Updated logical indices for foreground
%   - E: Total energy after graph cut
%
% Author:
%   Xiuming Zhang (Original, 2015)
%   Modernized: 2025
%   - Replaced MEX with built-in maxflow
%   - Vectorized computations
%   - Refactored into clear sub-functions

arguments
    pix_U (:,1) logical
    im_sub (:,:,3) {mustBeNumeric}
    alpha (:,1) {mustBeNumeric}
    gmm_U struct
    gmm_B struct
    pairwise (:,6) double {mustBeReal}
end

% Setup
[im_h, im_w, ~] = size(im_sub);
no_nodes = im_h * im_w;

% Step 1: Compute unary terms (data costs)
fprintf('Computing unary terms...\n');
unary = compute_unary_terms(im_sub, no_nodes, gmm_U, gmm_B);
fprintf('Unary terms computed\n');

% Step 2: Build graph and run maxflow
fprintf('Building graph structure...\n');
[gc_labels, elapsed] = solve_graph_cut(unary, pairwise, no_nodes);
fprintf('Maxflow completed in %.2f seconds\n', elapsed);

% Step 3: Compute energy
E = compute_energy(unary, pairwise, gc_labels);
fprintf('Total energy: %.2f\n', E);

% Step 4: Update labels
pix_U_new = update_labels(pix_U, alpha, gc_labels);

end


%% Private Helper Functions

function unary = compute_unary_terms(im_sub, no_nodes, gmm_U, gmm_B)
%COMPUTE_UNARY_TERMS Compute data terms for all pixels

im_1d = reshape(double(im_sub), no_nodes, 3);

% Compute for both foreground and background
unary = zeros(2, no_nodes);
unary(1, :) = compute_unary_batch(im_1d, gmm_U);
unary(2, :) = compute_unary_batch(im_1d, gmm_B);

end


function [gc_labels, elapsed] = solve_graph_cut(unary, pairwise, no_nodes)
%SOLVE_GRAPH_CUT Build graph and solve min-cut problem

% Setup graph nodes
source_id = no_nodes + 1;
sink_id = no_nodes + 2;
total_nodes = no_nodes + 2;

% Build capacity matrix
C = build_capacity_matrix(unary, pairwise, no_nodes, source_id, sink_id, total_nodes);

% Create digraph and solve
G = digraph(C);
fprintf('Graph: %d nodes, %d edges\n', numnodes(G), numedges(G));

% Run maxflow
tic;
[~, ~, cs, ~] = maxflow(G, source_id, sink_id);
elapsed = toc;

% Extract labels (1=foreground, 2=background)
gc_labels = 2 * ones(no_nodes, 1);
gc_labels(cs(cs <= no_nodes)) = 1;

end


function C = build_capacity_matrix(unary, pairwise, no_nodes, source_id, sink_id, total_nodes)
%BUILD_CAPACITY_MATRIX Construct sparse capacity matrix for graph

C = sparse(total_nodes, total_nodes);

% Add terminal edges (source/sink connections)
pixel_nodes = 1:no_nodes;
C(source_id, pixel_nodes) = unary(1, pixel_nodes);  % Source to pixels
C(pixel_nodes, sink_id) = unary(2, pixel_nodes);    % Pixels to sink

% Add pairwise edges (neighbor connections)
num_edges = size(pairwise, 1);
for e = 1:num_edges
    i = pairwise(e, 1);
    j = pairwise(e, 2);
    C(i, j) = pairwise(e, 4);  % i=foreground, j=background
    C(j, i) = pairwise(e, 5);  % i=background, j=foreground
end

end


function pix_U_new = update_labels(pix_U, alpha, gc_labels)
%UPDATE_LABELS Update pixel labels based on graph cut result

pix_U_new = pix_U;
alpha(alpha == 1) = gc_labels;
pix_U_new(alpha == 2) = 0;

end
