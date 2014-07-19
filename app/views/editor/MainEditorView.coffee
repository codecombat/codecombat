RootView = require 'views/kinds/RootView'
template = require 'templates/editor'

module.exports = class MainEditorView extends RootView
  id: 'editor-nav-view'
  template: template
