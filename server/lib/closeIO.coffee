config = require '../../server_config'
log = require 'winston'
request = require 'request'

apiKey = config.closeIO?.apiKey

module.exports =
  logError: (msg) ->
    log.error("Close.io Error: #{msg}")

  createSalesLead: (user, email, newLeadData) ->
    return @logError('No API key available') unless apiKey
    @getLead email, (error, lead) =>
      return @logError(JSON.stringify(error)) if error
      return if lead
      @createLead(user, email, newLeadData)

  createLead: (user, email, newLeadData) ->
    name = newLeadData.name ? email
    postData =
      display_name: newLeadData.organization ? name
      name: newLeadData.organization ? name
      contacts: [{
        emails: [{email: email}]
        name: name
      }]
      custom: {}
    postData.contacts[0].phones = [phone: newLeadData.phone] if newLeadData.phone
    for key, val of newLeadData
      continue if key in ['name', 'organization', 'phone']
      continue if _.isEmpty(val)
      postData.custom[key] = val
    postData.custom['userID'] = user.get('_id').valueOf() if user
    options =
      uri: 'https://' + apiKey + ':X@app.close.io/api/v1/lead/',
      body: JSON.stringify(postData)
    request.post options, (error, response, body) =>
      return @logError(JSON.stringify(error)) if error

  getLead: (email, done) ->
    uri = 'https://' + apiKey + ':X@app.close.io/api/v1/lead/?query=email_address:' + email
    request.get uri, (error, response, body) =>
      return done(error) if error
      leads = JSON.parse(body)
      return done("Unexpected leads format: " + body) unless leads.data?
      if leads.data?.length is 1
        return done(null, leads.data[0])
      else if leads.data?.length > 1
        return done('ERROR: multiple leads returned for ' + email + ' ' + leads.data.length)
      return done()

  getSalesContactEmail: (email, done) ->
    try
      # NOTE: does not work on + email addresses due to Close.io API bug
      uri = "https://#{apiKey}:X@app.close.io/api/v1/lead/?query=email_address:#{email}"
      request.get uri, (error, response, body) =>
        return done(error) if error
        leads = JSON.parse(body)
        return done("Unexpected leads format: " + body) unless leads.data?
        return done("No existing Close.IO lead found for #{email}") unless leads.data?.length > 0
        lead = leads.data[0]
        uri = "https://#{apiKey}:X@app.close.io/api/v1/activity/?lead_id=#{lead.id}"
        request.get uri, (error, response, body) =>
          return done(error) if error
          activities = JSON.parse(body)
          return done("Unexpected activities format: " + body) unless activities.data?
          for activity in activities.data when activity._type is 'Email'
            if /@codecombat\.(?:com)|(?:nl)/ig.test(activity.sender) and not activity.sender?.indexOf(config.mail.username) >= 0
              return done(null, activity.sender, lead.id)
          return done(null, config.mail.supportSchools, lead.id)
    catch error
      log.error("closeIO.getSalesContactEmail Error for #{email}: #{JSON.stringify(error)}")
      return done(error)

  sendMail: (fromAddress, subject, content, done) ->
    # log.info("DEBUG: closeIO.sendMail #{fromAddress} #{subject} #{content}")
    @getSalesContactEmail fromAddress, (err, salesContactEmail, leadID) ->
      return done("Error getting sales contact for #{fromAddress}: #{err}") if err
      matches = salesContactEmail.match(/^[a-zA-Z_]+ <(\w+@[a-zA-Z_]+?\.[a-zA-Z]{2,3})>$|(\w+@[a-zA-Z_]+?\.[a-zA-Z]{2,3})/i)
      salesContactEmail = matches?[1] ? matches?[2] ? config.mail.supportSchools
      salesContactEmail = config.mail.supportSchools if salesContactEmail?.indexOf('brian@codecombat.com') >= 0
      postData =
        to: [salesContactEmail]
        sender: config.mail.username
        subject: subject
        body_text: content
        lead_id: leadID
        status: 'outbox'
      options =
        uri: "https://#{apiKey}:X@app.close.io/api/v1/activity/email/"
        body: JSON.stringify(postData)
      request.post options, (error, response, body) =>
        return done(error) if error
        result = JSON.parse(body);
        if result.errors or result['field-errors']
          errorMessage = "Close.io Send email POST error for #{fromAddress} #{JSON.stringify(result.errors)} #{JSON.stringify(result['field-errors'])}";
          return done(errorMessage)
        return done()
