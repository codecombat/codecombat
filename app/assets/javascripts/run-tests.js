// Helper for running tests through Karma.
// Hooks into the test view logic for running tests.


window.userObject = {_id:'1'}
initialize = require('core/initialize');
initialize.init();
console.debug = function() {}; // Karma conf doesn't seem to work? Debug messages are still emitted when they shouldn't be.
TestView = require('views/TestView');
TestView.runTests();
