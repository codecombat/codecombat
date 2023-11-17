// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ArenaBalancerView;
require('app/styles/artisans/arena-balancer-view.sass');
const RootView = require('views/core/RootView');
const template = require('templates/artisans/arena-balancer-view');

const Campaigns = require('collections/Campaigns');
const Campaign = require('models/Campaign');

const Levels = require('collections/Levels');
const Level = require('models/Level');
const LevelSessions = require('collections/LevelSessions');
const ace = require('lib/aceContainer');
const aceUtils = require('core/aceUtils');
require('lib/setupTreema');
const treemaExt = require('core/treema-ext');
const storage = require('core/storage');
const ConfirmModal = require('views/core/ConfirmModal');

module.exports = (ArenaBalancerView = (function() {
  ArenaBalancerView = class ArenaBalancerView extends RootView {
    static initClass() {
      this.prototype.template = template;
      this.prototype.id = 'arena-balancer-view';

      this.prototype.events =
        {'click #go-button': 'onClickGoButton'};

      this.prototype.levelSlug = 'infinite-inferno';
    }

    constructor(options, levelSlug) {
      super(options);
      this.setUpVariablesTreema = this.setUpVariablesTreema.bind(this);
      this.onVariablesChanged = this.onVariablesChanged.bind(this);
      this.submitSessions = this.submitSessions.bind(this);
      this.levelSlug = levelSlug;
      this.getLevelInfo();
    }

    afterRender() {
      super.afterRender();
      const editorElements = this.$el.find('.ace');
      return (() => {
        const result = [];
        for (var el of Array.from(editorElements)) {
          var lang = this.$(el).data('language');
          var editor = ace.edit(el);
          var aceSession = editor.getSession();
          var aceDoc = aceSession.getDocument();
          aceSession.setMode(aceUtils.aceEditModes[lang]);
          result.push(editor.setTheme('ace/theme/textmate'));
        }
        return result;
      })();
    }
        //editor.setReadOnly true

    getLevelInfo() {
      this.level = this.supermodel.getModel(Level, this.levelSlug) || new Level({_id: this.levelSlug});
      this.supermodel.trackRequest(this.level.fetch());
      this.level.on('error', (level, error) => {
        this.level = level;
        return this.errorMessage = `Error loading level: ${error.statusText}`;
      });
      if (this.level.loaded) {
        return this.onLevelLoaded(this.level);
      } else {
        return this.listenToOnce(this.level, 'sync', this.onLevelLoaded);
      }
    }

    onLevelLoaded(level) {
      let left;
      const solutions = [];
      const hero = _.find((left = level.get("thangs")) != null ? left : [], {id: 'Hero Placeholder'});
      const plan = __guard__(_.find((hero != null ? hero.components : undefined) != null ? (hero != null ? hero.components : undefined) : [], x => __guard__(__guard__(x != null ? x.config : undefined, x2 => x2.programmableMethods), x1 => x1.plan)), x => x.config.programmableMethods.plan);
      if (!(this.solution = _.find((plan != null ? plan.solutions : undefined) != null ? (plan != null ? plan.solutions : undefined) : [], {description: 'arena-balancer'}))) {
        this.errorMessage = 'Configure a solution with description arena-balancer to use as the default';
      }
      this.render();
      return _.delay(this.setUpVariablesTreema, 100);  // Dunno why we need to delay
    }

    setUpVariablesTreema() {
      let matched;
      if (this.destroyed) { return; }
      const variableRegex = /<%= ?(.*?) ?%>/g;
      const variables = [];
      while ((matched = variableRegex.exec(this.solution.source))) {
        variables.push(matched[1]);
      }
      const dataStorageKey = ['arena-balancer-data', this.levelSlug].join(':');
      let data = storage.load(dataStorageKey);
      if (data == null) { data = {}; }
      const schema = {type: 'object', additionalProperties: false, properties: {}, required: variables, title: 'Variants', description: 'Combinatoric choice options'};
      for (var variable of Array.from(variables)) {
        schema.properties[variable] = { type: 'array', items: {
          type: 'object',
          additionalProperties: false,
          required: ['name', 'code'],
          default: {name: '', code: ''},
          properties: {
            name: {
              type: 'string',
              maxLength: 5,
              description: 'Very short name/code for variant that will appear in usernames'
            },
            code: {
              type: 'string',
              format: 'code',
              aceMode: 'ace/mode/javascript',
              title: 'Variant',
              description: 'Cartesian products will result'
            }
          }
        }
      };
        if (data[variable] == null) { data[variable] = [{name: '', code: ''}]; }
      }

      const treemaOptions = {
        schema,
        data,
        nodeClasses: {
          code: treemaExt.JavaScriptTreema
        },
        callbacks: {
          change: this.onVariablesChanged
        }
      };

      this.variablesTreema = this.$el.find('#variables-treema').treema(treemaOptions);
      this.variablesTreema.build();
      this.variablesTreema.open(3);
      return this.onVariablesChanged();
    }

    onVariablesChanged(e) {
      const dataStorageKey = ['arena-balancer-data', this.levelSlug].join(':');
      storage.save(dataStorageKey, this.variablesTreema.data);
      const cartesian = a => a.reduce((a, b) => a.flatMap(d => b.map(e => [d, e].flat())));
      const variables = [];
      for (var variable in this.variablesTreema.data) {
        var variants = [];
        for (var variant of Array.from(this.variablesTreema.data[variable])) {
          variants.push({variable, name: variant.name, code: variant.code});
        }
        variables.push(variants);
      }
      this.choices = cartesian(variables);
      return this.$('#go-button').text(`Create/Update All ${this.choices.length} Test Sessions`);
    }

    onClickGoButton(event) {
      const renderData = {
        title: 'Are you really sure?',
        body: `This will wipe all arena balancer sessions for ${this.levelSlug} and submit ${this.choices.length} new ones. Are you sure you want to do it? (Probably shouldn't be more than a couple thousand.)`,
        decline: 'Not really',
        confirm: 'Definitely'
      };
      this.confirmModal = new ConfirmModal(renderData);
      this.confirmModal.on('confirm', this.submitSessions);
      return this.openModalView(this.confirmModal);
    }

    submitSessions(e) {
      let variant;
      this.confirmModal.$el.find('#confirm-button').attr('disabled', true).text('Working... (can take a while)');
      const postData = {submissions: []};
      for (var choice of Array.from(this.choices)) {
        var context = {};
        for (variant of Array.from(choice)) { context[variant.variable] = variant.code; }
        var code = _.template(this.solution.source, context);
        var session = {name: ((() => {
          const result = [];
          for (variant of Array.from(choice)) {             result.push(variant.name);
          }
          return result;
        })()).join('-'), code};
        postData.submissions.push(session);
      }

      return $.ajax({
        data: JSON.stringify(postData),
        success: (data, status, jqXHR) => {
          noty({
            timeout: 5000,
            text: 'Arena balancing submission process started',
            type: 'success',
            layout: 'topCenter'
          });
          return __guardMethod__(this.confirmModal, 'hide', o => o.hide());
        },
        error: (jqXHR, status, error) => {
          console.error(jqXHR);
          noty({
            timeout: 5000,
            text: `Arena balancing submission process failed with error code ${jqXHR.status}`,
            type: 'error',
            layout: 'topCenter'
          });
          return __guardMethod__(this.confirmModal, 'hide', o => o.hide());
        },
        url: `/db/level/${this.levelSlug}/arena-balancer-sessions`,  // TODO
        type: 'POST',
        contentType: 'application/json'
      });
    }
  };
  ArenaBalancerView.initClass();
  return ArenaBalancerView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
function __guardMethod__(obj, methodName, transform) {
  if (typeof obj !== 'undefined' && obj !== null && typeof obj[methodName] === 'function') {
    return transform(obj, methodName);
  } else {
    return undefined;
  }
}