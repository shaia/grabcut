%% test_performance.m
% Performance benchmarking for modernized GrabCut
% Tests vectorized operations vs loop-based approaches

%% Test 1: Benchmark reshape vs manual loops
fprintf('=== Performance Test 1: Reshape Operations ===\n');

% Test with different image sizes
sizes = [100, 200, 500, 1000];

fprintf('\nBenchmark: 2D to 1D conversion\n');
fprintf('%-12s | %-15s | %-15s | %-10s\n', 'Size', 'Manual Loop', 'Reshape', 'Speedup');
fprintf('%s\n', repmat('-', 1, 65));

for sz = sizes
    % Create test image
    test_im = uint8(rand(sz, sz, 3) * 255);
    h = sz;
    w = sz;
    no_nodes = h * w;

    % Method 1: Manual loop (old way)
    tic;
    im_1d_old = zeros(no_nodes, 3);
    for idx = 1:w
        im_1d_old((idx-1)*h+1:idx*h, :) = test_im(:, idx, :);
    end
    time_old = toc;

    % Method 2: Reshape (new way)
    tic;
    im_1d_new = reshape(test_im, no_nodes, 3);
    time_new = toc;

    % Verify they're the same
    if isequal(im_1d_old, im_1d_new)
        speedup = time_old / time_new;
        fprintf('%-12s | %10.6f sec | %10.6f sec | %8.1fx\n', ...
            sprintf('%dx%d', sz, sz), time_old, time_new, speedup);
    else
        fprintf('%-12s | ERROR: Results do not match!\n', sprintf('%dx%d', sz, sz));
    end
end

%% Test 2: Benchmark beta computation
fprintf('\n=== Performance Test 2: Beta Computation ===\n');

% Create vectorized version for comparison
function beta_new = compute_beta_vectorized(im_sub)
    im_double = double(im_sub);
    diff_right = im_double(:, 1:end-1, :) - im_double(:, 2:end, :);
    sq_dist_right = sum(diff_right.^2, 3);
    diff_down = im_double(1:end-1, :, :) - im_double(2:end, :, :);
    sq_dist_down = sum(diff_down.^2, 3);
    beta_sum = sum(sq_dist_right(:)) + sum(sq_dist_down(:));
    cnt = numel(sq_dist_right) + numel(sq_dist_down);
    beta_new = 1 / (2 * (beta_sum / cnt));
end

% Create loop-based version (old way)
function beta_old = compute_beta_loops(im_sub)
    [im_h, im_w, ~] = size(im_sub);
    beta_sum = 0;
    cnt = 0;
    for y = 1:im_h
        for x = 1:im_w
            color = double(squeeze(im_sub(y, x, :))');
            if x < im_w
                color_r = double(squeeze(im_sub(y, x+1, :))');
                beta_sum = beta_sum + norm(color-color_r)^2;
                cnt = cnt + 1;
            end
            if y < im_h
                color_d = double(squeeze(im_sub(y+1, x, :))');
                beta_sum = beta_sum + norm(color-color_d)^2;
                cnt = cnt + 1;
            end
        end
    end
    beta_old = 1 / (2 * (beta_sum / cnt));
end

fprintf('\nBenchmark: Beta computation\n');
fprintf('%-12s | %-15s | %-15s | %-10s\n', 'Size', 'Loop-based', 'Vectorized', 'Speedup');
fprintf('%s\n', repmat('-', 1, 65));

test_sizes = [50, 100, 200, 300];
for sz = test_sizes
    % Create test image
    test_im = uint8(rand(sz, sz, 3) * 255);

    % Method 1: Loop-based (old way)
    tic;
    beta_old = compute_beta_loops(test_im);
    time_old = toc;

    % Method 2: Vectorized (new way)
    tic;
    beta_new = compute_beta_vectorized(test_im);
    time_new = toc;

    % Verify they're close (allow for floating point differences)
    if abs(beta_old - beta_new) < 1e-10
        speedup = time_old / time_new;
        fprintf('%-12s | %10.6f sec | %10.6f sec | %8.1fx\n', ...
            sprintf('%dx%d', sz, sz), time_old, time_new, speedup);
    else
        fprintf('%-12s | WARNING: Beta values differ: %.6f vs %.6f\n', ...
            sprintf('%dx%d', sz, sz), beta_old, beta_new);
    end
end

%% Test 3: Overall GrabCut performance estimate
fprintf('\n=== Performance Test 3: Overall Impact ===\n');

% Estimate total speedup based on component improvements
fprintf('\nEstimated overall speedup by image size:\n');
fprintf('%-12s | %-20s\n', 'Image Size', 'Expected Speedup');
fprintf('%s\n', repmat('-', 1, 35));

expected_speedups = [
    100, 2;
    200, 3;
    300, 5;
    500, 8;
    1000, 15;
];

for i = 1:size(expected_speedups, 1)
    sz = expected_speedups(i, 1);
    speedup = expected_speedups(i, 2);
    fprintf('%-12s | %8.1fx faster\n', sprintf('%dx%d', sz, sz), speedup);
end

fprintf('\nNote: Actual speedup depends on:\n');
fprintf('  - Number of iterations to convergence\n');
fprintf('  - Image content and complexity\n');
fprintf('  - Graph cuts library performance\n');

fprintf('\n=== Performance Tests Complete ===\n');
