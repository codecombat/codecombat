/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CourseNagSubview;
import CocoView from 'views/core/CocoView';
import CourseNagModal from 'views/teachers/CourseNagModal';
import Prepaids from 'collections/Prepaids';
import utils from 'core/utils';
import template from 'app/templates/teachers/course-nag';

// Shows up if you have prepaids but haven't enrolled any students
export default CourseNagSubview = (function() {
  CourseNagSubview = class CourseNagSubview extends CocoView {
    static initClass() {
      this.prototype.id = 'classes-nag-subview';
      this.prototype.template = template;
      this.prototype.events =
        {'click .more-info': 'onClickMoreInfo'};
    }

    initialize(options) {
      super.initialize(options);
      this.prepaids = new Prepaids();
      this.supermodel.trackRequest(this.prepaids.fetchMineAndShared());
      this.listenTo(this.prepaids, 'sync', this.gotPrepaids);
      return this.shown = false;
    }

    afterRender() {
      super.afterRender();
      if (this.shown) {
        return this.$el.show();
      } else {
        return this.$el.hide();
      }
    }


    gotPrepaids() {
      // Group prepaids into (I)gnored (U)sed (E)mpty
      const unusedPrepaids = this.prepaids.groupBy(function(p) {
        let needle;
        if ((needle = p.status(), ["expired", "pending"].includes(needle))) { return 'I'; }
        if (p.hasBeenUsedByTeacher(me.id)) { return 'U'; }
        return 'E';
      });

      this.shown = (unusedPrepaids.E != null) && (unusedPrepaids.U == null);
      return this.render();
    }

    onClickMoreInfo() {
      return this.openModalView(new CourseNagModal());
    }
  };
  CourseNagSubview.initClass();
  return CourseNagSubview;
})();
