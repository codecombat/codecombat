# Usage:
# > coffee scripts/node/screenshotAllLevels.coffee run

require('coffee-script');
require('coffee-script/register');

exec = require('child_process').exec

_ = require 'lodash'
str = require 'underscore.string'

exports.run = (mongoose) ->
  Campaign = require '../../server/models/Campaign'
  query = Campaign.find({slug: {$exists: true, $nin: ['auditions', 'picoctf', 'tests']}}, {slug: 1, levels: 1}).lean()
  query.exec (err, campaigns) ->
    levelSlugs = new Set()
    for campaign in campaigns
      for levelID, level of campaign.levels
        levelSlugs.add level.slug
    console.log "Found #{campaigns.length} campaigns with #{levelSlugs.size} levels."
    levelSlugs = Array.from levelSlugs

    screenshotLevel = ->
      levelSlug = levelSlugs.shift()
      return mongoose.connection.close() unless levelSlug
      url = "https://codecombat.com/play/level/#{levelSlug}"
      console.log url
      closeSafariCommand = 'osascript -e \'tell application "Safari"\n  close every window\nend tell\''
      exec closeSafariCommand, (err, stdout, stderr) ->
        console.log err, stdout, stderr if err or stderr
        exec "open -a /Applications/Safari.app #{url}", (err, stdout, stderr) ->
          console.log err, stdout, stderr if err or stderr
          setTimeout ->
            exec "screencapture -o -l$(osascript -e 'tell app \"Safari\" to id of window 1') \"/Users/winter/Downloads/levels/#{levelSlug}.png\"", (err, stdout, stderr) ->
              console.log err, stdout, stderr if err or stderr
              setTimeout screenshotLevel, 500
          , 10000

    screenshotLevel()

if _.last(process.argv) is 'run'
  database = require '../../server/commons/database'
  mongoose = require 'mongoose'

  ### SET UP ###
  do (setupLodash = this) ->
    GLOBAL._ = require 'lodash'
    _.str = require 'underscore.string'
    _.mixin _.str.exports()
    GLOBAL.tv4 = require('tv4').tv4

  database.connect()
  exports.run mongoose

# Fun stuff
#mkdir ~/Downloads/levels/cropped
#mogrify -crop 609x385+1+91 +repage -path ~/Downloads/levels/cropped *.png
#montage -tile 25x24 -geometry '203x128+0+0' ~/Downloads/levels/cropped/*.png ~/Downloads/all-codecombat-levels.png
