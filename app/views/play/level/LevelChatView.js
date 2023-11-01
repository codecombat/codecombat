/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LevelChatView;
require('app/styles/play/level/chat.sass');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/play/level/chat');
const {me} = require('core/auth');
const LevelBus = require('lib/LevelBus');
const ChatMessage = require('models/ChatMessage');
const utils = require('core/utils');
const fetchJson = require('core/api/fetch-json');
const co = require('co');
const userCreditApi = require('core/api/user-credits');
const SubscribeModal = require('views/core/SubscribeModal');
const _ = require('lodash');

module.exports = (LevelChatView = (function() {
  LevelChatView = class LevelChatView extends CocoView {
    static initClass() {
      this.prototype.id = 'level-chat-view';
      this.prototype.template = template;
      this.prototype.open = false;
      this.prototype.visible = false;

      this.prototype.events = {
        'keydown textarea': 'onChatKeydown',
        'keypress textarea': 'onChatKeypress',
        'click i': 'onIconClick',
        'click .fix-code-button': 'onFixCodeClick'
      };

      this.prototype.subscriptions = {
        'level:toggle-solution': 'onToggleSolution',
        'level:close-solution': 'onCloseSolution',
        'level:add-user-chat': 'onAddUserChat',
        'tome:spell-changed': 'onSpellChanged'
      };
    }

    constructor(options) {
      super(options);
      this.clearOldMessages = this.clearOldMessages.bind(this);
      this.onChatResponse = this.onChatResponse.bind(this);
      this.onWindowResize = this.onWindowResize.bind(this);
      this.levelID = options.levelID;
      this.session = options.session;
      this.sessionID = options.sessionID;
      this.bus = LevelBus.get(this.levelID, this.sessionID);
      this.aceConfig = options.aceConfig;
      this.onWindowResize = _.debounce(this.onWindowResize, 50);
      $(window).on('resize', this.onWindowResize);

      //# TODO: we took out session.multiplayer, so this will not fire. If we want to resurrect it, we'll of course need a new way of activating chat.
      //@listenTo(@session, 'change:multiplayer', @updateMultiplayerVisibility)
      this.visible = (this.aceConfig.levelChat !== 'none') || (me.getLevelChatExperimentValue() === 'beta');  // not 'control'

      this.regularlyClearOldMessages();
      this.playNoise = _.debounce(this.playNoise, 100);
      this.diffShown = false;
    }

    updateMultiplayerVisibility() {
      if (this.$el == null) { return; }
      try {
        return this.$el.toggle(Boolean(this.session.get('multiplayer')));
      } catch (e) {
        return console.error(`Couldn't toggle the style on the LevelChatView to ${Boolean(this.session.get('multiplayer'))} because of an error:`, e);
      }
    }

    afterRender() {
      this.chatTables = $('.table', this.$el);
      //@updateMultiplayerVisibility()
      this.$el.toggle(this.visible);
      return this.onWindowResize({});
    }

    regularlyClearOldMessages() {
      return;  // Leave chatbot messages around, actually
      return this.clearOldMessagesInterval = setInterval(this.clearOldMessages, 5000);
    }

    clearOldMessages() {
      const rows = $('.closed-chat-area.tr');
      return (() => {
        const result = [];
        for (var row of Array.from(rows)) {
          row = $(row);
          var added = row.data('added');
          if ((new Date().getTime() - added) > (60 * 1000)) {
            result.push(row.fadeOut(1000, function() { return $(this).remove(); }));
          } else {
            result.push(undefined);
          }
        }
        return result;
      })();
    }

    onNewMessage({ message, messageId }) {
      if (!(message != null ? message.system : undefined)) { this.$el.show(); }
      this.addOne({ message, messageId });
      this.trimClosedPanel();
      if (message.authorID !== me.id) { return this.playNoise(); }
    }

    playNoise() {
      return this.playSound('chat_received');
    }

    messageObjectToJQuery({ message, messageId, existingRow }) {
      let buttonContent, postContent, tr;
      const td = $('<div class="td message-content"></div>');
      let content = message.content || message.text;

      // Hide incomplete structured chat tags
      content = content.replace(/^\|$/gm, '');
      content = content.replace(/^\|Free\|?:? ?(.*?)$/gm, '$1');
      content = content.replace(/^\|Issue\|?:? ?(.*?)$/gm, '\n$1');
      content = content.replace(/^\|Explanation\|?:? ?(.*?)$/gm, '\n*$1*\n');
      //content = content.replace /\|Code\|?:? ?`{0,3}\n?((.|\n)*?)`{0,3}\n?$/g, '```$1```'
      content = content.replace(/\|Code\|?:? ?\n?```.*?\n((.|\n)*?)```\n?/g, (match, p1) => {
        this.lastFixedCode = p1;
        return '[Show Me]';
      });
      content = content.replace(/\|Code\|?:? ?\n?`{0,3}.*?\n((.|\n)*?)`{0,3}\n?$/g, function( match, p1) {
        const numberOfLines = (p1.match(/\n/g) || []).length + 1;
        if (p1) {
          Backbone.Mediator.publish('level:update-solution', {code: p1});
        }
        return '\n[Show Me]\n*Loading code fix' + '.'.repeat(numberOfLines) + '...*';
      });
      // Close any unclosed backticks delimiters so we get complete <code> tags
      const unclosedBackticks = (content.match(/`/g) || []).length;
      if ((unclosedBackticks % 2) !== 0) {
        content += '`';
      }

      //content = _.string.escapeHTML(content.trim())  # hmm, what to do with escaping when we often need code?
      content = content.trim();
      content = marked(content, {gfm: true, breaks: true});
      // TODO: this probably doesn't work with the links and buttons we intend to have, gotta think about sanitization properly

      content = content.replace(RegExp('  ', 'g'), '&nbsp; '); // coffeescript can't compile '/  /g'

      // Replace any <p><code>...</code></p> with <pre><code>...</code></pre>
      content = content.replace(/<p><code>((.|\n)*?)(?:(?!<\/code>)(.|\n))*?<\/code><\/p>/g, match => match.replace(/<p><code>/g, '<pre><code>').replace(/<\/code><\/p>/g, '</code></pre>'));

      if (_.string.startsWith(content, '/me')) {
        content = (message.authorName || (message.sender != null ? message.sender.name : undefined)) + content.slice(3);
      }

      const splitContent = content.split('\[Show Me\]');
      const preContent = splitContent[0];
      if (splitContent.length > 1) {
        buttonContent = `<p><button class='btn btn-illustrated btn-small btn-primary fix-code-button'>${$.i18n.t('play_level.chat_fix_' + (this.diffShown ? 'hide' : 'show'))}</button></p>`;
        postContent = splitContent[1];
      } else {
        this.$el.find('.fix-code-button').parent().remove();  // We only keep track of the latest one to fix, so get rid of old ones
        buttonContent = '';
        postContent = '';
      }

      // [show me] only appears on the ai message
      if (message.system) {
        td.append($('<span class="system"></span>').html(preContent));

      } else if (_.string.startsWith(content, '/me')) {
        td.append($('<span class="action"></span>').html(preContent));

      } else {
        // td.append($('<strong></strong>').text((message.authorName or message.sender?.name) + ': '))
        td.append($('<span class="pre-content"></span>').html(preContent));
        td.append($('<span class="button-content"></span>').html(buttonContent));
        td.append($('<span class="post-content"></span>').html(postContent));
      }

      if (existingRow != null ? existingRow.length : undefined) {
        tr = $(existingRow[0]);
        if ((splitContent.length > 1) && this.$el.find('.fix-code-button').length) { // if button should show, only replace the post content
          tr.find('.post-content').replaceWith(td.find('.post-content'));
        } else {
          tr.find('.td.message-content').replaceWith(td);
        }
      } else {
        let avatarTd;
        tr = $('<div class="tr message-row"></div>');
        const mbody = $('<div class="message-body"></div>');
        if ((message.authorID === me.id) || ((message.sender != null ? message.sender.id : undefined) === me.id)) {
          tr.addClass('me');
          avatarTd = $(`<div class='td player-avatar-cell avatar-cell'><a href='/editor/chat/${messageId || ''}' target='_blank'><img class='avatar' src='/db/user/${me.id}/avatar?s=80' alt='Player'></a></div>`);
        } else {
          avatarTd = $(`<div class='td chatbot-avatar-cell avatar-cell'><a href='/editor/chat/${messageId || ''}' target='_blank'><img class='avatar' src='/images/level/baby-griffin.png' alt='AI'></a></div>`);
        }
        if (message.streaming) { tr.addClass('streaming'); }
        mbody.append(avatarTd);
        mbody.append(td);
        tr.append(mbody);
      }
      return tr;
    }

    addOne({ message, messageId }) {
      if (message.system && (message.authorID === me.id)) { return; }
      if (!this.open) {
        this.onIconClick({});
      }
      const openPanel = $('.open-chat-area', this.$el);
      const height = openPanel.outerHeight();
      const distanceFromBottom = openPanel[0].scrollHeight - height - openPanel[0].scrollTop;
      const doScroll = distanceFromBottom < 10;
      const tr = this.messageObjectToJQuery({ message, messageId });
      tr.data('added', new Date().getTime());
      this.chatTables.append(tr);
      if (doScroll) { return this.scrollDown(); }
    }

    trimClosedPanel() {
      const closedPanel = $('.closed-chat-area', this.$el);
      const limit = 10;
      const rows = $('.tr', closedPanel);
      for (let i = 0; i < rows.length; i++) {
        var row = rows[i];
        if ((rows.length - i) <= limit) { break; }
        row.remove();
      }
      return this.scrollDown();
    }

    onChatKeydown(e) {
      return _.defer(function() {
        $(e.target).css('height', 27);
        return $(e.target).css('height', e.target.scrollHeight);
      });
    }

    onChatKeypress(e) {
      if (!key.isPressed('enter') || !!key.shift) { return; }
      const text = _.string.strip($(e.target).val());
      if (!text) { return false; }
      //@bus.sendMessage(text)  # TODO: bring back bus?
      this.checkCreditsAndAddMessage(text);
      $(e.target).val('');
      return false;
    }

    onIconClick(e) {
      this.open = !this.open;
      const openPanel = $('.open-chat-area', this.$el).toggle(this.open);
      const closedPanel = $('.closed-chat-area', this.$el).toggle(!this.open);
      this.scrollDown();
      if (window.getSelection != null) {
        const sel = window.getSelection();
        if (typeof sel.empty === 'function') {
          sel.empty();
        }
        return (typeof sel.removeAllRanges === 'function' ? sel.removeAllRanges() : undefined);
      } else {
        return document.selection.empty();
      }
    }

    onFixCodeClick(e) {
      return Backbone.Mediator.publish('level:toggle-solution', { code: this.lastFixedCode != null ? this.lastFixedCode : '' });
    }

    onToggleSolution() {
      const btn = this.$el.find('.fix-code-button');
      const show = $.i18n.t('play_level.chat_fix_show');
      const hide = $.i18n.t('play_level.chat_fix_hide');
      this.diffShown = !this.diffShown;
      if (this.diffShown) {
        return btn.html(hide);
      } else {
        return btn.html(show);
      }
    }

    onCloseSolution(e) {
      this.diffShown = false;
      this.$el.find('.fix-code-button').html($.i18n.t('play_level.chat_fix_show'));
      if (e.removeButton) { // when code is fixed, remove the button
        return this.$el.find('.fix-code-button').parent().remove();
      }
    }

    onAddUserChat(e) {
      return this.checkCreditsAndAddMessage(e.message);
    }

    checkCreditsAndAddMessage(message) {
      const uuid = crypto.randomUUID() || Date.now();
      return userCreditApi.redeemCredits({
        operation: 'LEVEL_CHAT_BOT',
        id: `${uuid}|${message.slice(0, 20)}`
      })
        .then(res => {
          return this.saveChatMessage({ text:  message });
      })
        .catch(err => {
          console.log('user credit redemption error', err);
          message = (err != null ? err.message : undefined) || 'Internal error';
          if (err.code === 402) {
            if (!me.hasSubscription()) {
              message = $.i18n.t('play_level.not_enough_credits_bot');
              this.openModalView(new SubscribeModal());
            } else {
              const {
                creditsLeft
              } = err;
              const creditObj = _.find(creditsLeft, c => c.creditsLeft <= 0);
              const interval = creditObj.durationKey;
              const amount = creditObj.durationAmount;
              message = $.i18n.t('play_level.not_enough_credits_interval', { interval, amount });
            }
          }
          return noty({ text: message, type: 'error', layout: 'center', timeout: 5000 });
      });
    }

    scrollDown() {
      const openPanel = $('.open-chat-area', this.$el)[0];
      return openPanel.scrollTop = openPanel.scrollHeight || 1000000;
    }

    onSpellChanged() {
      if (this.savingChatMessage) {
        this.reallySaveChatMessage(this.savingChatMessage);
        return this.savingChatMessage = undefined;
      }
    }

    isSpellChanged() {
      const {
        aether
      } = this.parent.subviews.tome_view.spellView.spellThang;
      const {
        spell
      } = this.parent.subviews.tome_view.spellView;
      return spell.source !== aether.raw;
    }

    cleanUpApiProperties(chat) {
      const {
        context
      } = chat;
      const currentCode = Object.values(context.code.current)[0];
      const solutionCode = __guard__(Object.values(context.code.solution || {}), x => x[0]) || ''; // let's only keep properties in current code
      const allApiProperties = context.apiProperties;
      const apiProperties = [];
      for (var doc of Array.from(allApiProperties)) {
        if (currentCode.includes(doc.name) || solutionCode.includes(doc.name)) {
          apiProperties.push(doc);
        }
      }
      return context.apiProperties = apiProperties;
    }

    saveChatMessage({ text, sender }) {
      if (this.isSpellChanged()) {
        Backbone.Mediator.publish('tome:manual-cast', {realTime: false});
        return this.savingChatMessage = { text, sender };
      } else {
        this.reallySaveChatMessage({ text, sender });
        return this.savingChatMessage = undefined;
      }
    }

    reallySaveChatMessage({ text, sender }) {
      const chatMessage = new ChatMessage(this.getChatMessageProps({ text, sender }));
      if (this.chatMessages == null) { this.chatMessages = []; }
      this.chatMessages.push(chatMessage);
      Backbone.Mediator.publish('level:gather-chat-message-context', { chat: chatMessage.attributes });
      this.cleanUpApiProperties(chatMessage.attributes);
      // This will enrich the message with the props from other parts of the app
      this.listenToOnce(chatMessage, 'sync', this.onChatMessageSaved);
      chatMessage.save();
      return this.$el.find('textarea').attr('placeholder', '');
    }
      //@onNewMessage message: chatMessage.get('message'), messageId: chatMessage.get('_id')  # TODO: do this now and add message id link later

    onChatMessageSaved(chatMessage) {
      this.onNewMessage({message: chatMessage.get('message'), messageId: chatMessage.get('_id')});  // TODO: temporarily putting this after save so we have message id link
      if (__guard__(__guard__(chatMessage.get('message'), x1 => x1.sender), x => x.kind) === 'bot') { return; }
      //fetchJson("/db/chat_message/#{chatMessage.id}/ai-response").then @onChatResponse
      return this.fetchChatMessageStream(chatMessage.id);
    }

    fetchChatMessageStream(chatMessageId) {
      const model = utils.getQueryVariable('model') || 'gpt-4'; // or 'gpt-4'
      return fetch(`/db/chat_message/${chatMessageId}/ai-response?model=${model}`).then(co.wrap(function*(response) {
        const reader = response.body.getReader();
        const decoder = new TextDecoder('utf-8');
        const sender = { kind: 'bot', name: 'Code AI' };  // TODO: handle sender name again
        this.startStreamingAIChatMessage(sender);
        let result = '';
        Backbone.Mediator.publish('level:streaming-solution', {finish: false});
        while (true) {
          var { done, value } = yield reader.read();
          var chunk = decoder.decode(value);
          chunk = chunk.replace(/(^{"propertyA":\["|"\],"propertyB":\[\]}$)/g, '').replace(/\\n/g, '\n').replace(/\\"/g, '"');
          result += chunk;
          this.addToStreamingAIChatMessage({sender, chunk, result});
          if (done) { break; }
        }

        Backbone.Mediator.publish('level:streaming-solution', {finish: true});
        this.clearStreamingAIChatMessage();
        return this.saveChatMessage({text: result, sender});
      }.bind(this))
      );
    }

    startStreamingAIChatMessage(sender) {
      return this.onNewMessage({message: { sender, text: '...', streaming: true }});
    }

    addToStreamingAIChatMessage({ sender, chunk, result }) {
      const lastRow = this.chatTables.find('.tr.streaming:last-child');
      // TODO: I commented out the .closed-chat-area to make this work, should bring that back and not have two elements in lastRow
      const tr = this.messageObjectToJQuery({ message: { sender, text: result, streaming: true }, existingRow: lastRow });
      tr.data('added', new Date().getTime());
      if (!(lastRow != null ? lastRow.length : undefined)) {
        this.chatTables.append(tr);
      }
      return this.scrollDown();
    }

    clearStreamingAIChatMessage() {
      const lastRow = this.chatTables.find('.tr.streaming:last-child');
      return lastRow.remove();
    }

    onChatResponse(message) {
      if (this.destroyed) { return; }
      //@onNewMessage message: message
      return this.saveChatMessage({text: message.text, sender: message.sender});
    }

    getChatMessageProps({ text, sender }) {
      let link;
      let actionButton;
      let freeText;
      sender =
        (sender != null ? sender.kind : undefined) === 'bot' ?{
          name: /(^Line \d|```)/m.test(text) ? 'Code AI' : 'Chat AI',
          kind: 'bot'
        }
        :{
          id: me.get('_id'),
          name: 'player',
          kind: 'player'
        };
      const props = {
        product: utils.getProduct(),
        kind: 'level-chat',
        //example: Boolean me.isAdmin() # TODO: implement the non-example version of the chat
        example: true,
        message: {
          text,
          textComponents: {},
          sender,
          startDate: new Date(),  // TODO: track when they started typing
          endDate: new Date()
        },
        context: {
          spokenLanguage: me.get('preferredLanguage', true),
          player: me.get('_id'),
          playerName: 'player',
          previousMessages: (((Array.from(this.chatMessages != null ? this.chatMessages : [])).map((m) => m.serializeMessage())))
        },
        permissions: [{ target: me.get('_id'), access: 'owner' }]
      };
      if (props.example) { props.releasePhase = 'beta'; }

      let structuredMessage = props.message.text;

      const codeIssueWithLineRegex = /^\|Issue\|: Line (\d+): (.+)$/m;
      const codeIssueWithLine = structuredMessage.match(codeIssueWithLineRegex);
      if (codeIssueWithLine) {
        props.message.textComponents.codeIssue = {line: parseInt(codeIssueWithLine[1], 10), text: codeIssueWithLine[2]};
        structuredMessage = structuredMessage.replace(codeIssueWithLineRegex, '');
      } else {
        const codeIssueRegex = /^\|Issue\|: (.+)$/m;
        const codeIssue = structuredMessage.match(codeIssueRegex);
        if (codeIssue) {
          props.message.textComponents.codeIssue = {text: codeIssue[1]};
          structuredMessage = structuredMessage.replace(codeIssueRegex, '');
        }
      }

      const codeIssueExplanationRegex = /^\|Explanation\|: (.+)$/m;
      const codeIssueExplanation = structuredMessage.match(codeIssueExplanationRegex);
      if (codeIssueExplanation) {
        props.message.textComponents.codeIssueExplanation = {text: codeIssueExplanation[1]};
        structuredMessage = structuredMessage.replace(codeIssueExplanationRegex, '');
      }

      const linkRegex = /^\|Link\|: \[(.+?)\]\((.+?)\)$/m;
      while ((link = structuredMessage.match(linkRegex))) {
        if (props.message.textComponents.links == null) { props.message.textComponents.links = []; }
        props.message.textComponents.links.push({text: link[1], url: link[2]});
        structuredMessage = structuredMessage.replace(linkRegex, '');
      }

      // TODO: remove explicit actionButton references, we'll probably autogenerate action buttons and just always have [Fix It] buttons
      const actionButtonRegex = /^<button( action='?"?(.+?)'?"?)?>(.+?)<\/button>$/m;
      while ((actionButton = structuredMessage.match(actionButtonRegex))) {
        if (props.message.textComponents.actionButtons == null) { props.message.textComponents.actionButtons = []; }
        var button = {text: actionButton[3]};
        if (actionButton[2]) {
          button.action = actionButton[2];
        }
        props.message.textComponents.actionButtons.push(button);
        structuredMessage = structuredMessage.replace(actionButtonRegex, '');
      }

      const codeRegex = /\|Code\|?:? ?```\n?((.|\n)+)```\n?/;
      const code = structuredMessage.match(codeRegex);
      if (code) {
        props.message.textComponents.code = code[1];
        structuredMessage = structuredMessage.replace(codeRegex, '');
      }

      const freeTextRegex = /^\|Free\|: (.+)$/m;
      const freeTextMatch = _.string.strip(structuredMessage).match(freeTextRegex);
      if (freeTextMatch) {
        freeText = freeTextMatch[1];
        structuredMessage = _.string.strip(structuredMessage).replace(freeTextRegex, '');
      } else {
        freeText = _.string.strip(structuredMessage);
      }

      if (freeText.length) { props.message.textComponents.freeText = freeText; }
      return props;
    }

    onWindowResize(e) {
      // Couldn't figure out the CSS to make this work, so doing it here
      if (this.destroyed) { return; }
      let maxHeight = $(window).height() - $('#thang-hud').offset().top - $('#thang-hud').height() - 25 - 30;
      if (maxHeight < 0) {
        // Just have to overlay the level, and have them close when done
        maxHeight = 0;
      }
      return this.$el.find('.closed-chat-area').css('max-height', maxHeight);
    }

    destroy() {
      key.deleteScope('level');
      if (this.clearOldMessagesInterval) { clearInterval(this.clearOldMessagesInterval); }
      $(window).off('resize', this.onWindowResize);
      return super.destroy();
    }
  };
  LevelChatView.initClass();
  return LevelChatView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}