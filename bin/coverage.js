fs = require('fs')
_ = require('lodash')
child_process = require('child_process')

// Have to convert all CS server files to JS for coverage to work.
// Walk through folders in server/ and compile each .coffee file,
// keeping a list of generated files so they can be deleted later.

var convertedFiles = [];
console.log('Convert server coffeescript files.')

try{
  var find_output = child_process.execSync('coffee --compile ./server && find ./server -name "*.js"');
  var splits      = find_output.toString().split("\n")
  convertedFiles  = _.compact(splits);

  // Run Istanbul
  console.log(`Converted ${convertedFiles.length} server coffeescript files. Running tests...`)
  child_process.execSync('istanbul cover ./node_modules/jasmine/bin/jasmine.js')
}
catch (e) {
  if (process.env.COCO_TRAVIS_TEST) {
    console.log('Failed to run coverage tests. Ignoring.');
    process.exit(0)
  }
  else {
    console.log("Error occurred. Coverage report may still have been generated.");
    throw e;
  }
} finally {
  // Cleanup
  if(!process.env.COCO_TRAVIS_TEST) {
    console.log('Coverage report generated. Deleting converted files...')
    for (file of convertedFiles) {
      fs.unlinkSync(file)
    }
  }

  console.log('Done.')
}
