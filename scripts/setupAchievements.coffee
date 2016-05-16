database = require '../server/commons/database'
mongoose = require 'mongoose'
log = require 'winston'
async = require 'async'

### SET UP ###
do (setupLodash = this) ->
  GLOBAL._ = require 'lodash'
  _.str = require 'underscore.string'
  _.mixin _.str.exports()

database.connect()


## Util

## Types
contributor = (obj) ->
  _.extend obj, # This way we get the name etc on top
    collection: 'users'
    userField: '_id'
    category: 'contributor'

### UNLOCKABLES ###
# Generally ordered according to user.stats schema
unlockableAchievements =
  signup:
    name: 'Signed Up'
    description: 'Signed up to the most awesome coding game around.'
    query: 'anonymous': false
    worth: 10
    collection: 'users'
    userField: '_id'
    category: 'misc'
    difficulty: 1
    recalculable: true

  completedFirstLevel:
    name: 'Completed 1 Level'
    description: 'Completed your very first level.'
    query: 'stats.gamesCompleted': $gte: 1
    worth: 20
    collection: 'users'
    userField: '_id'
    category: 'level'
    difficulty: 1
    recalculable: true

  completedFiveLevels:
    name: 'Completed 5 Levels'
    description: 'Completed 5 Levels.'
    query: 'stats.gamesCompleted': $gte: 5
    worth: 50
    collection: 'users'
    userField: '_id'
    category: 'level'
    difficulty: 2
    recalculable: true

  completedTwentyLevels:
    name: 'Completed 20 Levels'
    description: 'Completed 20 Levels.'
    query: 'stats.gamesCompleted': $gte: 20
    worth: 500
    collection: 'users'
    userField: '_id'
    category: 'level'
    difficulty: 3
    recalculable: true

  editedOneArticle: contributor
    name: 'Edited an Article'
    description: 'Edited your first Article.'
    query: 'stats.articleEdits': $gte: 1
    worth: 50
    difficulty: 1

  editedOneLevel: contributor
    name: 'Edited a Level'
    description: 'Edited your first Level.'
    query: 'stats.levelEdits': $gte: 1
    worth: 50
    difficulty: 1
    recalculable: true

  editedOneLevelSystem: contributor
    name: 'Edited a Level System'
    description: 'Edited your first Level System.'
    query: 'stats.levelSystemEdits': $gte: 1
    worth: 50
    difficulty: 1
    recalculable: true

  editedOneLevelComponent: contributor
    name: 'Edited a Level Component'
    description: 'Edited your first Level Component.'
    query: 'stats.levelComponentEdits': $gte: 1
    worth: 50
    difficulty: 1
    recalculable: true

  editedOneThangType: contributor
    name: 'Edited a Thang Type'
    description: 'Edited your first Thang Type.'
    query: 'stats.thangTypeEdits': $gte: 1
    worth: 50
    difficulty: 1
    recalculable: true

  submittedOnePatch: contributor
    name: 'Submitted a Patch'
    description: 'Submitted your very first patch.'
    query: 'stats.patchesSubmitted': $gte: 1
    worth: 50
    difficulty: 1
    recalculable: true

  contributedOnePatch: contributor
    name: 'Contributed a Patch'
    description: 'Got your very first accepted Patch.'
    query: 'stats.patchesContributed': $gte: 1
    worth: 50
    difficulty: 1
    recalculable: true

  acceptedOnePatch: contributor
    name: 'Accepted a Patch'
    description: 'Accepted your very first patch.'
    query: 'stats.patchesAccepted': $gte: 1
    worth: 50
    difficulty: 1
    recalculable: false

  oneTranslationPatch: contributor
    name: 'First Translation'
    description: 'Did your very first translation.'
    query: 'stats.totalTranslationPatches': $gte: 1
    worth: 50
    difficulty: 1
    recalculable: true

  oneMiscPatch: contributor
    name: 'First Miscellaneous Patch'
    description: 'Did your first miscellaneous patch.'
    query: 'stats.totalMiscPatches': $gte: 1
    worth: 50
    difficulty: 1
    recalculable: true

  oneArticleTranslationPatch: contributor
    name: 'First Article Translation'
    description: 'Did your very first Article translation.'
    query: 'stats.articleTranslationPatches': $gte: 1
    worth: 50
    difficulty: 1
    recalculable: true

  oneArticleMiscPatch: contributor
    name: 'First Misc Article Patch'
    description: 'Did your first miscellaneous Article patch.'
    query: 'stats.totalMiscPatches': $gte: 1
    worth: 50
    difficulty: 1
    recalculable: true

  oneLevelTranslationPatch: contributor
    name: 'First Level Translation'
    description: 'Did your very first Level translation.'
    query: 'stats.levelTranslationPatches': $gte: 1
    worth: 50
    difficulty: 1
    recalculable: true

  oneLevelMiscPatch: contributor
    name: 'First Misc Level Patch'
    description: 'Did your first misc Level patch.'
    query: 'stats.levelMiscPatches': $gte: 1
    worth: 50
    difficulty: 1
    recalculable: true


### REPEATABLES ###
repeatableAchievements =
  simulatedBy:
    name: 'Simulated ladder game'
    description: 'Simulated a ladder game.'
    query: 'simulatedBy': $gte: 1
    worth: 1
    collection: 'users'
    userField: '_id'
    category: 'ladder'
    difficulty: 1
    proportionalTo: 'simulatedBy'
    function:
      kind: 'logarithmic'
      parameters: # TODO tweak
        a: 5
        b: 1
        c: 0

Achievement = require '../server/models/Achievement'
EarnedAchievement = require '../server/models/EarnedAchievement'

Achievement.find {}, (err, achievements) ->
  achievementIDs = (achievement.get('_id') + '' for achievement in achievements)
  EarnedAchievement.remove {achievement: $in: achievementIDs}, (err, count) ->
    return log.error err if err?
    log.info "Removed #{count} earned achievements that were related"

    Achievement.remove {}, (err) ->
      log.error err if err?
      log.info 'Removed all achievements.'

      log.info "Got #{Object.keys(unlockableAchievements).length} unlockable achievements"
      log.info "and #{Object.keys(repeatableAchievements).length} repeatable achievements"
      achievements = _.extend unlockableAchievements, repeatableAchievements

      async.each Object.keys(achievements), (key, callback) ->
        achievement = achievements[key]
        log.info "Setting up '#{achievement.name}'..."
        achievementM = new Achievement achievement
        # What the actual * Mongoose? It automatically converts 'stats.edits' to a nested object
        achievementM.set 'query', achievement.query
        log.debug JSON.stringify achievementM.get 'query'
        achievementM.save (err) ->
          log.error err if err?
          callback()
      , (err) ->
        log.error err if err?
        log.info 'Finished setting up achievements.'
        process.exit()
