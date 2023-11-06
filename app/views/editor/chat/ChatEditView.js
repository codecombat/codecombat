// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ChatEditView;
require('app/styles/editor/chat/edit.sass');
const RootView = require('views/core/RootView');
const template = require('app/templates/editor/chat/edit');
const ChatMessage = require('models/ChatMessage');
const ConfirmModal = require('views/core/ConfirmModal');
const PatchesView = require('views/editor/PatchesView');
const errors = require('core/errors');

require('lib/game-libraries');
require('lib/setupTreema');
const treemaExt = require('core/treema-ext');

module.exports = (ChatEditView = (function() {
  ChatEditView = class ChatEditView extends RootView {
    static initClass() {
      this.prototype.id = 'editor-chat-edit-view';
      this.prototype.template = template;

      this.prototype.events = {
        'click #save-button': 'onClickSaveButton',
        'click #i18n-button': 'onPopulateI18N',
        'click #delete-button': 'confirmDeletion',
        'click #fix-button': 'onFix',
        'click #add-code-button': 'onAddCode',
        'click #regenerate-message-button': 'onRegenerateMessage'
      };
    }

    constructor(options, chatID) {
      super(options);
      this.deleteChatMessage = this.deleteChatMessage.bind(this);
      this.chatID = chatID;
      this.chat = new ChatMessage({_id: this.chatID});
      this.chat.saveBackups = true;
      this.supermodel.loadModel(this.chat);
    }

    onLoaded() {
      super.onLoaded();
      this.buildTreema();
      return this.listenTo(this.chat, 'change', () => {
        this.chat.updateI18NCoverage();
        return this.treema.set('/', this.chat.attributes);
      });
    }

    buildTreema() {
      if ((this.treema != null) || (!this.chat.loaded)) { return; }
      const data = $.extend(true, {}, this.chat.attributes);
      const options = {
        data,
        filePath: `db/chat_message/${this.chat.get('_id')}`,
        schema: ChatMessage.schema,
        readOnly: me.get('anonymous'),
        supermodel: this.supermodel
      };
      this.treema = this.$el.find('#chat-treema').treema(options);
      this.treema.build();
      if (this.treema.childrenTreemas.message != null) {
        this.treema.childrenTreemas.message.open(2);
      }
      if (this.treema.childrenTreemas.context != null) {
        this.treema.childrenTreemas.context.open(2);
      }
      __guard__(this.treema.childrenTreemas.context != null ? this.treema.childrenTreemas.context.childrenTreemas.i18n : undefined, x => x.close());
      return __guard__(this.treema.childrenTreemas.context != null ? this.treema.childrenTreemas.context.childrenTreemas.apiProperties : undefined, x1 => x1.close());
    }

    afterRender() {
      let left;
      super.afterRender();
      if (!this.supermodel.finished()) { return; }
      return this.originalMessageText != null ? this.originalMessageText : (this.originalMessageText = (left = __guard__(this.chat.get('message'), x => x.originalText)) != null ? left : __guard__(this.chat.get('message'), x1 => x1.text));
    }

    onPopulateI18N() {
      return this.chat.populateI18N();
    }

    onClickSaveButton(e) {
      this.treema.endExistingEdits();
      for (var key in this.treema.data) {
        var value = this.treema.data[key];
        this.chat.set(key, value);
      }

      // Store chat.message.originalText iff the current text is different than the original
      const message = this.chat.get('message');
      if ((message.text !== this.originalMessageText) && (message.originalText !== this.originalMessageText)) {
        message.originalText  = this.originalMessageText;
        this.chat.set('message', message);
      }

      this.chat.updateI18NCoverage();

      const res = this.chat.save();

      res.error((collection, response, options) => {
        return console.error(response);
      });

      return res.success(() => {
        const url = `/editor/chat/${this.chat.get('slug') || this.chat.id}`;
        return document.location.href = url;
      });
    }

    confirmDeletion() {
      const renderData = {
        title: 'Are you really sure?',
        body: 'This will completely delete the chat message.',
        decline: 'Not really',
        confirm: 'Definitely'
      };

      const confirmModal = new ConfirmModal(renderData);
      confirmModal.on('confirm', this.deleteChatMessage);
      return this.openModalView(confirmModal);
    }

    deleteChatMessage() {
      return $.ajax({
        type: 'DELETE',
        success() {
          noty({
            timeout: 5000,
            text: 'Aaaand it\'s gone.',
            type: 'success',
            layout: 'topCenter'
          });
          return _.delay(() => application.router.navigate('/editor/chat', {trigger: true})
          , 500);
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
        url: `/db/chat_message/${this.chat.id}`
      });
    }

    onFix(e) {
      const current = this.treema.get('/context/code/current/javascript');
      if ((current == null)) {
        return noty({
          timeout: 5000,
          text: 'You need to have current code to fix',
          type: 'error',
          layout: 'topCenter'
        });
      }
      this.treema.set('/context/code/fixed', {javascript: current});
      this.treema.childrenTreemas.context.childrenTreemas.code.open(1);
      this.treema.childrenTreemas.context.childrenTreemas.code.childrenTreemas.fixed.open();
      return this.treema.childrenTreemas.context.childrenTreemas.code.childrenTreemas.current.open();
    }

    onAddCode(e) {
      const a = this.treema.get('/context/code/current/javascript');
      let b = this.treema.get('/context/code/fixed/javascript');
      if (b == null) { b = this.treema.get('/context/code/solution/javascript'); }
      if ((a == null) || (b == null)) {
        return noty({
          timeout: 5000,
          text: 'You need to have both a current and solution context to add structured code to AI response.',
          type: 'error',
          layout: 'topCenter'
        });
      }
      let code = b;
      code = code.replace(/\s+$/, '');
      this.treema.set('/message/textComponents/code', code);
      const messageText = this.treema.get('/message/text');
      this.treema.set('/message/textComponents/actionButtons', [{action: 'fix', text: 'Fix It'}]);
      const button = '<button action="fix">Fix It</button>';
      this.treema.set('/message/text', `${messageText}\n\n${button}\n\n\`\`\`\n${code}\n\`\`\``);  // TODO: replace existing code?
      if (this.treema.childrenTreemas.message != null) {
        this.treema.childrenTreemas.message.close();
      }
      return (this.treema.childrenTreemas.message != null ? this.treema.childrenTreemas.message.open(2) : undefined);
    }

    onRegenerateMessage(e) {
      let code, explanation, free;
      const structured = this.treema.get('message/textComponents') || {};
      const components = [];
      if (free = structured.freeText) { components.push(`|Free|: ${free}`); }
      const { line, text } = structured.codeIssue || {};
      if (text && line) { components.push(`|Issue|: Line ${line}: ${text}`); }
      if (text && !line) { components.push(`|Issue|: ${text}`); }
      if (explanation = structured.codeIssueExplanation != null ? structured.codeIssueExplanation.text : undefined) { components.push(`|Explanation|: ${explanation}`); }
      for (var link of Array.from(structured.links || [])) {
        components.push(`|Link|: [${link.text}](${link.url})`);
      }
      if (code = structured.code) { components.push(`|Code|: \`\`\`\n${code}\n\`\`\``); }
      this.treema.set('message/text', components.join('\n'));
      if (this.treema.childrenTreemas.message != null) {
        this.treema.childrenTreemas.message.close();
      }
      return (this.treema.childrenTreemas.message != null ? this.treema.childrenTreemas.message.open(2) : undefined);
    }
  };
  ChatEditView.initClass();
  return ChatEditView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}