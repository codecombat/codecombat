require('app/styles/teachers/markdown-resource-view.sass')
# This is the generic view for rendering content from /app/assets/markdown

RootView = require 'views/core/RootView'
utils = require 'core/utils'
ace = require('lib/aceContainer')
aceUtils = require 'core/aceUtils'

module.exports = class MarkdownResourceView extends RootView
  id: 'markdown-resource-view'
  template: require 'app/templates/teachers/markdown-resource-view'

  events:
    'click .print-btn': 'onClickPrint'

  initialize: (options, @name) ->
    super(options)
    @content = ''
    @loadingData = true
    me.getClientCreatorPermissions()?.then(() => @render?())
    if utils.isOzaria and @name is 'getting-started'
      @name = 'getting-started-with-ozaria'
    $.get '/markdown/' + @name + '.md', (data, what, who, how) =>
      if /<!doctype html>/i.test(data)
        # Not found
        if utils.isOzaria
          Backbone.Mediator.publish 'router:navigate', route: '/teachers/resources'
          noty text: "#{$.i18n.t('not_found.page_not_found')}: #{@name}", layout: 'center', type: 'warning', killer: false, timeout: 6000
          return
      else
        renderer = new marked.Renderer()
        linkIDs = new Set
        renderer.heading = (text, level) =>
          if level not in [2, 3] or (_.string.startsWith(@name, 'faq') and level is 2)
            return "<h#{level}>#{text}</h#{level}>"
          linkID = _.string.slugify text
          if not linkID.replace(/(codecombat|-)/g, '') or linkIDs.has linkID
            linkID = 'header-' + linkIDs.size
          linkIDs.add linkID
          return "<h#{level}><a name='#{linkID}' id='#{linkID}' href='\##{linkID}'' class='header-link'></a>#{text}</h#{level}>"

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

  onClickPrint: ->
    window.tracker?.trackEvent 'Teachers Click Print Resource', { category: 'Teachers', label: @name }

  showTeacherLegacyNav: ->
    # Hack to hide legacy dashboard navigation from faq page
    if @name is 'faq'
      return false
    return true

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
