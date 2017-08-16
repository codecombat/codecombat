config = require '../../server_config'
log = require 'winston'
request = require 'request'

apiKey = config.closeIO?.apiKey
defaultSalesContactUserID = 'user_Fh0uLUkRIKMk2to61ISq8PneyQonuD2i7hes6RhZgDX'

module.exports =
  logError: (msg) ->
    log.error("Close.io Error: #{msg}")

  getSalesContactEmail: (userEmail, done) ->
    # Sales contact email precedence: previous email to contact, previous email to lead, lead custom field, lead status default
    try
      # NOTE: does not work on + email addresses due to Close.io API bug
      uri = "https://#{apiKey}:X@app.close.io/api/v1/lead/?query=email_address:#{userEmail}"
      request.get uri, (error, response, body) =>
        return done(error) if error
        leads = JSON.parse(body)
        return done("Unexpected Close leads format: " + body) unless leads.data?
        if leads.data?.length is 0
          return done(null, config.mail.supportSchools, defaultSalesContactUserID, null)
        lead = leads.data[0]
        uri = "https://#{apiKey}:X@app.close.io/api/v1/activity/?lead_id=#{lead.id}"
        request.get uri, (error, response, body) =>
          return done(error) if error
          activities = JSON.parse(body)
          return done("Unexpected activities format: " + body) unless activities.data?
          activityForThisContact = null
          activityForThisLead = null
          for activity in activities.data when activity?._type is 'Email'
            continue unless /@codecombat\.(?:com)|(?:nl)/ig.test(activity.sender)
            continue if activity.sender.indexOf('brian@codecombat.com') >= 0
            continue if activity.sender.indexOf(config.mail.username) >= 0
            activityForThisLead ?= activity
            for email in activity.to or [] when email?.toLowerCase() is userEmail?.toLowerCase()
              activityForThisContact ?= activity

          if activityForThisContact
            return done(null, activityForThisContact.sender, activityForThisContact.user_id, lead.id)
          else if activityForThisLead
            return done(null, activityForThisLead.sender, activityForThisLead.user_id, lead.id)

          if email = lead.custom?['auto_sales_email']
            # Have to lookup Close user Id if email from lead custom field
            uri = "https://#{apiKey}:X@app.close.io/api/v1/user/?_fields=id,email"
            request.get uri, (error, response, body) =>
              return done(error) if error
              users = JSON.parse(body)
              return done("Unexpected Close users format: " + body) unless users.data?
              userID = null
              for user in users.data or [] when user.email?.toLowerCase() is email.toLowerCase()
                userID = user.id
                break
              if userID
                return done(null, email, userID, lead.id)
              else
                @logError("No user found for leadID=#{lead.id} user=#{userEmail} auto_sales_email=#{lead.custom?['auto_sales_email']}")
                return done(null, config.mail.supportSchools, defaultSalesContactUserID, lead.id)
          else
            return done(null, config.mail.supportSchools, defaultSalesContactUserID, lead.id)
    catch error
      log.error("closeIO.getSalesContactEmail Error for #{userEmail}: #{JSON.stringify(error)}")
      return done(error)

  sendMail: (fromAddress, subject, content, salesContactEmail, leadID, done) ->
    # log.info("DEBUG: closeIO.sendMail #{fromAddress} #{subject} #{salesContactEmail}  #{leadID}")
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
      result = JSON.parse(body)
      if result.errors or result['field-errors']
        errorMessage = "Close.io Send email POST error for #{fromAddress} #{JSON.stringify(result.errors)} #{JSON.stringify(result['field-errors'])}"
        return done(errorMessage)
      return done()

  processLicenseRequest: (teacherEmail, userID, leadID, licensesRequested, amount, done) ->
    # log.info("DEBUG: closeIO.processLicenseRequest #{teacherEmail} #{userID} #{leadID} #{licensesRequested} #{amount}")

    # Update lead with licenses requested
    licensesRequested = parseInt(licensesRequested)
    putData = 'custom.licensesRequested': licensesRequested
    options =
      uri: "https://#{apiKey}:X@app.close.io/api/v1/lead/#{leadID}/"
      body: JSON.stringify(putData)
    request.put options, (error, response, body) =>
      return done(error) if error
      result = JSON.parse(body)
      if result.errors or result['field-errors']
        errorMessage = "Update Close.io lead PUT error for #{teacherEmail} #{leadID}"
        return done(errorMessage)

      # Create call task
      postData =
        _type: "lead"
        lead_id: leadID
        assigned_to: userID
        text: "Call license inquiry #{teacherEmail}"
        is_complete: false
      options =
        uri: "https://#{apiKey}:X@app.close.io/api/v1/task/"
        body: JSON.stringify(postData)
      request.post options, (error, response, body) =>
        return done(error) if error
        result = JSON.parse(body)
        if result.errors or result['field-errors']
          errorMessage = "Create Close.io call task POST error for #{teacherEmail} #{leadID}"
          return done(errorMessage)

        # Create opportunity
        dateWon = new Date()
        dateWon.setUTCMonth(dateWon.getUTCMonth() + 2)
        postData =
          note: "#{licensesRequested} licenses requested"
          confidence: 5
          date_won: dateWon.toISOString().substring(0, 10)
          lead_id: leadID
          status: 'Active'
          value: licensesRequested * amount
          value_period: "annual"
        options =
          uri: "https://#{apiKey}:X@app.close.io/api/v1/opportunity/"
          body: JSON.stringify(postData)
        request.post options, (error, response, body) =>
          return done(error) if error
          result = JSON.parse(body)
          if result.errors or result['field-errors']
            errorMessage = "Create Close.io opportunity POST error for #{teacherEmail} #{leadID}"
            return done(errorMessage)
          return done()
