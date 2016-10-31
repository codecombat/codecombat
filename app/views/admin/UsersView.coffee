RootView = require 'views/core/RootView'
template = require 'templates/admin/users'
User = require 'models/User'

module.exports = class UsersView extends RootView
  # TODO: Pagination, choosing filters on the page itself.

  id: 'admin-users-view'
  template: template

  constructor: (options) ->
    super options
    @getUsers()

  getUsers: ->
    # can have this page show arbitrary conditions, see mongoose queries
    # http://mongoosejs.com/docs/queries.html
    # Each list in conditions is a function call.
    # The first arg is the function name
    # The rest are the args for the function

    UserCollection = Backbone.Collection.extend({
      model: User
      url: '/db/user?conditions[limit]=20&conditions[sort]="-dateCreated"&filter[anonymous]=false'
    })
    @users = new UserCollection()
    @users.fetch()
    @listenTo(@users, 'all', @render)

  getRenderData: ->
    c = super()
    c.users = (user.attributes for user in @users.models)
    c
