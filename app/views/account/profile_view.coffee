View = require 'views/kinds/RootView'
template = require 'templates/account/profile'
User = require 'models/User'
LevelSession = require 'models/LevelSession'
CocoCollection = require 'collections/CocoCollection'
{me} = require 'lib/auth'
JobProfileContactView = require 'views/modal/job_profile_contact_modal'
JobProfileView = require 'views/account/job_profile_view'
forms = require 'lib/forms'

class LevelSessionsCollection extends CocoCollection
  url: -> "/db/user/#{@userID}/level.sessions/employer"
  model: LevelSession
  constructor: (@userID) ->
    super()

module.exports = class ProfileView extends View
  id: "profile-view"
  template: template
  subscriptions:
    'linkedin-loaded': 'onLinkedInLoaded'

  events:
    'click #toggle-editing': 'toggleEditing'
    'click #importLinkedIn': 'importLinkedIn'
    'click #toggle-job-profile-active': 'toggleJobProfileActive'
    'click #toggle-job-profile-approved': 'toggleJobProfileApproved'
    'click #save-notes-button': 'onJobProfileNotesChanged'
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
    @userID ?= me.id
    @onJobProfileNotesChanged = _.debounce @onJobProfileNotesChanged, 1000
    @authorizedWithLinkedIn = IN?.User?.isAuthorized()
    @linkedInLoaded = Boolean(IN.parse)
    @waitingForLinkedIn = false
    window.contractCallback = =>
      @authorizedWithLinkedIn = IN?.User?.isAuthorized()
      @render()
    super options
    if User.isObjectID @userID
      @finishInit()
    else
      $.ajax "/db/user/#{@userID}/nameToID", success: (@userID) =>
        @finishInit() unless @destroyed
        @render()

  finishInit: ->
    return unless @userID
    @uploadFilePath = "db/user/#{@userID}"
    @highlightedContainers = []
    if @userID is me.id
      @user = me
    else if me.isAdmin() or "employer" in me.get('permissions')
      @user = User.getByID(@userID)
      @user.fetch()
      @listenTo @user, "sync", =>
        @render()
      $.post "/db/user/#{me.id}/track/view_candidate"
      $.post "/db/user/#{@userID}/track/viewed_by_employer" unless me.isAdmin()
    else
      @user = User.getByID(@userID)
    @sessions = @supermodel.loadCollection(new LevelSessionsCollection(@userID), 'candidate_sessions').model

  onLinkedInLoaded: =>
    @linkedinLoaded = true
    if @waitingForLinkedIn
      @renderLinkedInButton()

  renderLinkedInButton: =>
    IN?.parse()

  afterInsert: ->
    super()
    linkedInButtonParentElement = document.getElementById("linkedInAuthButton")
    if linkedInButtonParentElement
      if @linkedinLoaded
        @renderLinkedInButton()
      else
        @waitingForLinkedIn = true

  importLinkedIn: =>
    overwriteConfirm = confirm("Importing LinkedIn data will overwrite your current work experience, skills, name, descriptions, and education. Continue?")
    unless overwriteConfirm then return
    application.linkedinHandler.getProfileData (err, profileData) =>
      @processLinkedInProfileData profileData
  jobProfileSchema: -> @user.schema().properties.jobProfile.properties

  processLinkedInProfileData: (p) ->
    #handle formatted-name
    currentJobProfile = @user.get('jobProfile')
    oldJobProfile = _.cloneDeep(currentJobProfile)
    jobProfileSchema = @user.schema().properties.jobProfile.properties

    if p["formattedName"]? and p["formattedName"] isnt "private"
      nameMaxLength = jobProfileSchema.name.maxLength
      currentJobProfile.name = p["formattedName"].slice(0,nameMaxLength)
    if p["skills"]?["values"].length
      skillNames = []
      skillMaxLength = jobProfileSchema.skills.items.maxLength
      for skill in p.skills.values
        skillNames.push skill.skill.name.slice(0,skillMaxLength)
      currentJobProfile.skills = skillNames
    if p["headline"]
      shortDescriptionMaxLength = jobProfileSchema.shortDescription.maxLength
      currentJobProfile.shortDescription = p["headline"].slice(0,shortDescriptionMaxLength)
    if p["summary"]
      longDescriptionMaxLength = jobProfileSchema.longDescription.maxLength
      currentJobProfile.longDescription = p.summary.slice(0,longDescriptionMaxLength)
    if p["positions"]?["values"]?.length
      newWorks = []
      workSchema = jobProfileSchema.work.items.properties
      for position in p["positions"]["values"]
        workObj = {}
        descriptionMaxLength = workSchema.description.maxLength

        workObj.description = position.summary?.slice(0,descriptionMaxLength)
        workObj.description ?= ""
        if position.startDate?.year?
          workObj.duration = "#{position.startDate.year} - "
          if (not position.endDate?.year) or (position.endDate?.year and position.endDate?.year > (new Date().getFullYear()))
            workObj.duration += "present"
          else
            workObj.duration += position.endDate.year
        else
          workObj.duration = ""
        durationMaxLength = workSchema.duration.maxLength
        workObj.duration = workObj.duration.slice(0,durationMaxLength)
        employerMaxLength = workSchema.employer.maxLength
        workObj.employer = position.company?.name ? ""
        workObj.employer = workObj.employer.slice(0,employerMaxLength)
        workObj.role = position.title ? ""
        roleMaxLength = workSchema.role.maxLength
        workObj.role = workObj.role.slice(0,roleMaxLength)
        newWorks.push workObj
      currentJobProfile.work = newWorks


    if p["educations"]?["values"]?.length
      newEducation = []
      eduSchema = jobProfileSchema.education.items.properties
      for education in p["educations"]["values"]
        educationObject = {}
        educationObject.degree = education.degree ? "Studied"

        if education.startDate?.year?
          educationObject.duration = "#{education.startDate.year} - "
          if (not education.endDate?.year) or (education.endDate?.year and education.endDate?.year > (new Date().getFullYear()))
            educationObject.duration += "present"
            if educationObject.degree is "Studied"
              educationObject.degree = "Studying"
          else
            educationObject.duration += education.endDate.year
        else
          educationObject.duration = ""
        if education.fieldOfStudy
          if educationObject.degree is "Studied" or educationObject.degree is "Studying"
            educationObject.degree += " #{education.fieldOfStudy}"
          else
            educationObject.degree += " in #{education.fieldOfStudy}"
        educationObject.degree = educationObject.degree.slice(0,eduSchema.degree.maxLength)
        educationObject.duration = educationObject.duration.slice(0,eduSchema.duration.maxLength)
        educationObject.school = education.schoolName ? ""
        educationObject.school = educationObject.school.slice(0,eduSchema.school.maxLength)
        educationObject.description = ""
        newEducation.push educationObject
      currentJobProfile.education = newEducation
    if p["publicProfileUrl"]
      #search for linkedin link
      links = currentJobProfile.links
      alreadyHasLinkedIn = false
      for link in links
        if link.link.toLowerCase().indexOf("linkedin") > -1
          alreadyHasLinkedIn = true
          break
      unless alreadyHasLinkedIn
        newLink =
          link: p["publicProfileUrl"]
          name: "LinkedIn"
        currentJobProfile.links.push newLink
    @user.set('jobProfile',currentJobProfile)
    validationErrors = @user.validate()
    if validationErrors
      @user.set('jobProfile',oldJobProfile)
      return alert("Please notify team@codecombat.com! There were validation errors from the LinkedIn import: #{JSON.stringify validationErrors}")
    else
      @render()

  getRenderData: ->
    context = super()
    context.userID = @userID
    context.linkedInAuthorized = @authorizedWithLinkedIn
    context.jobProfileSchema = me.schema().properties.jobProfile
    if @user and not jobProfile = @user.get 'jobProfile'
      jobProfile = {}
      for prop, schema of context.jobProfileSchema.properties
        jobProfile[prop] = _.clone schema.default if schema.default?
      for prop in context.jobProfileSchema.required
        jobProfile[prop] ?= {string: '', boolean: false, number: 0, integer: 0, array: []}[context.jobProfileSchema.properties[prop].type]
      @user.set 'jobProfile', jobProfile
    jobProfile.name ?= (@user.get('firstName') + ' ' + @user.get('lastName')).trim() if @user?.get('firstName')
    context.profile = jobProfile
    context.user = @user
    context.myProfile = @user?.id is context.me.id
    context.allowedToViewJobProfile = @user and (me.isAdmin() or "employer" in me.get('permissions') or (context.myProfile && !me.get('anonymous')))
    context.allowedToEditJobProfile = @user and (me.isAdmin() or (context.myProfile && !me.get('anonymous')))
    context.profileApproved = @user?.get 'jobProfileApproved'
    context.progress = @progress ? @updateProgress()
    @editing ?= context.myProfile and context.progress < 0.8
    context.editing = @editing
    context.marked = marked
    context.moment = moment
    context.iconForLink = @iconForLink
    if links = jobProfile?.links
      links = ($.extend(true, {}, link) for link in links)
      link.icon = @iconForLink link for link in links
      context.profileLinks = _.sortBy links, (link) -> not link.icon  # icons first
    if @sessions
      context.sessions = (s.attributes for s in @sessions.models when (s.get('submitted') or s.get('level-id') is 'gridmancer'))
      context.sessions.sort (a, b) -> (b.playtime ? 0) - (a.playtime ? 0)
    else
      context.sessions = []
    context

  afterRender: ->
    super()
    if me.get('employerAt')
      @$el.addClass 'viewed-by-employer'
    return unless @user
    unless @user.get('jobProfile')?.projects?.length or @editing
      @$el.find('.right-column').hide()
      @$el.find('.middle-column').addClass('double-column')
    unless @editing
      @$el.find('.editable-display').attr('title', '')
    @initializeAutocomplete()
    highlightNext = @highlightNext ? true
    justSavedSection = @$el.find('#' + @justSavedSectionID).addClass "just-saved"
    _.defer =>
      @progress = @updateProgress highlightNext
      _.delay ->
        justSavedSection.removeClass "just-saved", duration: 1500, easing: 'easeOutQuad'
      , 500

  initializeAutocomplete: (container) ->
    (container ? @$el).find('input[data-autocomplete]').each ->
      $(@).autocomplete(source: JobProfileView[$(@).data('autocomplete')], minLength: parseInt($(@).data('autocomplete-min-length')), delay: 0, autoFocus: true)

  toggleEditing: ->
    @editing = not @editing
    @render()
    _.delay @renderLinkedInButton, 1000
    @saveEdits()

  toggleJobProfileApproved: ->
    return unless me.isAdmin()
    approved = not @user.get 'jobProfileApproved'
    @user.set 'jobProfileApproved', approved
    res = @user.save {jobProfileApproved: approved}, {patch: true}
    res.success (model, response, options) => @render()

  toggleJobProfileActive: ->
    active = not @user.get('jobProfile').active
    @user.get('jobProfile').active = active
    @saveEdits()
    if active and not (me.isAdmin() or @stackLed)
      $.post "/stacklead"
      @stackLed = true

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
    @user.save {jobProfileNotes: notes}, {patch: true}

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
    @openModalView new JobProfileContactView recipientID: @user.id, recipientUserName: @user.get('name')

  showErrors: (errors) ->
    section = @$el.find '.saving'
    console.error "Couldn't save because of validation errors:", errors
    section.removeClass 'saving'
    forms.clearFormAlerts section
    # This is pretty lame, since we don't easily match which field had the error like forms.applyErrorsToForm can.
    section.find('form').addClass('has-error').find('.save-section').before($("<span class='help-block error-help-block'>#{errors[0].message}</span>"))

  saveEdits: (highlightNext) ->
    errors = @user.validate()
    return @showErrors errors if errors
    jobProfile = @user.get('jobProfile')
    jobProfile.updated = (new Date()).toISOString() if @user is me
    @user.set 'jobProfile', jobProfile
    return unless res = @user.save()
    res.error =>
      return if @destroyed
      @showErrors [message: res.responseText]
    res.success (model, response, options) =>
      return if @destroyed
      @justSavedSectionID = @$el.find('.editable-section.saving').removeClass('saving').attr('id')
      @highlightNext = highlightNext
      @render()
      @highlightNext = false
      @justSavedSectionID = null

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
    @$el.find('.emphasized').removeClass('emphasized')
    section = $(e.target).closest('.editable-section').removeClass 'deemphasized'
    section.find('.editable-form').show().find('select, input, textarea').first().focus()
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
        rootPropertiesSeen[key] = true unless i
        break if i is keyChain.length - 1
        child = parent[key]
        if _.isArray(child) and not resetOnce
          child = parent[key] = []
          resetOnce = true
        else unless child?
          child = parent[key] = {}
        parent = child
      if key is 'link' and keyChain[0] is 'projects' and not value
        delete parent[key]
      else
        parent[key] = value
    form.find('.editable-array').each ->
      key = $(@).data('property')
      unless rootPropertiesSeen[key]
        jobProfile[key] = []
    if section.hasClass('projects-container') and not section.find('.array-item').length
      jobProfile.projects = []
    section.addClass 'saving'
    @saveEdits true

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
      clone = $(arrayItem).clone(false)
      clone.find('input').each -> $(@).val('')
      clone.find('textarea').each -> $(@).text('')
      array.append clone
      @initializeAutocomplete clone
    for arrayItem, index in array.find('.array-item')
      for input in $(arrayItem).find('input, textarea')
        $(input).attr('name', $(input).attr('name').replace(/\[\d+\]/, "[#{index}]"))

  onClickLinkWhileEditing: (e) ->
    e.preventDefault()

  updateProgress: (highlightNext) ->
    return unless @user
    completed = 0
    totalWeight = 0
    next = null
    for metric in metrics = @getProgressMetrics()
      done = metric.fn()
      completed += metric.weight if done
      totalWeight += metric.weight
      next = metric unless next or done
    progress = Math.round 100 * completed / totalWeight
    bar = @$el.find('.profile-completion-progress .progress-bar')
    bar.css 'width', "#{progress}%"
    if next
      text = ""
      t = $.i18n.t
      text = "#{progress}% #{t 'account_profile.complete'}. #{t 'account_profile.next'}: #{next.name}"
      bar.parent().show().find('.progress-text').text text
      if highlightNext and next?.container and not (next.container in @highlightedContainers)
        @highlightedContainers.push next.container
        @$el.find(next.container).addClass 'emphasized'
        #@onEditSection target: next.container
        #$('#page-container').scrollTop 0
    else
      bar.parent().hide()
    completed / totalWeight

  getProgressMetrics: ->
    schema = me.schema().properties.jobProfile
    jobProfile = @user.get('jobProfile') ? {}
    exists = (field) -> -> jobProfile[field]
    modified = (field) -> -> jobProfile[field] and jobProfile[field] isnt schema.properties[field].default
    listStarted = (field, subfields) -> -> jobProfile[field]?.length and _.every subfields, (subfield) -> jobProfile[field][0][subfield]
    t = $.i18n.t
    @progressMetrics = [
      {name: t('account_profile.next_name'), weight: 1, container: '#name-container', fn: modified 'name'}
      {name: t('account_profile.next_short_description'), weight: 2, container: '#short-description-container', fn: modified 'shortDescription'}
      {name: t('account_profile.next_skills'), weight: 2, container: '#skills-container', fn: -> jobProfile.skills?.length >= 5}
      {name: t('account_profile.next_long_description'), weight: 3, container: '#long-description-container', fn: modified 'longDescription'}
      {name: t('account_profile.next_work'), weight: 3, container: '#work-container', fn: listStarted 'work', ['role', 'employer']}
      {name: t('account_profile.next_education'), weight: 3, container: '#education-container', fn: listStarted 'education', ['degree', 'school']}
      {name: t('account_profile.next_projects'), weight: 3, container: '#projects-container', fn: listStarted 'projects', ['name']}
      {name: t('account_profile.next_city'), weight: 1, container: '#basic-info-container', fn: modified 'city'}
      {name: t('account_profile.next_country'), weight: 0, container: '#basic-info-container', fn: exists 'country'}
      {name: t('account_profile.next_links'), weight: 2, container: '#links-container', fn: listStarted 'links', ['link', 'name']}
      {name: t('account_profile.next_photo'), weight: 2, container: '#profile-photo-container', fn: modified 'photoURL'}
      {name: t('account_profile.next_active'), weight: 1, fn: modified 'active'}
    ]
