config = require '../server_config'
request = require 'request'
log = require 'winston'

roomIDMap =
  main: 254598
  artisans: 1146994
  tower: 318356

module.exports.sendHipChatMessage = sendHipChatMessage = (message, rooms, options) ->
  return unless config.isProduction
  rooms ?= ['main']
  options ?= {}
  for room in rooms
    unless roomID = roomIDMap[room]
      log.error "Unknown HipChat room #{room}."
      continue
    unless key = config.hipchat[room]
      log.info "No HipChat API key for room #{room}."
      continue
    form =
      color: options.color or 'yellow'
      notify: false
      message: message
      messageFormat: 'html'
    if options.papertrail
      secondsFromEpoch = Math.floor(new Date().getTime() / 1000)
      link = "<a href=\"https://papertrailapp.com/groups/488214/events?time=#{secondsFromEpoch}\">PaperTrail</a>"
      form.message = "#{message} #{link}"
      form.color = options.color or 'red'
      form.notify = true
    url = "https://api.hipchat.com/v2/room/#{roomID}/notification?auth_token=#{key}"
    request.post {uri: url, json: form}, (err, res, body) ->
      return log.error 'Error sending Slack message:', err or body if err or /error/i.test body
      #log.info "Got HipChat message response:", body
