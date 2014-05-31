View = require 'views/kinds/RootView'
template = require 'templates/account/profile'
User = require 'models/User'
JobProfileContactView = require 'views/modal/job_profile_contact_modal'

module.exports = class ProfileView extends View
  id: "profile-view"
  template: template
  editing: false

  events:
    'click #toggle-editing': 'toggleEditing'
    'click #toggle-job-profile-approved': 'toggleJobProfileApproved'
    'click save-notes-button': 'onJobProfileNotesChanged'
    'click #contact-candidate': 'onContactCandidate'
    'click #enter-espionage-mode': 'enterEspionageMode'
    'click .editable-profile .profile-photo': 'onEditProfilePhoto'
    'click .editable-profile .editable-display': 'onEditSection'
    'click .editable-profile .save-section': 'onSaveSection'
    'click .editable-profile .glyphicon-remove': 'onCancelSectionEdit'
    'change .editable-profile .editable-array input': 'onEditArray'

  constructor: (options, @userID) ->
    @onJobProfileNotesChanged = _.debounce @onJobProfileNotesChanged, 1000
    super options
    if @userID is me.id
      @user = me
    else if me.isAdmin() or "employer" in me.get('permissions')
      @user = User.getByID(@userID)
      @user.fetch()
      @listenTo @user, "sync", =>
        @render()

  getRenderData: ->
    context = super()
    context.user = @user
    context.myProfile = @user.id is context.me.id
    context.allowedToViewJobProfile = me.isAdmin() or "employer" in me.get('permissions') or context.myProfile
    context.allowedToEditJobProfile = me.isAdmin() or context.myProfile
    context.editing = @editing
    context.jobProfileSchema = me.schema().properties.jobProfile
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
    unless @user.get('jobProfile')?.projects?.length or @editing
      @$el.find('.right-column').hide()
      @$el.find('.middle-column').addClass('double-column')
    unless @editing
      @$el.find('.editable-display').attr('title', '')

  updateProfileApproval: ->
    approved = @user.get 'jobProfileApproved'
    @$el.find('.approved').toggle Boolean(approved)
    @$el.find('.not-approved').toggle not approved

  toggleEditing: ->
    @editing = not @editing
    @render()

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

  saveEdits: (e) ->
    res = @user.validate()
    if res?
      console.error "Couldn't save because of validation errors:", res
      # TODO: show some sort of problem message here
      return
    jobProfile = @user.get('jobProfile')
    jobProfile.updated = (new Date()).toISOString()
    @user.set 'jobProfile', jobProfile
    return unless res = @user.save()
    res.error ->
      errors = JSON.parse(res.responseText)
      # TODO: show some sort of problem message here
    res.success (model, response, options) =>
      @render()

  onEditProfilePhoto: (e) ->
    filepicker.pick {mimetypes: 'image/*'}, @onProfilePhotoChosen

  onProfilePhotoChosen: (inkBlob) =>
    filePath = "db/user/#{@user.id}"
    body =
      url: inkBlob.url
      filename: inkBlob.filename
      mimetype: inkBlob.mimetype
      path: filePath
      force: true

    @uploadingPath = [filePath, inkBlob.filename].join('/')
    @$el.find('.profile-photo').addClass('saving')
    $.ajax '/file', type: 'POST', data: body, success: @onFileUploaded

  onFileUploaded: (e) =>
    @user.get('jobProfile').photoURL = @uploadingPath
    @saveEdits()

  onEditSection: (e) ->
    section = $(e.target).closest('.editable-section')
    section.find('.editable-form').show()
    section.find('.editable-display').hide()
    @$el.find('.editable-section').not(section).addClass 'deemphasized'
    column = section.closest('.full-height-column')
    @$el.find('.full-height-column').not(column).addClass 'deemphasized'

  onCancelSectionEdit: (e) ->
    @render()

  onSaveSection: (e) ->
    e.preventDefault()
    section = $(e.target).closest('.editable-section')
    isEmpty = @arrayItemIsEmpty
    section.find('.editable-array .array-item').each ->
      $(@).remove() if isEmpty @
    resetOnce = false  # We have to clear out arrays if we're going to redo them
    for field in $(e.target).closest('form').serializeArray()
      keyChain = @extractFieldKeyChain field.name
      value = @extractFieldValue keyChain[0], field.value
      console.log "Should save", keyChain, value
      parent = @user.get('jobProfile')
      for key, i in keyChain
        break if i is keyChain.length - 1
        child = parent[key]
        if _.isArray(child) and not resetOnce
          child = parent[key] = []
          resetOnce = true
        else unless child?
          child = parent[key] = {}
        parent = child
      console.log "  Setting", parent, "prop", key, "to", value
      parent[key] = value
    section.addClass 'saving'
    @saveEdits()

  extractFieldKeyChain: (key) ->
    # "root[projects][0][name]" -> ["projects", "0", "name"]
    key.replace(/^root/, '').replace(/\[(.*?)\]/g, '.$1').replace(/^\./, '').split(/\./)

  extractFieldValue: (key, value) ->
    switch key
      when 'active' then Boolean value
      else value

  arrayItemIsEmpty: (arrayItem) ->
    for input in $(arrayItem).find('input')
      return false if $(input).val()
    true

  onEditArray: (e) ->
    array = $(e.target).closest('.editable-array')
    arrayItems = array.find('.array-item')
    toRemove = []
    for arrayItem, index in arrayItems
      empty = @arrayItemIsEmpty arrayItem
      if index is arrayItems.length - 1
        lastEmpty = empty
      else if empty
        toRemove.unshift index
    $(arrayItems[emptyIndex]).remove() for emptyIndex in toRemove
    unless lastEmpty
      clone = $(arrayItem).clone(true)
      clone.find('input').each -> $(@).val('')
      array.append clone
    for arrayItem, index in array.find('.array-item')
      for input in $(arrayItem).find('input')
        $(input).attr('name', $(input).attr('name').replace(/\[\d+\]/, "[#{index}]"))
