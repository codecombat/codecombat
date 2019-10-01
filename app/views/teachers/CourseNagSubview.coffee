CocoView = require 'views/core/CocoView'
CourseNagModal = require 'views/teachers/CourseNagModal'
Prepaids = require 'collections/Prepaids'
utils = require 'core/utils'

template = require 'templates/teachers/course-nag'

# Shows up if you have prepaids but haven't enrolled any students
module.exports = class CourseNagSubview extends CocoView
  id: 'classes-nag-subview'
  template: template
  events:
    'click .more-info': 'onClickMoreInfo'

  initialize: (options) ->
    super(options)
    @prepaids = new Prepaids()
    @supermodel.trackRequest @prepaids.fetchMineAndShared()
    @listenTo @prepaids, 'sync', @gotPrepaids
    @shown = false

  afterRender: ->
    super()
    if @shown
      @$el.show()
    else
      @$el.hide()


  gotPrepaids: ->
    # Group prepaids into (I)gnored (U)sed (E)mpty
    unusedPrepaids = @prepaids.groupBy (p) ->
      return 'I' if p.status() in ["expired", "pending"]
      return 'U' if p.hasBeenUsedByTeacher(me.id)
      return 'E'

    @shown = unusedPrepaids.E? and not unusedPrepaids.U?
    @render()

  onClickMoreInfo: ->
    @openModalView new CourseNagModal()
