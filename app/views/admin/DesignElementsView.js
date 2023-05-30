// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let DesignElementsView;
import 'app/styles/admin/design-elements-view.sass';
import RootView from 'views/core/RootView';
import template from 'app/templates/admin/design-elements-view';
import 'vendor/scripts/jquery-ui-1.11.1.custom';
import 'vendor/styles/jquery-ui-1.11.1.custom.css';

export default DesignElementsView = (function() {
  DesignElementsView = class DesignElementsView extends RootView {
    static initClass() {
      this.prototype.id = 'design-elements-view';
      this.prototype.template = template;
    }

    afterInsert() {
      super.afterInsert();
      // hack to get hash links to work. Make this general?
      const {
        hash
      } = document.location;
      document.location.hash = '';
      setTimeout((() => document.location.hash = hash), 10);

      // modal
      this.$('#modal-2').find('.background-wrapper').addClass('plain');

      // tooltips
      this.$('[data-toggle="tooltip"]').tooltip({
        title: 'Lorem ipsum',
        trigger: 'click'
      });
      if (hash === '#tooltips') {
        setTimeout((() => this.$('[data-toggle="tooltip"]').tooltip('show')), 20);
      }

      // popovers
      if (hash === '#popovers') {
        setTimeout((() => this.$('#popover').popover('show')), 20);
      }

      // autocomplete
      const tags = [
        "ActionScript", "AppleScript", "Asp", "BASIC", "C", "C++", "Clojure", "COBOL", "ColdFusion", "Erlang",
        "Fortran", "Groovy", "Haskell", "Java", "JavaScript", "Lisp", "Perl", "PHP", "Python", "Ruby", "Scala", "Scheme"
      ];
      this.$('#tags').autocomplete({source: tags});
      if (hash === '#autocomplete') {
        setTimeout((() => this.$('#tags').autocomplete("search", "t")), 20);
      }

      // slider
      return this.$('#slider-example').slider();
    }
  };
  DesignElementsView.initClass();
  return DesignElementsView;
})();
