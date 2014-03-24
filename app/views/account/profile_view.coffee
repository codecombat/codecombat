View = require 'views/kinds/RootView'
template = require 'templates/account/profile'
User = require 'models/User'

module.exports = class ProfileView extends View
  id: "profile-view"
  template: template
  loading: true

  constructor: (options, @userID) ->
    super options
    @user = User.getByID(@userID)
    @loading = false if 'gravatarProfile' of @user
    @listenTo(@user, 'change', @userChanged)
    @listenTo(@user, 'error', @userError)

  userChanged: (user) ->
    @loading = false if 'gravatarProfile' of user
    @render()

  userError: (user) ->
    @loading = false
    @render()

  getRenderData: ->
    context = super()
    grav = @user.gravatarProfile
    grav = grav.entry[0] if grav
    addedContext =
      user: @user
      loading: @loading
      myProfile: @user.id is context.me.id
      grav: grav
      photoURL: @user.getPhotoURL()
    context[key] = addedContext[key] for key of addedContext
    context
