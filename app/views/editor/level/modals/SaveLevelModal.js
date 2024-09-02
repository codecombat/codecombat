const SaveVersionModal = require('views/editor/modal/SaveVersionModal')
const template = require('app/templates/editor/level/save-level-modal')
const forms = require('core/forms')
const LevelComponent = require('models/LevelComponent')
const LevelSystem = require('models/LevelSystem')
const DeltaView = require('views/editor/DeltaView')
const deltasLib = require('core/deltas')
const VerifierTest = require('views/editor/verifier/VerifierTest')
const SuperModel = require('models/SuperModel')

class SaveLevelModal extends SaveVersionModal {
  static initClass () {
    this.prototype.template = template
    this.prototype.instant = false
    this.prototype.modalWidthPercent = 60
    this.prototype.plain = true

    this.prototype.events = {
      'click #save-version-button': 'commitLevel',
      'submit form': 'commitLevel'
    }
  }

  constructor (options) {
    super(options)
    this.onVerifierTestUpdate = this.onVerifierTestUpdate.bind(this)
    this.level = options.level
    this.buildTime = options.buildTime
    this.commitMessage = options.commitMessage || ''
    this.listenToOnce(this.level, 'remote-changes-checked', this.onRemoteChangesChecked)
    this.level.checkRemoteChanges()
  }

  getRenderData (context) {
    context = context || {}
    context = super.getRenderData(context)
    context.level = this.level
    context.levelNeedsSave = this.level.hasLocalChanges()
    context.modifiedComponents = _.filter(this.supermodel.getModels(LevelComponent), this.shouldSaveEntity)
    context.modifiedSystems = _.filter(this.supermodel.getModels(LevelSystem), this.shouldSaveEntity)
    context.commitMessage = this.commitMessage
    this.hasChanges = (context.levelNeedsSave || context.modifiedComponents.length || context.modifiedSystems.length)
    this.lastContext = context
    context.showChangesWarning = this.showChangesWarning
    return context
  }

  onRemoteChangesChecked (data) {
    this.showChangesWarning = data.hasChanges
    this.render()
  }

  afterRender () {
    super.afterRender(false)
    const changeEls = this.$el.find('.changes-stub')
    let models = this.lastContext.levelNeedsSave ? [this.level] : []
    models = models.concat(this.lastContext.modifiedComponents)
    models = models.concat(this.lastContext.modifiedSystems)
    models = models.filter((m) => m.hasWriteAccess())
    for (let i = 0; i < changeEls.length; i++) {
      const changeEl = changeEls[i]
      const model = models[i]
      try {
        const deltaView = new DeltaView({ model, skipPaths: deltasLib.DOC_SKIP_PATHS })
        this.insertSubView(deltaView, $(changeEl))
      } catch (e) {
        console.error('Couldn\'t create delta view:', e)
      }
    }
    if (me.isAdmin()) {
      this.verify()
    }
  }

  shouldSaveEntity (m) {
    if (!m.hasWriteAccess()) { return false }
    if ((m.get('system') === 'ai') && (m.get('name') === 'Jitters') && (m.type() === 'LevelComponent')) {
      // Trying to debug the occasional phantom all-Components-must-be-saved bug
      console.log('Should we save', m.get('system'), m.get('name'), m, '? localChanges:', m.hasLocalChanges(), 'version:', m.get('version'), 'isPublished:', m.isPublished(), 'collection:', m.collection)
      return false
    }
    if (m.hasLocalChanges()) { return true }
    if (!m.get('version')) { console.error(`Trying to check major version of ${m.type()} ${m.get('name')}, but it doesn't have a version:`, m) }
    if (((m.get('version').major === 0) && (m.get('version').minor === 0)) || (!m.isPublished() && !m.collection)) { return true }
    // Sometimes we have two versions: one in a search collection and one with a URL. We only save changes to the latter.
    return false
  }

