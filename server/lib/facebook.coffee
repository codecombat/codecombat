request = require 'request'
Promise = require 'bluebird'

module.exports.fetchMe = (facebookAccessToken) ->
  return new Promise (resolve, reject) ->
    fields = ['email', 'first_name', 'last_name', 'gender'].join(',')
    qs = { access_token: facebookAccessToken, fields }
    url = "https://graph.facebook.com/v2.8/me"
    request.get url, {json: true, qs}, (err, res) ->
      if err
        reject(err)
      else
        resolve(res.body)
