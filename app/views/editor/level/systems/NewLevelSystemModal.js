// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let NewLevelSystemModal;
import 'app/styles/editor/level/system/new.sass';
import ModalView from 'views/core/ModalView';
import template from 'app/templates/editor/level/system/new';
import LevelSystem from 'models/LevelSystem';
import forms from 'core/forms';
import { me } from 'core/auth';

export default NewLevelSystemModal = (function() {
  NewLevelSystemModal = class NewLevelSystemModal extends ModalView {
    static initClass() {
      this.prototype.id = 'editor-level-system-new-modal';
      this.prototype.template = template;
      this.prototype.instant = false;
      this.prototype.modalWidthPercent = 60;
  
      this.prototype.events = {
        'click #new-level-system-submit': 'makeNewLevelSystem',
        'submit form': 'makeNewLevelSystem'
      };
    }

    makeNewLevelSystem(e) {
      e.preventDefault();
      let system = this.$el.find('#level-system-system').val();
      const name = this.$el.find('#level-system-name').val();
      system = new LevelSystem();
      system.set('name', name);
      system.set('code', system.get('code', true).replace(/Jitter/g, name));
      system.set('permissions', [{access: 'owner', target: me.id}]);  // Private until saved in a published Level
      const res = system.save(null, {type: 'POST'});  // Override PUT so we can trigger postFirstVersion logic
      if (!res) { return; }

      this.showLoading();
      res.error(() => {
        this.hideLoading();
        console.log('Got errors:', JSON.parse(res.responseText));
        return forms.applyErrorsToForm(this.$el, JSON.parse(res.responseText));
      });
      return res.success(() => {
        this.supermodel.registerModel(system);
        Backbone.Mediator.publish('editor:edit-level-system', {original: system.get('_id'), majorVersion: 0});
        return this.hide();
      });
    }
  };
  NewLevelSystemModal.initClass();
  return NewLevelSystemModal;
})();
