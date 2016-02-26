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
