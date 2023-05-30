// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let FilesView;
import RootComponent from 'views/core/RootComponent';
import template from 'app/templates/base-flat';
import FilesComponent from './FilesComponent.vue';

export default FilesView = (function() {
  FilesView = class FilesView extends RootComponent {
    static initClass() {
      this.prototype.id = 'files-view';
      this.prototype.template = template;
      this.prototype.VueComponent = FilesComponent;
    }
  };
  FilesView.initClass();
  return FilesView;
})();
