const scriptStartTime = new Date()

// This script tests the level generation algorithm by generating levels with random parameters and saving the results.

// Example usage:
// nodemon scripts/generateLevels.js --dry --debug

require('coffee-script').register()
const _ = require('lodash')
_.string = require('underscore.string')
_.mixin(_.str.exports())

const fs = require('fs')
const path = require('path')
const PWD = __dirname
const program = require('commander')
const moment = require('moment')
const levelGeneration = require('../app/lib/level-generation')

async function main () {
  const options = parseOptions()
  for (let i = 0; i < 1; ++i) {
    const parameters = {}
    const level = await levelGeneration.generateLevel(parameters)
    debug(level)
    await saveLevel(level, options)
  }
}

async function saveLevel (level, options) {
  const fileName = `level-${level.parametersKey}.json`

  // Make the levels output directory
  const levelsDir = path.join(PWD, 'levels')
  if (!fs.existsSync(levelsDir)) {
    fs.mkdirSync(levelsDir)
  }

  // Write the level to a file
  const levelPath = path.join(levelsDir, fileName)
  fs.writeFileSync(levelPath, JSON.stringify(level, null, 2))
  console.log(`Wrote level to ${levelPath}`)

  if (!options.dry) {
    // Write the level to the database
    // TODO
  }
}

function parseOptions () {
  console.log()
  program
    .description('Creates test levels to exercise the level-generation library')
    .option('-d, --debug', 'Debug logging') // TODO: differentiate normal, debug, and verbose logging levels
    .option('--dry', 'Dry run--does not write levels')
    .parse(process.argv)
  const options = program.opts()
  if (options.debug) {
    debugOutput = true
  }
  return options
}

let debugOutput = false
function debug (...args) {
  if (!debugOutput) return
  console.log('\x1b[36m%s\x1b[0m', moment().format('YYYY-MM-DD HH:mm:ss.SSS'), ...args)
}

main().then(() => {
  console.log('Finished in', moment.duration(new Date() - scriptStartTime).asSeconds(), 'seconds')
  process.exit(0)
}).catch((err) => {
  console.error('Error: ', err)
  process.exit(1)
})
