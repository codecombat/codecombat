const _ = require("lodash");
const devConfigFn = require("./webpack.development.config");

// Development config extension for working within a container or environment
// that doesn't support default `watch` options.
module.exports = env => {
  if (!env) env = {};
  const devConfig = devConfigFn(env);
  return _.merge(devConfig, {
    watchOptions: {
      ignored: /node_modules|bower_components/,
      poll: 8500
    }
  });
};
