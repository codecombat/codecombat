config = require '../../server_config'
request = require 'request'
User = require '../models/User'
http = require 'http'

authstr = new Buffer("#{config.picoCTF_auth.username}:#{config.picoCTF_auth.password}").toString 'base64'

papi = (url, req, cb) ->
  request
      url: "#{config.picoCTF_api_url}#{url}"
      jar: false
      headers:
        Cookie: "flask=#{req.cookies.flask}"
        Authorization: 'Basic ' + authstr
    , cb

class PicoStrategy
  constructor: () ->
    @name = 'local'

  authenticate: (req) ->
    papi "/team", req, (err, rr, body) =>
      return @fail err if err
      response = JSON.parse(body)
      return @fail response.message if response.status is 0

      data = response.data
      tid = data.tid
      fakeEmail = "#{tid}@coco.team"

      User.findOne(emailLower: fakeEmail).exec (err, user) =>
        return @success user if user

        user = new User
          anonymous: false
          name: data.team_name
          email: fakeEmail
          emailLower: fakeEmail
          aceConfig: {language: 'javascript'}
          volume: 0
        user.set 'testGroupNumber', Math.floor(Math.random() * 256)  # also in app/core/auth
        user.save (err) =>
          console.log "New user created!", user
          @success user


init = (app) ->
  app.get '/picoctf/problems', (req, res) ->
    papi "/problems/unlocked", req, (err, rr, body) ->
      res.json JSON.parse(body).data

  app.get '/picoctf/problems/all', (req, res) ->
    papi "/problems/all", req, (err, rr, body) ->
      res.json JSON.parse(body).data

  app.post '/picoctf/submit', (req, res) ->
    request.post
      url: "#{config.picoCTF_api_url}/problems/submit"
      jar: false
      form:
        pid: req.body.pid
        key: req.body.flag
        token: req.cookies.token
      headers:
        Cookie: "token=#{req.cookies.token};flask=#{req.cookies.flask}"
        Authorization: 'Basic ' + authstr
    , (err, rr, body) ->
      res.json JSON.parse(body)

module.exports =
  PicoStrategy: PicoStrategy
  init: init
