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
let StandardsCorrelationEditView;
require('app/styles/editor/standards/edit.sass');
const RootView = require('views/core/RootView');
const template = require('app/templates/editor/standards/edit');
const StandardsCorrelation = require('models/StandardsCorrelation');
const ConfirmModal = require('views/core/ConfirmModal');
const PatchesView = require('views/editor/PatchesView');
const errors = require('core/errors');
const nodes = require('views/editor/level/treema_nodes');

require('lib/game-libraries');
require('lib/setupTreema');
const treemaExt = require('core/treema-ext');

const Concepts = require('collections/Concepts');
const schemas = require('app/schemas/schemas');
let concepts = [];

module.exports = (StandardsCorrelationEditView = (function() {
  StandardsCorrelationEditView = class StandardsCorrelationEditView extends RootView {
    static initClass() {
      this.prototype.id = 'editor-standards-edit-view';
      this.prototype.template = template;

      this.prototype.events = {
        'click #save-button': 'onClickSaveButton',
        'click #i18n-button': 'onPopulateI18N'
      };
    }

    constructor(options, standardsID) {
      super(options);
      this.standardsID = standardsID;
      this.standards = new StandardsCorrelation({_id: this.standardsID});
      this.standards.saveBackups = true;
      this.supermodel.loadModel(this.standards);
    }

    onLoaded() {
      super.onLoaded();
      this.concepts = new Concepts([]);

      this.listenTo(this.concepts, 'sync', () => {
        concepts = this.concepts.models;
        schemas.concept.enum = _.map(concepts, c => c.get('key'));
        return this.onConceptsLoaded();
      });

      return this.concepts.fetch({
        data: { skip: 0, limit: 1000 }});
    }

    onConceptsLoaded() {
      this.buildTreema();
      return this.listenTo(this.standards, 'change', () => {
        this.standards.updateI18NCoverage();
        return this.treema.set('/', this.standards.attributes);
      });
    }

    buildTreema() {
      if ((this.treema != null) || (!this.standards.loaded)) { return; }
      const data = $.extend(true, {}, this.standards.attributes);
      const options = {
        data,
        filePath: `db/standards/${this.standards.get('_id')}`,
        schema: StandardsCorrelation.schema,
        readOnly: me.get('anonymous'),
        supermodel: this.supermodel,
        nodeClasses: {
          'concepts-list': nodes.conceptNodes(concepts).ConceptsListNode,
          'concept': nodes.conceptNodes(concepts).ConceptNode,
          'us-state-code': nodes.StateNode
        }
      };
      this.treema = this.$el.find('#standards-treema').treema(options);
      this.treema.build();
      return (this.treema.childrenTreemas.rewards != null ? this.treema.childrenTreemas.rewards.open(3) : undefined);
    }

    afterRender() {
      super.afterRender();
      if (!this.supermodel.finished()) { return; }
      if (me.get('anonymous')) { this.showReadOnly(); }
      this.patchesView = this.insertSubView(new PatchesView(this.standards), this.$el.find('.patches-view'));
      return this.patchesView.load();
    }

    onPopulateI18N() {
      return this.standards.populateI18N();
    }

    onClickSaveButton(e) {
      this.treema.endExistingEdits();
      for (var key in this.treema.data) {
        var value = this.treema.data[key];
        this.standards.set(key, value);
      }
      this.standards.updateI18NCoverage();

      const res = this.standards.save();

      res.error((collection, response, options) => {
        return console.error(response);
      });

      return res.success(() => {
        const url = `/editor/standards/${this.standards.get('slug') || this.standards.id}`;
        return document.location.href = url;
      });
    }
  };
  StandardsCorrelationEditView.initClass();
  return StandardsCorrelationEditView;
})());