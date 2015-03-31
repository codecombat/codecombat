RootView = require 'views/core/RootView'
template = require 'templates/clans/clan-details'

module.exports = class ClanDetailsView extends RootView
  id: 'clan-details-view'
  template: template

  constructor: (options, @clanID) ->
    super options
    @initMockData()

  getRenderData: =>
    context = super()
    context.clan = @clan
    context.members = @members
    context

  initMockData: ->
    @clan =
      title: 'Slay more munchkins'
      owner: 'mrsmith'
      memberCount: 8
      ownerID: me.get('_id')

    @members = [
      {id: me.get('_id'), name: 'mrsmith', level: 24}
      {id: me.get('_id'), name: 'Superman', level: 2}
      {id: me.get('_id'), name: 'batman', level: 1}
      {id: me.get('_id'), name: 'Bruce', level: 4}
    ]
