// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
import CocoClass from './CocoClass';

const namesCache = {};

class SystemNameLoader extends CocoClass {
  getName(id) { return (namesCache[id] != null ? namesCache[id].name : undefined); }

  setName(system) { return namesCache[system.get('original')] = {name: system.get('name')}; }
}

export default new SystemNameLoader();
