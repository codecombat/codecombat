/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let TeacherCourseSolutionView;
require('app/styles/teachers/teacher-course-solution-view.sass');
let utils = require('core/utils');
const RootView = require('views/core/RootView');
const Course = require('models/Course');
const Campaign = require('models/Campaign');
const Level = require('models/Level');
const LevelComponent = require('models/LevelComponent');
const Prepaids = require('collections/Prepaids');
const Levels = require('collections/Levels');
utils = require('core/utils');
const ace = require('lib/aceContainer');
const aceUtils = require('core/aceUtils');
const translateUtils = require('lib/translate-utils');
const api = require('core/api');

module.exports = (TeacherCourseSolutionView = (function() {
  TeacherCourseSolutionView = class TeacherCourseSolutionView extends RootView {
    static initClass() {
      this.prototype.id = 'teacher-course-solution-view';
      this.prototype.template = require('app/templates/teachers/teacher-course-solution-view');

      this.prototype.events = {
        'click .nav-link': 'onClickSolutionTab',
        'click .print-btn': 'onClickPrint'
      };
    }

    onClickSolutionTab(e) {
      const link = $(e.target).closest('a');
      const levelSlug = link.data('level-slug');
      const solutionIndex = link.data('solution-index');
      window.tracker.trackEvent('Click Teacher Course Solution Tab', {levelSlug, solutionIndex});
    }

    onClickPrint() {
      return (window.tracker ? window.tracker.trackEvent('Teachers Click Print Solution', { category: 'Teachers', label: this.courseID + "/" + this.language }) : undefined);
    }

    getTitle() {
      let title = $.i18n.t('teacher.course_solution');
      if (this.course) { title += " " + this.course.acronym(); }
      if (this.language !== "html") {
        title +=  " " + utils.capitalLanguages[this.language];
      }
      return title;
    }

    showTeacherLegacyNav() {
      // HACK: Hack to support legacy solution page with page from new teacher dashboard.
      //       Once new dashboard is released we can remove this check.
      if (__guard__(utils.getQueryVariables(), x => x['from-new-dashboard'])) {
        return false;
      }
      return true;
    }

    initialize(options, courseID, language) {
      this.courseID = courseID;
      this.language = language;
      this.isWebDev = [utils.courseIDs.WEB_DEVELOPMENT_2].includes(this.courseID);
      this.callOz = !!utils.getQueryVariable('callOz');
      console.log('callOz', this.callOz);
      if (me.isTeacher() || me.isAdmin() || me.isParentHome()) {
        this.prettyLanguage = this.camelCaseLanguage(this.language);
        if (options.campaignMode) {
          const campaignSlug = this.courseID;
          this.campaign = new Campaign({_id: campaignSlug});
          this.supermodel.trackRequest(this.campaign.fetch());
          this.levels = new Levels([], { url: `/db/campaign/${campaignSlug}/level-solutions`});
        } else {
          this.course = new Course({_id: this.courseID});
          this.supermodel.trackRequest(this.course.fetch({ callOz: this.callOz }));
          let levelSolutionsUrl = `/db/course/${this.courseID}/level-solutions`;
          if (this.callOz) {
            levelSolutionsUrl = `/ozaria${levelSolutionsUrl}`;
          }
          this.levels = new Levels([], { url: levelSolutionsUrl });
        }
        this.supermodel.loadCollection(this.levels, 'levels', {cache: false});

        this.levelNumberMap = {};
        this.prepaids = new Prepaids();
        this.supermodel.trackRequest(this.prepaids.fetchMineAndShared());
      }
      this.paidTeacher = me.isAdmin() || me.isPaidTeacher();
      __guard__(me.getClientCreatorPermissions(), x => x.then(() => (typeof this.render === 'function' ? this.render() : undefined)));
      return super.initialize(options);
    }

    camelCaseLanguage(language) {
      if (_.isEmpty(language)) { return language; }
      if (language === 'javascript') { return 'JavaScript'; }
      if (language === 'cpp') { return 'C++'; }
      return language.charAt(0).toUpperCase() + language.slice(1);
    }

    hideWrongLanguage(s) {
      if (!s) { return ''; }
      return s.replace(/```([a-z]+)[^`]+```/gm, (a, l) => {
        if (['cpp', 'java', 'python', 'lua', 'coffeescript'].includes(this.language) && (l === 'javascript') && !new RegExp(`\`\`\`${this.language}`).test(s)) { return `\`\`\`${this.language}
${translateUtils.translateJS(a.slice(13, +(a.length-4) + 1 || undefined), this.language, false)}
\`\`\``; }
        if (l !== this.language) { return ''; }
        return a;
      });
    }

    onLoaded() {
      let needle;
      this.paidTeacher = this.paidTeacher || (this.prepaids.find(p => (needle = p.get('type'), ['course', 'starter_license'].includes(needle)) && (p.get('maxRedeemers') > 0)) != null);
      this.listenTo(me, 'change:preferredLanguage', this.updateLevelData);
      this.updateLevelData();
      return this.fetchResourceHubResources();
    }

    updateLevelData() {
      let level;
      if (utils.isCodeCombat) {
        const solutionLanguages = [this.language];
        if ((this.language !== 'html') && this.isWebDev) { solutionLanguages.push('html'); }
        this.levelSolutionsMap = this.levels.getSolutionsMap(solutionLanguages);
      } else { // Ozaria
        this.levelSolutionsMap = this.levels.getSolutionsMap([this.language]);
        // TODO: When we have a property in the course like `modulesReleased`, we can limit and loop over that number here:
        this.levels.models = this.levels.models.filter(level => {
    // Intro types don't have solutions yet, so don't show them for now:
          if (level.get('type') === 'intro') {
            return false;
          }
          // Without a solution, guide or default code, there's nothing to show:
          const solution = this.levelSolutionsMap[level.get('original')] || [];
          if ((solution.length === 0) && !level.get('guide') && !level.get('begin')) {
            return false;
          }

          return true;
        });
      }
      for (level of Array.from((this.levels != null ? this.levels.models : undefined))) {
        var comp;
        var articles = __guard__(level.get('documentation'), x => x.specificArticles);
        if (articles) {
          var guide = articles.filter(x => x.name === "Overview").pop();
          if (guide) { level.set('guide', marked(this.hideWrongLanguage(utils.i18n(guide, 'body')))); }
          var intro = articles.filter(x => x.name === "Intro").pop();
          if (intro) { level.set('intro', marked(this.hideWrongLanguage(utils.i18n(intro, 'body')))); }
        }
        var heroPlaceholder = level.get('thangs').filter(x => x.id === 'Hero Placeholder').pop();
        if (utils.isCodeCombat) {
          comp = heroPlaceholder != null ? heroPlaceholder.components.filter(x => x.original.toString() === '524b7b5a7fc0f6d51900000e' ).pop() : undefined;
        } else {
          comp = heroPlaceholder != null ? heroPlaceholder.components.filter(x => LevelComponent.ProgrammableIDs.includes(x.original.toString())).pop() : undefined;
        }
        var programmableMethod = comp != null ? comp.config.programmableMethods.plan : undefined;
        if (programmableMethod) {
          var defaultCode, solutionLanguage, translatedDefaultCode;
          if (utils.isCodeCombat) {
            solutionLanguage = level.get('primerLanguage') || this.language;
            if (this.isWebDev && !level.get('primerLanguage')) { solutionLanguage = 'html'; }
          }
          try {
            if (utils.isCodeCombat) {
              defaultCode = programmableMethod.languages[solutionLanguage] || ((this.language === 'cpp') && translateUtils.translateJS(programmableMethod.source, 'cpp')) || programmableMethod.source;
            } else {
              defaultCode = programmableMethod.languages[level.get('primerLanguage') || this.language] || ((this.language === 'cpp') && translateUtils.translateJS(programmableMethod.source, 'cpp')) || programmableMethod.source;
            }
            translatedDefaultCode = _.template(defaultCode)(utils.i18n(programmableMethod, 'context'));
          } catch (e) {
            console.error('Broken solution for level:', level.get('name'));
            console.log(e);
            console.log(defaultCode);
            continue;
          }
          // See if it has <playercode> tags, extract them
          var playerCodeTag = utils.extractPlayerCodeTag(translatedDefaultCode);
          var finalDefaultCode = playerCodeTag ? playerCodeTag : translatedDefaultCode;
          level.set('begin', finalDefaultCode);
        }
      }
      const levels = [];
      for (level of Array.from((this.levels != null ? this.levels.models : undefined))) {
        if (level.get('original')) {var left, left1;

          if ((this.language != null) && (level.get('primerLanguage') === this.language)) { continue; }
          levels.push({
            key: level.get('original'),
            practice: (left = level.get('practice')) != null ? left : false,
            assessment: (left1 = level.get('assessment')) != null ? left1 : false
          });
        }
      }
      this.levelNumberMap = utils.createLevelNumberMap(levels);
      if (utils.isCodeCombat && ((this.course != null ? this.course.id : undefined) === utils.courseIDs.WEB_DEVELOPMENT_2)) {
        // Filter out non numbered levels.
        this.levels.models = this.levels.models.filter(l => l.get('original') in this.levelNumberMap);
      }
      return (typeof this.render === 'function' ? this.render() : undefined);
    }

    fetchResourceHubResources() {
      this.courseResources = [];
      return api.resourceHubResources.getResourceHubResources().then(allResources => {
        if (this.destroyed) { return; }
        for (var resource of Array.from(allResources)) {
          if ((resource.hidden !== false) && (Array.from(resource.courses != null ? resource.courses : []).includes(utils.courseAcronyms[this.courseID]))) {
            this.courseResources.push(resource);
          }
        }
        this.courseResources = _.sortBy(this.courseResources, 'priority');
        return this.render();
      }).catch(e => {
        return console.error(e);
      });
    }

    afterRender() {
      super.afterRender();
      return this.$el.find('pre:has(code[class*="lang-"])').each(function() {
        let lang;
        const codeElem = $(this).first().children().first();
        for (var mode in aceUtils.aceEditModes) { if ((codeElem != null ? codeElem.hasClass('lang-' + mode) : undefined)) { lang = mode; } }
        const aceEditor = aceUtils.initializeACE(this, lang || 'python');
        aceEditor.setShowInvisibles(false);
        aceEditor.setBehavioursEnabled(false);
        aceEditor.setAnimatedScroll(false);
        aceEditor.$blockScrolling = Infinity;
        if (utils.isOzaria) {
          return aceEditor.renderer.setShowGutter(true);
        }
      });
    }

    getLearningGoalsForLevel(level) {
      const documentation = level.get('documentation');
      if (!documentation) {
        return;
      }

      const {
        specificArticles
      } = documentation;
      if (!specificArticles) {
        return;
      }

      const learningGoals = _.find(specificArticles, { name: 'Learning Goals' });
      if (!learningGoals) {
        return;
      }

      return learningGoals.body;
    }
  };
  TeacherCourseSolutionView.initClass();
  return TeacherCourseSolutionView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}