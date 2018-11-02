// TODO: Reconcile env variables for this; maybe WEBPACK_ENV = travis/production/undefined
if (process.env.COCO_TRAVIS_TEST) {
  console.log("Automatically using Karma webpack config");
  module.exports = require("./webpack.karma.config");
} else if (process.env.BRUNCH_ENV == "production") {
  console.log("Automatically using Production webpack config");
  module.exports = require("./webpack.production.config");
} else if (process.env.COCO_ANALYZER_BUNDLE) {
  console.log("Automatically using Analyzer webpack config");
  module.exports = require("./webpack.analyzer.config");
} else if (process.env.DEV_CONTAINER) {
  console.log("Automatically using dev_container webpack config");
  module.exports = require("./webpack.dev_container.config");
} else {
  console.log("Automatically using Development webpack config");
  module.exports = require("./webpack.development.config");
}