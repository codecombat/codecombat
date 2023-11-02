/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let I18NEditArticleView;
const I18NEditModelView = require('./I18NEditModelView');
const Article = require('models/Article');

module.exports = (I18NEditArticleView = (function() {
  I18NEditArticleView = class I18NEditArticleView extends I18NEditModelView {
    static initClass() {
      this.prototype.id = 'i18n-edit-article-view';
      this.prototype.modelClass = Article;
    }

    buildTranslationList() {
      let i18n;
      const lang = this.selectedLanguage;

      // name, content
      if (i18n = this.model.get('i18n')) {
        let body, name;
        if (name = this.model.get('name')) {
          this.wrapRow('Article name', ['name'], name, i18n[lang] != null ? i18n[lang].name : undefined, []);
        }
        if (body = this.model.get('body')) {
          return this.wrapRow('Article body', ['body'], body, i18n[lang] != null ? i18n[lang].body : undefined, [], 'markdown');
        }
      }
    }
  };
  I18NEditArticleView.initClass();
  return I18NEditArticleView;
})());
