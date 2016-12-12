RootView = require 'views/core/RootView'
utils = require 'core/utils'

module.exports = class MarkdownResourceView extends RootView
  id: 'markdown-resource-view'
  template: require 'templates/teachers/markdown-resource-view'
  initialize: (options, @name) ->
    super(options)
    @content = ''
    $.get '/markdown/' + @name + '.md', (data) =>
      if data.indexOf('<!doctype html>') is -1
        i = 0
        @content = marked(data, sanitize: false).replace /<\/h5/g, () ->
          if i++ == 0
            '</h5'
          else
            '<a class="pull-right btn btn-md btn-navy back-to-top" href="#logo-img">Back to top</a></h5'

      if @name is 'cs1'
        $('body').append($("<img src='https://code.org/api/hour/begin_code_combat_teacher.png' style='visibility: hidden;'>"))

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

      aceEditor = utils.initializeACE c[0], lang
      aceEditor.setShowInvisibles false
      aceEditor.setBehavioursEnabled false
      aceEditor.setAnimatedScroll false
      aceEditor.$blockScrolling = Infinity
