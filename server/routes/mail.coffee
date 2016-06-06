mail = require '../commons/mail'
MailSent = require '../models/MailSent'
UserRemark = require '../models/UserRemark'
User = require '../models/User'
async = require 'async'
errors = require '../commons/errors'
config = require '../../server_config'
LevelSession = require '../models/LevelSession'
Level = require '../models/Level'
log = require 'winston'
sendwithus = require '../sendwithus'
if config.isProduction and config.redis.host isnt 'localhost'
  lockManager = require '../commons/LockManager'

module.exports.setup = (app) ->
  app.all config.mail.mailchimpWebhook, handleMailchimpWebHook
  app.get '/mail/cron/ladder-update', handleLadderUpdate
  app.get '/mail/cron/next-steps', handleNextSteps
  if lockManager
    setupScheduledEmails()

setupScheduledEmails = ->
  testForLockManager()
  mailTasks = [
    #  taskFunction: candidateUpdateProfileTask
    #  frequencyMs: 10 * 60 * 1000 #10 minutes
    #,
    #  taskFunction: internalCandidateUpdateTask
    #  frequencyMs: 10 * 60 * 1000 #10 minutes
    #,
    #  taskFunction: employerNewCandidatesAvailableTask
    #  frequencyMs: 10 * 60 * 1000 #10 minutes
    #,
    #  taskFunction: unapprovedCandidateFinishProfileTask
    #  frequencyMs: 10 * 60 * 1000
    #,
    #  taskFunction: emailUserRemarkTaskRemindersTask
    #  frequencyMs: 10 * 60 * 1000
  ]

  for mailTask in mailTasks
    setInterval mailTask.taskFunction, mailTask.frequencyMs

testForLockManager = -> unless lockManager then throw "The system isn't configured to do distributed locking!"

### Approved Candidate Update Reminder Task ###
candidateUpdateProfileTask = ->
  mailTaskName = "candidateUpdateProfileTask"
  lockDurationMs = 2 * 60 * 1000
  currentDate = new Date()
  timeRanges = []
  for weekPair in [[4, 2,'two weeks'], [8, 4, 'four weeks'], [52, 8, 'eight weeks']]
    timeRanges.push
      start: generateWeekOffset currentDate, weekPair[0]
      end: generateWeekOffset currentDate, weekPair[1]
      name: weekPair[2]
  lockManager.setLock mailTaskName, lockDurationMs, (err) ->
    if err? then return log.error "Error getting a distributed lock for task #{mailTaskName}: #{err}"
    async.each timeRanges, emailTimeRange.bind({mailTaskName: mailTaskName}), (err) ->
      if err
        log.error "There was an error sending the candidate profile update reminder emails: #{err}"
      lockManager.releaseLock mailTaskName, (err) ->
        if err? then return log.error "There was an error releasing the distributed lock for task #{mailTaskName}: #{err}"

generateWeekOffset = (originalDate, numberOfWeeks) ->
  return (new Date(originalDate.getTime() - numberOfWeeks * 7 * 24 * 60 * 60 * 1000)).toISOString()

emailTimeRange = (timeRange, emailTimeRangeCallback) ->
  waterfallContext =
    "timeRange": timeRange
    "mailTaskName": @mailTaskName
  async.waterfall [
    findAllCandidatesWithinTimeRange.bind(waterfallContext)
    (unfilteredCandidates, cb) ->
      async.reject unfilteredCandidates, candidateFilter.bind(waterfallContext), cb.bind(null, null)
    (filteredCandidates, cb) ->
      async.each filteredCandidates, sendReminderEmailToCandidate.bind(waterfallContext), cb
  ], emailTimeRangeCallback

findAllCandidatesWithinTimeRange = (cb) ->
  findParameters =
    "jobProfile.updated":
      $gt: @timeRange.start
      $lte: @timeRange.end
    "jobProfileApproved": true
  selection =  "_id email jobProfile.name jobProfile.updated emails" #make sure to check for anyNotes too.
  User.find(findParameters).select(selection).lean().exec cb

candidateFilter = (candidate, sentEmailFilterCallback) ->
  if candidate.emails?.anyNotes?.enabled is false or candidate.emails?.recruitNotes?.enabled is false
    return sentEmailFilterCallback true
  findParameters =
    "user": candidate._id
    "mailTask": @mailTaskName
    "metadata.timeRangeName": @timeRange.name
    "metadata.updated": candidate.jobProfile.updated
  MailSent.find(findParameters).lean().exec (err, sentMail) ->
    if err?
      log.error "Error finding mail sent for task #{@mailTaskName} and user #{candidate._id}!"
      sentEmailFilterCallback true
    else
      sentEmailFilterCallback Boolean(sentMail.length)

