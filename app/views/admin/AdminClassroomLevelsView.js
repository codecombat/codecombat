/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AdminClassroomLevelsView;
const RootComponent = require('views/core/RootComponent');
const template = require('app/templates/base-flat');
const AdminClassroomLevelsComponent = require('./AdminClassroomLevelsComponent.vue').default;

module.exports = (AdminClassroomLevelsView = (function() {
  AdminClassroomLevelsView = class AdminClassroomLevelsView extends RootComponent {
    static initClass() {
      this.prototype.id = 'admin-classroom-levels-view';
      this.prototype.template = template;
      this.prototype.VueComponent = AdminClassroomLevelsComponent;
    }
  };
  AdminClassroomLevelsView.initClass();
  return AdminClassroomLevelsView;
})());
