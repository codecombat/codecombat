View = require 'views/kinds/RootView'
template = require 'templates/employers'
app = require 'application'
User = require 'models/User'
UserRemark = require 'models/UserRemark'
{me} = require 'lib/auth'
CocoCollection = require 'collections/CocoCollection'
EmployerSignupView = require 'views/modal/employer_signup_modal'

class CandidatesCollection extends CocoCollection
  url: '/db/user/x/candidates'
  model: User

class UserRemarksCollection extends CocoCollection
  url: '/db/user.remark?project=contact,contactName,user'
  model: UserRemark

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

  afterInsert: ->
    super()
    _.delay @checkForEmployerSignupHash, 500

  getRenderData: ->
    ctx = super()
    ctx.isEmployer = @isEmployer()
    ctx.candidates = _.sortBy @candidates.models, (c) -> c.get('jobProfile').updated
    ctx.activeCandidates = _.filter ctx.candidates, (c) -> c.get('jobProfile').active
    ctx.inactiveCandidates = _.reject ctx.candidates, (c) -> c.get('jobProfile').active
    ctx.featuredCandidates = _.filter ctx.activeCandidates, (c) -> c.get('jobProfileApproved')
    ctx.otherCandidates = _.reject ctx.activeCandidates, (c) -> c.get('jobProfileApproved')
    ctx.remarks = {}
    ctx.remarks[remark.get('user')] = remark for remark in @remarks.models
    ctx.moment = moment
    ctx._ = _
    ctx

  isEmployer: ->
    userPermissions = me.get('permissions') ? []
    _.contains userPermissions, "employer"

  getCandidates: ->
    @candidates = new CandidatesCollection()
    @candidates.fetch()
    @remarks = new UserRemarksCollection()
    @remarks.fetch()
    # Re-render when we have fetched them, but don't wait and show a progress bar while loading.
    @listenToOnce @candidates, 'all', @renderCandidatesAndSetupScrolling
    @listenToOnce @remarks, 'all', @renderCandidatesAndSetupScrolling

  renderCandidatesAndSetupScrolling: =>
    @render()
    $(".nano").nanoScroller()
    if window.history?.state?.lastViewedCandidateID
      $(".nano").nanoScroller({scrollTo:$("#" + window.history.state.lastViewedCandidateID)})
    else if window.location.hash.length is 25
      $(".nano").nanoScroller({scrollTo:$(window.location.hash)})

  checkForEmployerSignupHash: =>
    if window.location.hash is "#employerSignupLoggingIn" and not ("employer" in me.get("permissions"))
      @openModalView application.router.getView("modal/employer_signup","_modal")
      window.location.hash = ""

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


    # e = exact text from cell
    # n = normalized value returned by the column parser
    # f = search filter input value
    # i = column index
    # $r = ???
    filterSelectExactMatch = (e, n, f, i, $r) -> e is f

    # call the tablesorter plugin and apply the uitheme widget
    @$el.find(".tablesorter").tablesorter
      theme: "bootstrap"
      widthFixed: true
      headerTemplate: "{content} {icon}"
      textSorter:
        6: (a, b, direction, column, table) ->
          days = []
          for s in [a, b]
            n = parseInt s
            n = 0 unless _.isNumber n
            n = 1 if /^a/.test s
            for [duration, factor] in [
              [/second/i, 1 / (86400 * 1000)]
              [/minute/i, 1 / 1440]
              [/hour/i, 1 / 24]
              [/week/i, 7]
              [/month/i, 30.42]
              [/year/i, 365.2425]
            ]
              if duration.test s
                n *= factor
                break
            if /^in /i.test s
              n *= -1
            days.push n
          days[0] - days[1]
      sortList: if @isEmployer() or me.isAdmin() then [[6, 0]] else [[0, 1]]
      # widget code contained in the jquery.tablesorter.widgets.js file
      # use the zebra stripe widget if you plan on hiding any rows (filter widget)
      widgets: ["uitheme", "zebra", "filter"]
      widgetOptions:
        # using the default zebra striping class name, so it actually isn't included in the theme variable above
        # this is ONLY needed for bootstrap theming if you are using the filter widget, because rows are hidden
        zebra: ["even", "odd"]

        # extra css class applied to the table row containing the filters & the inputs within that row
        filter_cssFilter: ""

        # If there are child rows in the table (rows with class name from "cssChildRow" option)
        # and this option is true and a match is found anywhere in the child row, then it will make that row
        # visible; default is false
        filter_childRows: false

        # if true, filters are collapsed initially, but can be revealed by hovering over the grey bar immediately
        # below the header row. Additionally, tabbing through the document will open the filter row when an input gets focus
        filter_hideFilters: false

        # Set this option to false to make the searches case sensitive
        filter_ignoreCase: true

        # jQuery selector string of an element used to reset the filters
        filter_reset: ".reset"

        # Use the $.tablesorter.storage utility to save the most recent filters
        filter_saveFilters: true

        # Delay in milliseconds before the filter widget starts searching; This option prevents searching for
        # every character while typing and should make searching large tables faster.
        filter_searchDelay: 150

        # Set this option to true to use the filter to find text from the start of the column
        # So typing in "a" will find "albert" but not "frank", both have a's; default is false
        filter_startsWith: false

        filter_functions:
          2:
            "Full-time": filterSelectExactMatch
            "Part-time": filterSelectExactMatch
            "Contracting": filterSelectExactMatch
            "Remote": filterSelectExactMatch
            "Internship": filterSelectExactMatch
          5:
            "0-1": (e, n, f, i, $r) -> n <= 1
            "2-5": (e, n, f, i, $r) -> 2 <= n <= 5
            "6+": (e, n, f, i, $r) -> 6 <= n
          6:
            "Last day": (e, n, f, i, $r) ->
              days = parseFloat $($r.find('td')[i]).data('profile-age')
              days <= 1
            "Last week": (e, n, f, i, $r) ->
              days = parseFloat $($r.find('td')[i]).data('profile-age')
              days <= 7
            "Last 4 weeks": (e, n, f, i, $r) ->
              days = parseFloat $($r.find('td')[i]).data('profile-age')
              days <= 28
          8:
            "✓": filterSelectExactMatch
            "✗": filterSelectExactMatch

  onCandidateClicked: (e) ->
    id = $(e.target).closest('tr').data('candidate-id')
    if id
      if window.history
        oldState = _.cloneDeep window.history.state ? {}
        oldState["lastViewedCandidateID"] = id
        window.history.replaceState(oldState,"")
      else
        window.location.hash = id
      url = "/account/profile/#{id}"
      window.open url,"_blank"
    else
      @openModalView new EmployerSignupView
