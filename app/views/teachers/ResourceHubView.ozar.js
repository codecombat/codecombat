/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ResourceHubView;
import 'app/styles/teachers/resource-hub-view.sass';
import RootView from 'views/core/RootView';

const resources = {
  'faq': {
    url: '/teachers/resources/faq',
    i18nCoverage: ['zh-HANS', 'he', 'nl-NL', 'pt-BR']
  },
  'getting-started': {
    url: '/teachers/resources/getting-started-with-ozaria',
    i18nCoverage: ['zh-HANS']
  },
  'ch1UnitOverview': {
    url: '/teachers/resources/ch1UnitOverview',
    i18nCoverage: ['zh-HANS']
  },
  'ch1LessonPlan': {
    url: '/teachers/resources/ch1LessonPlan',
    i18nCoverage: ['zh-HANS']
  },
  'ch1_Rubric': {
    url: '/teachers/resources/ch1_Rubric',
    i18nCoverage: ['zh-HANS']
  },
  'chapter2module1overview': {
    url: '/teachers/resources/chapter2module1overview',
    i18nCoverage: ['zh-HANS']
  },
  'chapter2module1lp': {
    url: '/teachers/resources/chapter2module1lp',
    i18nCoverage: ['zh-HANS']
  },
  'chapter2module2overview': {
    url: '/teachers/resources/chapter2module2overview',
    i18nCoverage: ['zh-HANS']
  },
  'chapter2module2lp': {
    url: '/teachers/resources/chapter2module2lp',
    i18nCoverage: ['zh-HANS']
  },
  'chapter2module3overview': {
    url: '/teachers/resources/chapter2module3overview',
    i18nCoverage: ['zh-HANS']
  },
  'chapter2module3lp': {
    url: '/teachers/resources/chapter2module3lp',
    i18nCoverage: ['zh-HANS']
  },
  'chapter2module4overview': {
    url: '/teachers/resources/chapter2module4overview',
    i18nCoverage: ['zh-HANS']
  },
  'chapter2module4lp': {
    url: '/teachers/resources/chapter2module4lp',
    i18nCoverage: ['zh-HANS']
  },
  'chapter2module5overview': {
    url: '/teachers/resources/chapter2module5overview',
    i18nCoverage: ['zh-HANS']
  },
  'chapter2module5lp': {
    url: '/teachers/resources/chapter2module5lp',
    i18nCoverage: ['zh-HANS']
  },
  'chapter2module6overview': {
    url: '/teachers/resources/chapter2module6overview',
    i18nCoverage: ['zh-HANS']
  },
  'chapter2module6lp': {
    url: '/teachers/resources/chapter2module6lp',
    i18nCoverage: ['zh-HANS']
  },
  'chapter2rubric': {
    url: '/teachers/resources/chapter2rubric',
    i18nCoverage: ['zh-HANS']
  },
  'chapter2rubric': {
    url: '/teachers/resources/chapter2rubric',
    i18nCoverage: ['zh-HANS']
  },
  'dashboardGuide': {
    url: 'https://s3.amazonaws.com/files.ozaria.com/Ozaria+Teacher+Dashboard+1.0+Guide+.pdf',
    i18nCoverage: ['zh-HANS'],
    i18n: {
      'zh-HANS': 'https://ozaria-assets.oss-cn-qingdao.aliyuncs.com/resource-hub/%E5%A5%A5%E4%BD%B3%E7%9D%BF%E6%95%99%E5%B8%88%E9%9D%A2%E6%9D%BF%E6%8C%87%E5%8D%97.pdf'
    }
  }
};

export default ResourceHubView = (function() {
  ResourceHubView = class ResourceHubView extends RootView {
    static initClass() {
      this.prototype.id = 'resource-hub-view';
      this.prototype.template = require('app/templates/teachers/resource-hub-view');
  
      this.prototype.events =
        {'click .resource-link': 'onClickResourceLink'};
    }

    getMeta() { return { title: `${$.i18n.t('nav.resource_hub')} | ${$.i18n.t('common.ozaria')}` }; }

    resourceURLuseLang(resource, lang) {
      if (!Array.from(resource.i18nCoverage).includes(lang)) { return resource.url; }
      return (resource.i18n != null ? resource.i18n[lang] : undefined) != null ? (resource.i18n != null ? resource.i18n[lang] : undefined) : resource.url + '-' + lang;
    }

    resourceURL(item) {
      return this.resourceURLuseLang(resources[item], (() => { switch (me.get('preferredLanguage')) {
        case 'nl-NL': case 'nl-BE': return 'nl-NL';
        case 'he': return 'he';
        case 'pt-BR': case 'pt-PT': return 'pt-BR';
        case 'zh-HANS': case 'zh-HANT': return 'zh-HANS';
        default: return '';
      } })()
      );
    }

    initialize() {
      super.initialize();
      return __guard__(me.getClientCreatorPermissions(), x => x.then(() => (typeof this.render === 'function' ? this.render() : undefined)));
    }

    onClickResourceLink(e) {
      const link = __guard__($(e.target).closest('a'), x => x.attr('href'));
      return (window.tracker != null ? window.tracker.trackEvent('Teachers Click Resource Hub Link', { category: 'Teachers', label: link }) : undefined);
    }
  };
  ResourceHubView.initClass();
  return ResourceHubView;
})();

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}