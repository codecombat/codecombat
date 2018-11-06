/**
 * NPM post-install middleware.
 * By default runs webpack.
 *
 * Set SKIP_WEBPACK=true` to skip the webpack build.
 * Set `DELETE_DEPENDENCIES=true` to delete node_modules and bower_components.
 * Useful when building the client for only the `public` folder.
 */
const cp = require("child_process");

const spawn = cp.spawn;
const exec = cp.exec;

const remove_dependencies = () => {
  const rm = exec("rm -rf node_modules && rm -rf bower_components");
  return rm;
};

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

  command.on("exit", () => {
    // Use when we only need the public folder.
    if (process.env.DELETE_DEPENDENCIES === "true") {
      console.log(
        "Cleaning up dependencies because `DELETE_DEPENDENCIES=true`."
      );
      remove_dependencies();
    }
  });
}
