// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let NewModelModal
const ModalView = require('views/core/ModalView')
const template = require('app/templates/editor/modal/new-model-modal')
const forms = require('core/forms')

module.exports = (NewModelModal = (function () {
  NewModelModal = class NewModelModal extends ModalView {
    static initClass () {
      this.prototype.id = 'new-model-modal'
      this.prototype.template = template
      this.prototype.plain = false

      this.prototype.events = {
        'click button.new-model-submit': 'onModelSubmitted',
        'submit form': 'onModelSubmitted'
      }
    }

    constructor (options) {
      super(options)
      this.modelClass = options.model
      this.modelLabel = options.modelLabel
      this.newModelTitle = `editor.new_${_.string.slugify(this.modelLabel)}_title`
      this.properties = options.properties
    }

    makeNewModel () {
      const model = new this.modelClass()
      const name = this.$el.find('#name').val()
      model.set('name', name)
      if (this.modelClass.name === 'Level') {
        model.set('tasks', this.modelClass.schema.default.tasks)
      }
      if (model.schema().properties.permissions) {
        model.set('permissions', [{ access: 'owner', target: me.id }])
      }
      if (this.properties != null) { for (const key in this.properties) { const prop = this.properties[key]; model.set(key, prop) } }
      return model
    }

    onModelSubmitted (e) {
      e.preventDefault()
      const model = this.makeNewModel()
      const res = model.save(null, { type: 'POST' }) // Override PUT so we can trigger postFirstVersion logic if needed
      if (!res) { return }

      forms.clearFormAlerts(this.$el)
      this.showLoading(this.$el.find('.modal-body'))
      res.error(() => {
        this.hideLoading()
        return forms.applyErrorsToForm(this.$el, JSON.parse(res.responseText))
      })
      // Backbone.Mediator.publish 'model-save-fail', model
      return res.success(() => {
        this.$el.modal('hide')
        return this.trigger('model-created', model)
      })
    }
    // Backbone.Mediator.publish 'model-save-success', model

    afterInsert () {
      super.afterInsert()
      return _.delay(() => (this.$el != null ? this.$el.find('#name').focus() : undefined), 500)
    }
  }
  NewModelModal.initClass()
  return NewModelModal
})())
