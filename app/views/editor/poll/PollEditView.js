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
let PollEditView;
require('app/styles/editor/poll/poll-edit-view.sass');
const RootView = require('views/core/RootView');
const template = require('app/templates/editor/poll/poll-edit-view');
const Poll = require('models/Poll');
const UserPollsRecord = require('models/UserPollsRecord');
const PollModal = require('views/play/modal/PollModal');
const ConfirmModal = require('views/core/ConfirmModal');
const PatchesView = require('views/editor/PatchesView');
const errors = require('core/errors');

require('lib/game-libraries');

module.exports = (PollEditView = (function() {
  PollEditView = class PollEditView extends RootView {
    static initClass() {
      this.prototype.id = 'editor-poll-edit-view';
      this.prototype.template = template;

      this.prototype.events = {
        'click #save-button': 'savePoll',
        'click #delete-button': 'confirmDeletion'
      };
    }

    constructor(options, pollID) {
      super(options);
      this.pushChangesToPreview = this.pushChangesToPreview.bind(this);
      this.deletePoll = this.deletePoll.bind(this);
      this.pollID = pollID;
      this.loadPoll();
      this.loadUserPollsRecord();
      this.pushChangesToPreview = _.throttle(this.pushChangesToPreview, 500);
    }

    loadPoll() {
      this.poll = new Poll({_id: this.pollID});
      this.poll.saveBackups = true;
      return this.supermodel.loadModel(this.poll);
    }

    loadUserPollsRecord() {
      const url = `/db/user.polls.record/-/user/${me.id}`;
      this.userPollsRecord = new UserPollsRecord().setURL(url);
      const onRecordSync = function() {
        if (this.destroyed) { return; }
        return this.userPollsRecord.url = function() { return '/db/user.polls.record/' + this.id; };
      };
      this.listenToOnce(this.userPollsRecord, 'sync', onRecordSync);
      this.userPollsRecord = this.supermodel.loadModel(this.userPollsRecord).model;
      if (this.userPollsRecord.loaded) { return onRecordSync.call(this); }
    }

    onLoaded() {
      super.onLoaded();

      if (this.poll.get('answers') === undefined) {
        this.poll.set('hidden', true);
      }

      this.buildTreema();
      return this.listenTo(this.poll, 'change', () => {
        this.poll.updateI18NCoverage();
        return this.treema.set('/', this.poll.attributes);
      });
    }

    buildTreema() {
      if ((this.treema != null) || (!this.poll.loaded) || (!me.isAdmin())) { return; }
      const data = $.extend(true, {}, this.poll.attributes);
      const options = {
        data,
        filePath: `db/poll/${this.poll.get('_id')}`,
        schema: Poll.schema,
        readOnly: me.get('anonymous'),
        callbacks: {
          change: () => { if (!this.hush) { return this.pushChangesToPreview(); } }
        }
      };
      this.treema = this.$el.find('#poll-treema').treema(options);
      this.treema.build();
      if (this.treema.childrenTreemas.answers != null) {
        this.treema.childrenTreemas.answers.open(1);
      }
      return this.pushChangesToPreview();
    }

    afterRender() {
      super.afterRender();
      if (!this.supermodel.finished()) { return; }
      this.pushChangesToPreview();
      this.patchesView = this.insertSubView(new PatchesView(this.poll), this.$el.find('.patches-view'));
      return this.patchesView.load();
    }

    pushChangesToPreview() {
      if (!this.treema) { return; }
      this.$el.find('#poll-view').empty();
      for (var key in this.treema.data) {
        var value = this.treema.data[key];
        this.poll.set(key, value);
      }
      if (this.pollModal != null) {
        this.pollModal.destroy();
      }
      this.pollModal = new PollModal({supermodel: this.supermodel, poll: this.poll, userPollsRecord: this.userPollsRecord, trapsFocus: false});
      this.pollModal.render();
      $('#poll-view').empty().append(this.pollModal.el);
      //pollModal.afterInsert()  # This blurs the active input; don't do it
      this.pollModal.$el.removeClass('modal fade').show();
      return this.pollModal.on('vote-updated', () => {
        this.hush = true;
        this.treema.set('/answers', this.pollModal.poll.get('answers'));
        return this.hush = false;
      });
    }

    // Validate that nextPoll is a valid poll, throwing if nextPoll is invalid.
    validateNextPollIds(data) {
      if (data == null) { data = []; }
      const currentPollId = this.poll.get('_id');
      const responsePromises = data
        .filter(({ nextPoll }) => nextPoll)
        .map(function({nextPoll, key}) {
          if (nextPoll === currentPollId) {
            throw new Error(`Aborted save: Error with nextPoll in answer with key: '${key}' - Do not reference the same poll in an answer.`);
          }
          return fetch(`/db/poll/${nextPoll}`)
            .then(function(r) {
              if (!r.ok) {
                throw new Error(`Aborted save: Error with nextPoll in answer with key: '${key}' - Poll with this id doesn't exist.`);
              }
            });
        });

      return Promise.all(responsePromises);
    }

    savePoll(e) {
      this.treema.endExistingEdits();
      for (var key in this.treema.data) {
        var value = this.treema.data[key];
        this.poll.set(key, value);
      }

      return this.validateNextPollIds(this.poll.get('answers')).then(() => {
        const res = this.poll.save();

        res.error((collection, response, options) => {
          return console.error(response);
        });

        return res.success(() => {
          const url = `/editor/poll/${this.poll.get('slug') || this.poll.id}`;
          return document.location.href = url;
      });
      });
    }

    confirmDeletion() {
      const renderData = {
        title: 'Are you really sure?',
        body: 'This will completely delete the poll, potentially breaking a lot of stuff you don\'t want breaking. Are you entirely sure?',
        decline: 'Not really',
        confirm: 'Definitely'
      };

      const confirmModal = new ConfirmModal(renderData);
      confirmModal.on('confirm', this.deletePoll);
      return this.openModalView(confirmModal);
    }

    deletePoll() {
      console.debug('deleting');
      return $.ajax({
        type: 'DELETE',
        success() {
          noty({
            timeout: 5000,
            text: 'Aaaand it\'s gone.',
            type: 'success',
            layout: 'topCenter'
          });
          return _.delay(() => application.router.navigate('/editor/poll', {trigger: true})
          , 500);
        },
        error(jqXHR, status, error) {
          console.error(jqXHR);
          return {
            timeout: 5000,
            text: `Deleting poll failed with error code ${jqXHR.status}`,
            type: 'error',
            layout: 'topCenter'
          };
        },
        url: `/db/poll/${this.poll.id}`
      });
    }
  };
  PollEditView.initClass();
  return PollEditView;
})());
