RootView = require 'views/core/RootView'

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

      @render()
