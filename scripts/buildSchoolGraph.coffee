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
  log.info "Found #{usersWithSchools.length} users of #{users.length} users registered after #{startDate}."
  nextPrompt users

nextPrompt = (users, question) ->
  # We look for the next top user to classify based on the number of suggestions we can make about what the school name should be.
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
  question = "Also apply this to other users? Ex.: 'all', '0 1 2 5 9-14', 'all but 38 59-65', '0' to just do this one, or blank to retype school name.\n> "
  prompt question, (answer) ->
    answer = answer.trim()
    if answer is ''
      console.log "Should just do", userToSchool._id, userToSchool.emailLower, userToSchool.schoolName
      targets = [userToSchool]
    else if answer is 'all'
      targets = [userToSchool].concat (s.user for s in suggestions)
      console.log "Doing all #{targets.length} users..."
    else if /^all/.test answer
      numbers = findNumbers answer, suggestions.length
      targets = [userToSchool].concat (s.user for s in suggestions)
      for number in numbers
        skip = if number then suggestions[number - 1].user else userToSchool
        targets = _.without targets, skip
      console.log "Doing all #{targets.length} users without #{numbers}..."
    else
      numbers = findNumbers answer, suggestions.length
      targets = _.filter ((if number then suggestions[number - 1].user else userToSchool) for number in numbers)
      console.log "Doing #{targets.length} users for #{numbers}..."
    #User.update {_id: {$in: (_.map targets, '_id')}}, {schoolName: schoolName}, {multi: true}, (err, result) ->
    User.update {_id: {$in: []}}, {schoolName: schoolName}, {multi: true}, (err, result) ->
      if err
        console.error "Ran into error doing the save:", err
        return finalizePrompt userToSchool, suggestions, schoolName, users
      console.log "Updated users' schoolNames. Result:", result
      # Take these users out of the pool to make suggestions about before going on to next suggestions.
      remainingUsers = _.without users, targets...
      nextPrompt remainingUsers

findNumbers = (answer, max) ->
  numbers = (parseInt(d, 10) for d in (' ' + answer + ' ').match(/ (\d+) /g) ? [])
  ranges = answer.match(/(\d+-\d+)/g) or []
  for range in ranges
    bounds = (parseInt(d, 10) for d in range.split('-'))
    for number in [bounds[0] .. bounds[1]]
      numbers.push number
  for number in numbers
    if number > max
      console.log "Incorrect number #{number} higher than max: #{max}"
  numbers

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
  # We find the top user from the top group that we can make the most reasoned suggestions about what the school name would be.
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
  # Look for other users with the same IP, course instances, clans, or similar school names or non-common shared email domains.
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
  if domain = getDomain target
    for otherUser in userCategories.domain[domain] when otherUser isnt target
      reason = "Domain match"
      if existingSuggestion = _.find(suggestions, user: otherUser)
        existingSuggestion.reasons.push reason
      else
        suggestions.push schoolName: otherUser.schoolName, reasons: [reason], user: otherUser
  return _.uniq suggestions, 'user'

userCategories = {}
topGroups = {}
usersCategorized = {}

sortUsers = (users) ->
  users = _.sortBy users, (u) -> -u.points
  users = _.sortBy users, ['schoolName', 'lastIP']
  for field in ['courseInstances', 'lastIP', 'schoolName', 'domain', 'clans']
    userCategories[field] = categorizeUsers users, field
    topGroups[field] = _.sortBy _.keys(userCategories[field]), (key) -> -userCategories[field][key].length
    topGroups[field] = (group for group in topGroups[field] when 2 < userCategories[field][group].length < (if field is 'clans' then 30 else 5000))

categorizeUsers = (users, field) ->
  categories = {}
  for user in users
    if field is 'domain'
      value = getDomain user
    else
      value = user[field]
    continue unless value
    values = if _.isArray(value) then value else [value]
    for value in values when value
      continue if value.trim and not value = value.trim()
      categories[value] ?= []
      categories[value].push user
  categories

getDomain = (user) ->
  domain = user.emailLower.split('@')[1]
  return null if commonEmailDomainMap[domain]
  typo = _.find commonEmailDomains, (commonDomain) -> stringScore(commonDomain, domain, 0.8) > 0.9
  return null if typo
  domain

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

# https://github.com/mailcheck/mailcheck/wiki/List-of-Popular-Domains
commonEmailDomains = [
  # Default domains included
  "aol.com", "att.net", "comcast.net", "facebook.com", "gmail.com", "gmx.com", "googlemail.com",
  "google.com", "hotmail.com", "hotmail.co.uk", "mac.com", "me.com", "mail.com", "msn.com",
  "live.com", "sbcglobal.net", "verizon.net", "yahoo.com", "yahoo.co.uk",

  # Other global domains
  "email.com", "games.com", "gmx.net", "hush.com", "hushmail.com", "icloud.com", "inbox.com",
  "lavabit.com", "love.com", "outlook.com", "pobox.com", "rocketmail.com",
  "safe-mail.net", "wow.com", "ygm.com", "ymail.com", "zoho.com", "fastmail.fm",

  # United States ISP domains
  "bellsouth.net", "charter.net", "comcast.net", "cox.net", "earthlink.net", "juno.com",

  # British ISP domains
  "btinternet.com", "virginmedia.com", "blueyonder.co.uk", "freeserve.co.uk", "live.co.uk",
  "ntlworld.com", "o2.co.uk", "orange.net", "sky.com", "talktalk.co.uk", "tiscali.co.uk",
  "virgin.net", "wanadoo.co.uk", "bt.com",

  # Domains used in Asia
  "sina.com", "qq.com", "naver.com", "hanmail.net", "daum.net", "nate.com", "yahoo.co.jp", "yahoo.co.kr", "yahoo.co.id", "yahoo.co.in", "yahoo.com.sg", "yahoo.com.ph",

  # French ISP domains
  "hotmail.fr", "live.fr", "laposte.net", "yahoo.fr", "wanadoo.fr", "orange.fr", "gmx.fr", "sfr.fr", "neuf.fr", "free.fr",

  # German ISP domains
  "gmx.de", "hotmail.de", "live.de", "online.de", "t-online.de", "web.de", "yahoo.de",

  # Russian ISP domains
  "mail.ru", "rambler.ru", "yandex.ru", "ya.ru", "list.ru",

  # Belgian ISP domains
  "hotmail.be", "live.be", "skynet.be", "voo.be", "tvcablenet.be", "telenet.be",

  # Argentinian ISP domains
  "hotmail.com.ar", "live.com.ar", "yahoo.com.ar", "fibertel.com.ar", "speedy.com.ar", "arnet.com.ar",

  # Domains used in Mexico
  "hotmail.com", "gmail.com", "yahoo.com.mx", "live.com.mx", "yahoo.com", "hotmail.es", "live.com", "hotmail.com.mx", "prodigy.net.mx", "msn.com"
]
commonEmailDomainMap = {}
commonEmailDomainMap[domain] = true for domain in commonEmailDomainMap