  async commitLevel (e) {
    e.preventDefault()
    this.level.set('buildTime', this.buildTime)
    let modelsToSave = []
    const formsToSave = []

    // Process forms
    this.$el.find('form').each((index, form) => {
      // Level form is first, then LevelComponents' forms, then LevelSystems' forms
      const fields = {}
      for (const field of Array.from($(form).serializeArray())) {
        fields[field.name] = field.value === 'on' ? true : field.value
      }
      const isLevelForm = $(form).attr('id') === 'save-level-form'
      let model
      if (isLevelForm) {
        model = this.level
      } else {
        const [kind, klass] = $(form).hasClass('component-form') ? ['component', LevelComponent] : ['system', LevelSystem]
        model = this.supermodel.getModelByOriginalAndMajorVersion(klass, fields[`${kind}-original`], parseInt(fields[`${kind}-parent-major-version`], 10))
        if (!model) { console.log('Couldn\'t find model for', kind, fields, 'from', this.supermodel.models) }
      }
      const newModel = fields.major ? model.cloneNewMajorVersion() : model.cloneNewMinorVersion()
      newModel.set('commitMessage', fields['commit-message'])
      modelsToSave.push(newModel)
      if (isLevelForm) {
        this.level = newModel
        if (fields.publish && !this.level.isPublished()) {
          this.level.publish()
        }
      } else if (this.level.isPublished() && !newModel.isPublished()) {
        newModel.publish() // Publish any LevelComponents that weren't published yet
      }
      formsToSave.push(form)
    })

    // Validate models
    for (const model of modelsToSave) {
      const errors = model.getValidationErrors()
      if (errors) {
        let messages = (errors.map((error) => `\t ${error.dataPath}: ${error.message}`))
        messages = messages.join('<br />')
        this.$el.find('#errors-wrapper .errors').html(messages)
        this.$el.find('#errors-wrapper').removeClass('hide')
        return
      }
    }

    this.showLoading()
    const tuples = _.zip(modelsToSave, formsToSave)

    try {
      for (const [newModel, form] of tuples) {
        if (newModel.get('i18nCoverage')) { newModel.updateI18NCoverage() }
        try {
          await newModel.save(null, { type: 'POST' }) // Override PUT so we can trigger postNewVersion logic
          modelsToSave = _.without(modelsToSave, newModel)
          const oldModel = _.find(this.supermodel.models, m => m.get('original') === newModel.get('original'))
          oldModel.clearBackup() // Otherwise looking at old versions is confusing.
        } catch (error) {
          console.log('Got errors:', error)
          forms.applyErrorsToForm($(form), error)
          this.hideLoading()
          return
        }
      }

      // All models saved successfully
      const url = `/editor/level/${this.level.get('slug') || this.level.id}`
      document.location.href = url
      this.hide()
    } catch (error) {
      console.error('An unexpected error occurred:', error)
      this.hideLoading()
    }
  }

  verify () {
    const solutions = this.level.getSolutions()
    if (!solutions || !solutions.length) { return this.$('#verifier-stub').hide() }
    this.running = (this.problems = (this.failed = (this.passedExceptFrames = (this.passed = 0))))
    this.waiting = solutions.length
    this.renderSelectors('#verifier-tests')
    for (const solution of solutions) {
      const childSupermodel = new SuperModel()
      childSupermodel.models = _.clone(this.supermodel.models)
      childSupermodel.collections = _.clone(this.supermodel.collections)
      // eslint-disable-next-line no-unused-vars
      const test = new VerifierTest(this.level.get('slug'), this.onVerifierTestUpdate, childSupermodel, solution.language, { devMode: true, solution })
    }
  }

  onVerifierTestUpdate (e) {
    if (this.destroyed) { return }
    if (e.state === 'running') {
      --this.waiting
      ++this.running
    } else if (['complete', 'error', 'no-solution'].includes(e.state)) {
      --this.running
      if (e.state === 'complete') {
        if (e.test.isSuccessful(true)) {
          ++this.passed
        } else if (e.test.isSuccessful(false)) {
          ++this.passedExceptFrames
        } else {
          ++this.failed
        }
      } else if (e.state === 'no-solution') {
        console.warn('Solution problem for', e.test.language)
        ++this.problems
      } else {
        ++this.problems
      }
    }
    this.renderSelectors('#verifier-tests')
  }
}

SaveLevelModal.initClass()
module.exports = SaveLevelModal