findEmployersSignedUpAfterDate = (dateObject, cb) ->
  countParameters =
    $or: [{"dateCreated": {$gte: dateObject}},{"signedEmployerAgreement":{$gte: dateObject}}]
    employerAt: {$exists: true}
    permissions: "employer"
  User.count countParameters, cb

sendReminderEmailToCandidate = (candidate, sendEmailCallback) ->
  findEmployersSignedUpAfterDate new Date(candidate.jobProfile.updated), (err, employersAfterCount) =>
    if err?
      log.error "There was an error finding employers who signed up after #{candidate.jobProfile.updated}: #{err}"
      return sendEmailCallback err
    if employersAfterCount < 2
      employersAfterCount = 2
    context =
      email_id: "tem_CtTLsKQufxrxoPMn7upKiL"
      recipient:
        address: candidate.email
        name: candidate.jobProfile.name
      email_data:
        new_company: employersAfterCount
        company_name: "CodeCombat"
        user_profile: "http://codecombat.com/account/profile/#{candidate._id}"
        recipient_address: encodeURIComponent(candidate.email)
    #log.info "Sending #{@timeRange.name} update reminder to #{context.recipient.name}(#{context.recipient.address})"
    newSentMail =
      mailTask: @mailTaskName
      user: candidate._id
      metadata:
        timeRangeName: @timeRange.name
        updated: candidate.jobProfile.updated
    MailSent.create newSentMail, (err) ->
      if err? then return sendEmailCallback err
      sendwithus.api.send context, (err, result) ->
        log.error "Error sending candidate update reminder email: #{err} with result #{result}" if err
        sendEmailCallback null
### End Approved Candidate Update Reminder Task ###

### Unapproved Candidate Finish Reminder Task ###
unapprovedCandidateFinishProfileTask = ->
  mailTaskName = "unapprovedCandidateFinishProfileTask"
  lockDurationMs = 2 * 60 * 1000
  currentDate = new Date()
  timeRanges = []
  for weekPair in [[4, 2,'two weeks'], [8, 4, 'four weeks'], [52, 8, 'eight weeks']]
    timeRanges.push
      start: generateWeekOffset currentDate, weekPair[0]
      end: generateWeekOffset currentDate, weekPair[1]
      name: weekPair[2]
  lockManager.setLock mailTaskName, lockDurationMs, (err) ->
    if err? then return log.error "Error getting a distributed lock for task #{mailTaskName}: #{err}"
    async.each timeRanges, emailUnapprovedCandidateTimeRange.bind({mailTaskName: mailTaskName}), (err) ->
      if err
        log.error "There was an error sending the candidate profile update reminder emails: #{err}"
      lockManager.releaseLock mailTaskName, (err) ->
        if err? then return log.error "There was an error releasing the distributed lock for task #{mailTaskName}: #{err}"

emailUnapprovedCandidateTimeRange = (timeRange, emailTimeRangeCallback) ->
  waterfallContext =
    "timeRange": timeRange
    "mailTaskName": @mailTaskName
  async.waterfall [
    findAllUnapprovedCandidatesWithinTimeRange.bind(waterfallContext)
    (unfilteredCandidates, cb) ->
      async.reject unfilteredCandidates, ignoredCandidateFilter, cb.bind(null,null)
    (unfilteredPotentialCandidates, cb) ->
      async.reject unfilteredPotentialCandidates, unapprovedCandidateFilter.bind(waterfallContext), cb.bind(null, null)
    (filteredCandidates, cb) ->
      async.each filteredCandidates, sendReminderEmailToUnapprovedCandidate.bind(waterfallContext), cb
  ], emailTimeRangeCallback

findAllUnapprovedCandidatesWithinTimeRange = (cb) ->
  findParameters =
    "jobProfile":
      $exists: true
    "jobProfile.updated":
      $gt: @timeRange.start
      $lte: @timeRange.end
    "jobProfileApproved": false
  selection =  "_id email jobProfile.name jobProfile.updated emails"
  User.find(findParameters).select(selection).lean().exec cb

ignoredCandidateFilter = (candidate, cb) ->
  findParameters =
    "user": candidate._id
    "contactName": "Ignore"
  UserRemark.count findParameters, (err, results) ->
    if err? then return true
    return cb Boolean(results.length)

