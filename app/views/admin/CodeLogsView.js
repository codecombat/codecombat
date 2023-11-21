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
let CodeLogsView;
require('app/styles/admin/codelogs-view.sass');
const RootView = require('views/core/RootView');
const template = require('app/templates/admin/codelogs-view');
const CodeLogCollection = require('collections/CodeLogs');
const CodeLog = require('models/CodeLog');
const utils = require('core/utils');

const CodePlaybackView = require('./CodePlaybackView');

module.exports = (CodeLogsView = (function() {
  CodeLogsView = class CodeLogsView extends RootView {
    constructor(...args) {
      super(...args);
      this.onBlurTooltip = this.onBlurTooltip.bind(this);
    }

    static initClass() {
      this.prototype.template = template;
      this.prototype.id = 'codelogs-view';
      this.prototype.tooltip = null;
      this.prototype.events = {
        'click .playback': 'onClickPlayback',
        'input #userid-search': 'onUserIDInput',
        'input #levelslug-search': 'onLevelSlugInput'
      };
    }

    initialize() {
      //@spade = new Spade()
      this.codelogs = new CodeLogCollection();
      this.supermodel.trackRequest(this.codelogs.fetchLatest());
      this.onUserIDInput = _.debounce(this.onUserIDInput, 300);
      return this.onLevelSlugInput = _.debounce(this.onLevelSlugInput, 300);
    }
      //@supermodel.trackRequest(@codelogs.fetch())

    onUserIDInput(e) {
      const userID = $('#userid-search')[0].value;
      if (userID !== '') {
        return Promise.resolve(this.codelogs.fetchByUserID(userID))
        .then(e => {
          return this.renderSelectors('#codelogtable');
        });
      } else {
        return Promise.resolve(this.codelogs.fetchLatest())
        .then(e => {
          return this.renderSelectors('#codelogtable');
        });
      }
    }

    onLevelSlugInput(e) {
      const slug = $('#levelslug-search')[0].value;
      if (slug !== '') {
        return Promise.resolve(this.codelogs.fetchBySlug(slug))
        .then(e => {
          return this.renderSelectors('#codelogtable');
        });
      } else {
        return Promise.resolve(this.codelogs.fetchLatest())
        .then(e => {
          return this.renderSelectors('#codelogtable');
        });
      }
    }

    onClickPlayback(e) {
      return this.insertSubView(this.codePlaybackView = new CodePlaybackView({rawLog:$(e.target).data('codelog')}));
    }

    deleteTooltip() {
      if (this.tooltip != null) {
        this.tooltip.off('blur');
        this.tooltip.remove();
        return this.tooltip = null;
      }
    }

    onBlurTooltip(e) {
      return this.deleteTooltip();
    }

    destroy() {
      this.deleteTooltip();
      return super.destroy();
    }
  };
  CodeLogsView.initClass();
  return CodeLogsView;
})());
