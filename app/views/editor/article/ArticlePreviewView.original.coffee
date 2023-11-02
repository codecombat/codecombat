require('app/styles/editor/article/preview.sass')
RootView = require 'views/core/RootView'
template = require 'app/templates/editor/article/preview'

require 'lib/game-libraries'

module.exports = class ArticlePreviewView extends RootView
  id: 'editor-article-preview-view'
  template: template
