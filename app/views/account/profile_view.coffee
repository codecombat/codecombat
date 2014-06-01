View = require 'views/kinds/RootView'
template = require 'templates/account/profile'
User = require 'models/User'
JobProfileContactView = require 'views/modal/job_profile_contact_modal'

module.exports = class ProfileView extends View
  id: "profile-view"
  template: template

  events:
    'click #toggle-editing': 'toggleEditing'
    'click #toggle-job-profile-active': 'toggleJobProfileActive'
    'click #toggle-job-profile-approved': 'toggleJobProfileApproved'
    'click save-notes-button': 'onJobProfileNotesChanged'
    'click #contact-candidate': 'onContactCandidate'
    'click #enter-espionage-mode': 'enterEspionageMode'
    'click .editable-profile .profile-photo': 'onEditProfilePhoto'
    'click .editable-profile .project-image': 'onEditProjectImage'
    'click .editable-profile .editable-display': 'onEditSection'
    'click .editable-profile .save-section': 'onSaveSection'
    'click .editable-profile .glyphicon-remove': 'onCancelSectionEdit'
    'change .editable-profile .editable-array input': 'onEditArray'
    'keyup .editable-profile .editable-array input': 'onEditArray'
    'click .editable-profile a': 'onClickLinkWhileEditing'

  constructor: (options, @userID) ->
    @onJobProfileNotesChanged = _.debounce @onJobProfileNotesChanged, 1000
    super options
    @uploadFilePath = "db/user/#{@userID}"
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
    context.progress = @progress ? @updateProgress()
    @editing ?= context.progress < 0.8
    context.editing = @editing
    context.jobProfileSchema = me.schema().properties.jobProfile
    context.marked = marked
    context.moment = moment
    context.iconForLink = @iconForLink
    unless jobProfile = @user.get 'jobProfile'
      @user.set 'jobProfile', jobProfile = {}
    jobProfile.name ?= (@user.get('firstName') + ' ' + @user.get('lastName')).trim() if @user.get('firstName')
    if links = jobProfile.links
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
    @progress = @updateProgress()

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

  toggleJobProfileActive: ->
    active = not @user.get('jobProfile').active
    @user.get('jobProfile').active = active
    @saveEdits()

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
    onSaving = =>
      @$el.find('.profile-photo').addClass('saving')
    onSaved = (uploadingPath) =>
      @user.get('jobProfile').photoURL = uploadingPath
      @saveEdits()
    filepicker.pick {mimetypes: 'image/*'}, @onImageChosen(onSaving, onSaved)

  onEditProjectImage: (e) ->
    img = $(e.target)
    onSaving = =>
      img.addClass('saving')
    onSaved = (uploadingPath) =>
      img.parent().find('input').val(uploadingPath)
      img.css('background-image', "url('/file/#{uploadingPath}')")
      img.removeClass('saving')
    filepicker.pick {mimetypes: 'image/*'}, @onImageChosen(onSaving, onSaved)

  formatImagePostData: (inkBlob) ->
    url: inkBlob.url, filename: inkBlob.filename, mimetype: inkBlob.mimetype, path: @uploadFilePath, force: true

  onImageChosen: (onSaving, onSaved) ->
    (inkBlob) =>
      onSaving()
      uploadingPath = [@uploadFilePath, inkBlob.filename].join('/')
      $.ajax '/file', type: 'POST', data: @formatImagePostData(inkBlob), success: @onImageUploaded(onSaved, uploadingPath)

  onImageUploaded: (onSaved, uploadingPath) ->
    (e) =>
      onSaved uploadingPath

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
    form = $(e.target).closest('form')
    isEmpty = @arrayItemIsEmpty
    section.find('.array-item').each ->
      console.log "removing", @ if isEmpty @
      $(@).remove() if isEmpty @
    resetOnce = false  # We have to clear out arrays if we're going to redo them
    serialized = form.serializeArray()
    jobProfile = @user.get 'jobProfile'
    rootPropertiesSeen = {}
    for field in serialized
      keyChain = @extractFieldKeyChain field.name
      value = @extractFieldValue keyChain[0], field.value
      parent = jobProfile
      for key, i in keyChain
        console.log key, i
        rootPropertiesSeen[key] = true unless i
        break if i is keyChain.length - 1
        child = parent[key]
        if _.isArray(child) and not resetOnce
          child = parent[key] = []
          resetOnce = true
          console.log "  resetting"
        else unless child?
          child = parent[key] = {}
        parent = child
      parent[key] = value
    form.find('.editable-array').each ->
      key = $(@).data('property')
      unless rootPropertiesSeen[key]
        jobProfile[key] = []
    if section.hasClass('projects-container') and not section.find('.array-item').length
      jobProfile.projects = []
    section.addClass 'saving'
    @saveEdits()

  extractFieldKeyChain: (key) ->
    # "root[projects][0][name]" -> ["projects", "0", "name"]
    key.replace(/^root/, '').replace(/\[(.*?)\]/g, '.$1').replace(/^\./, '').split(/\./)

  extractFieldValue: (key, value) ->
    switch key
      when 'active' then Boolean value
      when 'experience' then parseInt value or '0'
      else value

  arrayItemIsEmpty: (arrayItem) ->
    for input in $(arrayItem).find('input[type!=hidden], textarea')
      return false if $(input).val().trim()
    true

  onEditArray: (e) ->
    # We make sure there's always an empty array item at the end for the user to add to, deleting interstitial empties.
    array = $(e.target).closest('.editable-array')
    arrayItems = array.find('.array-item')
    toRemove = []
    for arrayItem, index in arrayItems
      empty = @arrayItemIsEmpty arrayItem
      if index is arrayItems.length - 1
        lastEmpty = empty
      else if empty and not $(arrayItem).find('input:focus, textarea:focus').length
        toRemove.unshift index
    $(arrayItems[emptyIndex]).remove() for emptyIndex in toRemove
    unless lastEmpty
      clone = $(arrayItem).clone(true)
      clone.find('input').each -> $(@).val('')
      clone.find('textarea').each -> $(@).text('')
      array.append clone
    for arrayItem, index in array.find('.array-item')
      for input in $(arrayItem).find('input, textarea')
        $(input).attr('name', $(input).attr('name').replace(/\[\d+\]/, "[#{index}]"))

  onClickLinkWhileEditing: (e) ->
    e.preventDefault()

  updateProgress: ->
    completed = 0
    totalWeight = 0
    next = null
    for metric in metrics = @getProgressMetrics()
      done = metric.fn()
      completed += metric.weight if done
      totalWeight += metric.weight
      next = metric.name unless next or done
    progress = Math.round 100 * completed / totalWeight
    bar = @$el.find('.profile-completion-progress .progress-bar')
    bar.css 'width', "#{progress}%"
    text = ""
    if next and progress > 40
      text = "#{progress}% complete. Next: #{next}"
    else if next and progress > 30
      text = "#{progress}%. Next: #{next}"
    else if next and progress > 20
      text = "#{progress}%: #{next}"
    else if progress > 11
      text = "#{progress}% complete."
    else if progress > 3
      text = "#{progress}%"
    bar.text text
    bar.parent().toggle Boolean progress
    completed / totalWeight

  getProgressMetrics: ->
    return @progressMetrics if @progressMetrics
    schema = me.schema().properties.jobProfile
    jobProfile = @user.get('jobProfile')
    exists = (field) -> -> jobProfile[field]
    modified = (field) -> -> jobProfile[field] and jobProfile[field] isnt schema.properties[field].default
    listStarted = (field, subfields) -> -> jobProfile[field]?.length and _.every subfields, (subfield) -> jobProfile[field][0][subfield]
    @progressMetrics = [
      {name: "job title?", weight: 0, fn: exists 'jobTitle'}
      {name: "choose your city.", weight: 1, fn: modified 'city'}
      {name: "pick your country.", weight: 0, fn: exists 'country'}
      {name: "provide your name.", weight: 1, fn: modified 'name'}
      {name: "summarize yourself at a glance.", weight: 2, fn: modified 'shortDescription'}
      {name: "list at least five skills.", weight: 2, fn: -> jobProfile.skills.length >= 5}
      {name: "describe the work you're looking for.", weight: 3, fn: modified 'longDescription'}
      {name: "list your work experience.", weight: 3, fn: listStarted 'work', ['role', 'employer']}
      {name: "recount your educational ordeals.", weight: 3, fn: listStarted 'education', ['degree', 'school']}
      {name: "show off up to three projects you've worked on.", weight: 3, fn: listStarted 'projects', ['name']}
      {name: "add any personal or social links.", weight: 2, fn: listStarted 'links', ['link', 'name']}
      {name: "add an optional professional photo.", weight: 2, fn: modified 'photoURL'}
      {name: "mark yourself open to offers to show up in searches.", weight: 1, fn: modified 'active'}
    ]
