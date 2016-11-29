Backbone = require('backbone')
request = require('request')
Promise = require('bluebird')
Promise.promisifyAll(request)
_ = require('lodash')

# path = require('path')
# sepia = require('sepia')
# sepia.fixtureDir(path.join(process.cwd(), 'tmp'))
# sepia.configure({
#   verbose: true
#   debug: true
# })

class ZenProspect
  @configure: ({authToken}) ->
    ZenProspect.authToken = authToken
  
  @stageIds = {
    'Do Not Contact': '57290b9c7ff0bb3b3ef2bebb'
    'Cold': '57290b9c7ff0bb3b3ef2beb7'
    'Approaching': '57290b9c7ff0bb3b3ef2beb8'
  }
    
# TODO: Just use backbone model as a base?
ZenProspect.Contact = class Contact extends Backbone.Model
  constructor: (attrs = {}) ->
    @attributes = _.merge {}, attrs

  requestOptions: ->
    json: true
    headers:
      "Content-Type": "application/json"
    url: @url()

  url: ->
    "https://www.zenprospect.com/api/v1/contacts/#{@attributes.id or ''}?codecombat_special_auth_token=#{ZenProspect.authToken}"

  fetch: ->
    req = request.getAsync @requestOptions()
    req.then (response) ->
      if response.body?.contact
        _.assign @attributes, response.body.contact
    req

  update: (attrs) ->
    _.assign @attributes, attrs
    request.putAsync _.merge @requestOptions(), { body: attrs }
    
  save: ->
    console.log @url()
    req = request.postAsync _.merge @requestOptions(), { body: @attributes }
    req.then (response) =>
      _.assign @attributes, response.body.contact
    req
    
  toCsvLine: ->
    [
      @name,
      @email,
      @phone,
      @title,
      @organization,
      @school_name,
      @district,
      @nces_school_id,
      @nces_district_id,
      new Date().toISOString(),
      @error
    ].map((s) -> "\"#{s || ''}\"").join(',') + '\n';
    
ZenProspect.Contacts = class Contacts extends Backbone.Collection
  model: ZenProspect.Contact
    
  @search: (query, done) ->
    queryString = "codecombat_special_auth_token=#{ZenProspect.authToken}&q_keywords=#{query}"
    options = {
      url: "https://www.zenprospect.com/api/v1/contacts/search?#{queryString}",
      headers: {
        'Accept': 'application/json'
      }
      json: true
    };
    request.getAsync(options).then (response) ->
      wrapped = new ZenProspect.Contacts(response?.body?.contacts)
      done(null, wrapped)
    .catch (err) ->
      console.log err
      done(err, null)

Promise.promisifyAll(ZenProspect.Contacts)


module.exports = ZenProspect
