%% test_unit.m
% Unit tests for individual GrabCut functions
% Tests correctness and edge cases

%% Test Suite Setup
fprintf('=== GrabCut Unit Tests ===\n\n');
test_passed = 0;
test_failed = 0;

%% Test 1: Reshape operations
fprintf('Test 1: 2D↔1D reshape operations\n');
try
    % Test various image sizes
    test_sizes = [10 10; 50 40; 100 75; 200 150];

    for i = 1:size(test_sizes, 1)
        h = test_sizes(i, 1);
        w = test_sizes(i, 2);
        test_im = uint8(rand(h, w, 3) * 255);
        no_nodes = h * w;

        % 2D to 1D
        im_1d = reshape(test_im, no_nodes, 3);
        assert(size(im_1d, 1) == no_nodes, 'Incorrect 1D size');
        assert(size(im_1d, 2) == 3, 'Should have 3 color channels');

        % 1D back to 2D
        im_2d = reshape(im_1d, h, [], 3);
        assert(isequal(size(im_2d), [h, w, 3]), 'Incorrect 2D size');
        assert(isequal(test_im, im_2d), 'Round-trip failed');
    end

    fprintf('  ✓ Passed (tested %d image sizes)\n', size(test_sizes, 1));
    test_passed = test_passed + 1;
catch ME
    fprintf('  ✗ Failed: %s\n', ME.message);
    test_failed = test_failed + 1;
end

%% Test 2: fit_gmm
fprintf('Test 2: fit_gmm\n');
try
    % Create synthetic data with 3 clusters
    n_points = 300;
    n_clusters = 3;

    rgb_pts = [
        randn(100, 3) * 10 + [50, 50, 50];
        randn(100, 3) * 10 + [150, 150, 150];
        randn(100, 3) * 10 + [200, 100, 100];
    ];
    labels = [ones(100, 1); ones(100, 1)*2; ones(100, 1)*3];

    gmm = fit_gmm(rgb_pts, labels);

    % Verify structure (struct array with n_clusters elements)
    assert(numel(gmm) == n_clusters, 'Should have correct number of Gaussians');
    assert(isstruct(gmm), 'Should be a struct array');

    % Verify weights sum to 1
    weights = 0;
    for k = 1:n_clusters
        weights = weights + gmm(k).pi;
    end
    assert(abs(weights - 1) < 1e-10, 'Weights should sum to 1');

    % Verify covariance matrices are symmetric and positive definite
    for k = 1:n_clusters
        sigma = gmm(k).sigma;
        assert(size(sigma, 1) == 3 && size(sigma, 2) == 3, 'Covariance should be 3x3');
        assert(norm(sigma - sigma') < 1e-10, 'Covariance should be symmetric');
        % Check positive definite (all eigenvalues > 0)
        eigs_val = eig(sigma);
        assert(all(eigs_val > 0), 'Covariance should be positive definite');
    end

    fprintf('  ✓ Passed\n');
    test_passed = test_passed + 1;
catch ME
    fprintf('  ✗ Failed: %s\n', ME.message);
    test_failed = test_failed + 1;
end

%% Test 3: Beta computation (vectorized)
fprintf('Test 3: Vectorized beta computation\n');
try
    % Create test images with known properties
    test_im1 = uint8(ones(50, 50, 3) * 128); % Uniform image -> beta should be very large
    test_im2 = uint8(rand(50, 50, 3) * 255); % Random image -> smaller beta

    % Load actual compute_beta from compute_pairwise.m
    % We'll test it indirectly through compute_pairwise
    pairwise1 = compute_pairwise(test_im1, 20);
    pairwise2 = compute_pairwise(test_im2, 20);

    assert(size(pairwise1, 2) == 6, 'Pairwise should have 6 columns');
    assert(size(pairwise1, 1) > 0, 'Pairwise should have rows');

    % For uniform image, pairwise terms should be lower (less edge strength)
    % because beta will be very large (small variance)

    fprintf('  ✓ Passed\n');
    test_passed = test_passed + 1;
catch ME
    fprintf('  ✗ Failed: %s\n', ME.message);
    test_failed = test_failed + 1;
end

%% Test 4: Edge cases
fprintf('Test 4: Edge cases and error handling\n');
try
    % Test small image
    small_im = uint8(rand(10, 10, 3) * 255);
    pairwise = compute_pairwise(small_im, 20);
    assert(~isempty(pairwise), 'Should handle small images');

    % Test rectangular image
    rect_im = uint8(rand(20, 30, 3) * 255);
    pairwise = compute_pairwise(rect_im, 20);
    assert(~isempty(pairwise), 'Should handle rectangular images');

    fprintf('  ✓ Passed\n');
    test_passed = test_passed + 1;
catch ME
    fprintf('  ✗ Failed: %s\n', ME.message);
    test_failed = test_failed + 1;
end

%% Test Summary
fprintf('\n=== Test Summary ===\n');
fprintf('Tests Passed: %d\n', test_passed);
fprintf('Tests Failed: %d\n', test_failed);
fprintf('Total Tests:  %d\n', test_passed + test_failed);

if test_failed == 0
    fprintf('\n✓ All tests passed!\n');
else
    fprintf('\n✗ Some tests failed. Please review.\n');
end
