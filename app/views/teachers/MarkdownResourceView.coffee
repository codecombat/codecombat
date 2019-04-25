require('app/styles/teachers/markdown-resource-view.sass')
# This is the generic view for rendering content from /app/assets/markdown

RootView = require 'views/core/RootView'
utils = require 'core/utils'
ace = require('lib/aceContainer')
aceUtils = require 'core/aceUtils'

module.exports = class MarkdownResourceView extends RootView
  id: 'markdown-resource-view'
  template: require 'templates/teachers/markdown-resource-view'

  initialize: (options, @name) ->
    super(options)
    @content = ''
    @loadingData = true
    me.getClientCreatorPermissions()?.then(() => @render?())
    $.get '/markdown/' + @name + '.md', (data) =>
      unless /<!doctype html>/i.test(data)
        renderer = new marked.Renderer()
        linkIDs = new Set
        renderer.heading = (text, level) =>
          if level not in [2, 3] or (_.string.startsWith(@name, 'faq') and level is 2)
            return "<h#{level}>#{text}</h#{level}>"
          linkID = _.string.slugify text
          if not linkID.replace(/(codecombat|-)/g, '') or linkIDs.has linkID
            linkID = 'header-' + linkIDs.size
          linkIDs.add linkID
          return "<h#{level}><a name='#{linkID}' id='#{linkID}' href='\##{linkID}''><span class='header-link'></span></a>#{text}</h#{level}>"

        i = 0
        @content = marked(data, {sanitize: false, renderer}).replace /<\/h5/g, () ->
          if i++ == 0
            '</h5'
          else
            align = if me.get('preferredLanguage') in ['he', 'ar', 'fa', 'ur'] then 'left' else 'right'
            buttonText = $.i18n.t 'teacher.back_to_top'
            "<a class='pull-#{align} btn btn-md btn-navy back-to-top' href='#top'>#{buttonText}</a></h5"

      if @name is 'cs1'
        $('body').append($("<img src='https://code.org/api/hour/begin_code_combat_teacher.png' style='visibility: hidden;'>"))
      @loadingData = false
      @render()


  afterRender: ->
    super()
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