unapprovedCandidateFilter = (candidate, sentEmailFilterCallback) ->
  if candidate.emails?.anyNotes?.enabled is false or candidate.emails?.recruitNotes?.enabled is false
    return sentEmailFilterCallback true
  findParameters =
    "user": candidate._id
    "mailTask": @mailTaskName
    "metadata.timeRangeName": @timeRange.name
    "metadata.updated": candidate.jobProfile.updated
  MailSent.find(findParameters).lean().exec (err, sentMail) ->
    if err?
      log.error "Error finding mail sent for task #{@mailTaskName} and user #{candidate._id}!"
      sentEmailFilterCallback true
    else
      sentEmailFilterCallback Boolean(sentMail.length)

sendReminderEmailToUnapprovedCandidate = (candidate, sendEmailCallback) ->
  if err?
    log.error "There was an error finding employers who signed up after #{candidate.jobProfile.updated}: #{err}"
    return sendEmailCallback err
  context =
    email_id: "tem_RXyjzmc7S2HJH287pfoSPN"
    recipient:
      address: candidate.email
      name: candidate.jobProfile.name
    email_data:
      user_profile: "http://codecombat.com/account/profile/#{candidate._id}"
      recipient_address: encodeURIComponent(candidate.email)
  #log.info "Sending #{@timeRange.name} finish profile reminder to #{context.recipient.name}(#{context.recipient.address})"
  newSentMail =
    mailTask: @mailTaskName
    user: candidate._id
    metadata:
      timeRangeName: @timeRange.name
      updated: candidate.jobProfile.updated
  MailSent.create newSentMail, (err) ->
    if err? then return sendEmailCallback err
    sendwithus.api.send context, (err, result) ->
      log.error "Error sending candidate finish profile reminder email: #{err} with result #{result}" if err
      sendEmailCallback null
### End Unapproved Candidate Finish Reminder Task ###

### Internal Candidate Update Reminder Email ###
internalCandidateUpdateTask = ->
  mailTaskName = "internalCandidateUpdateTask"
  lockDurationMs = 2 * 60 * 1000
  lockManager.setLock mailTaskName, lockDurationMs, (err) ->
    if err? then return log.error "Error getting a distributed lock for task #{mailTaskName}: #{err}"
    emailInternalCandidateUpdateReminder.call {"mailTaskName":mailTaskName}, (err) ->
      if err
        log.error "There was an error sending the internal candidate update reminder.: #{err}"
      lockManager.releaseLock mailTaskName, (err) ->
        if err? then return log.error "There was an error releasing the distributed lock for task #{mailTaskName}: #{err}"

emailInternalCandidateUpdateReminder = (internalCandidateUpdateReminderCallback) ->
  currentTime = new Date()
  beginningOfUTCDay = new Date()
  beginningOfUTCDay.setUTCHours(0,0,0,0)
  asyncContext =
    "beginningOfUTCDay": beginningOfUTCDay
    "currentTime": currentTime
    "mailTaskName": @mailTaskName
  async.waterfall [
    findNonApprovedCandidatesWhoUpdatedJobProfileToday.bind(asyncContext)
    (unfilteredCandidates, cb) ->
      async.reject unfilteredCandidates, candidatesUpdatedTodayFilter.bind(asyncContext), cb.bind(null,null)
    (filteredCandidates, cb) ->
      async.each filteredCandidates, sendInternalCandidateUpdateReminder.bind(asyncContext), cb
  ], internalCandidateUpdateReminderCallback

findNonApprovedCandidatesWhoUpdatedJobProfileToday = (cb) ->
  findParameters =
    "jobProfile.updated":
      $lte: @currentTime.toISOString()
      $gt: @beginningOfUTCDay.toISOString()
    "jobProfileApproved": false
  User.find(findParameters).select("_id jobProfile.name jobProfile.updated").lean().exec cb

candidatesUpdatedTodayFilter = (candidate, cb) ->
  findParameters =
    "user": candidate._id
    "mailTask": @mailTaskName
    "metadata.beginningOfUTCDay": @beginningOfUTCDay
  MailSent.find(findParameters).lean().exec (err, sentMail) ->
    if err?
      log.error "Error finding mail sent for task #{@mailTaskName} and user #{candidate._id}!"
      cb true
    else
      cb Boolean(sentMail.length)

sendInternalCandidateUpdateReminder = (candidate, cb) ->
  context =
    email_id: "tem_Ac7nhgKqatTHBCgDgjF5pE"
    recipient:
      address: "team@codecombat.com"
      name: "The CodeCombat Team"
    email_data:
      new_candidate_profile: "http://codecombat.com/account/profile/#{candidate._id}"
  #log.info "Sending candidate updated reminder for #{candidate.jobProfile.name}"
  newSentMail =
    mailTask: @mailTaskName
    user: candidate._id
    metadata:
      beginningOfUTCDay: @beginningOfUTCDay

  MailSent.create newSentMail, (err) ->
    if err? then return cb err
    sendwithus.api.send context, (err, result) ->
      log.error "Error sending interal candidate update email: #{err} with result #{result}" if err
      cb null

