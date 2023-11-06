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
let AIDocumentEditView;
require('app/styles/editor/ai-document/edit.sass');
const RootView = require('views/core/RootView');
const template = require('app/templates/editor/ai-document/edit');
const AIDocument = require('models/AIDocument');
const ConfirmModal = require('views/core/ConfirmModal');
const PatchesView = require('views/editor/PatchesView');
const errors = require('core/errors');

require('lib/game-libraries');
require('lib/setupTreema');
const treemaExt = require('core/treema-ext');

module.exports = (AIDocumentEditView = (function() {
  AIDocumentEditView = class AIDocumentEditView extends RootView {
    static initClass() {
      this.prototype.id = 'editor-ai-document-edit-view';
      this.prototype.template = template;

      this.prototype.events = {
        'click #save-button': 'onClickSaveButton',
        'click #delete-button': 'confirmDeletion'
      };
    }

    constructor(options, documentID) {
      super(options);
      this.deleteAIDocument = this.deleteAIDocument.bind(this);
      this.documentID = documentID;
      this.document = new AIDocument({_id: this.documentID});
      this.document.saveBackups = true;
      this.supermodel.loadModel(this.document);
    }

    onLoaded() {
      super.onLoaded();
      this.buildTreema();
      return this.listenTo(this.document, 'change', () => {
        return this.treema.set('/', this.document.attributes);
      });
    }

    buildTreema() {
      if ((this.treema != null) || (!this.document.loaded)) { return; }
      const data = $.extend(true, {}, this.document.attributes);
      const options = {
        data,
        filePath: `db/ai_document/${this.document.get('_id')}`,
        schema: AIDocument.schema,
        readOnly: me.get('anonymous'),
        supermodel: this.supermodel,
        nodeClasses: {
          'document-by-type': DocumentByTypeNode
        }
      };
      this.treema = this.$el.find('#ai-document-treema').treema(options);
      this.treema.build();
      return this.treema.open(2);
    }

    afterRender() {
      super.afterRender();
      if (!this.supermodel.finished()) { return; }
    }

    onClickSaveButton(e) {
      this.treema.endExistingEdits();
      for (var key in this.treema.data) {
        var value = this.treema.data[key];
        this.document.set(key, value);
      }

      const res = this.document.save();

      res.error((collection, response, options) => {
        return console.error(response);
      });

      return res.success(() => {
        const url = `/editor/ai-document/${this.document.get('slug') || this.document.id}`;
        return document.location.href = url;
      });
    }

    confirmDeletion() {
      const renderData = {
        title: 'Are you really sure?',
        body: 'This will completely delete the document.',
        decline: 'Not really',
        confirm: 'Definitely'
      };

      const confirmModal = new ConfirmModal(renderData);
      confirmModal.on('confirm', this.deleteAIDocument);
      return this.openModalView(confirmModal);
    }

    deleteAIDocument() {
      return $.ajax({
        type: 'DELETE',
        success() {
          noty({
            timeout: 5000,
            text: 'Aaaand it\'s gone.',
            type: 'success',
            layout: 'topCenter'
          });
          return _.delay(() => application.router.navigate('/editor/ai-document', {trigger: true})
          , 500);
        },
        error(jqXHR, status, error) {
          console.error(jqXHR);
          return {
            timeout: 5000,
            text: `Deleting document message failed with error code ${jqXHR.status}`,
            type: 'error',
            layout: 'topCenter'
          };
        },
        url: `/db/ai_document/${this.document.id}`
      });
    }
  };
  AIDocumentEditView.initClass();
  return AIDocumentEditView;
})());


class DocumentByTypeNode extends TreemaNode.nodeMap.string {
  buildValueForDisplay(valEl, data) {
    super.buildValueForDisplay(valEl, data);

    if (!data) { return; }
    if (this.parent.data.type === 'html') {
      // Create a new iframe element
      const iframe = document.createElement('iframe');

      // Set some properties for the iframe
      iframe.style.width = '200%';
      iframe.style.height = '500px';
      iframe.className = 'treema-iframe';
      iframe.style.overflow = 'scroll';
      iframe.style.transform = 'scale(0.5) translate(-50%, -50%)';
      iframe.srcdoc = data;
      // Append the new iframe to the parent element
      this.$el.find('.treema-iframe').remove();
      return this.$el.append(iframe);
    }
  }
}


  // limitChoices: (options) ->
  //   if @parent.keyForParent is 'concepts' and (not this.parent.parent)
  //     options = (o for o in options when _.find(concepts, (c) -> c.concept is o and not c.automatic and not c.deprecated))  # Allow manual, not automatic
  //   else
  //     options = (o for o in options when _.find(concepts, (c) -> c.concept is o and not c.deprecated))  # Allow both
  //   super options

  // onClick: (e) ->
  //   return if this.parent.keyForParent is 'concepts' and (not this.parent.parent) and @$el.hasClass('concept-automatic')  # Don't allow editing of automatic concepts
  //   super e