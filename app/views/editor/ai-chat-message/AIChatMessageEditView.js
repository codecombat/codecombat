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
let AIChatMessageEditView;
require('app/styles/editor/ai-chat-message/edit.sass');
const RootView = require('views/core/RootView');
const template = require('app/templates/editor/ai-chat-message/edit');
const AIChatMessage = require('models/AIChatMessage');
const ConfirmModal = require('views/core/ConfirmModal');
const PatchesView = require('views/editor/PatchesView');
const errors = require('core/errors');

const nodes = require('views/editor/level/treema_nodes');

require('lib/game-libraries');
require('lib/setupTreema');
const treemaExt = require('core/treema-ext');

module.exports = (AIChatMessageEditView = (function() {
  AIChatMessageEditView = class AIChatMessageEditView extends RootView {
    static initClass() {
      this.prototype.id = 'editor-ai-chat-message-edit-view';
      this.prototype.template = template;

      this.prototype.events = {
        'click #save-button': 'onClickSaveButton',
        'click #delete-button': 'confirmDeletion',
        'click #i18n-button': 'onPopulateI18N'
      };
    }

    constructor(options, chatMessageID) {
      super(options);
      this.deleteAIChatMessage = this.deleteAIChatMessage.bind(this);
      this.chatMessageID = chatMessageID;
      this.chatMessage = new AIChatMessage({_id: this.chatMessageID});
      this.chatMessage.saveBackups = true;
      this.supermodel.loadModel(this.chatMessage);
    }

    onLoaded() {
      super.onLoaded();
      this.buildTreema();
      return this.listenTo(this.chatMessage, 'change', () => {
        return this.treema.set('/', this.chatMessage.attributes);
      });
    }

    buildTreema() {
      if ((this.treema != null) || (!this.chatMessage.loaded)) { return; }
      const data = $.extend(true, {}, this.chatMessage.attributes);
      const options = {
        data,
        filePath: `db/ai_chat_message/${this.chatMessage.get('_id')}`,
        schema: AIChatMessage.schema,
        readOnly: me.get('anonymous'),
        supermodel: this.supermodel,
        nodeClasses: {
          'chat-message-parent-link': nodes.ChatMessageParentLinkNode,
          'ai-document-link': nodes.AIDocumentLinkNode
        }
      };
      this.treema = this.$el.find('#ai-chat-message-treema').treema(options);
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
        this.chatMessage.set(key, value);
      }

      const res = this.chatMessage.save();

      res.error((collection, response, options) => {
        return console.error(response);
      });

      return res.success(() => {
        const url = `/editor/ai-chat-message/${this.chatMessage.get('slug') || this.chatMessage.id}`;
        return document.location.href = url;
      });
    }

    onPopulateI18N() {
      return this.chatMessage.populateI18N();
    }

    confirmDeletion() {
      const renderData = {
        title: 'Are you really sure?',
        body: 'This will completely delete the chat message.',
        decline: 'Not really',
        confirm: 'Definitely'
      };

      const confirmModal = new ConfirmModal(renderData);
      confirmModal.on('confirm', this.deleteAIChatMessage);
      return this.openModalView(confirmModal);
    }

    deleteAIChatMessage() {
      return $.ajax({
        type: 'DELETE',
        success() {
          noty({
            timeout: 5000,
            text: 'Aaaand it\'s gone.',
            type: 'success',
            layout: 'topCenter'
          });
          return _.delay(() => application.router.navigate('/editor/ai-chat-message', {trigger: true})
          , 500);
        },
        error(jqXHR, status, error) {
          console.error(jqXHR);
          return {
            timeout: 5000,
            text: `Deleting chat message message failed with error code ${jqXHR.status}`,
            type: 'error',
            layout: 'topCenter'
          };
        },
        url: `/db/ai_chat_message/${this.chatMessage.id}`
      });
    }
  };
  AIChatMessageEditView.initClass();
  return AIChatMessageEditView;
})());
