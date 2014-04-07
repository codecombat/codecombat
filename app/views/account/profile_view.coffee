View = require 'views/kinds/RootView'
template = require 'templates/account/profile'
User = require 'models/User'

module.exports = class ProfileView extends View
  id: "profile-view"
  template: template
  loadingProfile: true

  constructor: (options, @userID) ->
    super options
    @user = User.getByID(@userID)
    @loadingProfile = false if 'gravatarProfile' of @user
    @listenTo(@user, 'change', @userChanged)
    @listenTo(@user, 'error', @userError)

  userChanged: (user) ->
    @loadingProfile = false if 'gravatarProfile' of user
    @render()

  userError: (user) ->
    @loadingProfile = false
    @render()

  getRenderData: ->
    context = super()
    grav = @user.gravatarProfile
    grav = grav.entry[0] if grav
    addedContext =
      user: @user
      loadingProfile: @loadingProfile
      myProfile: @user.id is context.me.id
      grav: grav
      photoURL: @user.getPhotoURL()
    context[key] = addedContext[key] for key of addedContext
    context.marked = marked
    context.moment = moment
    context
