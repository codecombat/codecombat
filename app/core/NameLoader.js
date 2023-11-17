// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const CocoClass = require('core/CocoClass');

const namesCache = {};

class NameLoader extends CocoClass {
  constructor(...args) {
    super(...args)
    this.loadedNames = this.loadedNames.bind(this)
  }

  loadNames(ids) {
    const toLoad = _.uniq((Array.from(ids).filter((id) => !namesCache[id])));
    if (!toLoad.length) { return false; }
    const jqxhrOptions = {
      url: '/db/user/x/names',
      type: 'POST',
      data: {ids: toLoad},
      success: this.loadedNames
    };

    return jqxhrOptions;
  }

  loadedNames(newNames) {
    return _.extend(namesCache, newNames);
  }

  getName(id) {
    if ((namesCache[id] != null ? namesCache[id].firstName : undefined) && (namesCache[id] != null ? namesCache[id].lastName : undefined)) {
      return `${(namesCache[id] != null ? namesCache[id].firstName : undefined)} ${(namesCache[id] != null ? namesCache[id].lastName : undefined)}`;
    }
    return (namesCache[id] != null ? namesCache[id].firstName : undefined) || (namesCache[id] != null ? namesCache[id].name : undefined) || id;
  }
}

module.exports = new NameLoader();
