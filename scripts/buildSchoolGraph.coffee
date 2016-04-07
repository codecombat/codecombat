# Organize our users' schoolNames.

database = require '../server/commons/database'
mongoose = require 'mongoose'
log = require 'winston'
async = require 'async'
moment = require 'moment'
fs = require 'fs'
exec = require('child_process').exec

### SET UP ###
do (setupLodash = this) ->
  GLOBAL._ = require 'lodash'
  _.str = require 'underscore.string'
  _.mixin _.str.exports()
  GLOBAL.tv4 = require('tv4').tv4

database.connect()

UserHandler = require '../server/handlers/user_handler'
User = require '../server/models/User'

startDate = new Date 2015, 11, 1

debugging = false

query = dateCreated: {$gt: startDate}, emailLower: {$exists: true}
selection = 'name emailLower schoolName courseInstances clans ageRange dateCreated referrer points lastIP hourOfCode preferredLanguage lastLevel'
User.find(query).select(selection).lean().exec (err, users) ->
  usersWithSchools = _.filter users, 'schoolName'
  log.info "Found #{usersWithSchools.length} users of #{users.length} users registered after #{startDate}."
  nextPrompt users

nextPrompt = (users, question, userToSchool, suggestions) ->
  # We look for the next top user to classify based on the number of suggestions we can make about what the school name should be.
  sortUsers users
  unless userToSchool
    return console.log('Done.') or process.exit() unless [userToSchool, suggestions] = findUserToSchool users
  question ?= formatSuggestions userToSchool, suggestions
  openTSV userToSchool, suggestions
  prompt question, (answer) ->
    answer = answer.trim()
    return console.log('Bye.') or process.exit() if answer in ['q', 'quit']
    if answer is ''
      return nextPrompt _.without users, userToSchool
    else unless _.isNaN(num = parseInt(answer, 10))
      schoolName = if num then suggestions[num - 1]?.schoolName else userToSchool.schoolName
      return finalizePrompt userToSchool, suggestions, schoolName, users
    else if answer.length < 10
      console.log "#{answer}? That's kind of short--I don't think school names and locations can be this short. What should it really be?"
      return nextPrompt users, "> ", userToSchool, suggestions
    else unless /,.+,/.test answer
      console.log "#{answer}? We need the full location (with two commas), like Example High School, Springfield, IL. What should it really be?"
      return nextPrompt users, "> ", userToSchool, suggestions
    else
      return finalizePrompt userToSchool, suggestions, answer, users

finalizePrompt = (userToSchool, suggestions, schoolName, users) ->
  console.log "Selected schoolName: \"#{schoolName}\""
  question = "Also apply this to other users? Ex.: 'all', '0 1 2 5 9-14', 'all but 38 59-65', '0' to just do this one, q to quit, or blank to retype school name.\n> "
  prompt question, (answer) ->
    answer = answer.trim()
    return console.log('Bye.') or process.exit() if answer in ['q', 'quit']
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
    User.update {_id: {$in: (_.map targets, '_id')}}, {schoolName: schoolName}, {multi: true}, (err, result) ->
    #User.update {_id: {$in: []}}, {schoolName: schoolName}, {multi: true}, (err, result) ->
      if err
        console.error "Ran into error doing the save:", err
        return finalizePrompt userToSchool, suggestions, schoolName, users
      console.log "Updated users' schoolNames. Result:", result
      # Take these users out of the pool to make suggestions about before going on to next suggestions.
      remainingUsers = _.without users, targets...
      nextPrompt remainingUsers

findNumbers = (answer, max) ->
  answer = answer.replace /,/g, ' '
  numbers = (parseInt(d, 10) for d in (' ' + answer + ' ').replace(/ /g, '  ').match(/ (\d+) /g) ? [])
  ranges = answer.match(/(\d+-\d+)/g) or []
  for range in ranges
    bounds = (parseInt(d, 10) for d in range.split('-'))
    for number in [bounds[0] .. bounds[1]]
      numbers.push number
  for number in numbers
    if number > max
      console.log "Incorrect number #{number} higher than max: #{max}"
  numbers

formatUser = (user, relativeToUser, separator='  ') ->
  values = []
  for key in ['name', 'emailLower', 'ageRange', 'dateCreated', 'lastLevel', 'points', 'referrer', 'hourOfCode']
    val = user[key]
    if key is 'dateCreated'
      val = if relativeToUser then moment(val).from(relativeToUser.dateCreated) else moment(val).fromNow()
    values.push val
  values.join separator