### End Internal Candidate Update Reminder Email ###
### Employer New Candidates Available Email ###
employerNewCandidatesAvailableTask = ->
  mailTaskName = "employerNewCandidatesAvailableTask"
  lockDurationMs = 2 * 60 * 1000
  lockManager.setLock mailTaskName, lockDurationMs, (err) ->
    if err? then return log.error "Error getting a distributed lock for task #{mailTaskName}: #{err}"
    emailEmployerNewCandidatesAvailable.call {"mailTaskName":mailTaskName}, (err) ->
      if err
        log.error "There was an error completing the new candidates available task: #{err}"
      lockManager.releaseLock mailTaskName, (err) ->
        if err? then return log.error "There was an error releasing the distributed lock for task #{mailTaskName}: #{err}"

emailEmployerNewCandidatesAvailable = (emailEmployerNewCandidatesAvailableCallback) ->
  currentTime = new Date()
  asyncContext =
    "currentTime": currentTime
    "mailTaskName": @mailTaskName

  async.waterfall [
    findAllEmployers
    makeEmployerNamesEasilyAccessible
    (allEmployers, cb) ->
      async.reject allEmployers, employersEmailedDigestMoreThanWeekAgoFilter.bind(asyncContext), cb.bind(null,null)
    (employersToEmail, cb) ->
      async.each employersToEmail, sendEmployerNewCandidatesAvailableEmail.bind(asyncContext), cb
  ], emailEmployerNewCandidatesAvailableCallback

findAllEmployers = (cb) ->
  findParameters =
    "employerAt":
      $exists: true
    permissions: "employer"
  selection = "_id email employerAt signedEmployerAgreement.data.firstName signedEmployerAgreement.data.lastName activity dateCreated emails"
  User.find(findParameters).select(selection).lean().exec cb

makeEmployerNamesEasilyAccessible = (allEmployers, cb) ->
  for employer, index in allEmployers
    if employer.signedEmployerAgreement?.data?.firstName
      employer.name = employer.signedEmployerAgreement.data.firstName + " " + employer.signedEmployerAgreement.data.lastName
      delete employer.signedEmployerAgreement
    allEmployers[index] = employer
  cb null, allEmployers

employersEmailedDigestMoreThanWeekAgoFilter = (employer, cb) ->
  if employer.emails?.employerNotes?.enabled is false
    return cb true
  if not employer.signedEmployerAgreement and not employer.activity?.login?
    return cb true
  findParameters =
    "user": employer._id
    "mailTask": @mailTaskName
    "sent":
      $gt: new Date(@currentTime.getTime() - 14 * 24 * 60 * 60 * 1000)
  MailSent.find(findParameters).lean().exec (err, sentMail) ->
    if err?
      log.error "Error finding mail sent for task #{@mailTaskName} and employer #employer._id}!"
      cb true
    else
      cb Boolean(sentMail.length)

sendEmployerNewCandidatesAvailableEmail = (employer, cb) ->
  lastLoginDate = employer.activity?.login?.last ? employer.dateCreated
  countParameters =
    "jobProfileApproved": true
    $or: [
        jobProfileApprovedDate:
          $gt: lastLoginDate.toISOString()
      ,
        jobProfileApprovedDate:
          $exists: false
        "jobProfile.updated":
          $gt: lastLoginDate.toISOString()
    ]
  User.count countParameters, (err, numberOfCandidatesSinceLogin) =>
    if err? then return cb err
    if numberOfCandidatesSinceLogin < 4
      return cb null
    context =
      email_id: "tem_CCcHKr95Nvu5bT7c7iHCtm"
      recipient:
        address: employer.email
      email_data:
        new_candidates: numberOfCandidatesSinceLogin
        employer_company_name: employer.employerAt
        company_name: "CodeCombat"
        recipient_address: encodeURIComponent(employer.email)
    if employer.name
      context.recipient.name = employer.name
    log.info "Sending available candidates update reminder to #{context.recipient.name}(#{context.recipient.address})"
    newSentMail =
      mailTask: @mailTaskName
      user: employer._id
    MailSent.create newSentMail, (err) ->
      if err? then return cb err
      sendwithus.api.send context, (err, result) ->
        log.error "Error sending employer candidates available email: #{err} with result #{result}" if err
        cb null

### End Employer New Candidates Available Email ###

