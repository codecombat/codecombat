View = require 'views/kinds/RootView'
template = require 'templates/employers'
app = require 'application'
User = require 'models/User'
CocoCollection = require 'models/CocoCollection'
EmployerSignupView = require 'views/modal/employer_signup_modal'

class CandidatesCollection extends CocoCollection
  url: '/db/user/x/candidates'
  model: User

module.exports = class EmployersView extends View
  id: "employers-view"
  template: template

  events:
    'click tbody tr': 'onCandidateClicked'

  constructor: (options) ->
    super options
    @getCandidates()

  afterRender: ->
    super()
    @sortTable() if @candidates.models.length

  getRenderData: ->
    c = super()
    c.candidates = @candidates.models
    c.moment = moment
    c

  getCandidates: ->
    @candidates = new CandidatesCollection()
    @candidates.fetch()
    # Re-render when we have fetched them, but don't wait and show a progress bar while loading.
    @listenToOnce @candidates, 'all', @render

  sortTable: ->
    # http://mottie.github.io/tablesorter/docs/example-widget-bootstrap-theme.html
    $.extend $.tablesorter.themes.bootstrap,
      # these classes are added to the table. To see other table classes available,
      # look here: http://twitter.github.com/bootstrap/base-css.html#tables
      table: "table table-bordered"
      caption: "caption"
      header: "bootstrap-header" # give the header a gradient background
      footerRow: ""
      footerCells: ""
      icons: "" # add "icon-white" to make them white; this icon class is added to the <i> in the header
      sortNone: "bootstrap-icon-unsorted"
      sortAsc: "icon-chevron-up"  # glyphicon glyphicon-chevron-up" # we are still using v2 icons
      sortDesc: "icon-chevron-down"  # glyphicon-chevron-down" # we are still using v2 icons
      active: "" # applied when column is sorted
      hover: "" # use custom css here - bootstrap class may not override it
      filterRow: "" # filter row class
      even: "" # odd row zebra striping
      odd: "" # even row zebra striping

    # call the tablesorter plugin and apply the uitheme widget
    @$el.find(".tablesorter").tablesorter(
      theme: "bootstrap"
      widthFixed: true
      headerTemplate: "{content} {icon}"
      # widget code contained in the jquery.tablesorter.widgets.js file
      # use the zebra stripe widget if you plan on hiding any rows (filter widget)
      widgets: [
        "uitheme"
        "zebra"
      ]
      widgetOptions:
        # using the default zebra striping class name, so it actually isn't included in the theme variable above
        # this is ONLY needed for bootstrap theming if you are using the filter widget, because rows are hidden
        zebra: [
          "even"
          "odd"
        ]
        # reset filters button
        filter_reset: ".reset"
    )

  onCandidateClicked: (e) ->
    id = $(e.target).closest('tr').data('candidate-id')
    if id
      url = "/account/profile/#{id}"
      app.router.navigate url, {trigger: true}
    else
      @openModalView new EmployerSignupView