formatSuggestions = (userToSchool, suggestions) ->
  suggestionPrompts = ("#{_.str.rpad(i + 1, 3)}  #{_.str.rpad(s.schoolName, 50)} #{s.reasons.length} #{if s.reasons.length > 1 then 'Matches' else 'Match'}: #{s.reasons.join(', ')}\tfrom user: #{formatUser(s.user, userToSchool)}" for s, i in suggestions).join('\n')
  """
  What should the school for this user be?
  0    #{_.str.rpad(userToSchool.schoolName, 50)} #{formatUser(userToSchool)}
  Suggestions:
  #{suggestionPrompts}
  Choose a number, type a name, enter to skip, or q to quit.
  > """

openTSV = (userToSchool, suggestions) ->
  header = ['#', 'School Name', 'Matches', 'Name', 'Email', 'Age', 'Signup', 'Last Level', 'Points', 'Referrer', 'HoC'].join '\t'
  rows = [[0, userToSchool.schoolName, '', formatUser(userToSchool, null, '\t')].join '\t']
  for s, i in suggestions
    matches = s.reasons.length + ' ' + if s.reasons.length > 1 then 'Matches' else 'Match' + ': ' + s.reasons.join(', ')
    rows.push [i + 1, s.schoolName, matches, formatUser(s.user, userToSchool, '\t')].join '\t'
  contents = [header].concat(rows).join('\n') + '\n'
  path = "#{process.env.HOME}/Downloads/#{userToSchool.emailLower}.tsv"
  fs.writeFile path, contents, {flags: 'w'}, (err) ->
    console.log 'Error writing school suggestions TSV:', err if err
    exec "open -a /Applications/Numbers.app #{path}"

checkedTopGroups = {}
findUserToSchool = (users) ->
  # We find the top user from the top group that we can make the most reasoned suggestions about what the school name would be.
  [bestTarget, bestTargetSuggestions, bestSuggestionsScore, bestGroup] = [null, [], 0, null]
  for field, groups of topGroups
    for nextLargestGroup in groups when not checkedTopGroups[nextLargestGroup]
      possibleTargets = userCategories[field][nextLargestGroup]
      schoolNames = (t.schoolName for t in _.uniq possibleTargets, 'schoolName')
      # TODO: better method to avoid showing users where everyone in the suggestion already has the same school (because we have already done this group)
      alreadyDone = false
      for schoolName in schoolNames when schoolName?.length > 10 and /,.+,/.test schoolName  # Long enough school name with location info (two commas)
        sharedCount = _.filter(possibleTargets, schoolName: schoolName).length
        if sharedCount > 20 and sharedCount > 0.25 * possibleTargets.length
          console.log 'Already done', schoolName, sharedCount, possibleTargets.length, 'for', field, nextLargestGroup
          alreadyDone = true
      continue if alreadyDone
      nSamples = Math.min 15, Math.max(4, Math.floor possibleTargets.length / 20)
      if debugging then console.log 'Checking', nSamples, 'samples of', possibleTargets.length, 'players in the biggest', field, 'group:', nextLargestGroup
      for i in [0 ... nSamples]
        target = possibleTargets[Math.floor i * possibleTargets.length / (nSamples + 1)]
        suggestions = findSuggestions target
        suggestionsScore = scoreSuggestions suggestions, target
        if suggestionsScore > bestSuggestionsScore
          bestTarget = target
          bestTargetSuggestions = suggestions
          bestSuggestionsScore = suggestionsScore
          bestGroup = nextLargestGroup
      break
  checkedTopGroups[bestGroup] = true
  return [bestTarget, bestTargetSuggestions]

