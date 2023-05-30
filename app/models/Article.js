// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Article;
import CocoModel from './CocoModel';

export default Article = (function() {
  Article = class Article extends CocoModel {
    static initClass() {
      this.className = 'Article';
      this.schema = require('schemas/models/article');
      this.prototype.urlRoot = '/db/article';
      this.prototype.saveBackups = true;
      this.prototype.editableByArtisans = true;
    }
  };
  Article.initClass();
  return Article;
})();
