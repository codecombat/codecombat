/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AIDocumentSearchView;
require('app/styles/editor/ai-document/table.sass');
const SearchView = require('views/common/SearchView');

module.exports = (AIDocumentSearchView = (function() {
  AIDocumentSearchView = class AIDocumentSearchView extends SearchView {
    static initClass() {
      this.prototype.id = 'editor-ai-document-home-view';
      this.prototype.modelLabel = 'Document';
      this.prototype.model = require('models/AIDocument');
      this.prototype.modelURL = '/db/ai_document';
      this.prototype.tableTemplate = require('app/templates/editor/ai-document/table');
      this.prototype.projection = ['type', 'source'];
      this.prototype.page = 'ai-document';
      this.prototype.canMakeNew = false;
  
      this.prototype.events =
        {'click #delete-button': 'deleteAIDocument'};
    }

    getRenderData() {
      const context = super.getRenderData();
      context.currentEditor = 'editor.ai_document_title';
      context.currentNew = 'editor.new_ai_document_title';
      context.currentNewSignup = 'editor.new_ai_document_title_login';
      context.currentSearch = 'editor.ai_document_search_title';
      this.$el.i18n();
      this.applyRTLIfNeeded();
      return context;
    }

    deleteAIDocument(e) {
      const documentId = $(e.target).parents('tr').data('document');
      const documentName = $(e.target).parents('tr').data('name');
      if (!window.confirm(`Really delete document ${documentName}?`)) {
        noty({text: 'Cancelled', timeout: 1000});
        return;
      }
      this.$el.find(`tr[data-document='${documentId}']`).remove();
      return $.ajax({
        type: 'DELETE',
        success() {
          return noty({
            timeout: 2000,
            text: 'Aaaand it\'s gone.',
            type: 'success',
            layout: 'topCenter'
          });
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
        url: `/db/ai_document/${documentId}`
      });
    }
  };
  AIDocumentSearchView.initClass();
  return AIDocumentSearchView;
})());
