/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let DynamicAPCSPView;
import 'app/styles/teachers/markdown-resource-view.sass';
import RootView from 'views/core/RootView';
import api from 'core/api';
import ace from 'lib/aceContainer';
import aceUtils from 'core/aceUtils';
import APCSPLanding from './APCSPLanding';

export default DynamicAPCSPView = (function() {
  DynamicAPCSPView = class DynamicAPCSPView extends RootView {
    static initClass() {
      this.prototype.id = 'dynamic-apcsp-view';
      this.prototype.template = require('app/templates/teachers/dynamic-apcsp-view');
    }

    getMeta() {
      return {
        title: $.i18n.t('apcsp.title'),
        meta: [
          { vmid: 'meta-description', name: 'description', content: $.i18n.t('apcsp.meta_description') }
        ]
      };
    }

    initialize(options, name) {
      this.name = name;
      super.initialize(options);
      if (this.name == null) { this.name = 'index'; }
      this.content = '';
      this.loadingData = true;
      __guard__(me.getClientCreatorPermissions(), x => x.then(() => (typeof this.render === 'function' ? this.render() : undefined)));
      if (!this.cannotAccess()) {
        let promise;
        if (_.string.startsWith(this.name, 'markdown/')) {
          if (!_.string.endsWith(this.name, '.md')) {
            this.name = this.name + '.md';
          }
          promise = api.markdown.getMarkdownFile(this.name.replace('markdown/', ''));
        } else {
          promise = api.apcsp.getAPCSPFile(this.name);
        }

        return promise.then(data => {
          this.content = marked(data, {sanitize: false});
          this.loadingData = false;
          return this.render();
        }).catch(error => {
          this.loadingData = false;
          if (error.code === 404) {
            this.notFound = true;
            return this.render();
          } else {
            console.error(error);
            this.error = error.message;
            return this.render();
          }
        });
      }
    }

    cannotAccess() {
      return false; // me.isAnonymous() or !me.isTeacher() or !me.get('verifiedTeacher')
    }

    afterRender() {
      super.afterRender();
      if (this.cannotAccess()) {
        new APCSPLanding({
          el: this.$('#apcsp-landing')[0]
        });
      }

      this.$el.find('pre>code').each(function() {
        const els = $(this);
        const c = els.parent();
        let lang = els.attr('class');
        if (lang) {
          lang = lang.replace(/^lang-/,'');
        } else {
          lang = 'python';
        }

        const aceEditor = aceUtils.initializeACE(c[0], lang);
        aceEditor.setShowInvisibles(false);
        aceEditor.setBehavioursEnabled(false);
        aceEditor.setAnimatedScroll(false);
        return aceEditor.$blockScrolling = Infinity;
      });
      if (_.contains(location.href, '#')) {
        return _.defer(() => {
          // Remind the browser of the fragment in the URL, so it jumps to the right section.
          return location.href = location.href;
        });
      }
    }
  };
  DynamicAPCSPView.initClass();
  return DynamicAPCSPView;
})();

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}