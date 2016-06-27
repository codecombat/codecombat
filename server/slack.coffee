config = require '../server_config'
request = require 'request'
log = require 'winston'

roomChannelMap =
  main: '#general'
  artisans: '#artisan'
  
module.exports.sendChangedSlackMessage = (options) ->
  message = "#{options.creator.get('name')} saved a change to #{options.target.get('name')}: #{options.target.get('commitMessage') or '(no commit message)'} #{options.docLink}"
  @sendSlackMessage message, ['artisans']

module.exports.sendSlackMessage = (message, rooms=['tower'], options={}) ->
  unless config.isProduction
    log.info "Slack msg: #{message}"
    return
  unless token = config.slackToken
    log.info "No Slack token."
    return
  for room in rooms
    channel = roomChannelMap[room] ? room
    form =
      channel: channel
      token: token
      text: message
      as_user: true
      unfurl_links: false
      unfurl_media: false
    if options.papertrail
      secondsFromEpoch = Math.floor(new Date().getTime() / 1000)
      link = "https://papertrailapp.com/groups/488214/events?time=#{secondsFromEpoch}"
      form.text += " #{link}"
    # https://api.slack.com/docs/formatting
    form.text = form.text.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
    url = "https://slack.com/api/chat.postMessage"
    request.post {uri: url, form: form}, (err, res, body) ->
      try
        response = JSON.parse(body)
        return log.error('Error sending Slack message:', err) if err
        return log.error("Slack returned error: #{response.error}") unless response.ok
        log.warn("Slack returned warning: #{response.warning}") if response.warning 
        # log.info "Got Slack message response:", body
      catch error
        log.error("Slack response parse error: #{error}")