### Task Emails ###
emailUserRemarkTaskRemindersTask = ->
  mailTaskName = "emailUserRemarkTaskRemindersTask"
  lockDurationMs = 2 * 60 * 1000
  lockManager.setLock mailTaskName, lockDurationMs, (err) ->
    if err? then return log.error "Error getting a distributed lock for task #{mailTaskName}: #{err}"
    emailUserRemarkTaskReminders.call {"mailTaskName":mailTaskName}, (err) ->
      if err
        log.error "There was an error completing the #{mailTaskName}: #{err}"
      lockManager.releaseLock mailTaskName, (err) ->
        if err? then return log.error "There was an error releasing the distributed lock for task #{mailTaskName}: #{err}"

emailUserRemarkTaskReminders = (cb) ->
  currentTime = new Date()
  asyncContext =
    "currentTime": currentTime
    "mailTaskName": @mailTaskName

  async.waterfall [
    findAllIncompleteUserRemarkTasksDue.bind(asyncContext)
    processRemarksIntoTasks.bind(asyncContext)
    (allTasks, cb) ->
      async.reject allTasks, taskReminderAlreadySentThisWeekFilter.bind(asyncContext), cb.bind(null,null)
    (tasksToRemind, cb) ->
      async.each tasksToRemind, sendUserRemarkTaskEmail.bind(asyncContext), cb
  ], cb

findAllIncompleteUserRemarkTasksDue = (cb) ->
  findParameters =
    tasks:
      $exists: true
      $elemMatch:
        date:
          $lte: @currentTime.toISOString()
        status:
          $ne: 'Completed'
  selection = "contact user tasks"
  UserRemark.find(findParameters).select(selection).lean().exec cb

processRemarksIntoTasks = (remarks, cb) ->
  tasks = []
  for remark in remarks
      for task in remark.tasks
        taskObject =
          date: task.date
          action: task.action
          contact: remark.contact
          user: remark.user
          remarkID: remark._id
        tasks.push taskObject
  cb null, tasks

taskReminderAlreadySentThisWeekFilter = (task, cb) ->
  findParameters =
    "user": task.contact
    "mailTask": @mailTaskName
    "sent":
      $gt: new Date(@currentTime.getTime() - 7 * 24 * 60 * 60 * 1000)
    "metadata":
      remarkID: task.remarkID
      taskAction: task.action
      date: task.date
  MailSent.count findParameters, (err, count) ->
    if err? then return cb true
    return cb Boolean(count)

sendUserRemarkTaskEmail = (task, cb) ->
  mailTaskName = @mailTaskName
  User.findOne("_id":task.contact).select("email").lean().exec (err, contact) ->
    if err? then return cb err
    User.findOne("_id":task.user).select("jobProfile.name").lean().exec (err, user) ->
      if err? then return cb err
      context =
        email_id: "tem_aryDjyw6JmEmbKtCMTSwAM"
        recipient:
          address: contact.email
        email_data:
          task_text: task.action
          candidate_name: user.jobProfile?.name ? "(Name not listed in job profile)"
          candidate_link: "http://codecombat.com/account/profile/#{task.user}"
          due_date: task.date
      #log.info "Sending recruitment task reminder to #{contact.email}"
      newSentMail =
        mailTask: mailTaskName
        user: task.contact
        "metadata":
          remarkID: task.remarkID
          taskAction: task.action
          date: task.date
      MailSent.create newSentMail, (err) ->
        if err? then return cb err
        sendwithus.api.send context, (err, result) ->
          log.error "Error sending #{mailTaskName} to #{contact.email}: #{err} with result #{result}" if err
          cb null

### New Recruit Leaderboard Email ###
###
newRecruitLeaderboardEmailTask = ->
  # tem_kMQFCKX3v4DNAQDsMAsPJC
  #maxRank and maxRankTime should be recorded if isSimulating is false
  mailTaskName = "newRecruitLeaderboardEmailTask"
  lockDurationMs = 6000
  lockManager.setLock mailTaskName, lockDurationMs, (err, lockResult) ->
###
### End New Recruit Leaderboard Email ###

### Employer Matching Candidate Notification Email ###
###
employerMatchingCandidateNotificationTask = ->
  # tem_mYsepTfWQ265noKfZJcbBH
  #save email filters in their own collection
  mailTaskName = "employerMatchingCandidateNotificationTask"
  lockDurationMs = 6000
  lockManager.setLock mailTaskName, lockDurationMs, (err, lockResult) ->
###
### End Employer Matching Candidate Notification Email ###
### Employer ignore ###

DEBUGGING = false
LADDER_PREGAME_INTERVAL = 2 * 3600 * 1000  # Send emails two hours before players last submitted.
getTimeFromDaysAgo = (now, daysAgo) ->
  t = now - 86400 * 1000 * daysAgo - LADDER_PREGAME_INTERVAL

