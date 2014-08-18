// Helper for running tests through Karma.
// Hooks into the test view logic for running tests.

require('initialize');
console.debug = function() {}; // Karma conf doesn't seem to work? Debug messages are still emitted when they shouldn't be.
TestView = require('views/TestView');
TestView.runTests();