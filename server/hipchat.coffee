config = require '../server_config'
request = require 'request'
log = require 'winston'

module.exports.sendHipChatMessage = sendHipChatMessage = (message) ->
  return unless key = config.hipchatAPIKey
  return unless config.isProduction
  roomID = 254598
  form =
    color: 'yellow'
    notify: false
    message: message
    messageFormat: 'html'
  url = "https://api.hipchat.com/v2/room/#{roomID}/notification?auth_token=#{key}"
  request.post {uri: url, json: form}, (err, res, body) ->
    return log.error 'Error sending HipChat patch request:', err or body if err or /error/i.test body
    #log.info "Got HipChat patch response:", body

module.exports.sendTowerHipChatMessage = sendTowerHipChatMessage = (message) ->
  secondsFromEpoch = Math.floor(new Date().getTime() / 1000)
  link = "<a href=\"https://papertrailapp.com/groups/488214/events?time=#{secondsFromEpoch}\">PaperTrail</a>"
  message = "#{message} #{link}"
  return unless key = config.hipchatTowerAPIKey
  return unless config.isProduction
  roomID = 318356
  form =
    color: 'red'
    notify: true
    message: message
    messageFormat: 'html'
  url = "https://api.hipchat.com/v2/room/#{roomID}/notification?auth_token=#{key}"
  request.post {uri: url, json: form}, (err, res, body) ->
    return log.error 'Error sending HipChat Tower message:', err or body if err or /error/i.test body
