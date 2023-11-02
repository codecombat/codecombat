// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AIModelSearchView;
require('app/styles/editor/ai-chat-message/table.sass');
const SearchView = require('views/common/SearchView');

module.exports = (AIModelSearchView = (function() {
  AIModelSearchView = class AIModelSearchView extends SearchView {
    static initClass() {
      this.prototype.id = 'editor-ai-chat-message-home-view';
      this.prototype.modelLabel = 'Model';
      this.prototype.model = require('models/AIChatMessage');
      this.prototype.modelURL = '/db/ai_chat_message';
      this.prototype.tableTemplate = require('app/templates/editor/ai-chat-message/table');
      this.prototype.projection = ['name', 'preview', 'actor', 'description', 'text', 'document','parent', 'parentKind'];
      this.prototype.page = 'ai-chat-message';
      this.prototype.canMakeNew = false;
  
      this.prototype.events =
        {'click #delete-button': 'deleteAIModel'};
    }

    getRenderData() {
      const context = super.getRenderData();
      context.currentEditor = 'editor.ai_chat_message_title';
      context.currentNew = 'editor.new_ai_chat_message_title';
      context.currentNewSignup = 'editor.new_ai_chat_message_title_login';
      context.currentSearch = 'editor.ai_chat_message_search_title';
      this.$el.i18n();
      this.applyRTLIfNeeded();
      return context;
    }

    deleteAIModel(e) {
      const chatMessageId = $(e.target).parents('tr').data('chat-message');
      const chatMessageName = $(e.target).parents('tr').data('name');
      if (!window.confirm(`Really delete chat message ${chatMessageName}?`)) {
        noty({text: 'Cancelled', timeout: 1000});
        return;
      }
      this.$el.find(`tr[data-chat-message='${chatMessageId}']`).remove();
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
            text: `Deleting chat message failed with error code ${jqXHR.status}`,
            type: 'error',
            layout: 'topCenter'
          };
        },
        url: `/db/ai_chat_messsage/${chatMessageId}`
      });
    }
  };
  AIModelSearchView.initClass();
  return AIModelSearchView;
})());
