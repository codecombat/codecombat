require('app/styles/play/level/web-surface-view.sass')
CocoView = require 'views/core/CocoView'
template = require 'templates/play/level/web-surface-view'
HtmlExtractor = require 'lib/HtmlExtractor'

module.exports = class WebSurfaceView extends CocoView
  id: 'web-surface-view'
  template: template

  subscriptions:
    'tome:html-updated': 'onHTMLUpdated'
    'web-dev:hover-line': 'onHoverLine'
    'web-dev:stop-hovering-line': 'onStopHoveringLine'

  initialize: (options) ->
    @goals = (goal for goal in options.goalManager?.goals ? [] when goal.html)
    # Consider https://www.npmjs.com/package/css-select to do this on virtualDom instead of in iframe on concreteDOM
    super(options)

  getRenderData: ->
    _.merge super(), { fullUnsafeContentHostname: serverConfig.fullUnsafeContentHostname }

  afterRender: ->
    super()
    @iframe = @$('iframe')[0]
    $(@iframe).on 'load', (e) =>
      window.addEventListener 'message', @onIframeMessage
      @iframeLoaded = true
      @onIframeLoaded?()
      @onIframeLoaded = null

  # TODO: make clicking Run actually trigger a 'create' update here (for resetting scripts)

  onHTMLUpdated: (e) ->
    unless @iframeLoaded
      return @onIframeLoaded = => @onHTMLUpdated e unless @destroyed

    # TODO: pull out the actual scripts, styles, and body/elements they are doing so we can merge them with our initial structure on the other side
    { @virtualDom, styles, scripts } = HtmlExtractor.extractStylesAndScripts(e.html)
    @cssSelectors = HtmlExtractor.extractCssSelectors(styles, scripts)
    # TODO: Do something better than this hack for detecting which lines are CSS, which are HTML
    @rawCssLines = HtmlExtractor.extractCssLines(styles)
    @rawJQueryLines = HtmlExtractor.extractJQueryLines(scripts)

    messageType = if e.create or not @virtualDom then 'create' else 'update'
    @iframe.contentWindow.postMessage {type: messageType, dom: @virtualDom, styles, scripts, goals: @goals}, '*'

  combineNodes: (type, nodes) ->
    if _.any(nodes, (node) -> node.type isnt type)
      throw new Error("Can't combine nodes of different types. (Got #{nodes.map (n) -> n.type})")
    children = nodes.map((n) -> n.children).reduce(((a,b) -> a.concat(b)), [])
    if _.isEmpty(children)
      deku.element(type, {})
    else
      deku.element(type, {}, children)

  onStopHoveringLine: ->
    @iframe.contentWindow.postMessage({ type: 'highlight-css-selector', selector: '' }, '*')

  onHoverLine: ({ row, line }) ->
    if _.contains(@rawCssLines, line)
      # They're hovering over lines of CSS, not HTML
      trimLine = (line.match(/\s(.*)\s*{/)?[1] or line).trim().split(/ +/).join(' ')
      hoveredCssSelector = _.find @cssSelectors, (selector) ->
        trimLine is selector
    else if _.contains(@rawJQueryLines, line)
      # It's a jQuery call
      trimLine = (line.match(/\$\(\s*['"](.*)['"]\s*\)/)?[1] or '').trim()
      hoveredCssSelector = _.find @cssSelectors, (selector) ->
        trimLine is selector
    else
      # They're not hovering over a line with a selector, so don't highlight anything
      hoveredCssSelector = ''
    @iframe.contentWindow.postMessage({ type: 'highlight-css-selector', selector: hoveredCssSelector }, '*')
    null

  onIframeMessage: (event) =>
    origin = event.origin or event.originalEvent.origin
    unless new RegExp("^https?:\/\/#{serverConfig.fullUnsafeContentHostname}$").test origin
      return console.log 'Ignoring message from bad origin:', origin
    unless event.source is @iframe.contentWindow
      return console.log 'Ignoring message from somewhere other than our iframe:', event.source
    switch event.data.type
      when 'goals-updated'
        Backbone.Mediator.publish 'god:new-html-goal-states', goalStates: event.data.goalStates, overallStatus: event.data.overallStatus
      when 'error'
        # NOTE: The line number in this is relative to the script tag, not the user code. The offset is added in SpellView.
        Backbone.Mediator.publish 'web-dev:error', _.pick(event.data, ['message', 'line', 'column', 'url'])
      else
        console.warn 'Unknown message type', event.data.type, 'for message', event, 'from origin', origin

  destroy: ->
    window.removeEventListener 'message', @onIframeMessage
    super()
