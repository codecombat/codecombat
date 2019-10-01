// Helper for running tests through Karma.
// Hooks into the test view logic for running tests.
require("app/app.js");

window.userObject = { _id: "1" };
window.serverConfig = {
  picoCTF: false,
  production: false,
  buildInfo: { sha: "dev" }
};
window.StripeCheckout = { configure: function() {} };
window.features = { freeOnly: false, chinaInfra: DEF_CHINA_INFRA };
window.serverSession = {};

const initialize = require("core/initialize");
initialize.init();
application.testing = true;
application.karmaTest = true;

console.debug = function() {}; // Karma conf doesn't seem to work? Debug messages are still emitted when they shouldn't be.
const TestView = require("views/TestView");
TestView.runTests();
