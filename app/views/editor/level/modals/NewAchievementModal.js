// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let NewAchievementModal;
import NewModelModal from 'views/editor/modal/NewModelModal';
import template from 'app/templates/editor/level/modal/new-achievement';
import forms from 'core/forms';
import Achievement from 'models/Achievement';

export default NewAchievementModal = (function() {
  NewAchievementModal = class NewAchievementModal extends NewModelModal {
    static initClass() {
      this.prototype.id = 'new-achievement-modal';
      this.prototype.template = template;
      this.prototype.plain = false;
  
      this.prototype.events =
        {'click #save-new-achievement-link': 'onAchievementSubmitted'};
    }

    constructor(options) {
      super(options);
      this.level = options.level;
    }

    onAchievementSubmitted(e) {
      const slug = _.string.slugify(this.$el.find('#name').val());
      const url = `/editor/achievement/${slug}`;
      return window.open(url, '_blank');
    }

    createQuery() {
      const checked = this.$el.find('[name=queryOptions]:checked');
      const checkedValues = (Array.from(checked).map((check) => $(check).val()));
      const query = {};
      for (var id of Array.from(checkedValues)) {
        switch (id) {
          case 'misc-level-completion':
            query['state.complete'] = true;
            break;
          default:
            query[`state.goalStates.${id}.status`] = 'success';
        }
      }
      query['level.original'] = this.level.get('original');
      return query;
    }

    makeNewModel() {
      const achievement = new Achievement;
      const name = this.$el.find('#name').val();
      const description = this.$el.find('#description').val();
      const query = this.createQuery();

      achievement.set('name', name);
      achievement.set('description', description);
      achievement.set('query', query);
      achievement.set('collection', 'level.sessions');
      achievement.set('userField', 'creator');
      achievement.set('related', this.level.get('original'));

      return achievement;
    }
  };
  NewAchievementModal.initClass();
  return NewAchievementModal;
})();
