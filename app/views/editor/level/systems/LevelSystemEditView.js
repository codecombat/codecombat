// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LevelSystemEditView;
require('app/styles/editor/level/system/level-system-edit-view.sass');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/editor/level/system/level-system-edit-view');
const LevelSystem = require('models/LevelSystem');
const SystemVersionsModal = require('views/editor/level/systems/SystemVersionsModal');
const PatchesView = require('views/editor/PatchesView');
const SaveVersionModal = require('views/editor/modal/SaveVersionModal');
require('lib/setupTreema');
const ace = require('lib/aceContainer');

module.exports = (LevelSystemEditView = (function() {
  LevelSystemEditView = class LevelSystemEditView extends CocoView {
    static initClass() {
      this.prototype.id = 'level-system-edit-view';
      this.prototype.template = template;
      this.prototype.editableSettings = ['name', 'description', 'codeLanguage', 'dependencies', 'propertyDocumentation', 'i18n'];

      this.prototype.events = {
        'click #done-editing-system-button': 'endEditing',
        'click .nav a'(e) { return $(e.target).tab('show'); },
        'click #system-patches-tab'() { return this.patchesView.load(); },
        'click #system-code-tab': 'buildCodeEditor',
        'click #system-config-schema-tab': 'buildConfigSchemaTreema',
        'click #system-settings-tab': 'buildSettingsTreema',
        'click #system-history-button': 'showVersionHistory',
        'click #patch-system-button': 'startPatchingSystem',
        'click #system-watch-button': 'toggleWatchSystem'
      };
    }

    constructor(options) {
      super(options);
      this.onSystemSettingsEdited = this.onSystemSettingsEdited.bind(this);
      this.onConfigSchemaEdited = this.onConfigSchemaEdited.bind(this);
      this.onEditorChange = this.onEditorChange.bind(this);
      this.levelSystem = this.supermodel.getModelByOriginalAndMajorVersion(LevelSystem, options.original, options.majorVersion || 0);
      if (!this.levelSystem) { console.log('Couldn\'t get levelSystem for', options, 'from', this.supermodel.models); }
    }

    afterRender() {
      super.afterRender();
      this.buildSettingsTreema();
      this.buildConfigSchemaTreema();
      this.buildCodeEditor();
      this.patchesView = this.insertSubView(new PatchesView(this.levelSystem), this.$el.find('.patches-view'));
      return this.updatePatchButton();
    }

    buildSettingsTreema() {
      const data = _.pick(this.levelSystem.attributes, (value, key) => Array.from(this.editableSettings).includes(key));
      const schema = _.cloneDeep(LevelSystem.schema);
      schema.properties = _.pick(schema.properties, (value, key) => Array.from(this.editableSettings).includes(key));
      schema.required = _.intersection(schema.required, this.editableSettings);
      schema.default = _.pick(schema.default, (value, key) => Array.from(this.editableSettings).includes(key));

      const treemaOptions = {
        filePath: this.options.filePath,
        supermodel: this.supermodel,
        schema,
        data,
        callbacks: {change: this.onSystemSettingsEdited}
      };
      treemaOptions.readOnly = me.get('anonymous');
      this.systemSettingsTreema = this.$el.find('#edit-system-treema').treema(treemaOptions);
      this.systemSettingsTreema.build();
      return this.systemSettingsTreema.open();
    }

    onSystemSettingsEdited() {
      // Make sure it validates first?
      for (var key in this.systemSettingsTreema.data) {
        var value = this.systemSettingsTreema.data[key];
        if (key !== 'js') { this.levelSystem.set(key, value); }
      } // will compile code if needed
      return this.updatePatchButton();
    }

    buildConfigSchemaTreema() {
      const treemaOptions = {
        filePath: this.options.filePath,
        supermodel: this.supermodel,
        schema: LevelSystem.schema.properties.configSchema,
        data: $.extend(true, {}, this.levelSystem.get('configSchema')),
        callbacks: {change: this.onConfigSchemaEdited}
      };
      treemaOptions.readOnly = me.get('anonymous');
      this.configSchemaTreema = this.$el.find('#config-schema-treema').treema(treemaOptions);
      this.configSchemaTreema.build();
      this.configSchemaTreema.open();
      // TODO: schema is not loaded for the first one here?
      return this.configSchemaTreema.tv4.addSchema('metaschema', LevelSystem.schema.properties.configSchema);
    }

    onConfigSchemaEdited() {
      this.levelSystem.set('configSchema', this.configSchemaTreema.data);
      return this.updatePatchButton();
    }

    buildCodeEditor() {
      this.destroyAceEditor(this.editor);
      const editorEl = $('<div></div>').text(this.levelSystem.get('code')).addClass('inner-editor');
      this.$el.find('#system-code-editor').empty().append(editorEl);
      this.editor = ace.edit(editorEl[0]);
      this.editor.setReadOnly(me.get('anonymous'));
      const session = this.editor.getSession();
      if (this.levelSystem.get('codeLanguage') === 'javascript') {
        session.setMode('ace/mode/javascript');
        session.setTabSize(4);
      } else {
        session.setMode('ace/mode/coffee');
        session.setTabSize(2);
      }
      session.setNewLineMode = 'unix';
      session.setUseSoftTabs(true);
      return this.editor.on('change', this.onEditorChange);
    }

    onEditorChange() {
      this.levelSystem.set('code', this.editor.getValue());
      return this.updatePatchButton();
    }

    updatePatchButton() {
      return this.$el.find('#patch-system-button').toggle(Boolean(this.levelSystem.hasLocalChanges()));
    }

    endEditing(e) {
      Backbone.Mediator.publish('editor:level-system-editing-ended', {system: this.levelSystem});
      return null;
    }

    showVersionHistory(e) {
      const systemVersionsModal = new SystemVersionsModal({}, this.levelSystem.id);
      this.openModalView(systemVersionsModal);
      return Backbone.Mediator.publish('editor:view-switched', {});
    }

    startPatchingSystem(e) {
      this.openModalView(new SaveVersionModal({model: this.levelSystem}));
      return Backbone.Mediator.publish('editor:view-switched', {});
    }

    toggleWatchSystem() {
      console.log('toggle watch system?');
      const button = this.$el.find('#system-watch-button');
      this.levelSystem.watch(button.find('.watch').is(':visible'));
      return button.find('> span').toggleClass('secret');
    }

    destroy() {
      this.destroyAceEditor(this.editor);
      if (this.systemSettingsTreema != null) {
        this.systemSettingsTreema.destroy();
      }
      if (this.configSchemaTreema != null) {
        this.configSchemaTreema.destroy();
      }
      return super.destroy();
    }
  };
  LevelSystemEditView.initClass();
  return LevelSystemEditView;
})());