isRequestFromDesignatedCronHandler = (req, res) ->
  requestIP = req.headers['x-forwarded-for']?.replace(' ', '').split(',')[0]
  if requestIP isnt config.mail.cronHandlerPublicIP and requestIP isnt config.mail.cronHandlerPrivateIP
    console.log "RECEIVED REQUEST FROM IP #{requestIP}(headers indicate #{req.headers['x-forwarded-for']}"
    console.log 'UNAUTHORIZED ATTEMPT TO SEND TRANSACTIONAL LADDER EMAIL THROUGH CRON MAIL HANDLER'
    res.send('You aren\'t authorized to perform that action. Only the specified Cron handler may perform that action.')
    res.end()
    return false
  return true

### Ladder Update Email ###

handleLadderUpdate = (req, res) ->
  return unless DEBUGGING or isRequestFromDesignatedCronHandler req, res
  res.send('Great work, Captain Cron! I can take it from here.')
  res.end()
  # TODO: somehow fetch the histograms
  #emailDays = [1, 2, 4, 7, 14, 30]
  emailDays = [1, 3, 7]  # Reduced to keep smaller monthly recipient footprint
  now = new Date()
  for daysAgo in emailDays
    # Get every session that was submitted in a 5-minute window after the time.
    startTime = getTimeFromDaysAgo now, daysAgo
    endTime = startTime + 5 * 60 * 1000
    if DEBUGGING
      endTime = startTime + 15 * 60 * 1000  # Debugging: make sure there's something to send
    findParameters = {submitted: true, submitDate: {$gt: new Date(startTime), $lte: new Date(endTime)}}
    # TODO: think about putting screenshots in the email
    selectString = 'creator team levelName levelID totalScore matches submitted submitDate scoreHistory level.original unsubscribed'
    query = LevelSession.find(findParameters)
      .select(selectString)
      .lean()
    do (daysAgo) ->
      query.exec (err, results) ->
        if err
          log.error "Couldn't fetch ladder updates for #{findParameters}\nError: #{err}"
          return errors.serverError res, "Ladder update email query failed: #{JSON.stringify(err)}"
        #log.info "Found #{results.length} ladder sessions to email updates about for #{daysAgo} day(s) ago."
        sendLadderUpdateEmail result, now, daysAgo for result in results

sendLadderUpdateEmail = (session, now, daysAgo) ->
  User.findOne({_id: session.creator}).select('name email firstName lastName emailSubscriptions emails preferredLanguage').exec (err, user) ->
    if err
      log.error "Couldn't find user for #{session.creator} from session #{session._id}"
      return
    allowNotes = user.isEmailSubscriptionEnabled 'anyNotes'
    unless user.get('email') and allowNotes and not session.unsubscribed
      #log.info "Not sending email to #{user.get('email')} #{user.get('name')} because they only want emails about #{user.get('emailSubscriptions')}, #{user.get('emails')} - session unsubscribed: #{session.unsubscribed}"
      return
    unless session.levelName and session.team
      #log.info "Not sending email to #{user.get('email')} #{user.get('name')} because the session had levelName #{session.levelName} or team #{session.team} in it."
      return
    name = if user.get('firstName') and user.get('lastName') then "#{user.get('firstName')}" else user.get('name')
    name = 'Wizard' if not name or name is 'Anonymous'

    # Fetch the most recent defeat and victory, if there are any.
    # (We could look at strongest/weakest, but we'd have to fetch everyone, or denormalize more.)
    matches = _.filter session.matches, (match) -> match.date >= getTimeFromDaysAgo now, daysAgo
    defeats = _.filter matches, (match) -> match.metrics.rank is 1 and match.opponents[0].metrics.rank is 0
    victories = _.filter matches, (match) -> match.metrics.rank is 0 and match.opponents[0].metrics.rank is 1

    defeat = _.last defeats
    victory = _.last victories

    sendEmail = (defeatContext, victoryContext, levelVersionsContext) ->
      # TODO: do something with the preferredLanguage?
      context =
        email_id: sendwithus.templates.ladder_update_email
        recipient:
          address: if DEBUGGING then 'nick@codecombat.com' else user.get('email')
          name: name
        email_data:
          name: name
          days_ago: daysAgo
          wins: victories.length
          losses: defeats.length
          total_score: Math.round(session.totalScore * 100)
          team: session.team
          team_name: session.team[0].toUpperCase() + session.team.substr(1)
          level_name: session.levelName
          session_id: session._id
          ladder_url: "http://codecombat.com/play/ladder/#{session.levelID}#my-matches"
          score_history_graph_url: getScoreHistoryGraphURL session, daysAgo
          defeat: defeatContext
          victory: victoryContext
          levelVersions: levelVersionsContext
      #log.info "Sending ladder update email to #{context.recipient.address} with #{context.email_data.wins} wins and #{context.email_data.losses} losses since #{daysAgo} day(s) ago."
      sendwithus.api.send context, (err, result) ->
        log.error "Error sending ladder update email: #{err} with result #{result}" if err

    urlForMatch = (match) ->
      "http://codecombat.com/play/level/#{session.levelID}?team=#{session.team}&opponent=#{match.opponents[0].sessionID}"

    onFetchedDefeatedOpponent = (err, defeatedOpponent) ->
      if err
        log.error "Couldn't find defeateded opponent: #{err}"
        defeatedOpponent = null
      victoryContext = {opponent_name: defeatedOpponent?.name ? 'Anonymous', url: urlForMatch(victory)} if victory

      onFetchedVictoriousOpponent = (err, victoriousOpponent) ->
        if err
          log.error "Couldn't find victorious opponent: #{err}"
          victoriousOpponent = null
        defeatContext = {opponent_name: victoriousOpponent?.name ? 'Anonymous', url: urlForMatch(defeat)} if defeat

        Level.find({original: session.level.original, created: {$gt: session.submitDate}}).select('created commitMessage version').sort('-created').lean().exec (err, levelVersions) ->
          sendEmail defeatContext, victoryContext, (if levelVersions.length then levelVersions else null)

      if defeat
        User.findOne({_id: defeat.opponents[0].userID}).select('name').lean().exec onFetchedVictoriousOpponent
      else
        onFetchedVictoriousOpponent null, null

    if victory
      User.findOne({_id: victory.opponents[0].userID}).select('name').lean().exec onFetchedDefeatedOpponent
    else
      onFetchedDefeatedOpponent null, null

