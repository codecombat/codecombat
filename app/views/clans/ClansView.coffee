app = require 'core/application'
RootView = require 'views/core/RootView'
template = require 'templates/clans/clans'

module.exports = class MainAdminView extends RootView
  id: 'clans-view'
  template: template

  events:
    'click .clan-title': 'onClickClanTitle'

  constructor: (options) ->
    super options
    @initMockData()

  getRenderData: ->
    context = super()
    context.myClans = @myClans
    context.publicClans = @publicClans
    context

  onClickClanTitle: (e) ->
    if clanID = $(e.target).data('id')
      app.router.navigate "/clans/#{clanID}"
    else
      console.error "No clan ID found for public clan row."

  initMockData: ->
    @myClans = [
      {id: 1, title: 'FC Dallas', owner: 'soccerfan', memberCount: 4, member: true, ownerID: me.get('_id')}
      {id: 2, title: 'Mr. Smith 4th period', owner: 'mrsmith', memberCount: 23, member: true, ownerID: me.get('_id')}
      {id: 3, title: 'Test Title 21', owner: 'matt', memberCount: 12, member: true, ownerID: me.get('_id')}
      {id: 4, title: 'Slay more munchkins', owner: 'mrsmith', memberCount: 8, member: true, ownerID: me.get('_id')}
    ]

    @publicClans = [
      {id: 1, title: 'FC Dallas', owner: 'soccerfan', memberCount: 4, member: true, ownerID: me.get('_id')}
      {id: 2, title: 'Mr. Smith 4th period', owner: 'mrsmith', memberCount: 23, member: true, ownerID: me.get('_id')}
      {id: 5, title: 'tourney tanks', owner: 'jkl324', memberCount: 7, member: false, ownerID: me.get('_id')}
      {id: 6, title: 'Pythonistas', owner: 'bob219', memberCount: 50, member: false, ownerID: me.get('_id')}
    ]
