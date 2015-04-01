RootView = require 'views/core/RootView'
template = require 'templates/clans/clan-details'
Clan = require 'models/Clan'

module.exports = class ClanDetailsView extends RootView
  id: 'clan-details-view'
  template: template

  constructor: (options, @clanID) ->
    super options
    @clan = new Clan _id: @clanID
    @supermodel.loadModel @clan, 'clan', cache: false

  getRenderData: =>
    context = super()
    context.clan = @clan
    context.isOwner = @clan.get('ownerID') is me.id
    context.isMember = _.find(@clan.get('members'), (m) -> m.id is me.id) ? false
    context
