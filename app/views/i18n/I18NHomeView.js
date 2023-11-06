// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Cinematic, Cutscene, I18NHomeView, Interactive;
const RootView = require('views/core/RootView');
const template = require('app/templates/i18n/i18n-home-view');
const CocoCollection = require('collections/CocoCollection');
const Courses = require('collections/Courses');
const Article = require('models/Article');
const utils = require('core/utils');
if (utils.isOzaria) {
  Interactive = require('ozaria/site/models/Interactive');
  Cutscene = require('ozaria/site/models/Cutscene');
}
const ResourceHubResource = require('models/ResourceHubResource');
const ChatMessage = require('models/ChatMessage');
const AIScenario = require('models/AIScenario');
const AIDocument = require('models/AIDocument');
const AIChatMessage = require('models/AIChatMessage');
const Concept = require('models/Concept');
const StandardsCorrelation = require('models/StandardsCorrelation');

const LevelComponent = require('models/LevelComponent');
const ThangType = require('models/ThangType');
const Level = require('models/Level');
const Achievement = require('models/Achievement');
const Campaign = require('models/Campaign');
if (utils.isOzaria) {
  Cinematic = require('ozaria/site/models/Cinematic');
}
const Poll = require('models/Poll');

const languages = _.keys(require('locale/locale')).sort();
const PAGE_SIZE = 100;
const QUERY_PARAMS = '?view=i18n-coverage&archived=false';