getScoreHistoryGraphURL = (session, daysAgo) ->
  # Totally duplicated in My Matches tab for now until we figure out what we're doing.
  since = new Date() - 86400 * 1000 * daysAgo
  scoreHistory = (s for s in session.scoreHistory ? [] when s[0] >= since)
  return '' unless scoreHistory.length > 1
  scoreHistory = _.last scoreHistory, 100  # Chart URL needs to be under 2048 characters for GET
  times = (s[0] for s in scoreHistory)
  times = ((100 * (t - times[0]) / (times[times.length - 1] - times[0])).toFixed(1) for t in times)
  scores = (s[1] for s in scoreHistory)
  lowest = _.min scores  #.concat([0])
  highest = _.max scores  #.concat(50)
  scores = (Math.round(100 * (s - lowest) / (highest - lowest)) for s in scores)
  currentScore = Math.round scoreHistory[scoreHistory.length - 1][1] * 100
  minScore = Math.round(100 * lowest)
  maxScore = Math.round(100 * highest)
  chartData = times.join(',') + '|' + scores.join(',')
  "https://chart.googleapis.com/chart?chs=600x75&cht=lxy&chtt=Score%3A+#{currentScore}&chts=222222,12,r&chf=a,s,000000FF&chls=2&chd=t:#{chartData}&chxt=y&chxr=0,#{minScore},#{maxScore}"

### End Ladder Update Email ###

### Next Steps Email ###

handleNextSteps = (req, res) ->
  return unless DEBUGGING or isRequestFromDesignatedCronHandler req, res
  res.send('Great work, Captain Cron! I can take it from here.')
  res.end()
  emailDays = [1]
  now = new Date()
  for daysAgo in emailDays
    # Get every User that was created in a 5-minute window after the time.
    startTime = getTimeFromDaysAgo now, daysAgo
    endTime = startTime + 5 * 60 * 1000
    findParameters = {dateCreated: {$gt: new Date(startTime), $lte: new Date(endTime)}, emailLower: {$exists: true}}
    selectString = 'name firstName lastName lastLevel points email gender emailSubscriptions emails dateCreated preferredLanguage aceConfig.language activity stats earned testGroupNumber ageRange courseInstances'
    query = User.find(findParameters).select(selectString)
    do (daysAgo) ->
      query.exec (err, results) ->
        if err
          log.error "Couldn't fetch next steps users for #{findParameters}\nError: #{err}"
          return errors.serverError res, "Next steps email query failed: #{JSON.stringify(err)}"
        log.info "Found #{results.length} next-steps users to email updates about for #{daysAgo} day(s) ago." if DEBUGGING
        sendNextStepsEmail result, now, daysAgo for result in results

