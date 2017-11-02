require('app/styles/admin/admin-outcomes-report.sass')
utils = require 'core/utils'
RootView = require 'views/core/RootView'

module.exports = class OutcomesReportResultView extends RootView
  id: 'admin-outcomes-report-result-view'
  template: require 'templates/admin/outcome-report-result-view'
  events:
    'click .back-btn': 'onClickBackButton'
    'click .print-btn': 'onClickPrintButton'
  initialize: (@options) ->
    return super() unless me.isAdmin()
    @format = _.identity
    
    if window?.Intl?.NumberFormat?
      intl = new window.Intl.NumberFormat()
      @format = intl.format.bind(intl)

    @courses = @options.courses.map (course) =>
      _.merge course, {completion: @options.courseCompletion[course._id].completion}

    # Reorder CS2 in front of WD1/GD1 if it's more completed, to account for us changing the order around.
    cs1 = _.find @courses, {slug: 'introduction-to-computer-science'}
    cs2 = _.find @courses, {slug: 'computer-science-2'}
    gd1 = _.find @courses, {slug: 'game-development-1'}
    wd1 = _.find @courses, {slug: 'web-development-1'}

    if cs2?.completion > _.max([gd1?.completion, wd1?.completion])
      @courses.splice(@courses.indexOf(cs2), 1)
      @courses.splice(_.max([@courses.indexOf(cs1), 0]) + 1, 0, cs2)
    super()

  onClickBackButton: ->
    console.log("Back View is", @options.backView)
    application.router.openView(@options.backView)

  onClickPrintButton: ->
    window.print()
