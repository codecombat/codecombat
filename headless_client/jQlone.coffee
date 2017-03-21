#jQuery for node, reimplementated for compatibility purposes. Poorly.
#Leaves out all the DOM stuff but allows ajax.
_ = require 'lodash'
request = require 'request'
Deferred = require 'JQDeferred'
module.exports = $ = (input) ->
  console.log 'Ignored jQuery: ', input if $._debug
  append: (input)-> exports: ()->

# Non-standard jQuery stuff. Don't use outside of server.
$._cookies = request.jar()

$.when = Deferred.when
$.ajax = (options) ->
  responded = false
  url = options.url
  if url.indexOf('http')
    url = '/' + url unless url[0] is '/'
    url = $._server + url

  console.log 'Requesting: ' + JSON.stringify options if $._debug
  console.log 'URL: ' + url if $._debug
  if /db\/thang.type\/names/.test url
    url += '?_=' + Math.random()  # Make sure that the ThangType names don't get cached, since response varies based on parameters in a way that apparently doesn't work in this hacky implementation.
  deferred = Deferred()
  request
    url: url
    jar: $._cookies
    json: options.parse
    method: options.type
    body: options.data
    , (error, response, body) ->
      console.log 'HTTP Request:' + JSON.stringify options if $._debug and not error
      if responded
        console.log '\t↳Already returned before.' if $._debug
        return
      if (error)
        console.warn "\t↳Returned: error: #{error}"
        deferred.reject(error)
      else
        console.log "\t↳Returned: statusCode #{response.statusCode}: #{if options.parse then JSON.stringify body else body}" if $._debug
        deferred.resolve(body, response, status: response.statusCode)

      statusCode = response.statusCode if response?
      options.complete(status: statusCode) if options.complete?
      responded = true
  deferred.promise().done(options.success).fail(options.error)

$.extend = (deep, into, from) ->
  copy = _.clone(from, deep)
  if into
    _.assign into, copy
    copy = into
  copy

$.isArray = (object) ->
  _.isArray object

$.isPlainObject = (object) ->
  _.isPlainObject object
