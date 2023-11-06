// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SaveLevelModal;
const SaveVersionModal = require('views/editor/modal/SaveVersionModal');
const template = require('app/templates/editor/level/save-level-modal');
const forms = require('core/forms');
const LevelComponent = require('models/LevelComponent');
const LevelSystem = require('models/LevelSystem');
const DeltaView = require('views/editor/DeltaView');
const PatchModal = require('views/editor/PatchModal');
const deltasLib = require('core/deltas');
const VerifierTest = require('views/editor/verifier/VerifierTest');
const SuperModel = require('models/SuperModel');

module.exports = (SaveLevelModal = (function() {
  SaveLevelModal = class SaveLevelModal extends SaveVersionModal {
    static initClass() {
      this.prototype.template = template;
      this.prototype.instant = false;
      this.prototype.modalWidthPercent = 60;
      this.prototype.plain = true;

      this.prototype.events = {
        'click #save-version-button': 'commitLevel',
        'submit form': 'commitLevel'
      };
    }

    constructor(options) {
      super(options);
      this.onVerifierTestUpate = this.onVerifierTestUpate.bind(this);
      this.level = options.level;
      this.buildTime = options.buildTime;
      this.commitMessage = options.commitMessage != null ? options.commitMessage : "";
      this.listenToOnce(this.level, 'remote-changes-checked', this.onRemoteChangesChecked);
      this.level.checkRemoteChanges();
    }

    getRenderData(context) {
      if (context == null) { context = {}; }
      context = super.getRenderData(context);
      context.level = this.level;
      context.levelNeedsSave = this.level.hasLocalChanges();
      context.modifiedComponents = _.filter(this.supermodel.getModels(LevelComponent), this.shouldSaveEntity);
      context.modifiedSystems = _.filter(this.supermodel.getModels(LevelSystem), this.shouldSaveEntity);
      context.commitMessage = this.commitMessage;
      this.hasChanges = (context.levelNeedsSave || context.modifiedComponents.length || context.modifiedSystems.length);
      this.lastContext = context;
      context.showChangesWarning = this.showChangesWarning;
      return context;
    }

    onRemoteChangesChecked(data) {
      this.showChangesWarning = data.hasChanges;
      return this.render();
    }

    afterRender() {
      super.afterRender(false);
      const changeEls = this.$el.find('.changes-stub');
      let models = this.lastContext.levelNeedsSave ? [this.level] : [];
      models = models.concat(this.lastContext.modifiedComponents);
      models = models.concat(this.lastContext.modifiedSystems);
      models = ((() => {
        const result = [];
        for (var m of Array.from(models)) {           if (m.hasWriteAccess()) {
            result.push(m);
          }
        }
        return result;
      })());
      for (let i = 0; i < changeEls.length; i++) {
        var changeEl = changeEls[i];
        var model = models[i];
        try {
          var deltaView = new DeltaView({model, skipPaths: deltasLib.DOC_SKIP_PATHS});
          this.insertSubView(deltaView, $(changeEl));
        } catch (e) {
          console.error('Couldn\'t create delta view:', e);
        }
      }
      if (me.isAdmin()) { return this.verify(); }
    }

    shouldSaveEntity(m) {
      if (!m.hasWriteAccess()) { return false; }
      if ((m.get('system') === 'ai') && (m.get('name') === 'Jitters') && (m.type() === 'LevelComponent')) {
        // Trying to debug the occasional phantom all-Components-must-be-saved bug
        console.log("Should we save", m.get('system'), m.get('name'), m, "? localChanges:", m.hasLocalChanges(), "version:", m.get('version'), 'isPublished:', m.isPublished(), 'collection:', m.collection);
        return false;
      }
      if (m.hasLocalChanges()) { return true; }
      if (!m.get('version')) { console.error(`Trying to check major version of ${m.type()} ${m.get('name')}, but it doesn't have a version:`, m); }
      if (((m.get('version').major === 0) && (m.get('version').minor === 0)) || (!m.isPublished() && !m.collection)) { return true; }
      // Sometimes we have two versions: one in a search collection and one with a URL. We only save changes to the latter.
      return false;
    }

    commitLevel(e) {
      let form, model, newModel;
      e.preventDefault();
      this.level.set('buildTime', this.buildTime);
      let modelsToSave = [];
      const formsToSave = [];
      for (form of Array.from(this.$el.find('form'))) {
        // Level form is first, then LevelComponents' forms, then LevelSystems' forms
        var fields = {};
        for (var field of Array.from($(form).serializeArray())) {
          fields[field.name] = field.value === 'on' ? true : field.value;
        }
        var isLevelForm = $(form).attr('id') === 'save-level-form';
        if (isLevelForm) {
          model = this.level;
        } else {
          var [kind, klass] = Array.from($(form).hasClass('component-form') ? ['component', LevelComponent] : ['system', LevelSystem]);
          model = this.supermodel.getModelByOriginalAndMajorVersion(klass, fields[`${kind}-original`], parseInt(fields[`${kind}-parent-major-version`], 10));
          if (!model) { console.log('Couldn\'t find model for', kind, fields, 'from', this.supermodel.models); }
        }
        newModel = fields.major ? model.cloneNewMajorVersion() : model.cloneNewMinorVersion();
        newModel.set('commitMessage', fields['commit-message']);
        modelsToSave.push(newModel);
        if (isLevelForm) {
          this.level = newModel;
          if (fields['publish'] && !this.level.isPublished()) {
            this.level.publish();
          }
        } else if (this.level.isPublished() && !newModel.isPublished()) {
          newModel.publish();  // Publish any LevelComponents that weren't published yet
        }
        formsToSave.push(form);
      }

      for (model of Array.from(modelsToSave)) {
        var errors;
        if (errors = model.getValidationErrors()) {
          var messages = (Array.from(errors).map((error) => `\t ${error.dataPath}: ${error.message}`));
          messages = messages.join('<br />');
          this.$el.find('#errors-wrapper .errors').html(messages);
          this.$el.find('#errors-wrapper').removeClass('hide');
          return;
        }
      }

      this.showLoading();
      const tuples = _.zip(modelsToSave, formsToSave);
      return (() => {
        const result = [];
        for ([newModel, form] of Array.from(tuples)) {
          if (newModel.get('i18nCoverage')) { newModel.updateI18NCoverage(); }
          var res = newModel.save(null, {type: 'POST'});  // Override PUT so we can trigger postNewVersion logic
          result.push(((newModel, form) => {
            res.error(() => {
              this.hideLoading();
              console.log('Got errors:', JSON.parse(res.responseText));
              return forms.applyErrorsToForm($(form), JSON.parse(res.responseText));
            });
            return res.success(() => {
              modelsToSave = _.without(modelsToSave, newModel);
              const oldModel = _.find(this.supermodel.models, m => m.get('original') === newModel.get('original'));
              oldModel.clearBackup();  // Otherwise looking at old versions is confusing.
              if (!modelsToSave.length) {
                const url = `/editor/level/${this.level.get('slug') || this.level.id}`;
                document.location.href = url;
                return this.hide();
              }
            });  // This will destroy everything, so do it last
          })(newModel, form));
        }
        return result;
      })();
    }

    verify() {
      let solutions;
      if ((!(solutions = this.level.getSolutions())) || !solutions.length) { return this.$('#verifier-stub').hide(); }
      this.running = (this.problems = (this.failed = (this.passedExceptFrames = (this.passed = 0))));
      this.waiting = solutions.length;
      this.renderSelectors('#verifier-tests');
      return (() => {
        const result = [];
        for (var solution of Array.from(solutions)) {
          var test;
          var childSupermodel = new SuperModel();
          childSupermodel.models = _.clone(this.supermodel.models);
          childSupermodel.collections = _.clone(this.supermodel.collections);
          result.push(test = new VerifierTest(this.level.get('slug'), this.onVerifierTestUpate, childSupermodel, solution.language, {devMode: true, solution}));
        }
        return result;
      })();
    }

    onVerifierTestUpate(e) {
      if (this.destroyed) { return; }
      if (e.state === 'running') {
        --this.waiting;
        ++this.running;
      } else if (['complete', 'error', 'no-solution'].includes(e.state)) {
        --this.running;
        if (e.state === 'complete') {
          if (e.test.isSuccessful(true)) {
            ++this.passed;
          } else if (e.test.isSuccessful(false)) {
            ++this.passedExceptFrames;
          } else {
            ++this.failed;
          }
        } else if (e.state === 'no-solution') {
          console.warn('Solution problem for', e.test.language);
          ++this.problems;
        } else {
          ++this.problems;
        }
      }
      return this.renderSelectors('#verifier-tests');
    }
  };
  SaveLevelModal.initClass();
  return SaveLevelModal;
})());
