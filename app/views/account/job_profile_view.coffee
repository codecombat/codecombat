CocoView = require 'views/kinds/CocoView'
template = require 'templates/account/job_profile'
{me} = require('lib/auth')

module.exports = class JobProfileView extends CocoView
  id: 'job-profile-view'
  template: template

  editableSettings: [
    'lookingFor', 'active', 'name', 'city', 'country', 'skills', 'experience', 'shortDescription', 'longDescription',
    'work', 'education', 'visa', 'projects', 'links', 'jobTitle'
  ]
  readOnlySettings: [
    'updated'
  ]

  constructor: (options) ->
    super options
    unless me.schema().loaded
      @addSomethingToLoad("user_schema")
      @listenToOnce me, 'schema-loaded', => @somethingLoaded 'user_schema'

  afterRender: ->
    super()
    return if @loading()
    @buildJobProfileTreema()

  buildJobProfileTreema: ->
    visibleSettings = @editableSettings.concat @readOnlySettings
    data = _.pick (me.get('jobProfile') ? {}), (value, key) => key in visibleSettings
    data.name ?= (me.get('firstName') + ' ' + me.get('lastName')).trim() if me.get('firstName')
    schema = _.cloneDeep me.schema().get('properties').jobProfile
    schema.properties = _.pick schema.properties, (value, key) => key in visibleSettings
    schema.required = _.intersection schema.required, visibleSettings
    for prop in @readOnlySettings
      schema.properties[prop].readOnly = true
    treemaOptions =
      filePath: "db/user/#{me.id}"
      schema: schema
      data: data
      aceUseWrapMode: true
      callbacks: {change: @onJobProfileChanged}

    @jobProfileTreema = @$el.find('#job-profile-treema').treema treemaOptions
    @jobProfileTreema.build()
    @jobProfileTreema.open()

  onJobProfileChanged: (e) =>
    @hasEditedProfile = true
    @trigger 'change'

  getData: ->
    return {} unless me.get('jobProfile') or @hasEditedProfile
    _.pick @jobProfileTreema.data, (value, key) => key in @editableSettings
