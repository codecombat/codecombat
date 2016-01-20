LevelEditView = require 'views/editor/level/LevelEditView'

emptyLevel = {'_id': '53a0a1e2d9048dbc3a793c81', 'name': 'Emptiness', 'description': 'Tis nothing..', 'documentation': {'generalArticles': [], 'specificArticles': []}, 'scripts': [], 'thangs': [], 'systems': [], 'victory': {}, 'version': {'minor': 0, 'major': 0, 'isLatestMajor': true, 'isLatestMinor': true}, 'index': '5388f9ac9a904d0000d94f87', 'slug': 'emptiness', 'creator': '5388f9ac9a904d0000d94f87', 'original': '53a0a1e2d9048dbc3a793c81', 'watchers': ['5388f9ac9a904d0000d94f87'], '__v': 0, 'created': '2014-06-17T20:15:30.207Z', 'permissions': [{'access': 'owner', 'target': '5388f9ac9a904d0000d94f87'}]}

describe 'LevelEditView', ->
  describe 'revert button', ->
    it 'opens just one modal when you click it', ->
      view = new LevelEditView({}, 'something')
      request = jasmine.Ajax.requests.first()
      request.respondWith {status: 200, responseText: JSON.stringify(emptyLevel)}
      me.set('anonymous', false) # otherwise button may be disabled an not fire
      view.render()
      spyOn(view, 'openModalView')
      view.$el.find('#revert-button').click()
      expect(view.openModalView.calls.count()).toBe(1)
