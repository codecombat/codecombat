var spawn = require('child_process').spawn

if (process.env.SKIP_WEBPACK == "true") {
  console.log("Skipping webpack build because SKIP_WEBPACK=true")
}
else{
  var command = spawn("webpack");
  command.stdout.on('data', function (data) {
    process.stdout.write(data);
  });
  command.stderr.on('data', function (data) {
    process.stdout.write(data);
  });
}