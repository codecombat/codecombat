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
let LevelComponentEditView;
require('app/styles/editor/level/component/level-component-edit-view.sass');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/editor/level/component/level-component-edit-view');
const LevelComponent = require('models/LevelComponent');
const ComponentVersionsModal = require('views/editor/component/ComponentVersionsModal');
const PatchesView = require('views/editor/PatchesView');
const SaveVersionModal = require('views/editor/modal/SaveVersionModal');
const ace = require('lib/aceContainer');

require('lib/setupTreema');

module.exports = (LevelComponentEditView = (function() {
  LevelComponentEditView = class LevelComponentEditView extends CocoView {
    static initClass() {
      this.prototype.id = 'level-component-edit-view';
      this.prototype.template = template;
      this.prototype.editableSettings = ['name', 'description', 'system', 'codeLanguage', 'dependencies', 'propertyDocumentation', 'i18n', 'context'];

      this.prototype.events = {
        'click #done-editing-component-button': 'endEditing',
        'click .nav a'(e) { return $(e.target).tab('show'); },
        'click #component-patches-tab'() { return this.patchesView.load(); },
        'click #component-code-tab': 'buildCodeEditor',
        'click #component-config-schema-tab': 'buildConfigSchemaTreema',
        'click #component-settings-tab': 'buildSettingsTreema',
        'click #component-history-button': 'showVersionHistory',
        'click #patch-component-button': 'startPatchingComponent',
        'click #component-watch-button': 'toggleWatchComponent',
        'click #pop-component-i18n-button': 'onPopulateI18N'
      };
    }

    constructor(options) {
      super(options);
      this.onComponentSettingsEdited = this.onComponentSettingsEdited.bind(this);
      this.onConfigSchemaEdited = this.onConfigSchemaEdited.bind(this);
      this.onEditorChange = this.onEditorChange.bind(this);
      this.levelComponent = this.supermodel.getModelByOriginalAndMajorVersion(LevelComponent, options.original, options.majorVersion || 0);
      if (!this.levelComponent) { console.log('Couldn\'t get levelComponent for', options, 'from', this.supermodel.models); }
      this.onEditorChange = _.debounce(this.onEditorChange, 1000);
    }

    getRenderData(context) {
      if (context == null) { context = {}; }
      context = super.getRenderData(context);
      context.editTitle = `${this.levelComponent.get('system')}.${this.levelComponent.get('name')}`;
      context.component = this.levelComponent;
      return context;
    }

    onLoaded() { return this.render(); }

    afterRender() {
      super.afterRender();
      this.buildSettingsTreema();
      this.buildConfigSchemaTreema();
      this.buildCodeEditor();
      this.patchesView = this.insertSubView(new PatchesView(this.levelComponent), this.$el.find('.patches-view'));
      if (this.levelComponent.watching()) { this.$el.find('#component-watch-button').find('> span').toggleClass('secret'); }
      return this.updatePatchButton();
    }

    buildSettingsTreema() {
      let data = _.pick(this.levelComponent.attributes, (value, key) => Array.from(this.editableSettings).includes(key));
      data = $.extend(true, {}, data);
      const schema = _.cloneDeep(LevelComponent.schema);
      schema.properties = _.pick(schema.properties, (value, key) => Array.from(this.editableSettings).includes(key));
      schema.required = _.intersection(schema.required, this.editableSettings);
      schema.default = _.pick(schema.default, (value, key) => Array.from(this.editableSettings).includes(key));

      const treemaOptions = {
        filePath: this.options.filePath,
        supermodel: this.supermodel,
        schema,
        data,
        readonly: me.get('anonymous'),
        callbacks: {change: this.onComponentSettingsEdited}
      };
      this.componentSettingsTreema = this.$el.find('#edit-component-treema').treema(treemaOptions);
      this.componentSettingsTreema.build();
      return this.componentSettingsTreema.open();
    }

    onComponentSettingsEdited() {
      // Make sure it validates first?
      for (var key in this.componentSettingsTreema.data) {
        var value = this.componentSettingsTreema.data[key];
        if (key !== 'js') { this.levelComponent.set(key, value); }
      } // will compile code if needed
      return this.updatePatchButton();
    }

    buildConfigSchemaTreema() {
      const configSchema = $.extend(true, {}, this.levelComponent.get('configSchema'));
      if (configSchema.properties) {
        // Alphabetize (#1297)
        const propertyNames = _.keys(configSchema.properties);
        propertyNames.sort();
        const orderedProperties = {};
        for (var prop of Array.from(propertyNames)) {
          orderedProperties[prop] = configSchema.properties[prop];
        }
        configSchema.properties = orderedProperties;
      }
      const treemaOptions = {
        filePath: this.options.filePath,
        supermodel: this.supermodel,
        schema: LevelComponent.schema.properties.configSchema,
        data: configSchema,
        readOnly: me.get('anonymous'),
        callbacks: {change: this.onConfigSchemaEdited}
      };
      this.configSchemaTreema = this.$el.find('#config-schema-treema').treema(treemaOptions);
      this.configSchemaTreema.build();
      this.configSchemaTreema.open();
      // TODO: schema is not loaded for the first one here?
      return this.configSchemaTreema.tv4.addSchema('metaschema', LevelComponent.schema.properties.configSchema);
    }

    onConfigSchemaEdited() {
      this.levelComponent.set('configSchema', this.configSchemaTreema.data);
      return this.updatePatchButton();
    }

    buildCodeEditor() {
      this.destroyAceEditor(this.editor);
      const editorEl = $('<div></div>').text(this.levelComponent.get('code')).addClass('inner-editor');
      this.$el.find('#component-code-editor').empty().append(editorEl);
      this.editor = ace.edit(editorEl[0]);
      this.editor.setReadOnly(me.get('anonymous'));
      const session = this.editor.getSession();
      if (this.levelComponent.get('codeLanguage') === 'javascript') {
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
      if (this.destroyed) { return; }
      this.levelComponent.set('code', this.editor.getValue());
      return this.updatePatchButton();
    }

    updatePatchButton() {
      return this.$el.find('#patch-component-button').toggle(Boolean(this.levelComponent.hasLocalChanges()));
    }

    endEditing(e) {
      Backbone.Mediator.publish('editor:level-component-editing-ended', {component: this.levelComponent});
      return null;
    }

    showVersionHistory(e) {
      const componentVersionsModal = new ComponentVersionsModal({}, this.levelComponent.id);
      this.openModalView(componentVersionsModal);
      return Backbone.Mediator.publish('editor:view-switched', {});
    }

    startPatchingComponent(e) {
      this.openModalView(new SaveVersionModal({model: this.levelComponent}));
      return Backbone.Mediator.publish('editor:view-switched', {});
    }

    toggleWatchComponent() {
      const button = this.$el.find('#component-watch-button');
      this.levelComponent.watch(button.find('.watch').is(':visible'));
      return button.find('> span').toggleClass('secret');
    }

    onPopulateI18N() {
      this.levelComponent.populateI18N();
      return this.render();
    }

    destroy() {
      this.destroyAceEditor(this.editor);
      if (this.componentSettingsTreema != null) {
        this.componentSettingsTreema.destroy();
      }
      if (this.configSchemaTreema != null) {
        this.configSchemaTreema.destroy();
      }
      return super.destroy();
    }
  };
  LevelComponentEditView.initClass();
  return LevelComponentEditView;
})());
