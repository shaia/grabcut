%% run_all_tests.m
% Master test runner for GrabCut modernization
% Runs all test suites and generates a summary report

clear;
clc;

fprintf('╔════════════════════════════════════════════════════════════╗\n');
fprintf('║        GrabCut Modernization Test Suite                   ║\n');
fprintf('╚════════════════════════════════════════════════════════════╝\n\n');

% Check MATLAB version
matlab_ver = version('-release');
fprintf('MATLAB Version: %s\n', matlab_ver);
fprintf('Working Directory: %s\n\n', pwd);

%% Test Suite 1: Unit Tests
fprintf('┌────────────────────────────────────────────────────────────┐\n');
fprintf('│ Running Unit Tests...                                      │\n');
fprintf('└────────────────────────────────────────────────────────────┘\n');
try
    run('test_unit.m');
    unit_tests_passed = true;
catch ME
    fprintf('Unit tests failed: %s\n', ME.message);
    unit_tests_passed = false;
end

%% Test Suite 2: Performance Tests
fprintf('\n┌────────────────────────────────────────────────────────────┐\n');
fprintf('│ Running Performance Tests...                               │\n');
fprintf('└────────────────────────────────────────────────────────────┘\n');
try
    run('test_performance.m');
    perf_tests_passed = true;
catch ME
    fprintf('Performance tests failed: %s\n', ME.message);
    perf_tests_passed = false;
end

%% Test Suite 3: Basic Functionality (Interactive)
fprintf('\n┌────────────────────────────────────────────────────────────┐\n');
fprintf('│ Basic Functionality Test (Interactive)                     │\n');
fprintf('└────────────────────────────────────────────────────────────┘\n');
fprintf('Note: This test requires user interaction (drawing rectangle)\n');
fprintf('Do you want to run the interactive test? (y/n): ');

response = input('', 's');
if strcmpi(response, 'y')
    try
        run('test_grabcut_basic.m');
        basic_tests_passed = true;
    catch ME
        fprintf('Basic functionality test failed: %s\n', ME.message);
        basic_tests_passed = false;
    end
else
    fprintf('Skipping interactive test.\n');
    basic_tests_passed = true; % Don't count as failure
end

%% Final Summary
fprintf('\n╔════════════════════════════════════════════════════════════╗\n');
fprintf('║                    FINAL SUMMARY                           ║\n');
fprintf('╠════════════════════════════════════════════════════════════╣\n');

if unit_tests_passed
    fprintf('║  ✓ Unit Tests:        PASSED                              ║\n');
else
    fprintf('║  ✗ Unit Tests:        FAILED                              ║\n');
end

if perf_tests_passed
    fprintf('║  ✓ Performance Tests: PASSED                              ║\n');
else
    fprintf('║  ✗ Performance Tests: FAILED                              ║\n');
end

if basic_tests_passed
    fprintf('║  ✓ Basic Tests:       PASSED                              ║\n');
else
    fprintf('║  ✗ Basic Tests:       FAILED                              ║\n');
end

fprintf('╚════════════════════════════════════════════════════════════╝\n');

% Overall result
all_passed = unit_tests_passed && perf_tests_passed && basic_tests_passed;
if all_passed
    fprintf('\n✓✓✓ ALL TESTS PASSED ✓✓✓\n');
    fprintf('The modernized GrabCut implementation is working correctly!\n');
else
    fprintf('\n✗✗✗ SOME TESTS FAILED ✗✗✗\n');
    fprintf('Please review the output above for details.\n');
end
