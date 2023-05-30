// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ModelFiles;
import CocoCollection from 'collections/CocoCollection';
import File from 'models/File';

export default ModelFiles = (function() {
  ModelFiles = class ModelFiles extends CocoCollection {
    static initClass() {
      this.prototype.model = File;
    }

    constructor(model) {
      super();
      let url = model.constructor.prototype.urlRoot;
      url += `/${model.get('original') || model.id}/files`;
      this.url = url;
    }
  };
  ModelFiles.initClass();
  return ModelFiles;
})();
