// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AdminClassroomLevelsView;
import RootComponent from 'views/core/RootComponent';
import template from 'app/templates/base-flat';
import AdminClassroomLevelsComponent from './AdminClassroomLevelsComponent.vue';

export default AdminClassroomLevelsView = (function() {
  AdminClassroomLevelsView = class AdminClassroomLevelsView extends RootComponent {
    static initClass() {
      this.prototype.id = 'admin-classroom-levels-view';
      this.prototype.template = template;
      this.prototype.VueComponent = AdminClassroomLevelsComponent;
    }
  };
  AdminClassroomLevelsView.initClass();
  return AdminClassroomLevelsView;
})();
