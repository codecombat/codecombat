const ModalView = require('views/core/ModalView')
const template = require('app/templates/editor/fork-modal')
const forms = require('core/forms')

class ForkModal extends ModalView {
  constructor (options) {
    super(options)
    this.editorPath = options.editorPath // like 'level' or 'thang'
    this.model = options.model
    this.modelClass = this.model.constructor
  }

  forkModel (e) {
    e.preventDefault()
    this.showLoading()
    forms.clearFormAlerts(this.$el)
    // eslint-disable-next-line new-cap
    const newModel = new this.modelClass($.extend(true, {}, this.model.attributes))
    newModel.unset('_id')
    newModel.unset('version')
    newModel.unset('creator')
    newModel.unset('created')
    newModel.unset('original')
    newModel.unset('parent')
    newModel.unset('i18n')
    newModel.unset('i18nCoverage')
    newModel.unset('tasks')
    newModel.set('commitMessage', `Forked from ${this.model.get('name')}`)
    newModel.set('name', this.$el.find('#fork-model-name').val())
    if (this.model.schema().properties.permissions) {
      newModel.set('permissions', [{ access: 'owner', target: me.id }])
    }
    const newPathPrefix = `editor/${this.editorPath}/`
    const res = newModel.save(null, { type: 'POST' }) // Override PUT so we can trigger postFirstVersion logic
    if (!res) { return }
    res.error(() => {
      this.hideLoading()
      forms.applyErrorsToForm(this.$el.find('form'), JSON.parse(res.responseText))
    })
    res.success(() => {
      this.hide()
      application.router.navigate(newPathPrefix + newModel.get('slug'), { trigger: true })
    })
  }
}

ForkModal.prototype.id = 'fork-modal'
ForkModal.prototype.template = template
ForkModal.prototype.instant = false

ForkModal.prototype.events = {
  'click #fork-model-confirm-button': 'forkModel',
  'submit form': 'forkModel'
}

module.exports = ForkModal
