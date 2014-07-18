RootView = require 'views/kinds/RootView'
template = require 'templates/editor'

module.exports = class EditorView extends RootView
  id: 'editor-nav-view'
  template: template
