CocoView = require 'views/core/CocoView'
template = require 'templates/play/menu/guide-view'
Article = require 'models/Article'
SubscribeModal = require 'views/core/SubscribeModal'
utils = require 'core/utils'

# let's implement this once we have the docs database schema set up

module.exports = class LevelGuideView extends CocoView
  template: template
  id: 'guide-view'
  className: 'tab-pane'
  helpVideoHeight: '295'
  helpVideoWidth: '471'

  events:
    'click .start-subscription-button': 'clickSubscribe'

  constructor: (options) ->
    @levelSlug = options.level.get('slug')
    @sessionID = options.session.get('_id')
    @requiresSubscription = not me.isPremium()
    @helpVideos = options.level.get('helpVideos') ? []
    @trackedHelpVideoStart = @trackedHelpVideoFinish = false
    # A/B Testing video tutorial styles
    @helpVideosIndex = me.getVideoTutorialStylesIndex(@helpVideos.length)
    @helpVideo = @helpVideos[@helpVideosIndex] if @helpVideos.length > 0
    @videoLocked = not @helpVideo?.free and @requiresSubscription

    @firstOnly = options.firstOnly
    @docs = options?.docs ? options.level.get('documentation') ? {}
    general = @docs.generalArticles or []
    specific = @docs.specificArticles or []

    articles = options.supermodel.getModels(Article)
    articleMap = {}
    articleMap[article.get('original')] = article for article in articles
    general = (articleMap[ref.original] for ref in general)
    general = (article.attributes for article in general when article)

    @docs = specific.concat(general)
    @docs = $.extend(true, [], @docs)
    @docs = [@docs[0]] if @firstOnly and @docs[0]
    doc.html = marked(@filterCodeLanguages(utils.i18n(doc, 'body'))) for doc in @docs
    doc.name = (utils.i18n doc, 'name') for doc in @docs
    doc.slug = _.string.slugify(doc.name) for doc in @docs
    super()

  destroy: ->
    if @vimeoListenerAttached
      if window.addEventListener
        window.removeEventListener('message', @onMessageReceived, false)
      else
        window.detachEvent('onmessage', @onMessageReceived, false)
    super()

  getRenderData: ->
    c = super()
    c.docs = @docs
    c.showVideo = @helpVideos.length > 0
    c.videoLocked = @videoLocked
    c

  afterRender: ->
    super()
    if @docs.length is 1 and @helpVideos.length > 0
      @setupVideoPlayer() unless @videoLocked
    else
      # incredible hackiness. Getting bootstrap tabs to work shouldn't be this complex
      @$el.find('.nav-tabs li:first').addClass('active')
      @$el.find('.tab-content .tab-pane:first').addClass('active')
      @$el.find('.nav-tabs a').click(@clickTab)
    @playSound 'guide-open'

  filterCodeLanguages: (text) ->
    currentLanguage = me.get('aceConfig')?.language or 'python'
    excludedLanguages = _.without ['javascript', 'python', 'coffeescript', 'clojure', 'lua', 'io'], currentLanguage
    exclusionRegex = new RegExp "```(#{excludedLanguages.join('|')})\n[^`]+```\n?", 'gm'
    text.replace exclusionRegex, ''

  clickSubscribe: (e) ->
    level = @levelSlug # Save ref to level slug
    @openModalView new SubscribeModal()
    window.tracker?.trackEvent 'Show subscription modal', category: 'Subscription', label: 'help video clicked', level: level

  clickTab: (e) =>
    @$el.find('li.active').removeClass('active')
    @playSound 'guide-tab-switch'

  afterInsert: ->
    super()
    Backbone.Mediator.publish 'level:docs-shown', {}

  onHidden: ->
    createjs?.Sound?.setVolume?(@volume ? ( me.get('volume') ? 1.0))
    Backbone.Mediator.publish 'level:docs-hidden', {}

  onShown: ->
    # TODO: Disable sound only when video is playing?
    @volume ?= me.get('volume') ? 1.0
    createjs?.Sound?.setVolume(0.0)

  onStartHelpVideo: ->
    unless @trackedHelpVideoStart
      window.tracker?.trackEvent 'Start help video', level: @levelSlug, ls: @sessionID, style: @helpVideo?.style
      @trackedHelpVideoStart = true

  onFinishHelpVideo: ->
    unless @trackedHelpVideoFinish
      window.tracker?.trackEvent 'Finish help video', level: @levelSlug, ls: @sessionID, style: @helpVideo?.style
      @trackedHelpVideoFinish = true

  setupVideoPlayer: () ->
    return unless @helpVideo
    # Always use HTTPS
    # TODO: Not specifying the protocol should work based on Vimeo docs, but breaks postMessage/eventing in practice.
    url = "https:" + @helpVideo.url.substr @helpVideo.url.indexOf '/'
    @setupVimeoVideoPlayer url

  setupVimeoVideoPlayer: (helpVideoURL) ->
    # Setup Vimeo player
    # https://developer.vimeo.com/player/js-api#universal-with-postmessage

    # Create Vimeo iframe player
    tag = document.createElement('iframe')
    tag.id = 'help-video-player'
    tag.src = helpVideoURL + "?api=1&badge=0&byline=0&portrait=0&title=0"
    tag.height = @helpVideoHeight
    tag.width = @helpVideoWidth
    tag.allowFullscreen = true
    @$el.find('#help-video-player').replaceWith(tag)

    @onMessageReceived = (e) =>
      data = JSON.parse(e.data)
      if data.event is 'ready'
        # Vimeo player is ready, can now hook up other events
        # https://developer.vimeo.com/player/js-api#events
        player = $('#help-video-player')[0]
        player.contentWindow.postMessage JSON.stringify(method: 'addEventListener', value: 'play'), helpVideoURL
        player.contentWindow.postMessage JSON.stringify(method: 'addEventListener', value: 'finish'), helpVideoURL
      else if data.event is 'play'
        @onStartHelpVideo?()
      else if data.event is 'finish'
        @onFinishHelpVideo?()

    # Listen for Vimeo player 'ready'
    if window.addEventListener
      window.addEventListener('message', @onMessageReceived, false)
    else
      window.attachEvent('onmessage', @onMessageReceived, false)
    @vimeoListenerAttached = true
