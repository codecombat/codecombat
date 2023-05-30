require('app/styles/artisans/arena-balancer-view.sass')
RootView = require 'views/core/RootView'
template = require 'templates/artisans/arena-balancer-view'

Campaigns = require 'collections/Campaigns'
Campaign = require 'models/Campaign'

Levels = require 'collections/Levels'
Level = require 'models/Level'
LevelSessions = require 'collections/LevelSessions'
ace = require 'lib/aceContainer'
aceUtils = require 'core/aceUtils'
require 'lib/setupTreema'
treemaExt = require 'core/treema-ext'
storage = require 'core/storage'
ConfirmModal = require 'views/core/ConfirmModal'

module.exports = class ArenaBalancerView extends RootView
  template: template
  id: 'arena-balancer-view'

  events:
    'click #go-button': 'onClickGoButton'

  levelSlug: 'infinite-inferno'

  constructor: (options, @levelSlug) ->
    super options
    @getLevelInfo()

  afterRender: ->
    super()
    editorElements = @$el.find('.ace')
    for el in editorElements
      lang = @$(el).data('language')
      editor = ace.edit el
      aceSession = editor.getSession()
      aceDoc = aceSession.getDocument()
      aceSession.setMode aceUtils.aceEditModes[lang]
      editor.setTheme 'ace/theme/textmate'
      #editor.setReadOnly true

  getLevelInfo: () ->
    @level = @supermodel.getModel(Level, @levelSlug) or new Level _id: @levelSlug
    @supermodel.trackRequest @level.fetch()
    @level.on 'error', (@level, error) =>
      return @errorMessage = "Error loading level: #{error.statusText}"
    if @level.loaded
      @onLevelLoaded @level
    else
      @listenToOnce @level, 'sync', @onLevelLoaded

  onLevelLoaded: (level) ->
    solutions = []
    hero = _.find level.get("thangs") ? [], id: 'Hero Placeholder'
    plan = _.find(hero?.components ? [], (x) -> x?.config?.programmableMethods?.plan)?.config.programmableMethods.plan
    unless @solution = _.find(plan?.solutions ? [], description: 'arena-balancer')
      @errorMessage = 'Configure a solution with description arena-balancer to use as the default'
    @render()
    _.delay @setUpVariablesTreema, 100  # Dunno why we need to delay

  setUpVariablesTreema: =>
    return if @destroyed
    variableRegex = /<%= ?(.*?) ?%>/g
    variables = []
    while matched = variableRegex.exec @solution.source
      variables.push matched[1]
    dataStorageKey = ['arena-balancer-data', @levelSlug].join(':')
    data = storage.load dataStorageKey
    data ?= {}
    schema = type: 'object', additionalProperties: false, properties: {}, required: variables, title: 'Variants', description: 'Combinatoric choice options'
    for variable in variables
      schema.properties[variable] = type: 'array', items:
        type: 'object'
        additionalProperties: false
        required: ['name', 'code']
        default: {name: '', code: ''}
        properties:
          name:
            type: 'string'
            maxLength: 5
            description: 'Very short name/code for variant that will appear in usernames'
          code:
            type: 'string'
            format: 'code'
            aceMode: 'ace/mode/javascript'
            title: 'Variant'
            description: 'Cartesian products will result'
      data[variable] ?= [name: '', code: '']

    treemaOptions =
      schema: schema
      data: data
      nodeClasses:
        code: treemaExt.JavaScriptTreema
      callbacks:
        change: @onVariablesChanged

    @variablesTreema = @$el.find('#variables-treema').treema treemaOptions
    @variablesTreema.build()
    @variablesTreema.open(3)
    @onVariablesChanged()

  onVariablesChanged: (e) =>
    dataStorageKey = ['arena-balancer-data', @levelSlug].join(':')
    storage.save dataStorageKey, @variablesTreema.data
    cartesian = (a) -> a.reduce((a, b) -> a.flatMap((d) -> b.map((e) -> [d, e].flat())))
    variables = []
    for variable of @variablesTreema.data
      variants = []
      for variant in @variablesTreema.data[variable]
        variants.push {variable: variable, name: variant.name, code: variant.code}
      variables.push variants
    @choices = cartesian variables
    @$('#go-button').text "Create/Update All #{@choices.length} Test Sessions"

  onClickGoButton: (event) ->
    renderData =
      title: 'Are you really sure?'
      body: "This will wipe all arena balancer sessions for #{@levelSlug} and submit #{@choices.length} new ones. Are you sure you want to do it? (Probably shouldn't be more than a couple thousand.)"
      decline: 'Not really'
      confirm: 'Definitely'
    @confirmModal = new ConfirmModal renderData
    @confirmModal.on 'confirm', @submitSessions
    @openModalView @confirmModal

  submitSessions: (e) =>
    @confirmModal.$el.find('#confirm-button').attr('disabled', true).text('Working... (can take a while)')
    postData = submissions: []
    for choice in @choices
      context = {}
      context[variant.variable] = variant.code for variant in choice
      code = _.template @solution.source, context
      session = name: (variant.name for variant in choice).join('-'), code: code
      postData.submissions.push session

    $.ajax
      data: JSON.stringify postData
      success: (data, status, jqXHR) =>
        noty
          timeout: 5000
          text: 'Arena balancing submission process started'
          type: 'success'
          layout: 'topCenter'
        @confirmModal?.hide?()
      error: (jqXHR, status, error) =>
        console.error jqXHR
        noty
          timeout: 5000
          text: "Arena balancing submission process failed with error code #{jqXHR.status}"
          type: 'error'
          layout: 'topCenter'
        @confirmModal?.hide?()
      url: "/db/level/#{@levelSlug}/arena-balancer-sessions"  # TODO
      type: 'POST'
      contentType: 'application/json'
