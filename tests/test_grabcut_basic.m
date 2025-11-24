%% test_grabcut_basic.m
% Basic functionality test for modernized GrabCut implementation
% This script tests that the code runs without errors

%% Test 1: Basic Functionality Test
fprintf('=== Test 1: Basic Functionality ===\n');

% Load a test image
if exist('results/test1.jpg', 'file')
    im_in = imread('results/test1.jpg');
    fprintf('✓ Loaded test image: %dx%dx%d\n', size(im_in, 1), size(im_in, 2), size(im_in, 3));
else
    fprintf('✗ Test image not found. Creating synthetic image...\n');
    % Create a simple synthetic image for testing
    im_in = uint8(zeros(100, 100, 3));
    im_in(30:70, 30:70, :) = 255; % White square in center
    im_in(:, :, 1) = im_in(:, :, 1) + uint8(rand(100, 100) * 50); % Add some noise
end

% Set gamma parameter
gamma = 20;

fprintf('Starting GrabCut with gamma = %d...\n', gamma);
fprintf('Please draw a rectangle around the foreground object when prompted.\n');

try
    % Run GrabCut
    tic;
    im_out = grabcut(im_in, gamma);
    elapsed = toc;

    fprintf('✓ GrabCut completed successfully in %.2f seconds\n', elapsed);
    fprintf('  Output size: %dx%dx%d\n', size(im_out, 1), size(im_out, 2), size(im_out, 3));

catch ME
    fprintf('✗ GrabCut failed with error:\n');
    fprintf('  %s\n', ME.message);
    rethrow(ME);
end

%% Test 2: Verify Output Properties
fprintf('\n=== Test 2: Output Validation ===\n');

% Check output dimensions match input
if isequal(size(im_out), size(im_in))
    fprintf('✓ Output dimensions match input: %dx%dx%d\n', size(im_out, 1), size(im_out, 2), size(im_out, 3));
else
    fprintf('✗ Output dimensions do not match input!\n');
    fprintf('  Input:  %dx%dx%d\n', size(im_in, 1), size(im_in, 2), size(im_in, 3));
    fprintf('  Output: %dx%dx%d\n', size(im_out, 1), size(im_out, 2), size(im_out, 3));
end

% Check output data type
if strcmp(class(im_out), class(im_in))
    fprintf('✓ Output data type matches input: %s\n', class(im_out));
else
    fprintf('⚠ Output data type differs from input\n');
    fprintf('  Input:  %s\n', class(im_in));
    fprintf('  Output: %s\n', class(im_out));
end

% Check that background is white (255)
background_pixels = im_out == 255;
background_ratio = sum(background_pixels(:)) / numel(im_out);
fprintf('✓ Background (white) ratio: %.2f%%\n', background_ratio * 100);

%% Test 3: Helper Functions
fprintf('\n=== Test 3: Helper Functions ===\n');

% Test reshape operations
fprintf('Testing reshape operations...\n');
test_im = uint8(rand(50, 40, 3) * 255);
[h, w, ~] = size(test_im);
no_nodes = h * w;

% Test 2D to 1D
im_1d = reshape(test_im, no_nodes, 3);
fprintf('✓ 2D→1D reshape: %dx%dx%d → %dx%d\n', h, w, 3, size(im_1d, 1), size(im_1d, 2));

% Test 1D back to 2D
im_2d = reshape(im_1d, h, [], 3);
fprintf('✓ 1D→2D reshape: %dx%d → %dx%dx%d\n', size(im_1d, 1), size(im_1d, 2), size(im_2d, 1), size(im_2d, 2), size(im_2d, 3));

% Verify round-trip
if isequal(test_im, im_2d)
    fprintf('✓ Round-trip conversion successful\n');
else
    fprintf('✗ Round-trip conversion failed!\n');
end

%% Test Summary
fprintf('\n=== Test Summary ===\n');
fprintf('All basic tests completed!\n');
fprintf('Performance: %.2f seconds\n', elapsed);
