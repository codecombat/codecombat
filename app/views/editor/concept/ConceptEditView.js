// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ConceptEditView;
require('app/styles/editor/concept/edit.sass');
const RootView = require('views/core/RootView');
const template = require('app/templates/editor/concept/edit');
const Concept = require('models/Concept');
const ConfirmModal = require('views/core/ConfirmModal');
const PatchesView = require('views/editor/PatchesView');
const errors = require('core/errors');

require('lib/game-libraries');
require('lib/setupTreema');
const treemaExt = require('core/treema-ext');

module.exports = (ConceptEditView = (function() {
  ConceptEditView = class ConceptEditView extends RootView {
    static initClass() {
      this.prototype.id = 'editor-concept-edit-view';
      this.prototype.template = template;

      this.prototype.events = {
        'click #save-button': 'onClickSaveButton',
        'click #i18n-button': 'onPopulateI18N'
      };
    }

    constructor(options, conceptID) {
      super(options);
      this.conceptID = conceptID;
      this.concept = new Concept({_id: this.conceptID});
      this.concept.saveBackups = true;
      this.supermodel.loadModel(this.concept);
    }

    onLoaded() {
      super.onLoaded();
      this.buildTreema();
      return this.listenTo(this.concept, 'change', () => {
        this.concept.updateI18NCoverage();
        return this.treema.set('/', this.concept.attributes);
      });
    }

    buildTreema() {
      if ((this.treema != null) || (!this.concept.loaded)) { return; }
      const data = $.extend(true, {}, this.concept.attributes);
      const options = {
        data,
        filePath: `db/concept/${this.concept.get('_id')}`,
        schema: Concept.schema,
        readOnly: me.get('anonymous'),
        supermodel: this.supermodel,
        nodeClasses: { code: treemaExt.JavaScriptTreema }
      };
      this.treema = this.$el.find('#concept-treema').treema(options);
      this.treema.build();
      return (this.treema.childrenTreemas.rewards != null ? this.treema.childrenTreemas.rewards.open(3) : undefined);
    }

    afterRender() {
      super.afterRender();
      if (!this.supermodel.finished()) { return; }
      if (me.get('anonymous')) { this.showReadOnly(); }
      this.patchesView = this.insertSubView(new PatchesView(this.concept), this.$el.find('.patches-view'));
      return this.patchesView.load();
    }

    onPopulateI18N() {
      return this.concept.populateI18N();
    }

    onClickSaveButton(e) {
      this.treema.endExistingEdits();
      for (var key in this.treema.data) {
        var value = this.treema.data[key];
        this.concept.set(key, value);
      }
      this.concept.updateI18NCoverage();

      const res = this.concept.save();

      res.error((collection, response, options) => {
        return console.error(response);
      });

      return res.success(() => {
        const url = `/editor/concept/${this.concept.get('slug') || this.concept.id}`;
        return document.location.href = url;
      });
    }
  };
  ConceptEditView.initClass();
  return ConceptEditView;
})());