findSuggestions = (target) ->
  # Look for other users with the same IP, course instances, clans, or similar school names or non-common shared email domains.
  # TODO: Actually make suggestions based on students that signed up at almost the same time
  suggestions = []
  t0 = new Date()
  if debugging then console.log '  Checking suggestions for', target.emailLower, target.schoolName, (new Date()) - t0
  if target.lastIP
    for otherUser in (userCategories.lastIP[target.lastIP] ? []) when otherUser isnt target
      suggestions.push schoolName: otherUser.schoolName, reasons: ['IP'], user: otherUser
  for leagueType in ['courseInstances', 'clans']
    if debugging then console.log '    Now checking', leagueType, (new Date()) - t0
    if target[leagueType]?.length
      for league in target[leagueType]
        for otherUser in (userCategories[leagueType][league] ? []) when otherUser isnt target
          reason = _.str.humanize(leagueType)
          if existingSuggestion = _.find(suggestions, user: otherUser)
            existingSuggestion.reasons.push reason
          else
            suggestions.push schoolName: otherUser.schoolName, reasons: [reason], user: otherUser
  if target.schoolName?.length > 5
    if debugging then console.log '    Now checking schoolName', (new Date()) - t0
    nameMatches = []
    for otherSchoolName in topGroups.schoolName
      score = stringScore otherSchoolName, target.schoolName, 0.8
      continue if score < 0.25
      nameMatches.push schoolName: otherSchoolName, score: score
    nameMatches = (match.schoolName for match in (_.sortBy nameMatches, (match) -> -match.score))
    for match in nameMatches.slice(0, 10)
      reason = "Name"
      for otherUser in (userCategories.schoolName[match] ? []) when otherUser isnt target
        if existingSuggestion = _.find(suggestions, user: otherUser)
          existingSuggestion.reasons.push reason
        else
          suggestions.push schoolName: match, reasons: [reason], user: otherUser
  if debugging then console.log '    Now checking domain', (new Date()) - t0
  if domain = getDomain target
    for otherUser in (userCategories.domain[domain] ? []) when otherUser isnt target
      reason = "Domain"
      if existingSuggestion = _.find(suggestions, user: otherUser)
        existingSuggestion.reasons.push reason
      else
        suggestions.push schoolName: otherUser.schoolName, reasons: [reason], user: otherUser
  if debugging then console.log '    Now checking referrer', (new Date()) - t0
  if referrer = getReferrer target
    for otherUser in (userCategories.referrer[referrer] ? []) when otherUser isnt target
      reason = "Referrer"
      if existingSuggestion = _.find(suggestions, user: otherUser)
        existingSuggestion.reasons.push reason
      else
        suggestions.push schoolName: otherUser.schoolName, reasons: [reason], user: otherUser
  if debugging then console.log '    Done checking referrer', (new Date()) - t0
  suggestions = _.sortBy suggestions, (s) -> (s.schoolName or '').toLowerCase()
  suggestions = _.sortBy suggestions, (s) -> -scoreSuggestions [s], target
  return suggestions

scoreSuggestions = (suggestions, target) ->
  _.reduce suggestions, ((sum, suggestion) ->
    for suggestion in suggestions
      for reason in suggestion.reasons
        sum += switch reason
          when 'Course instances' then 150
          when 'IP' then 40
          when 'Referrer' then 20
          when 'Name' then 15
          when 'Domain' then (if getDomain(target) in ['cps.edu', 'mynewcaneyisd.org', 'fsusd.org', 'edison.k12.nj.us'] then 1 else 10)
          when 'Clans' then 0.01
    sum
  ), 0

userCategories = {}
topGroups = {}
usersCategorized = {}

sortUsers = (users) ->
  users = _.sortBy users, (u) -> -u.points
  users = _.sortBy users, 'lastIP'
  users = _.sortBy users, (u) -> (u.schoolName or '').toLowerCase()
  for field in ['courseInstances', 'lastIP', 'schoolName', 'domain', 'clans', 'referrer']
    userCategories[field] = categorizeUsers users, field
    topGroups[field] = _.sortBy _.keys(userCategories[field]), (key) -> -userCategories[field][key].length
    topGroups[field] = (group for group in topGroups[field] when 2 < userCategories[field][group].length < (if field is 'clans' then 30 else 5000))

categorizeUsers = (users, field) ->
  categories = {}
  for user in users
    if field is 'domain'
      value = getDomain user
    else if field is 'referrer'
      value = getReferrer user
    else
      value = user[field]
    continue unless value
    values = if _.isArray(value) then value else [value]
    for value in values when value
      continue if value.trim and not value = value.trim()
      categories[value] ?= []
      categories[value].push user
  categories

typoCache = {}
getDomain = (user) ->
  return null unless domain = user.emailLower.split('@')[1]
  return null if commonEmailDomainMap[domain]
  # Too slow? Is this actually slow?
  #typo = typoCache[domain]
  #return null if typo
  #return domain if typo is false
  #typo = _.find commonEmailDomains, (commonDomain) -> stringScore(commonDomain, domain, 0.8) > 0.9
  #typoCache[domain] = Boolean(typo)
  #return null if typo
  domain

commonReferrersRegex = /(google|bing\.|yahoo|duckduckgo|jobs\.lever|code\.org|twitter|facebook|dollarclick|stumbleupon|vk\.com|playpcesor|reddit|lifehacker|favorite|bnext|freelance|taringa|blogthinkbig|graphism|inside\.com|korben|habrahabr|iplaysoft|geekbrains|playground|ycombinator|github)/
getReferrer = (user) ->
  return null unless referrer = user.referrer?.toLowerCase().trim()
  referrer = referrer.replace /^https?:\/\//, ''
  return null if commonReferrersRegex.test referrer
  return classCode if classCode = referrer.match(/\?_cc=(\S+)$/)?[1]
  return null if /codecombat/.test referrer
  referrer

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
  "sina.com", "qq.com", "naver.com", "hanmail.net", "daum.net", "nate.com", "yahoo.co.jp", "yahoo.co.kr", "yahoo.co.id", "yahoo.co.in", "yahoo.com.sg", "yahoo.com.ph", "yahoo.com.tw"

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
commonEmailDomainMap[domain] = true for domain in commonEmailDomains
