/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let IdentifyView;
import RootView from 'views/core/RootView';
import { me } from 'core/auth';
import template from 'app/templates/user/identify-view';
import utils from 'core/utils';

export default IdentifyView = (function() {
  IdentifyView = class IdentifyView extends RootView {
    static initClass() {
      this.prototype.id = 'identify-view';
      this.prototype.template = template;
    }

    getRenderData() {
      const context = super.getRenderData();
      context.callbackID = utils.getQueryVariable('id');
      context.callbackURL = utils.getQueryVariable('callback') + `?id=${context.callbackID}&username=${me.get('name')}`;
      context.callbackSource = utils.getQueryVariable('source');
      return context;
    }
  };
  IdentifyView.initClass();
  return IdentifyView;
})();
