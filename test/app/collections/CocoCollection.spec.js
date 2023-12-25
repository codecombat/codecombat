/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const CocoCollection = require('collections/CocoCollection');
const LevelComponent = require('models/LevelComponent');

describe('CocoCollection', () => it('can be given a project function to include a project query arg', function() {
  const collection = new CocoCollection([], {
    url: '/db/level.component',
    project:['name', 'description'],
    model: LevelComponent
  });
  collection.fetch({data: {view: 'items'}});
  return expect(jasmine.Ajax.requests.mostRecent().url).toBe('/db/level.component?view=items&project=name%2Cdescription');
}));
