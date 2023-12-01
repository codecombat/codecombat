// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let NewLevelComponentModal
require('app/styles/editor/level/component/new.sass')
const ModalView = require('views/core/ModalView')
const template = require('app/templates/editor/level/component/new')
const LevelComponent = require('models/LevelComponent')
const forms = require('core/forms')
const { me } = require('core/auth')

module.exports = (NewLevelComponentModal = (function () {
  NewLevelComponentModal = class NewLevelComponentModal extends ModalView {
    static initClass () {
      this.prototype.id = 'editor-level-component-new-modal'
      this.prototype.template = template
      this.prototype.instant = false
      this.prototype.modalWidthPercent = 60

      this.prototype.events = {
        'click #new-level-component-submit': 'makeNewLevelComponent',
        'submit form': 'makeNewLevelComponent'
      }
    }

    constructor (options) {
      super(options)
      this.systems = LevelComponent.schema.properties.system.enum
    }

    makeNewLevelComponent (e) {
      e.preventDefault()
      const system = this.$el.find('#level-component-system').val()
      const name = this.$el.find('#level-component-name').val()
      const component = new LevelComponent()
      component.set('system', system)
      component.set('name', name)
      component.set('code', component.get('code', true).replace(/AttacksSelf/g, name))
      component.set('permissions', [{ access: 'owner', target: me.id }]) // Private until saved in a published Level
      const res = component.save(null, { type: 'POST' }) // Override PUT so we can trigger postFirstVersion logic
      if (!res) { return }

      this.showLoading()
      res.error(() => {
        this.hideLoading()
        console.log('Got errors:', JSON.parse(res.responseText))
        return forms.applyErrorsToForm(this.$el, JSON.parse(res.responseText))
      })
      return res.success(() => {
        this.supermodel.registerModel(component)
        return this.hide()
      })
    }
  }
  NewLevelComponentModal.initClass()
  return NewLevelComponentModal
})())
