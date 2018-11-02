var child_process = require('child_process')
var exec = child_process.exec

if (process.env.SKIP_WEBPACK) {
  console.log("Skipping webpack build because SKIP_WEBPACK=true")
}
else{
  var command = "npm run webpack";
  exec (command, function(err, stdout, stderr) {
    if (err){
      console.log( "Error running webpack:", err )
    }
    else{
      console.log(stdout)
    }
  })
}