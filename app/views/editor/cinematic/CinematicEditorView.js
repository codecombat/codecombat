/**
 * Will contain a bare bones cinematic editor.
 */

const RootComponent = require('views/core/RootComponent')
const template = require('app/views/vue-template.pug')
const CinematicEditorComponent = require('./CinematicEditorComponent.vue').default

class CinematicEditView extends RootComponent {
}

CinematicEditView.prototype.id = 'cinematic-view'
CinematicEditView.prototype.template = template
CinematicEditView.prototype.VueComponent = CinematicEditorComponent
CinematicEditView.prototype.propsData = {}

module.exports = CinematicEditView
