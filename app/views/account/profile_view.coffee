View = require 'views/kinds/RootView'
template = require 'templates/account/profile'
User = require 'models/User'
JobProfileContactView = require 'views/modal/job_profile_contact_modal'

module.exports = class ProfileView extends View
  id: "profile-view"
  template: template

  events:
    'click #toggle-job-profile-approved': 'toggleJobProfileApproved'
    'click save-notes-button': 'onJobProfileNotesChanged'
    'click #contact-candidate': 'onContactCandidate'
    'click #enter-espionage-mode': 'enterEspionageMode'

  constructor: (options, @userID) ->
    @onJobProfileNotesChanged = _.debounce @onJobProfileNotesChanged, 1000
    super options
    if @userID is me.id
      @user = me
    else
      @user = User.getByID(@userID)
      @user.fetch()
      @listenTo @user, "sync", =>
        @render()

  getRenderData: ->
    context = super()
    context.user = @user
    context.myProfile = @user.id is context.me.id
    context.marked = marked
    context.moment = moment
    context.iconForLink = @iconForLink
    if links = @user.get('jobProfile')?.links
      links = ($.extend(true, {}, link) for link in links)
      link.icon = @iconForLink link for link in links
      context.profileLinks = _.sortBy links, (link) -> not link.icon  # icons first
    context

  afterRender: ->
    super()
    @updateProfileApproval() if me.isAdmin()
    unless @user.get('jobProfile')?.projects?.length
      @$el.find('.right-column').hide()
      @$el.find('.middle-column').addClass('double-column')

  updateProfileApproval: ->
    approved = @user.get 'jobProfileApproved'
    @$el.find('.approved').toggle Boolean(approved)
    @$el.find('.not-approved').toggle not approved

  toggleJobProfileApproved: ->
    approved = not @user.get 'jobProfileApproved'
    @user.set 'jobProfileApproved', approved
    @user.save()
    @updateProfileApproval()

  enterEspionageMode: ->
    postData = emailLower: @user.get('email').toLowerCase(), usernameLower: @user.get('name').toLowerCase()
    $.ajax
      type: "POST",
      url: "/auth/spy"
      data: postData
      success: @espionageSuccess

  espionageSuccess: (model) ->
    window.location.reload()

  onJobProfileNotesChanged: (e) =>
    notes = @$el.find("#job-profile-notes").val()
    @user.set 'jobProfileNotes', notes
    @user.save()

  iconForLink: (link) ->
    icons = [
      {icon: 'facebook', name: 'Facebook', domain: /facebook\.com/, match: /facebook/i}
      {icon: 'twitter', name: 'Twitter', domain: /twitter\.com/, match: /twitter/i}
      {icon: 'github', name: 'GitHub', domain: /github\.(com|io)/, match: /github/i}
      {icon: 'gplus', name: 'Google Plus', domain: /plus\.google\.com/, match: /(google|^g).?(\+|plus)/i}
      {icon: 'linkedin', name: 'LinkedIn', domain: /linkedin\.com/, match: /(google|^g).?(\+|plus)/i}
    ]
    for icon in icons
      if (link.name.search(icon.match) isnt -1) or (link.link.search(icon.domain) isnt -1)
        icon.url = "/images/pages/account/profile/icon_#{icon.icon}.png"
        return icon
    null

  onContactCandidate: (e) ->
    @openModalView new JobProfileContactView recipientID: @user.id
