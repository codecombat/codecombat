RootView = require 'views/core/RootView'

module.exports = class MarkdownResourceView extends RootView
  id: 'markdown-resource-view'
  template: require 'templates/teachers/markdown-resource-view'
  initialize: (options, @name) ->
    super(options)
    @content = ''
    $.get '/markdown/' + @name + '.md', (data) =>
      if data.indexOf('<!doctype html>') is -1
        @content = "<span class='backlink'><a href='/teachers/resources/'>< Back to Resource Hub</a></span><div class='print'><span class='glyphicon glyphicon-print'></span><a href='javascript:window.print()'> Print this guide</a></div><div class='lesson-plans' id='"+ @name + "'>" + marked(data, sanitize: false) + "</div>"
      else
        @content = "<h1>Not Found</h1><a href='/teachers/resources/'>< Back to Resource Hub</a>"

      @render()
