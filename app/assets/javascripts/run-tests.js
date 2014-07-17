// Helper for running tests through Karma.
// Hooks into the test view logic for running tests.

require('initialize');
TestView = require('views/TestView');
TestView.runTests();