sendNextStepsEmail = (user, now, daysAgo) ->
  unless user.isEmailSubscriptionEnabled('generalNews') and user.isEmailSubscriptionEnabled('anyNotes')
    log.info "Not sending email to #{user.get('email')} #{user.get('name')} because they only want emails about #{JSON.stringify(user.get('emails'))}" if DEBUGGING
    return

  LevelSession.find({creator: user.get('_id') + ''}).select('levelName levelID changed state.complete playtime').lean().exec (err, sessions) ->
    return log.error "Couldn't find sessions for #{user.get('email')}: #{err}" if err
    complete = (s for s in sessions when s.state?.complete)
    incomplete = (s for s in sessions when not s.state?.complete)
    return if complete.length < 2

    # TODO: find the next level to do somehow, for real
    if incomplete.length
      nextLevel = name: incomplete[0].levelName, slug: incomplete[0].levelID
    else
      nextLevel = null
    err = null
    do (err, nextLevel) ->
      return log.error "Couldn't find next level for #{user.get('email')}: #{err}" if err
      name = if user.get('firstName') and user.get('lastName') then "#{user.get('firstName')}" else user.get('name')
      name = 'Hero' if not name or name in ['Anoner', 'Anonymous']
      #secretLevel = switch user.get('testGroupNumber') % 8
      #  when 0, 1, 2, 3 then name: 'Forgetful Gemsmith', slug: 'forgetful-gemsmith'
      #  when 4, 5, 6, 7 then name: 'Signs and Portents', slug: 'signs-and-portents'
      secretLevel = name: 'Signs and Portents', slug: 'signs-and-portents'  # We turned off this test for now and are sending everyone to forgetful-gemsmith

      # TODO: make this smarter, actually data-driven, looking at all available sessions
      shadowGuardSession = _.find sessions, levelID: 'shadow-guard'
      isFast = shadowGuardSession and shadowGuardSession.playtime < 90  # Average is 107s
      isVeryFast = shadowGuardSession and shadowGuardSession.playtime < 75
      isAdult = user.get('ageRange') in ['18-24', '25-34', '35-44', '45-100']
      isKid = not isAdult  # Assume kid if not specified
      # Used to use these categories to customize the email; not doing it right now. TODO: customize it again in Sendwithus.
      # TODO: do something with the preferredLanguage?
      context =
        email_id: sendwithus.templates.next_steps_email
        recipient:
          address: if DEBUGGING then 'nick@codecombat.com' else user.get('email')
          name: name
        email_data:
          name: name
          days_ago: daysAgo
          nextLevelName: nextLevel?.name
          nextLevelLink: if nextLevel then "http://codecombat.com/play/level/#{nextLevel.slug}" else null
          secretLevelName: secretLevel.name
          secretLevelLink: "http://codecombat.com/play/level/#{secretLevel.slug}"
          levelsComplete: complete.length
          isCoursePlayer: user.get('courseInstances')?.length > 0
      log.info "Sending next steps email to #{context.recipient.address} with #{context.email_data.nextLevelName} next and #{context.email_data.levelsComplete} levels complete since #{daysAgo} day(s) ago." if DEBUGGING
      sendwithus.api.send context, (err, result) ->
        log.error "Error sending next steps email: #{err} with result #{result}" if err

### End Next Steps Email ###

handleMailchimpWebHook = (req, res) ->
  post = req.body

  unless post.type in ['unsubscribe', 'profile']
    res.send 'Bad post type'
    return res.end()

  unless post.data.email
    res.send 'No email provided'
    return res.end()

  query = {'mailChimp.leid': post.data.web_id}
  User.findOne query, (err, user) ->
    return errors.serverError(res) if err
    if not user
      return errors.notFound(res)

    handleProfileUpdate(user, post) if post.type is 'profile'
    handleUnsubscribe(user) if post.type is 'unsubscribe'

    user.updatedMailChimp = true # so as not to echo back to mailchimp
    user.save (err) ->
      return errors.serverError(res) if err
      res.end('Success')

module.exports.handleProfileUpdate = handleProfileUpdate = (user, post) ->
  mailchimpSubs = post.data.merges.INTERESTS.split(', ')

  for [mailchimpEmailGroup, emailGroup] in _.zip(mail.MAILCHIMP_GROUPS, mail.NEWS_GROUPS)
    user.setEmailSubscription emailGroup, mailchimpEmailGroup in mailchimpSubs

  fname = post.data.merges.FNAME
  user.set('firstName', fname) if fname

  lname = post.data.merges.LNAME
  user.set('lastName', lname) if lname

  user.set 'mailChimp.email', post.data.email
  user.set 'mailChimp.euid', post.data.id


module.exports.handleUnsubscribe = handleUnsubscribe = (user) ->
  user.set 'emailSubscriptions', []
  for emailGroup in mail.NEWS_GROUPS
    user.setEmailSubscription emailGroup, false
