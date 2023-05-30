// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ChatSearchView;
import 'app/styles/editor/chat/table.sass';
import SearchView from 'views/common/SearchView';

export default ChatSearchView = (function() {
  ChatSearchView = class ChatSearchView extends SearchView {
    static initClass() {
      this.prototype.id = 'editor-chat-home-view';
      this.prototype.modelLabel = 'Chat';
      this.prototype.model = require('models/ChatMessage');
      this.prototype.modelURL = '/db/chat_message';
      this.prototype.tableTemplate = require('app/templates/editor/chat/table');
      this.prototype.projection = ['startDate', 'endDate', 'kind', 'example', 'releasePhase', 'context.levelName', 'message.sender.name', 'message.text'];
      this.prototype.page = 'chat';
      this.prototype.canMakeNew = false;
      this.prototype.limit = 10000;
  
      this.prototype.events =
        {'click #delete-button': 'deleteChatMessage'};
    }

    getRenderData() {
      const context = super.getRenderData();
      context.currentEditor = 'editor.chat_title';
      context.currentNew = 'editor.new_chat_title';
      context.currentNewSignup = 'editor.new_chat_title_login';
      context.currentSearch = 'editor.chat_search_title';
      this.$el.i18n();
      this.applyRTLIfNeeded();
      return context;
    }

    deleteChatMessage(e) {
      const chatId = $(e.target).parents('tr').data('chat');
      this.$el.find(`tr[data-chat='${chatId}']`).remove();
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
        url: `/db/chat_message/${chatId}`
      });
    }

    formatChat(chat) {
      let content = __guard__(chat.get('message'), x => x.text) || '';
      content = content.replace(/^\|Free\|?:? ?(.*?)$/gm, '$1');
      content = content.replace(/^\|Issue\|?:? ?(.*?)$/gm, '\n$1');
      content = content.replace(/^\|Explanation\|?:? ?(.*?)$/gm, '\n*$1*\n');
      content = content.replace(/\|Code\|?:? ?```\n?((.|\n)*?)```\n?/g, (match, p1) => {
        return '[Fix Code]';
      });
      content = content.trim();
      content = marked(content, {gfm: true, breaks: true});
      content = content.replace(RegExp('  ', 'g'), '&nbsp; '); // coffeescript can't compile '/  /g'
      // Replace any <p><code>...</code></p> with <pre><code>...</code></pre>
      content = content.replace(/<p><code>((.|\n)*?)(?:(?!<\/code>)(.|\n))*?<\/code><\/p>/g, match => match.replace(/<p><code>/g, '<pre><code>').replace(/<\/code><\/p>/g, '</code></pre>'));
      content = content.replace(/\[Fix Code\]/g, '<p><button class="btn btn-illustrated btn-small btn-primary fix-code-button">Fix Code</button></p>');
      return content;
    }
  };
  ChatSearchView.initClass();
  return ChatSearchView;
})();

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}