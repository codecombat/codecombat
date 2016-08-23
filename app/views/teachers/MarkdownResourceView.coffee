RootView = require 'views/core/RootView'

module.exports = class MarkdownResourceView extends RootView
  id: 'markdown-resource-view'
  template: require 'templates/teachers/markdown-resource-view'
  initialize: (options, @name) ->
    super(options)
    @content = ''
    $.get '/markdown/' + @name + '.md', (data) =>
      if data.indexOf('<!doctype html>') is -1
        @content = marked(data, sanitize: false)

      @render()