module.exports = (I18NHomeView = (function() {
  I18NHomeView = class I18NHomeView extends RootView {
    static initClass() {
      this.prototype.id = 'i18n-home-view';
      this.prototype.template = template;

      this.prototype.events = {
        'change #language-select': 'onLanguageSelectChanged',
        'change #type-select': 'onTypeSelectChanged'
      };
    }

    constructor(options) {
      super(options);
      let collections;
      this.selectedLanguage = me.get('preferredLanguage') || '';
      this.selectedTypes = '';

      //-
      const i18nComparator =  function(m) {
        if (m.specificallyCovered) { return 2; }
        if (m.generallyCovered) { return 1; }
        return 0;
      };
      this.aggregateModels = new Backbone.Collection();
      const that = this;
      const filterModel = Backbone.Collection.extend({
        comparator: i18nComparator,
        filter(attribute, value) {
          return this.reset(that.aggregateModels.filter(function(model) {
            if (value === '') { return true; }
            if (attribute === 'className') {
              return model.constructor.className === value;
            } else {
              return model.get(attribute) === value;
            }
          }));
        }
      });
      this.filteredModels = new filterModel();
      this.aggregateModels.comparator = i18nComparator;

      const project = ['name', 'components.original', 'i18n', 'i18nCoverage', 'slug'];

      this.thangTypes = new CocoCollection([], { url: `/db/thang.type${QUERY_PARAMS}`, project, model: ThangType });
      this.components = new CocoCollection([], { url: `/db/level.component${QUERY_PARAMS}`, project, model: LevelComponent });
      this.levels = new CocoCollection([], { url: `/db/level${QUERY_PARAMS}`, project, model: Level });
      this.achievements = new CocoCollection([], { url: `/db/achievement${QUERY_PARAMS}`, project, model: Achievement });
      this.campaigns = new CocoCollection([], { url: `/db/campaign${QUERY_PARAMS}`, project, model: Campaign });
      this.polls = new CocoCollection([], { url: `/db/poll${QUERY_PARAMS}`, project, model: Poll });
      this.courses = new Courses();
      this.articles = new CocoCollection([], { url: `/db/article${QUERY_PARAMS}`, project, model: Article });
      this.resourceHubResource = new CocoCollection([], { url: `/db/resource_hub_resource${QUERY_PARAMS}`, project, model: ResourceHubResource });
      if (utils.isOzaria) {
        this.interactive = new CocoCollection([], { url: `/db/interactive${QUERY_PARAMS}`, project, model: Interactive });
        this.cinematics = new CocoCollection([], { url: `/db/cinematic${QUERY_PARAMS}`, project, model: Cinematic });
        this.cutscene = new CocoCollection([], { url: `/db/cutscene${QUERY_PARAMS}`, project, model: Cutscene });
      }
      this.resourceHubResource = new CocoCollection([], { url: `/db/resource_hub_resource${QUERY_PARAMS}`, project, model: ResourceHubResource });
      this.chatMessage = new CocoCollection([], { url: `/db/chat_message${QUERY_PARAMS}`, project, model: ChatMessage });
      this.aiScenario = new CocoCollection([], { url: `/db/ai_scenario${QUERY_PARAMS}`, project, model: AIScenario });
      // @aiChatMessage = new CocoCollection([], { url: "/db/ai_chat_message#{QUERY_PARAMS}", project: project, model: AIChatMessage })
      // @aiDocument = new CocoCollection([], { url: "/db/ai_document#{QUERY_PARAMS}", project: project, model: AIDocument })
      this.concepts = new CocoCollection([], { url: `/db/concept${QUERY_PARAMS}`, project, model: Concept });
      this.standardsCorrelations = new CocoCollection([], { url: `/db/standards${QUERY_PARAMS}`, project, model: StandardsCorrelation });

      if (utils.isOzaria) {
        collections = [this.thangTypes, this.components, this.levels, this.achievements, this.campaigns, this.polls, this.courses, this.articles, this.interactive, this.cinematics, this.cutscene, this.resourceHubResource, this.concepts, this.standardsCorrelations];
      } else {
        collections = [this.thangTypes, this.components, this.levels, this.achievements, this.campaigns, this.polls, this.courses, this.articles, this.resourceHubResource, this.chatMessage, this.aiScenario, this.concepts, this.standardsCorrelations];
      }
      for (var c of Array.from(collections)) {
        c.skip = 0;

        c.fetch({data: {skip: 0, limit: PAGE_SIZE}, cache:false});
        this.supermodel.loadCollection(c, 'documents');
        this.listenTo(c, 'sync', this.onCollectionSynced);
      }
    }


    onCollectionSynced(collection) {
      for (var model of Array.from(collection.models)) {
        model.i18nURLBase = (() => { switch (model.constructor.className) {
          case 'Concept': return '/i18n/concept/';
          case 'StandardsCorrelation': return '/i18n/standards/';
          case 'ThangType': return '/i18n/thang/';
          case 'LevelComponent': return '/i18n/component/';
          case 'Achievement': return '/i18n/achievement/';
          case 'Level': return '/i18n/level/';
          case 'Campaign': return '/i18n/campaign/';
          case 'Poll': return '/i18n/poll/';
          case 'Course': return '/i18n/course/';
          case 'Product': return '/i18n/product/';
          case 'Article': return '/i18n/article/';
          case 'Interactive': return '/i18n/interactive/';
          case 'Cinematic': return '/i18n/cinematic/';
          case 'Cutscene': return '/i18n/cutscene/';
          case 'ResourceHubResource': return '/i18n/resource_hub_resource/';
          case 'ChatMessage': return '/i18n/chat_message/';
          case 'AIScenario': return '/i18n/ai/scenario/';
          case 'AIChatMessage': return '/i18n/ai/chat_message/';
          case 'AIDocument': return '/i18n/ai/document/';
        } })();
      }
      const getMore = collection.models.length === PAGE_SIZE;
      this.aggregateModels.add(collection.models);
      this.filteredModels.add(collection.models);
      this.render();

      if (getMore) {
        collection.skip += PAGE_SIZE;
        return collection.fetch({data: {skip: collection.skip, limit: PAGE_SIZE}});
      }
    }

    getRenderData() {
      let m;
      const c = super.getRenderData();
      this.updateCoverage();
      c.languages = languages;
      c.selectedLanguage = this.selectedLanguage;
      c.selectedTypes = this.selectedTypes;
      c.collection = this.filteredModels;

      const covered = ((() => {
        const result = [];
        for (m of Array.from(this.filteredModels.models)) {           if (m.specificallyCovered) {
            result.push(m);
          }
        }
        return result;
      })()).length;
      const coveredGenerally = ((() => {
        const result1 = [];
        for (m of Array.from(this.filteredModels.models)) {           if (m.generallyCovered) {
            result1.push(m);
          }
        }
        return result1;
      })()).length;
      const total = this.filteredModels.models.length;
      c.progress = total ? parseInt((100 * covered) / total) : 100;
      c.progressGeneral = total ? parseInt((100 * coveredGenerally) / total) : 100;
      c.showGeneralCoverage = /-/.test(this.selectedLanguage != null ? this.selectedLanguage : 'en');  // Only relevant for languages with more than one family, like zh-HANS

      return c;
    }

    updateCoverage() {
      const selectedBase = this.selectedLanguage.slice(0, 3);
      const relatedLanguages = ((() => {
        const result = [];
        for (var l of Array.from(languages)) {           if (_.string.startsWith(l, selectedBase) && (l !== this.selectedLanguage)) {
            result.push(l);
          }
        }
        return result;
      })());
      for (var model of Array.from(this.filteredModels.models)) {
        this.updateCoverageForModel(model, relatedLanguages);
        if (_.string.startsWith(this.selectedLanguage, 'en')) { model.generallyCovered = true; }
      }
      return this.filteredModels.sort();
    }

    updateCoverageForModel(model, relatedLanguages) {
      let left;
      model.specificallyCovered = true;
      model.generallyCovered = true;
      const coverage = (left = model.get('i18nCoverage')) != null ? left : [];

      if (!Array.from(coverage).includes(this.selectedLanguage)) {
        model.specificallyCovered = false;
        if (!_.any((Array.from(relatedLanguages).map((l) => Array.from(coverage).includes(l))))) {
          model.generallyCovered = false;
          return;
        }
      }
    }

    afterRender() {
      super.afterRender();
      this.addLanguagesToSelect(this.$el.find('#language-select'), this.selectedLanguage);
      this.$el.find('option[value="en-US"]').remove();
      this.$el.find('option[value="en-GB"]').remove();
      if (utils.isCodeCombat) {
        return this.addTypesToSelect($('#type-select'), ['ThangType', 'LevelComponent', 'Level', 'Achievement', 'Campaign', 'Poll', 'Course', 'Article', 'ResourceHubResource', 'ChatMessage', 'AIScenario']);
      } else {
        return this.addTypesToSelect($('#type-select'), ['ThangType', 'LevelComponent', 'Level', 'Achievement', 'Campaign', 'Poll', 'Course', 'Article', 'ResourceHubResource', 'Interactive', 'Cinematic', 'Cutscene']);
      }
    }

    onLanguageSelectChanged(e) {
      this.selectedLanguage = $(e.target).val();
      if (this.selectedLanguage) {
        // simplest solution, see if this actually ends up being not what people want
        me.set('preferredLanguage', this.selectedLanguage);
        me.patch();
      }
      return this.render();
    }

    addTypesToSelect(e, types) {
      const $select = e;
      $select.empty();
      $select.append($('<option>').attr('value', '').text('Select One...'));
      return Array.from(types).map((type) =>
        $select.append($('<option>').attr('value', type).text(type)));
    }

    onTypeSelectChanged(e) {
      this.selectedType = $(e.target).val();
      this.filteredModels.filter('className', this.selectedType);
      this.render();
      return $('#type-select').val(this.selectedType);
    }
  };
  I18NHomeView.initClass();
  return I18NHomeView;
})());