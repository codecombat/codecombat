###
This file will simulate games on node.js by emulating the browser environment.
At some point, most of the code can be merged with Simulator.coffee
###

bowerComponentsPath = "./bower_components/"
headlessClientPath = "./headless_client/"

# SETTINGS
options =
  workerCode: require headlessClientPath + 'worker_world'
  debug: false # Enable logging of ajax calls mainly
  testing: true # Instead of simulating 'real' games, use the same one over and over again. Good for leak hunting.
  testFile: require headlessClientPath + 'test.js'
  leakTest: false # Install callback that tries to find leaks automatically
  exitOnLeak: false # Exit if leak is found. Only useful if leaktest is set to true, obviously.
  heapdump: false # Dumps the whole heap after every pass. The heap dumps can then be viewed in Chrome browser.
  headlessClient: true

options.heapdump = require('heapdump') if options.heapdump
server = if options.testing then "http://127.0.0.1:3000" else "http://codecombat.com"

# Disabled modules
disable = [
  'lib/AudioPlayer'
  'locale/locale'
  '../locale/locale'
]


# Start of the actual code. Setting up the enivronment to match the environment of the browser

# the path used for the loader. __dirname is module dependent.
path = __dirname

m = require 'module'
request = require 'request'

originalLoader = m._load

unhook = () ->
  m._load = originalLoader

hook = () ->
  m._load = hookedLoader


JASON = require 'jason'

# Global emulated stuff
GLOBAL.window = GLOBAL
GLOBAL.document = location: pathname: "headless_client"
GLOBAL.console.debug = console.log

GLOBAL.Worker = require('webworker-threads').Worker
Worker::removeEventListener = (what) ->
  if what is 'message'
    @onmessage = -> #This webworker api has only one event listener at a time.

GLOBAL.tv4 = require('tv4').tv4

GLOBAL.marked = setOptions: ->

GLOBAL.navigator =
#  userAgent: "nodejs"
  platform: "headless_client"
  vendor: "codecombat"
  opera: false

store = {}
GLOBAL.localStorage =
    getItem: (key) => store[key]
    setItem: (key, s) => store[key] = s
    removeItem: (key) => delete store[key]

# Hook node.js require. See https://github.com/mfncooper/mockery/blob/master/mockery.js
# The signature of this function *must* match that of Node's Module._load,
# since it will replace that.
# (Why is there no easier way?)
hookedLoader = (request, parent, isMain) ->
  if request == 'lib/God'
    request = 'lib/Buddha'

  if request in disable or ~request.indexOf('templates')
    console.log 'Ignored ' + request if options.debug
    return class fake
  else if '/' in request and not (request[0] is '.') or request is 'application'
    request = path + '/app/' + request
  else if request is 'underscore'
    request = 'lodash'

  console.log "loading " + request if options.debug
  originalLoader request, parent, isMain


#jQuery wrapped for compatibility purposes. Poorly.
GLOBAL.$ = GLOBAL.jQuery = (input) ->
  console.log 'Ignored jQuery: ' + input if options.debug
  append: (input)-> exports: ()->

cookies = request.jar()

$.ajax = (options) ->
  responded = false
  url = options.url
  if url.indexOf('http')
    url = '/' + url unless url[0] is '/'
    url = server + url

  data = options.data


  #if (typeof data) is 'object'
    #console.warn JSON.stringify data
    #data = JSON.stringify data

  console.log "Requesting: " + JSON.stringify options if options.debug
  console.log "URL: " + url if options.debug
  request
    url: url
    jar: cookies
    json: options.parse
    method: options.type
    body: data
    , (error, response, body) ->
      console.log "HTTP Request:" + JSON.stringify options if options.debug and not error

      if responded
        console.log "\t↳Already returned before." if options.debug
        return

      if (error)
        console.warn "\t↳Returned: error: #{error}"
        options.error(error) if options.error?
      else
        console.log "\t↳Returned: statusCode #{response.statusCode}: #{if options.parse then JSON.stringify body else body}" if options.debug
        options.success(body, response, status: response.statusCode) if options.success?


      statusCode = response.statusCode if response?
      options.complete(status: statusCode) if options.complete?
      responded = true

$.extend = (deep, into, from) ->
  copy = _.clone(from, deep);
  if into
    _.assign into, copy
    copy = into
  copy

$.isArray = (object) ->
  _.isArray object

$.isPlainObject = (object) ->
  _.isPlainObject object


do (setupLodash = this) ->
  GLOBAL._ = require 'lodash'
  _.str = require 'underscore.string'
  _.string = _.str
  _.mixin _.str.exports()


# load Backbone. Needs hooked loader to reroute underscore to lodash.
hook()
GLOBAL.Backbone = require bowerComponentsPath + 'backbone/backbone'
unhook()
Backbone.$ = $

require bowerComponentsPath + 'validated-backbone-mediator/backbone-mediator'
# Instead of mediator, dummy might be faster yet suffice?
#Mediator = class Mediator
#  publish: (id, object) ->
#    console.Log "Published #{id}: #{object}"
#  @subscribe: () ->
#  @unsubscribe: () ->

GLOBAL.Aether = require 'aether'

# Set up new loader.
hook()

login = require './login.coffee' #should contain an object containing they keys 'username' and 'password'


#Login user and start the code.
$.ajax
  url: '/auth/login'
  type: "POST"
  data: login
  parse: true
  error: (error) -> "Bad Error. Can't connect to server or something. " + error
  success: (response) ->
    console.log "User: " + response
    GLOBAL.window.userObject = response # JSON.parse response

    User = require 'models/User'

    World = require 'lib/world/world'
    LevelLoader = require 'lib/LevelLoader'
    GoalManager = require 'lib/world/GoalManager'

    SuperModel = require 'models/SuperModel'

    log = require 'winston'

    CocoClass = require 'lib/CocoClass'

    Simulator = require 'lib/simulator/Simulator'

    sim = new Simulator options

    sim.fetchAndSimulateTask()
