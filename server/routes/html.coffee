User = require '../users/User'
UserHandler = require '../users/user_handler'
LevelSession = require '../levels/sessions/LevelSession'
Campaign = require '../campaigns/Campaign'
Level = require '../levels/Level'
config = require '../../server_config'
log = require 'winston'
Mandate = require '../models/Mandate'
utils = require '../lib/utils'
cheerio = require 'cheerio'
en = require '../../app/locale/en'
_ = require 'lodash'

translate = (key) ->
  html = /^\[html\]/.test(key)
  key = key.substring(6) if html

  t = en.translation
  #TODO: Replace with _.property when we get modern lodash
  path = key.split(/[.]/)
  while path.length > 0
    k = path.shift()
    t = t[k]
    return key unless t?

  return out =
    text: t
    html: html


makeConext = (req) ->
  view =
    isIPadBrowser:  -> false
    isMobile:  -> false
    isOldBrowser: -> false
    forumLink: -> 'http://discourse.codecombat.com/'
    showAds: -> true

  me = 
    getPhotoURL:  -> ''
    isAnonymous:  -> true
    get: (what) -> ''
    level:  -> ''
    displayName:  -> ''
    isTeacher:  -> false
    isOnPremiumServer: -> false
    isAdmin: -> false
    gems: -> 0
    isPremium: -> false

  opts = 
    view: view
    me: me
    i18n: (a, b) ->
      return a.i18n.en[a] if 'i18n' in a
      a[b]

injectView = (res, view, opts, next) ->
  res.render (view + '.jade'), opts, (err, data) ->
    if err
      res.locals.pageContent =  ('<pre>' + err + '</pre>')
      return next()

    c = cheerio.load(data)
    name = view.split(/\//).pop()
    name += '-view' unless /-view$/.test(name)
    roots = c.root().children()
    elms = c('[data-i18n]')
    elms.each (i, e) ->
      i = c(this)
      t = translate(i.data('i18n'))
      if t.html
        i.html(t.text)
      else
        i.text(t.text);

    o = cheerio.load("<div>")
    container = o('div')
    container.attr('id', name)
    container.html(c.html())

    unless o('.style-flat').length > 0
      container.addClass('site-chrome')
      container.addClass('show-background') unless opts.showBackground is false
      container.attr('style', 'display: none') if opts.dontActuallyShow

    res.locals.pageContent =  o.html()
    next()

exports.setup = (app) ->
  handle = (route, view, next) ->
    app.get route, (req, res) ->
      try
        next req, res, (opts) ->
          injectView res, view, opts, ->
            renderMain req, res
      catch e
        renderMain req, res

  handleSimply = (route, view, extra) ->
    handle route, view, (req, res, next) ->
      opts = makeConext req
      if extra
        _.extend opts.view, extra(req, res) 
      
      next(opts)

  handleSimply '/', 'new-home-view', ->
    justPlaysCourses: -> false
    courses: {models: []}

  handleSimply '/about', 'about'
  handleSimply '/community', 'community-view'
  handleSimply '/contribute', 'contribute/contribute'
  handleSimply '/teachers/quote', 'request-quote-view', ->
    trialRequest:
      isNew: -> true
  handleSimply '/courses/teachers', 'courses/teacher-courses-view', ->
    classrooms:
      models: []
    courses:
      models: []
  handleSimply '/legal', 'legal'
  handleSimply '/privacy', 'privacy' 

  handle '/play', 'play/campaign-view', (req, res, next) ->
    opts = makeConext req
    Campaign.find({type: 'hero'}).exec (err, docs) ->
      levels = {}
      docs.forEach (m,k) -> 
        v = m.toObject()
        levels[v.slug] =
          attributes:
            fullName: v.name
            name: v.name
            slug: v.slug
            description: v.description
            i18n: v.i18n
          get: (name) -> v[name]

      res.locals.campaigns = levels
      res.locals.adjacentCampaigns = []
      res.locals.levels = []
      opts.showBackground = false
      next opts

  handle '/play/:campaign', 'play/campaign-view', (req, res, next) ->
    opts = makeConext req
    Campaign.findOne({type: 'hero', slug: req.params.campaign}).exec (err, doc) ->
      levels = {}
      v = doc.toObject()
      
      res.locals.campaign = 
        attributes:
            fullName: v.name
            name: v.name
            slug: v.slug
            description: v.description
            i18n: v.i18n
          get: (name) -> v[name]
      res.locals.adjacentCampaigns = []
      res.locals.levelStatusMap = {}
      res.locals.levelDifficultyMap = {}
      res.locals.levelPlayCountMap = {}
      res.locals.marked = (o) -> o
      res.locals.levels = v.levels
      opts.dontActuallyShow = true
      opts.showBackground = false
      next opts

  handle '/play/level/:level', 'play/level', (req, res, next) ->
    opts = makeConext req
    Level.findOne({slug: req.params.level}).exec (err, doc) ->
      opts.showBackground = false
      opts.dontActuallyShow = true
      next opts


exports.renderMain = renderMain = (req,res) ->
  user = if req.user then JSON.stringify(UserHandler.formatEntity(req, req.user)).replace(/\//g, '\\/') else '{}'
  res.locals.pageContent = res.locals.pageContent || '!'
  Mandate.findOne({}).cache(5 * 60 * 1000).exec (err, mandate) ->
    if err
      log.error "Error getting mandate config: #{err}"
      configData = {}
    else
      configData =  _.omit mandate?.toObject() or {}, '_id'
    configData.picoCTF = config.picoCTF
    configData.production = config.isProduction
    
    res.locals.serverConfig = configData
    res.locals.userObjectTag = user
    res.locals.amActually = req.session.amActually

    res.header 'Cache-Control', 'no-cache, no-store, must-revalidate'
    res.header 'Pragma', 'no-cache'
    res.header 'Expires', 0
    res.render 'main.jade'
