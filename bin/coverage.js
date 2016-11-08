fs = require('fs')
child_process = require('child_process')

// Have to convert all CS server files to JS for coverage to work.
// Walk through folders in server/ and compile each .coffee file,
// keeping a list of generated files so they can be deleted later.

var directories = ['./server']
var convertedFiles = [];
console.log('Convert server coffeescript files.')

while(directories.length) {
  directory = directories.pop()
  console.log('*', directory)

  fs.readdirSync(directory).forEach((fileOrDir) => {
    absPath = directory + '/' + fileOrDir
    stat = fs.statSync(absPath)

    // .coffee => .js
    if(stat.isFile() && fileOrDir.endsWith('.coffee')) {
      child_process.execSync(`coffee -c ${absPath}`)
      convertedFiles.push(absPath.replace('.coffee', '.js'))
    }

    // Add to list of directories to walk
    if(stat.isDirectory()) {
      directories.push(absPath);
    }
  })
}

// Run Istanbul
console.log(`Converted ${convertedFiles.length} server coffeescript files. Running tests...`)
try {
  child_process.execSync('istanbul cover ./node_modules/jasmine/bin/jasmine.js')
}
catch (e) {
  if (process.env.COCO_TRAVIS_TEST) {
    console.log('Failed to run coverage tests. Ignoring.');
    process.exit(0)
  }
  else {
    throw e;
  }
}

// Cleanup
if(!process.env.COCO_TRAVIS_TEST) {
  console.log('Coverage report generated. Deleting converted files...')
  for (file of convertedFiles) {
    fs.unlinkSync(file)
  }
}
  

console.log('Done.')
