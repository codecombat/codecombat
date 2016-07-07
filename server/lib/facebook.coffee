request = require 'request'
Promise = require 'bluebird'

module.exports.fetchMe = (facebookAccessToken) ->
  return new Promise (resolve, reject) ->
    url = "https://graph.facebook.com/me?access_token=#{facebookAccessToken}"
    request.get url, {json: true}, (err, res) ->
      if err
        reject(err)
      else
        resolve(res.body)
