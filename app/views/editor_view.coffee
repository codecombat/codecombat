View = require 'views/kinds/RootView'
template = require 'templates/editor'

module.exports = class EditorView extends View
  id: "editor-level-view"
  template: template