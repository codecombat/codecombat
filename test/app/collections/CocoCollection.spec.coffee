CocoCollection = require 'collections/CocoCollection'
LevelComponent = require 'models/LevelComponent'

describe 'CocoCollection', ->
  it 'can be given a project function to include a project query arg', ->
    collection = new CocoCollection([], {
      url: '/db/level.component'
      project:['name', 'description']
      model: LevelComponent
    })
    collection.fetch({data: {view: 'items'}})
    expect(jasmine.Ajax.requests.mostRecent().url).toBe('/db/level.component?view=items&project=name%2Cdescription')
