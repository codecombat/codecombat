/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ArticleVersionsModal;
const VersionsModal = require('views/editor/modal/VersionsModal');

module.exports = (ArticleVersionsModal = (function() {
  ArticleVersionsModal = class ArticleVersionsModal extends VersionsModal {
    static initClass() {
      this.prototype.id = 'editor-article-versions-view';
      this.prototype.url = '/db/article/';
      this.prototype.page = 'article';
    }

    constructor(options, ID) {
      this.ID = ID;
      super(options, this.ID, require('models/Article'));
    }
  };
  ArticleVersionsModal.initClass();
  return ArticleVersionsModal;
})());
