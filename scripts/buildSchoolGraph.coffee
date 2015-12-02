# Organize our users' schoolNames.

database = require '../server/commons/database'
mongoose = require 'mongoose'
log = require 'winston'
async = require 'async'

### SET UP ###
do (setupLodash = this) ->
  GLOBAL._ = require 'lodash'
  _.str = require 'underscore.string'
  _.mixin _.str.exports()
  GLOBAL.tv4 = require('tv4').tv4

database.connect()

UserHandler = require '../server/users/user_handler'
User = require '../server/users/User'

startDate = new Date 2015, 11, 1

query = dateCreated: {$gt: startDate}, emailLower: {$exists: true}
selection = 'name emailLower schoolName courseInstances clans ageRange dateCreated referrer points'
User.find(query).select(selection).lean().exec (err, users) ->
  usersWithSchools = _.filter users, 'schoolName'
  schoolNames = _.uniq (u.schoolName for u in usersWithSchools)
  log.info "Found #{usersWithSchools.length} users of #{users.length} users registered after #{startDate} with schools like:\n#{schoolNames.slice(0, 10).join('\n')}"

  # For each user, come up with a confidence that their school is correct.
  # For users with low confidence, look for similarities to other users with high confidence.
  # If we have enough data, prompt to update the school.
  # After each update, recalculate confidence to find the next user with low confidence.

  # How do we come up with confidence estimate?
  # If there are many students with the same school name, it's either correct or a rename must happen.
  # If the school name is unique but similar to a school name with many students, it's probably incorrect.
  #   But if we determine it is correct, how can we record this fact so it doesn't keep asking?

  # How can we infer the school name when we think it's not correct?
  # We look for users with confident schoolNames in shared courseInstances.
  # ... in shared clans.
  # ... with the same lastIP that doesn't cover the lastIP of students from multiple schools.
  # If we find a school-district-formatted email domain, we could try to match to other schoolNames in that domain, but I doubt that will be helpful until we have a lot of data and a lot of time to manually look things up.

  # TODO: do all this work when we actually have a bunch of schoolNames in the system, or these heuristics won't be well-calibrated.

  nextPrompt users

nextPrompt = (users) ->
  return console.log('Done.') or process.exit() unless [userToSchool, suggestions] = findUserToSchool users
  prompt "What should the school for #{JSON.stringify(userToSchool)} be?\nSuggestions: #{suggestions}\n", (answer) ->
    return console.log('Bye.') or process.exit() if answer in ['q', 'quit']
    console.log "You said #{answer}, so we should do something about that."
    nextPrompt users

findUserToSchool = (users) ->
  users.sort (a, b) -> b.points - a.points
  usersWithSchools = _.filter users, 'schoolName'
  schoolNames = _.uniq (u.schoolName for u in usersWithSchools)
  return [users[0], schoolNames]


# https://github.com/joshaven/string_score
stringScore = (_a, word, fuzziness) ->
  return 1 if word is _a
  return 0 if word is ""

  runningScore = 0
  string = _a
  lString = string.toLowerCase()
  strLength = string.length
  lWord = word.toLowerCase()
  wordLength = word.length
  startAt = 0
  fuzzies = 1

  if fuzziness
    fuzzyFactor = 1 - fuzziness

  if fuzziness
    for i in [0...wordLength]
      idxOf = lString.indexOf lWord[i], startAt
      if idxOf is -1
        fuzzies += fuzzyFactor
      else
        if startAt is idxOf
          charScore = 0.7
        else
          charScore = 0.1
          charScore += 0.8 if string[idxOf - 1] is ' '
        charScore += 0.1 if string[idxOf] is word[i]
        runningScore += charScore
        startAt = idxOf + 1
  else
    for i in [0...wordLength]
      idxOf = lString.indexOf lWord[i], startAt
    return 0 if idxOf is -1
    if startAt is idxOf
      charScore = 0.7
    else
      charScore = 0.1
      charScore += 0.8 if string[idxOf - 1] is word[i]
      runningScore += charScore
      startAt = idxOf + 1
  finalScore = 0.5 * (runningScore / strLength + runningScore / wordLength) / fuzzies
  finalScore += 0.15 if lWord[0] is lString[0] and finalScore < 0.85
  finalScore

prompt = (question, callback) ->
  process.stdin.resume()
  process.stdout.write question
  process.stdin.once 'data', (data) ->
    callback data.toString().trim()
