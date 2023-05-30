// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ArticlePreviewView;
import 'app/styles/editor/article/preview.sass';
import RootView from 'views/core/RootView';
import template from 'app/templates/editor/article/preview';
import 'lib/game-libraries';

export default ArticlePreviewView = (function() {
  ArticlePreviewView = class ArticlePreviewView extends RootView {
    static initClass() {
      this.prototype.id = 'editor-article-preview-view';
      this.prototype.template = template;
    }
  };
  ArticlePreviewView.initClass();
  return ArticlePreviewView;
})();
