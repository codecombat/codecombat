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
let I18NEditModelView;
const RootView = require('views/core/RootView');
const locale = require('locale/locale');
const Patch = require('models/Patch');
const Patches = require('collections/Patches');
const PatchModal = require('views/editor/PatchModal');
const template = require('app/templates/i18n/i18n-edit-model-view');
const deltasLib = require('core/deltas');
const modelDeltas = require('lib/modelDeltas');
const ace = require('lib/aceContainer');

/*
  This view is the superclass for all views which Diplomats use to submit translations
  for database documents. They all work mostly the same, except they each set their
  `@modelClass` which is a patchable Backbone model class, and they use `@wrapRow()`
  to dynamically specify which properties are being translated.
*/

const UNSAVED_CHANGES_MESSAGE = 'You have unsaved changes! Really discard them?';

module.exports = (I18NEditModelView = (function() {
  I18NEditModelView = class I18NEditModelView extends RootView {
    static initClass() {
      this.prototype.className = 'editor i18n-edit-model-view';
      this.prototype.template = template;

      this.prototype.events = {
        'input .translation-input': 'onInputChanged',
        'change #language-select': 'onLanguageSelectChanged',
        'click #patch-submit': 'onSubmitPatch',
        'click .open-patch-link': 'onClickOpenPatchLink'
      };
    }

    constructor(options, modelHandle) {
      super(options);
      this.onEditorChange = this.onEditorChange.bind(this);
      this.modelHandle = modelHandle;

      this.model = new this.modelClass({_id: this.modelHandle});
      this.supermodel.trackRequest(this.model.fetch());
      this.patches = new Patches();
      this.listenTo(this.patches, 'change', function() { return this.renderSelectors('#patches-col'); });
      this.patches.comparator = '_id';
      this.supermodel.trackRequest(this.patches.fetchMineFor(this.model));

      this.selectedLanguage = me.get('preferredLanguage', true);
      this.madeChanges = false;
    }

    showLoading($el) {
      if ($el == null) { $el = this.$el.find('.outer-content'); }
      return super.showLoading($el);
    }

    onLoaded() {
      super.onLoaded();
      return this.originalModel = this.model.clone();
    }

    getRenderData() {
      const c = super.getRenderData();

      c.model = this.model;
      c.selectedLanguage = this.selectedLanguage;

      this.translationList = [];
      if (this.supermodel.finished()) { this.buildTranslationList(); } else { []; }
      for (let index = 0; index < this.translationList.length; index++) { var result = this.translationList[index]; result.index = index; }
      c.translationList = this.translationList;

      return c;
    }

    afterRender() {
      super.afterRender();

      this.ignoreLanguageSelectChanges = true;
      const $select = this.$el.find('#language-select').empty();
      this.addLanguagesToSelect($select, this.selectedLanguage);
      this.$el.find('option[value="en-US"]').remove();
      this.ignoreLanguageSelectChanges = false;
      const editors = [];

      this.$el.find('tr[data-format="markdown"]').each((index, el) => {
        let enEl, toEl;
        const foundEnEl = (enEl=$(el).find('.english-value-row div')[0]);
        if (foundEnEl != null) {
          const englishEditor = ace.edit(foundEnEl);
          englishEditor.el = enEl;
          englishEditor.setReadOnly(true);
          editors.push(englishEditor);
        }
        const foundToEl = (toEl=$(el).find('.to-value-row div')[0]);
        if (foundToEl != null) {
          const toEditor = ace.edit(foundToEl);
          toEditor.el = toEl;
          toEditor.on('change', this.onEditorChange);
          return editors.push(toEditor);
        }
      });

      return (() => {
        const result = [];
        for (var editor of Array.from(editors)) {
          var session = editor.getSession();
          session.setTabSize(2);
          session.setMode('ace/mode/markdown');
          session.setNewLineMode = 'unix';
          session.setUseSoftTabs(true);
          session.setUseWrapMode(true);
          result.push(editor.setOptions({ maxLines: Infinity }));
        }
        return result;
      })();
    }

    onEditorChange(event, editor) {
      if (this.destroyed) { return; }
      const index = $(editor.el).data('index');
      const rowInfo = this.translationList[index];
      const value = editor.getValue();
      return this.onTranslationChanged(rowInfo, value);
    }

    wrapRow(title, key, enValue, toValue, path, format) {
      if (!enValue) { return; }
      if (!toValue) { toValue = ''; }
      const doNotTranslate = enValue.match(/(['"`][^\s`]+['"`])/gi);
      return this.translationList.push({title, doNotTranslate, key, enValue, toValue, path, format});
    }

    buildTranslationList() { return []; } // overwrite

    onInputChanged(e) {
      const index = $(e.target).data('index');
      const rowInfo = this.translationList[index];
      const value = $(e.target).val();
      return this.onTranslationChanged(rowInfo, value);
    }

    onTranslationChanged(rowInfo, value) {
      //- Navigate down to where the translation will live
      let seg;
      let base = this.model.attributes;

      for (seg of Array.from(rowInfo.path)) {
        base = base[seg];
      }

      base = base.i18n;

      if (base[this.selectedLanguage] == null) { base[this.selectedLanguage] = {}; }
      base = base[this.selectedLanguage];

      if (rowInfo.key.length > 1) {
        for (seg of Array.from(rowInfo.key.slice(0, +-2 + 1 || undefined))) {
          if (base[seg] == null) { base[seg] = {}; }
          base = base[seg];
        }
      }

      //- Set the data in a non-kosher way
      base[rowInfo.key[rowInfo.key.length-1]] = value;
      this.model.saveBackup();

      //- Enable patch submit button
      this.$el.find('#patch-submit').attr('disabled', null);
      this.madeChanges = true;

      //- Update whether we are missing an identifier we thought we should still be there
      return this.$(`*[data-index=${rowInfo.index}]`).parents('table').find('.doNotTranslate code').each(function(index, el) {
        const identifier = $(el).text();
        return $(el).toggleClass('missing-identifier', value && (value.indexOf(identifier) === -1));
      });
    }

    onLanguageSelectChanged(e) {
      if (this.ignoreLanguageSelectChanges) { return; }
      if (this.madeChanges) {
        if (!confirm(UNSAVED_CHANGES_MESSAGE)) { return; }
      }
      this.selectedLanguage = $(e.target).val();
      if (this.selectedLanguage) {
        me.set('preferredLanguage', this.selectedLanguage);
        me.patch();
      }
      this.madeChanges = false;
      this.model.set(this.originalModel.clone().attributes);
      return this.render();
    }

    onClickOpenPatchLink(e) {
      const patchID = $(e.currentTarget).data('patch-id');
      const patch = this.patches.get(patchID);
      const modal = new PatchModal(patch, this.model);
      return this.openModalView(modal);
    }

    onLeaveMessage() {
      if (this.madeChanges) {
        return UNSAVED_CHANGES_MESSAGE;
      }
    }

    onSubmitPatch(e) {
      // Added due to high volume of translations getting set on english fields.
      if (['en-US', 'en-GB', 'en'].includes(this.selectedLanguage)) {
        alert(`Blocked change to ${this.selectedLanguage} field. Please check your language setting.`);
        return;
      }

      const delta = modelDeltas.getDeltaWith(this.originalModel, this.model);
      const flattened = deltasLib.flattenDelta(delta);
      let {
        className
      } = this.model.constructor;
      if (className.startsWith('AI')) { className = className.replace('AI', 'Ai'); }
      const collection = _.string.underscored(className);
      const patch = new Patch({
        delta,
        target: { collection, 'id': this.model.id },
        commitMessage: `Diplomat submission for lang ${this.selectedLanguage}: ${flattened.length} change(s).`
      });
      const errors = patch.validate();
      const button = $(e.target);
      button.attr('disabled', 'disabled');
      if (!delta) { return button.text('No changes submitted, did not save patch.'); }
      if (errors) { return button.text('Failed to Submit Changes'); }
      const res = patch.save(null, { url: _.result(this.model, 'url') + '/patch' });
      if (!res) { return button.text('Failed to Submit Changes'); }
      button.text('Submitting...');
      return Promise.resolve(res)
      .then(() => {
        this.madeChanges = false;
        this.patches.add(patch);
        this.renderSelectors('#patches-col');
        return button.text('Submit Changes');
    }).catch(() => {
        button.text('Error Submitting Changes');
        return this.$el.find('#patch-submit').attr('disabled', null);
      });
    }
  };
  I18NEditModelView.initClass();
  return I18NEditModelView;
})());
