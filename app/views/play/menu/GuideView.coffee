CocoView = require 'views/core/CocoView'
template = require 'templates/play/menu/guide-view'
Article = require 'models/Article'
SubscribeModal = require 'views/core/SubscribeModal'
utils = require 'core/utils'

module.exports = class LevelGuideView extends CocoView
  template: template
  id: 'guide-view'
  className: 'tab-pane'
  helpVideoHeight: '295'
  helpVideoWidth: '471'

  events:
    'click .start-subscription-button': 'clickSubscribe'

  constructor: (options) ->
    super options
    @levelSlug = options.level.get('slug')
    @sessionID = options.session.get('_id')
    @requiresSubscription = not me.isPremium()
    @isCourseLevel = options.level.get('type', true) in ['course', 'course-ladder']
    @helpVideos = if @isCourseLevel then [] else options.level.get('helpVideos') ? []
    @trackedHelpVideoStart = @trackedHelpVideoFinish = false
    # A/B Testing video tutorial styles
    @helpVideosIndex = me.getVideoTutorialStylesIndex(@helpVideos.length)
    @helpVideo = @helpVideos[@helpVideosIndex] if @helpVideos.length > 0 and not @isCourseLevel
    @videoLocked = not (@helpVideo?.free or @isCourseLevel) and @requiresSubscription

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
    @addPicoCTFProblem() if window.serverConfig.picoCTF
    doc.html = marked(utils.filterMarkdownCodeLanguages(utils.i18n(doc, 'body'), options.session.get('codeLanguage'))) for doc in @docs
    doc.slug = _.string.slugify(doc.name) for doc in @docs
    doc.name = (utils.i18n doc, 'name') for doc in @docs

  destroy: ->
    if @vimeoListenerAttached
      if window.addEventListener
        window.removeEventListener('message', @onMessageReceived, false)
      else
        window.detachEvent('onmessage', @onMessageReceived, false)
    oldEditor.destroy() for oldEditor in @aceEditors ? []
    super()

  getRenderData: ->
    c = super()
    c.docs = @docs
    c.showVideo = @helpVideos.length > 0 unless @isCourseLevel
    c.videoLocked = @videoLocked
    c

  afterRender: ->
    super()
    @setupVideoPlayer() unless @videoLocked
    if @docs.length + @helpVideos.length > 1
      if @helpVideos.length
        startingTab = 0
      else
        startingTab = _.findIndex @docs, slug: 'overview'
        startingTab = 0 if startingTab is -1
      # incredible hackiness. Getting bootstrap tabs to work shouldn't be this complex
      @$el.find(".nav-tabs li:nth(#{startingTab})").addClass('active')
      @$el.find(".tab-content .tab-pane:nth(#{startingTab})").addClass('active')
      @$el.find('.nav-tabs a').click(@clickTab)
      @$el.addClass 'has-tabs'
    @configureACEEditors()
    @playSound 'guide-open'

  configureACEEditors: ->
    oldEditor.destroy() for oldEditor in @aceEditors ? []
    @aceEditors = []
    aceEditors = @aceEditors
    codeLanguage = @options.session.get('codeLanguage') or me.get('aceConfig')?.language or 'python'
    @$el.find('pre').each ->
      aceEditor = utils.initializeACE @, codeLanguage
      aceEditors.push aceEditor

  clickSubscribe: (e) ->
    level = @levelSlug # Save ref to level slug
    @openModalView new SubscribeModal()
    # TODO: Added levelID on 2/9/16. Remove level property and associated AnalyticsLogEvent 'properties.level' index later.
    window.tracker?.trackEvent 'Show subscription modal', category: 'Subscription', label: 'help video clicked', level: level, levelID: level

  clickTab: (e) =>
    @$el.find('li.active').removeClass('active')
    @playSound 'guide-tab-switch'

  afterInsert: ->
    super()
    Backbone.Mediator.publish 'level:docs-shown', {}

  onHidden: ->
    if @vimeoListenerAttached
      player = @$('#help-video-player')[0]
      player.contentWindow.postMessage JSON.stringify(method: 'pause'), '*'
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
    tag.mozAllowFullscreen = true
    $tag = $(tag)
    $tag.attr('webkitallowfullscreen', true) # strong arm Safari into working
    @$el.find('#help-video-player').replaceWith($tag)

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

  addPicoCTFProblem: ->
    return unless problem = @options.level.picoCTFProblem
    @docs = [name: 'Intro', body: '', slug: 'intro'] unless @docs.length
    for doc in @docs when doc.name in ['Overview', 'Intro']
      doc.body += """
        ### #{problem.name}

        #{problem.description}

        #{problem.category} - #{problem.score} points

        Hint: #{problem.hints}
      """.replace /<p>(.*?)<\/p>/gi, '$1'
