View = require 'views/kinds/RootView'
template = require 'templates/editor/article/preview'

module.exports = class PreviewView extends View
  id: 'editor-article-preview-view'
  template: template
