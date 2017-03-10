CocoView = require 'views/core/CocoView'
CourseNagModal = require 'views/teachers/CourseNagModal'
Prepaids = require 'collections/Prepaids'
utils = require 'core/utils'

template = require 'templates/teachers/course-nag'

module.exports = class CourseNagSubview extends CocoView
  id: 'classes-nag-subview'
  template: template
  events:
    'click .more-info': 'onClickMoreInfo'

  initialize: (options) ->
    super(options)
    @prepaids = new Prepaids()
    @supermodel.trackRequest @prepaids.fetchByCreator(me.id)
    @listenTo @prepaids, 'sync', @gotPrepaids
    @shown = false

  afterRender: ->
    super()
    if @shown
      @$el.fadeIn()
    else
      @$el.hide()


  gotPrepaids: ->
    unusedPrepaids = @prepaids.groupBy (p) ->
      return 'I' if p.status() in ["expired", "pending"]
      return 'U' if p.get('exhausted') is true
      return 'U' if p.get('redeemers')?.length isnt 0
      return 'E'
    
    @shown = unusedPrepaids.E? and not unusedPrepaids.U?
    @render()

  onClickMoreInfo: ->
    @openModalView new CourseNagModal()
