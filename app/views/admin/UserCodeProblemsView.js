// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let UserCodeProblemsView;
import RootView from 'views/core/RootView';
import template from 'app/templates/admin/user-code-problems';
import UserCodeProblem from 'models/UserCodeProblem';

export default UserCodeProblemsView = (function() {
  UserCodeProblemsView = class UserCodeProblemsView extends RootView {
    static initClass() {
      // TODO: Pagination, choosing filters on the page itself.
  
      this.prototype.id = 'admin-user-code-problems-view';
      this.prototype.template = template;
    }

    constructor(options) {
      super(options);
      this.fetchingData = true;
      this.getUserCodeProblems();
    }

    getUserCodeProblems() {
      // can have this page show arbitrary conditions, see mongoose queries
      // http://mongoosejs.com/docs/queries.html
      // Each list in conditions is a function call.
      // The first arg is the function name
      // The rest are the args for the function

      const lastMonth = new Date();
      if (lastMonth.getMonth() === 1) {
        lastMonth.setMonth(12);
        lastMonth.setYear(lastMonth.getYear() - 1);
      } else {
        lastMonth.setMonth(lastMonth.getMonth() - 1);
      }

      let conditions = [
        ['limit', 300],
        ['sort', '-created'],
        ['where', 'created'],
        ['gte', lastMonth.toString()]
      ];
      conditions = $.param({conditions:JSON.stringify(conditions)});
      const UserCodeProblemCollection = Backbone.Collection.extend({
        model: UserCodeProblem,
        url: '/db/user.code.problem?' + conditions
      });
      this.userCodeProblems = new UserCodeProblemCollection();
      this.userCodeProblems.fetch();
      return this.listenTo(this.userCodeProblems, 'all', function() {
        this.fetchingData = false;
        return this.render();
      });
    }

    getRenderData() {
      const c = super.getRenderData();
      c.fetchingData = this.fetchingData;
      c.userCodeProblems = (Array.from(this.userCodeProblems.models).map((problem) => problem.attributes));
      return c;
    }
  };
  UserCodeProblemsView.initClass();
  return UserCodeProblemsView;
})();
