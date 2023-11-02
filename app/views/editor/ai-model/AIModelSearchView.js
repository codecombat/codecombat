/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AIModelSearchView;
require('app/styles/editor/ai-model/table.sass');
const SearchView = require('views/common/SearchView');

module.exports = (AIModelSearchView = (function() {
  AIModelSearchView = class AIModelSearchView extends SearchView {
    static initClass() {
      this.prototype.id = 'editor-ai-model-home-view';
      this.prototype.modelLabel = 'Model';
      this.prototype.model = require('models/AIModel');
      this.prototype.modelURL = '/db/ai_model';
      this.prototype.tableTemplate = require('app/templates/editor/ai-model/table');
      this.prototype.projection = ['name', 'family', 'description'];
      this.prototype.page = 'ai-model';
      this.prototype.canMakeNew = true;
  
      this.prototype.events =
        {'click #delete-button': 'deleteAIModel'};
    }

    getRenderData() {
      const context = super.getRenderData();
      context.currentEditor = 'editor.ai_model_title';
      context.currentNew = 'editor.new_ai_model_title';
      context.currentNewSignup = 'editor.new_ai_model_title_login';
      context.currentSearch = 'editor.ai_model_search_title';
      this.$el.i18n();
      this.applyRTLIfNeeded();
      return context;
    }

    deleteAIModel(e) {
      const modelId = $(e.target).parents('tr').data('model');
      const modelName = $(e.target).parents('tr').data('name');
      if (!window.confirm(`Really delete model ${modelName}?`)) {
        noty({text: 'Cancelled', timeout: 1000});
        return;
      }
      this.$el.find(`tr[data-model='${modelId}']`).remove();
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
            text: `Deleting model message failed with error code ${jqXHR.status}`,
            type: 'error',
            layout: 'topCenter'
          };
        },
        url: `/db/ai_model/${modelId}`
      });
    }
  };
  AIModelSearchView.initClass();
  return AIModelSearchView;
})());
