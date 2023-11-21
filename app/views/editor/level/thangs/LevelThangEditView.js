// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LevelThangEditView;
require('app/styles/editor/level/thang/level-thang-edit-view.sass');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/editor/level/thang/level-thang-edit-view');
const ThangComponentsEditView = require('views/editor/component/ThangComponentsEditView');
const ThangType = require('models/ThangType');
const ace = require('lib/aceContainer');
const utils = require('core/utils');
require('vendor/scripts/jquery-ui-1.11.1.custom');
require('vendor/styles/jquery-ui-1.11.1.custom.css');

module.exports = (LevelThangEditView = (function() {
  LevelThangEditView = class LevelThangEditView extends CocoView {
    static initClass() {
      /*
      In the level editor, is the bar at the top when editing a single thang.
      Everything below is part of the ThangComponentsEditView, which is shared with the
      ThangType editor view.
      */

      this.prototype.id = 'level-thang-edit-view';
      this.prototype.template = template;

      this.prototype.events = {
        'click #all-thangs-link': 'navigateToAllThangs',
        'click #thang-name-link span': 'toggleNameEdit',
        'click #thang-type-link span': 'toggleTypeEdit',
        'blur #thang-name-link input': 'toggleNameEdit',
        'blur #thang-type-link input': 'toggleTypeEdit',
        'keydown #thang-name-link input': 'toggleNameEditIfReturn',
        'keydown #thang-type-link input': 'toggleTypeEditIfReturn',
        'click #prev-thang-link': 'navigateToPreviousThang',
        'click #next-thang-link': 'navigateToNextThang'
      };

      this.prototype.subscriptions =
        {'editor:level-thangs-changed': 'onThangsEdited'};
    }

    constructor(options) {
      if (options == null) { options = {}; }
      super(options);
      this.onComponentsChanged = this.onComponentsChanged.bind(this);
      this.reportChanges = this.reportChanges.bind(this);
      this.world = options.world;
      this.thangData = $.extend(true, {}, options.thangData != null ? options.thangData : {});
      this.level = options.level;
      this.oldPath = options.oldPath;
      this.reportChanges = _.debounce(this.reportChanges, 500);
    }

    onLoaded() { return this.render(); }
    afterRender() {
      let m;
      super.afterRender();
      let thangType = this.supermodel.getModelByOriginal(ThangType, this.thangData.thangType);
      const options = {
        components: this.thangData.components,
        supermodel: this.supermodel,
        level: this.level,
        world: this.world
      };

      if (this.level.isType('hero', 'hero-ladder', 'hero-coop', 'course', 'course-ladder', 'game-dev', 'web-dev') || utils.isCodeCombat) { options.thangType = thangType; }

      this.thangComponentEditView = new ThangComponentsEditView(options);
      this.listenTo(this.thangComponentEditView, 'components-changed', this.onComponentsChanged);
      this.insertSubView(this.thangComponentEditView);
      const thangTypeNames = ((() => {
        const result = [];
        for (m of Array.from(this.supermodel.getModels(ThangType))) {           result.push(m.get('name'));
        }
        return result;
      })());
      const input = this.$el.find('#thang-type-link input').autocomplete({source: thangTypeNames, minLength: 0, delay: 0, autoFocus: true});
      thangType = _.find(this.supermodel.getModels(ThangType), m => m.get('original') === this.thangData.thangType);
      const thangTypeName = (thangType != null ? thangType.get('name') : undefined) || 'None';
      input.val(thangTypeName);
      this.$el.find('#thang-type-link span').text(thangTypeName);
      return this.hideLoading();
    }

    navigateToAllThangs() {
      return Backbone.Mediator.publish('editor:level-thang-done-editing', {thangData: $.extend(true, {}, this.thangData), oldPath: this.oldPath});
    }

    navigateToPreviousThang(e) {
      return this.navigateThangsInDirection(-1);
    }

    navigateToNextThang(e) {
      return this.navigateThangsInDirection(1);
    }

    navigateThangsInDirection(dir) {
      let nextThang;
      const flattenedThangs = this.parent.flattenThangs(this.parent.groupThangs(this.level.get('thangs')));
      const currentIndex = _.findIndex(flattenedThangs, {id: this.thangData.id});
      if (nextThang = flattenedThangs[(currentIndex + dir + flattenedThangs.length) % flattenedThangs.length]) {
        return Backbone.Mediator.publish('editor:edit-level-thang', {thangID: nextThang.id});
      }
    }

    toggleNameEdit() {
      const link = this.$el.find('#thang-name-link');
      const wasEditing = link.find('input:visible').length;
      const span = link.find('span');
      const input = link.find('input');
      if (wasEditing) { span.text(input.val()); } else { input.val(span.text()); }
      link.find('span, input').toggle();
      if (!wasEditing) { input.select(); }
      return this.thangData.id = span.text();
    }

    toggleTypeEdit() {
      const link = this.$el.find('#thang-type-link');
      const wasEditing = link.find('input:visible').length;
      const span = link.find('span');
      const input = link.find('input');
      if (wasEditing) { span.text(input.val()); }
      link.find('span, input').toggle();
      if (!wasEditing) { input.select(); }
      const thangTypeName = input.val();
      const thangType = _.find(this.supermodel.getModels(ThangType), m => m.get('name') === thangTypeName);
      if (thangType && wasEditing) {
        return this.thangData.thangType = thangType.get('original');
      }
    }

    toggleNameEditIfReturn(e) {
      if (e.which === 13) { return this.$el.find('#thang-name-link input').blur(); }
    }

    toggleTypeEditIfReturn(e) {
      if (e.which === 13) { return this.$el.find('#thang-type-link input').blur(); }
    }

    onComponentsChanged(components) {
      this.thangData.components = components;
      return this.reportChanges();
    }

    reportChanges() {
      if (this.destroyed) { return; }
      this.reporting = true;
      Backbone.Mediator.publish('editor:level-thang-edited', {thangData: $.extend(true, {}, this.thangData), oldPath: this.oldPath});
      return this.reporting = false;
    }

    onThangsEdited(e) {
      // Propagate these edits to our Thang
      let newThang;
      if (this.reporting) { return; }  // Not if they're our own edits
      if (!(newThang = _.find(e.thangs, {id: this.thangData.id}))) { return; }
      if (_.isEqual(newThang, this.thangData)) { return; }
      this.thangData = newThang;
      this.thangComponentEditView.components = newThang.components != null ? newThang.components : [];
      return this.thangComponentEditView.onComponentsChanged();
    }
  };
  LevelThangEditView.initClass();
  return LevelThangEditView;
})());
