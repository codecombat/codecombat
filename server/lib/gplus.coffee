request = require 'request'
Promise = require 'bluebird'

module.exports.fetchMe = (gplusAccessToken) ->
  return new Promise (resolve, reject) ->
    url = "https://www.googleapis.com/oauth2/v2/userinfo?access_token=#{gplusAccessToken}"
    request.get url, {json: true}, (err, res) ->
      if err
        reject(err)
      else
        resolve(res.body)
