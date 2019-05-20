require('app/styles/teachers/markdown-resource-view.sass')
RootView = require 'views/core/RootView'
api = require 'core/api'
ace = require('lib/aceContainer')
aceUtils = require 'core/aceUtils'
APCSPLanding = require('./APCSPLanding').default

module.exports = class DynamicAPCSPView extends RootView
  id: 'dynamic-apcsp-view'
  template: require 'templates/teachers/dynamic-apcsp-view'

  getMeta: ->
    title: $.i18n.t 'apcsp.title'
    meta: [
      { vmid: 'meta-description', name: 'description', content: $.i18n.t 'apcsp.meta_description' }
    ]

  initialize: (options, @name) ->
    super(options)
    @name ?= 'index'
    @content = ''
    @loadingData = true
    me.getClientCreatorPermissions()?.then(() => @render?())
    unless @cannotAccess()
      if _.string.startsWith(@name, 'markdown/')
        unless _.string.endsWith(@name, '.md')
          @name = @name + '.md'
        promise = api.markdown.getMarkdownFile(@name.replace('markdown/', ''))
      else
        promise = api.apcsp.getAPCSPFile(@name)

      promise.then((data) =>
        @content = marked(data, sanitize: false)
        @loadingData = false
        @render()
      ).catch((error) =>
        @loadingData = false
        if error.code is 404
          @notFound = true
          @render()
        else
          console.error(error)
          @error = error.message
          @render()
      )

  cannotAccess: ->
    return me.isAnonymous() or !me.isTeacher() or !me.get('verifiedTeacher')

  afterRender: ->
    super()
    if @cannotAccess()
      new APCSPLanding({
        el: @$('#apcsp-landing')[0]
      })

    @$el.find('pre>code').each ->
      els = $(@)
      c = els.parent()
      lang = els.attr('class')
      if lang
        lang = lang.replace(/^lang-/,'')
      else
        lang = 'python'

      aceEditor = aceUtils.initializeACE c[0], lang
      aceEditor.setShowInvisibles false
      aceEditor.setBehavioursEnabled false
      aceEditor.setAnimatedScroll false
      aceEditor.$blockScrolling = Infinity
    if _.contains(location.href, '#')
      _.defer =>
        # Remind the browser of the fragment in the URL, so it jumps to the right section.
        location.href = location.href
