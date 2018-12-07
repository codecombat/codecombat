/**
 * NPM post-install middleware.
 * By default runs webpack.
 *
 * Set SKIP_WEBPACK=true` to skip the webpack build.
 */
const cp = require("child_process");

const spawn = cp.spawn;

if (process.env.SKIP_WEBPACK === "true") {
  console.log("Skipping webpack build because SKIP_WEBPACK=true");
} else {
  const command = spawn("webpack");
  command.stdout.on("data", function(data) {
    process.stdout.write(data);
  });
  command.stderr.on("data", function(data) {
    process.stdout.write(data);
  });
}
