config = require '../server_config'
request = require 'request'
log = require 'winston'

roomChannelMap =
  artisan: '#artisan'
  artisans: '#artisan'
  eng: '#eng'
  main: '#general'
  ops: '#ops'
  tower: '#general'
  sales: '#sales'
  game: '#game'
  starters: '#starters'

module.exports.sendChangedSlackMessage = (options) ->
  message = "#{options.creator.get('name')} saved a change to #{options.target.get('name')}: #{options.target.get('commitMessage') or '(no commit message)'} #{options.docLink}"
  @sendSlackMessage message, ['artisans']

module.exports.sendSlackMessage = (message, rooms=['#eng'], options={}) ->
  unless config.isProduction or options.forceSend
    log.info "Slack msg: #{message} #{JSON.stringify(rooms)}, #{JSON.stringify(options)}"
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
      link = "https://app.logdna.com/logs/view?t=timestamp:#{secondsFromEpoch}"
      form.text += " #{link}"
    if options.markdown?  # true/false
      form.mrkdwn = options.markdown
    # https://api.slack.com/docs/formatting
    form.text = form.text.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
    url = "https://slack.com/api/chat.postMessage"
    request.post {uri: url, form: form}, (err, res, body) ->
      try
        response = JSON.parse(body)
        return log.error('Error sending Slack message:', err) if err
        return log.error("Slack returned error: #{response.error} to channel #{channel} with message #{message}") unless response.ok
        log.warn("Slack returned warning: #{response.warning}") if response.warning
        log.info "Got Slack message response:", body unless options.quiet
      catch error
        log.error("Slack response parse error: #{error}")
