/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let HoC2018View;
import RootComponent from 'views/core/RootComponent';
import template from 'app/templates/base-flat';
import HoC2018 from './HoC2018Component.vue';
import CreateAccountModal from 'views/core/CreateAccountModal/CreateAccountModal';
import utils from 'core/utils';

export default HoC2018View = (function() {
  HoC2018View = class HoC2018View extends RootComponent {
    static initClass() {
      this.prototype.id = 'hoc-2018';
      this.prototype.template = template;
      this.prototype.VueComponent = HoC2018;
      this.prototype.skipMetaBinding = true;
    }

    constructor(options) {
      super(options);
      this.propsData = {
        onGetCS1Free: teacherEmail => {
          if (_.isEmpty(teacherEmail)) { return; }
          return this.openModalView(new CreateAccountModal({startOnPath: 'teacher', email: teacherEmail}));
        },
        activity() {
          return utils.getQueryVariable('activity') || 'ai-league';
        }
      };
    }
  };
  HoC2018View.initClass();
  return HoC2018View;
})();
