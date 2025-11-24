function E = compute_energy(unary, pairwise, gc_labels)
%COMPUTE_ENERGY Calculate total energy of current labeling
%
% Inputs:
%   - unary: 2xN matrix of unary costs (foreground, background)
%   - pairwise: no_edges × 6 matrix of pairwise costs
%   - gc_labels: Nx1 vector of pixel labels (1=foreground, 2=background)
%
% Output:
%   - E: Total energy (unary + pairwise)
%
% Author:
%   Xiuming Zhang (Original, 2015)
%   Modernized: 2025

arguments
    unary (2,:) double {mustBeReal}
    pairwise (:,6) double {mustBeReal}
    gc_labels (:,1) {mustBeInteger, mustBeInRange(gc_labels, 1, 2)}
end

% Unary energy (vectorized)
E_unary = sum(unary(sub2ind(size(unary), gc_labels', 1:numel(gc_labels))));

% Pairwise energy
E_pairwise = compute_pairwise_energy(pairwise, gc_labels);

E = E_unary + E_pairwise;

end


function E_pairwise = compute_pairwise_energy(pairwise, gc_labels)
%COMPUTE_PAIRWISE_ENERGY Calculate smoothness energy
%
% Inputs:
%   - pairwise: no_edges × 6 matrix
%   - gc_labels: Nx1 vector of pixel labels
%
% Output:
%   - E_pairwise: Pairwise smoothness energy

num_edges = size(pairwise, 1);
E_pairwise = 0;

for e = 1:num_edges
    i = pairwise(e, 1);
    j = pairwise(e, 2);
    label_i = gc_labels(i);
    label_j = gc_labels(j);

    % Select appropriate cost based on label combination
    % Column 3: both=1, Column 4: i=1,j=2, Column 5: i=2,j=1, Column 6: both=2
    if label_i == 1 && label_j == 1
        E_pairwise = E_pairwise + pairwise(e, 3);
    elseif label_i == 1 && label_j == 2
        E_pairwise = E_pairwise + pairwise(e, 4);
    elseif label_i == 2 && label_j == 1
        E_pairwise = E_pairwise + pairwise(e, 5);
    else
        E_pairwise = E_pairwise + pairwise(e, 6);
    end
end

end
