RootView = require 'views/core/RootView'
template = require 'templates/editor/article/preview'

module.exports = class ArticlePreviewView extends RootView
  id: 'editor-article-preview-view'
  template: template
