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

#startDate = new Date 2015, 11, 1
startDate = new Date 2015, 11, 8  # Testing

query = dateCreated: {$gt: startDate}, emailLower: {$exists: true}
selection = 'name emailLower schoolName courseInstances clans ageRange dateCreated referrer points lastIP hourOfCode preferredLanguage lastLevel'
User.find(query).select(selection).lean().exec (err, users) ->
  usersWithSchools = _.filter users, 'schoolName'
  schoolNames = _.uniq (u.schoolName for u in usersWithSchools)
  log.info "Found #{usersWithSchools.length} users of #{users.length} users registered after #{startDate} with schools like:\n\t#{schoolNames.slice(0, 10).join('\n\t')}"

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

  nextPrompt users

nextPrompt = (users, question) ->
  sortUsers users
  return console.log('Done.') or process.exit() unless [userToSchool, suggestions] = findUserToSchool users
  question ?= formatSuggestions userToSchool, suggestions
  prompt question, (answer) ->
    return console.log('Bye.') or process.exit() if answer in ['q', 'quit']
    answer = answer.trim()
    if answer is ''
      users = _.without users, userToSchool
    else unless _.isNaN(num = parseInt(answer, 10))
      schoolName = if num then suggestions[num - 1]?.schoolName else userToSchool.schoolName
      return finalizePrompt userToSchool, suggestions, schoolName, users
    else if answer.length < 10
      console.log "#{answer}? That's kind of short--I don't think school names and locations can be this short. What should it really be?"
      return nextPrompt users, "> "
    else
      return finalizePrompt userToSchool, suggestions, answer, users
    nextPrompt users

finalizePrompt = (userToSchool, suggestions, schoolName, users) ->
  console.log "Selected schoolName: \"#{schoolName}\""
  question = "Also apply this to other users? Ex.: 'all', '0 1 2 5', 'all -3 -4 -5', '0' to just do this one, or blank to retype school name.\n> "
  prompt question, (answer) ->
    answer = answer.trim()
    if answer is ''
      console.log "Should just do", userToSchool._id, userToSchool.emailLower, userToSchool.schoolName
      targets = [userToSchool]
    else if answer is 'all'
      targets = [userToSchool].concat (s.user for s in suggestions)
      console.log "Doing all #{targets.length} users..."
    else if /^all/.test answer
      targets = [userToSchool].concat (s.user for s in suggestions)
      numbers = _.filter (parseInt(d, 10) for d in answer.split(/ *-/)), (n) -> not _.isNaN n
      for number in numbers
        skip = if number then suggestions[number - 1].user else userToSchool
        targets = _.without targets, skip
      console.log "Doing all #{targets.length} users without #{numbers}..."
    else
      numbers = _.filter (parseInt(d, 10) for d in answer.split(/ +/)), (n) -> not _.isNaN n
      targets = ((if number then suggestions[number - 1].user else userToSchool) for number in numbers)
      console.log "Doing #{targets.length} users for #{numbers}..."
    #User.update {_id: {$in: (_.map targets, '_id')}}, {schoolName: schoolName}, {multi: true}, (err, result) ->
    User.update {_id: {$in: []}}, {schoolName: schoolName}, {multi: true}, (err, result) ->
      if err
        console.error "Ran into error doing the save:", err
        return finalizePrompt userToSchool, suggestions, schoolName, users
      console.log "Updated users' schoolNames. Result:", result
      remainingUsers = _.without users, targets...
      nextPrompt remainingUsers

formatUser = (user) ->
  # TODO: replace date string with relative time since signup compared to target user
  _.values(_.pick(user, ['name', 'emailLower', 'ageRange', 'dateCreated', 'lastLevel', 'points', 'referrer', 'hourOfCode'])).join('  ')

formatSuggestions = (userToSchool, suggestions) ->
  suggestionPrompts = ("#{_.str.rpad(i + 1, 3)}  #{_.str.rpad(s.schoolName, 50)} #{s.reasons.join(' + ')}\tfrom user: #{formatUser(s.user)}" for s, i in suggestions).join('\n')
  """
  What should the school for this user be?
  0    #{_.str.rpad(userToSchool.schoolName, 50)} #{formatUser(userToSchool)}
  Suggestions:
  #{suggestionPrompts}
  Choose a number, type a name, enter to skip, or q to quit.
  > """

findUserToSchool = (users) ->
  # TODO: don't show users where everyone in the suggestion already has the same school (because we have already done this group)
  [bestTarget, bestTargetSuggestions, mostReasons] = [null, [], 0]
  for field, groups of topGroups
    largestGroup = groups[0]
    target = userCategories[field][largestGroup][0]
    suggestions = findSuggestions target
    reasons = _.reduce suggestions, ((sum, suggestion) -> sum + (if suggestion.schoolName then suggestion.reasons.length else 0)), 0
    if reasons > mostReasons
      bestTarget = target
      bestTargetSuggestions = suggestions
      mostReasons = reasons
  return [bestTarget, bestTargetSuggestions]

findSuggestions = (target) ->
  suggestions = []
  if target.lastIP
    for otherUser in userCategories.lastIP[target.lastIP] when otherUser isnt target
      suggestions.push schoolName: otherUser.schoolName, reasons: ["IP match"], user: otherUser
  for leagueType in ['courseInstances', 'clans']
    if target[leagueType]?.length
      for league in target[leagueType]
        for otherUser in userCategories[leagueType][league] when otherUser isnt target
          reason = "#{_.str.humanize(leagueType)} match"
          if existingSuggestion = _.find(suggestions, user: otherUser)
            existingSuggestion.reasons.push reason
          else
            suggestions.push schoolName: otherUser.schoolName, reasons: [reason], user: otherUser
  if target.schoolName?.length > 5
    nameMatches = []
    for otherSchoolName in topGroups.schoolName
      score = stringScore otherSchoolName, target.schoolName, 0.8
      continue if score < 0.25
      nameMatches.push schoolName: otherSchoolName, score: score
    nameMatches = (match.schoolName for match in (_.sortBy nameMatches, (match) -> -match.score))
    for match in nameMatches.slice(0, 10)
      reason = "Name match"
      for otherUser in userCategories.schoolName[match] when otherUser isnt target
        if existingSuggestion = _.find(suggestions, user: otherUser)
          existingSuggestion.reasons.push reason
        else
          suggestions.push schoolName: match, reasons: [reason], user: otherUser
  return _.uniq suggestions, 'user'

userCategories = {}
topGroups = {}
usersCategorized = {}

sortUsers = (users) ->
  users = _.sortBy users, (u) -> -u.points
  users = _.sortBy users, ['schoolName', 'lastIP']
  # TODO: also match users by shared school email domains when we can identify those
  for field in ['courseInstances', 'lastIP', 'schoolName', 'clans']
    userCategories[field] = categorizeUsers users, field
    topGroups[field] = _.sortBy _.keys(userCategories[field]), (key) -> -userCategories[field][key].length
    topGroups[field] = (group for group in topGroups[field] when 2 < userCategories[field][group].length < (if field is 'clans' then 30 else 5000))

categorizeUsers = (users, field) ->
  categories = {}
  for user in users when value = user[field]
    values = if _.isArray(value) then value else [value]
    for value in values when value
      continue if value.trim and not value.trim()
      categories[value] ?= []
      categories[value].push user
  categories


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
