// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let FilesView
const RootComponent = require('views/core/RootComponent')
const template = require('app/templates/base-flat')
const FilesComponent = require('./FilesComponent.vue').default

module.exports = (FilesView = (function () {
  FilesView = class FilesView extends RootComponent {
    static initClass () {
      this.prototype.id = 'files-view'
      this.prototype.template = template
      this.prototype.VueComponent = FilesComponent
    }
  }
  FilesView.initClass()
  return FilesView
})())
