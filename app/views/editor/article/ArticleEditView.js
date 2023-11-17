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
let ArticleEditView;
require('app/styles/editor/article/edit.sass');
const RootView = require('views/core/RootView');
const VersionHistoryView = require('./ArticleVersionsModal');
const template = require('app/templates/editor/article/edit');
const Article = require('models/Article');
const SaveVersionModal = require('views/editor/modal/SaveVersionModal');
const PatchesView = require('views/editor/PatchesView');
require('views/modal/RevertModal');
require('lib/setupTreema');
const RevertModal = require('views/modal/RevertModal');

require('lib/game-libraries');

module.exports = (ArticleEditView = (function() {
  ArticleEditView = class ArticleEditView extends RootView {
    static initClass() {
      this.prototype.id = 'editor-article-edit-view';
      this.prototype.template = template;

      this.prototype.events = {
        'click #preview-button': 'openPreview',
        'click #history-button': 'showVersionHistory',
        'click #save-button': 'openSaveModal',
        'click [data-toggle="coco-modal"][data-target="modal/RevertModal"]': 'openRevertModal'
      };
    }

    constructor(options, articleID) {
      super(options);
      this.pushChangesToPreview = this.pushChangesToPreview.bind(this);
      this.articleID = articleID;
      this.article = new Article({_id: this.articleID});
      this.article.saveBackups = true;
      this.supermodel.loadModel(this.article);
      this.pushChangesToPreview = _.throttle(this.pushChangesToPreview, 500);
    }

    onLoaded() {
      super.onLoaded();
      this.buildTreema();
      return this.listenTo(this.article, 'change', () => {
        this.article.updateI18NCoverage();
        return this.treema.set('/', this.article.attributes);
      });
    }

    buildTreema() {
      if ((this.treema != null) || (!this.article.loaded)) { return; }
      if (!this.article.attributes.body) {
        this.article.set('body', '');
      }
      const data = $.extend(true, {}, this.article.attributes);
      const options = {
        data,
        filePath: `db/thang.type/${this.article.get('original')}`,
        schema: Article.schema,
        readOnly: me.get('anonymous'),
        callbacks: {
          change: this.pushChangesToPreview
        }
      };
      this.treema = this.$el.find('#article-treema').treema(options);
      return this.treema.build();
    }

    pushChangesToPreview() {
      let id;
      for (var key in this.treema.data) {
        var value = this.treema.data[key];
        this.article.set(key, value);
      }
      if (!this.treema || !this.preview) { return; }
      const m = marked(this.treema.data.body);
      const b = $(this.preview.document.body);
      const onLoadHandler = () => {
        if (b.find('#insert').length === 1) {
          b.find('#insert').html(m);
          b.find('#title').text(this.treema.data.name);
          return clearInterval(id);
        }
      };
      return id = setInterval(onLoadHandler, 100);
    }

    afterRender() {
      super.afterRender();
      if (!this.supermodel.finished()) { return; }
      if (me.get('anonymous')) { this.showReadOnly(); }
      this.patchesView = this.insertSubView(new PatchesView(this.article), this.$el.find('.patches-view'));
      return this.patchesView.load();
    }

    openPreview() {
      if (!this.preview || this.preview.closed) {
        this.preview = window.open('/editor/article/preview', 'preview', 'height=800,width=600');
      }
      if (window.focus) { this.preview.focus(); }
      this.preview.onload = () => this.pushChangesToPreview();
      return false;
    }

    openSaveModal() {
      const modal = new SaveVersionModal({model: this.article, noNewMajorVersions: true});
      this.openModalView(modal);
      this.listenToOnce(modal, 'save-new-version', this.saveNewArticle);
      return this.listenToOnce(modal, 'hidden', function() { return this.stopListening(modal); });
    }

    openRevertModal(e) {
      e.stopPropagation();
      return this.openModalView(new RevertModal());
    }

    saveNewArticle(e) {
      this.treema.endExistingEdits();
      for (var key in this.treema.data) {
        var value = this.treema.data[key];
        this.article.set(key, value);
      }

      this.article.set('commitMessage', e.commitMessage);
      const res = this.article.saveNewMinorVersion();
      if (!res) { return; }
      const modal = this.$el.find('#save-version-modal');
      this.enableModalInProgress(modal);

      res.error(() => {
        return this.disableModalInProgress(modal);
      });

      return res.success(() => {
        this.article.clearBackup();
        modal.modal('hide');
        const url = `/editor/article/${this.article.get('slug') || this.article.id}`;
        return document.location.href = url;
      });
    }

    showVersionHistory(e) {
      const versionHistoryView = new VersionHistoryView({article: this.article}, this.articleID);
      this.openModalView(versionHistoryView);
      return Backbone.Mediator.publish('editor:view-switched', {});
    }
  };
  ArticleEditView.initClass();
  return ArticleEditView;
})());
