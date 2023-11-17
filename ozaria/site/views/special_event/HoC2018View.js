/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let HoC2018View;
const RootComponent = require('views/core/RootComponent');
const template = require('templates/base-flat');
const HoC2018 = require('./HoC2018Component.vue').default;
const CreateAccountModal = require('views/core/CreateAccountModal/CreateAccountModal');

module.exports = (HoC2018View = (function() {
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
        }
      };
    }
  };
  HoC2018View.initClass();
  return HoC2018View;
})());
