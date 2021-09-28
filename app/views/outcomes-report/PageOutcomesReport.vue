<script>
import { mapGetters, mapActions, mapState } from 'vuex'
import OutcomesReportResultComponent from './OutcomesReportResultComponent'
import { getOutcomesReportStats } from '../../core/api/outcomes-reports'

const orgKinds = {
  'administrative-region': { displayName: 'State', childKinds: ['school-district'] },  // TODO: localize
  'school-district': { displayName: 'District', childKinds: ['school'] },
  'school-admin': { displayName: 'Administrator', childKinds: ['teacher'] },
  'school-network': { displayName: 'Network', childKinds: ['school-subnetwork', 'school'] },
  'school-subnetwork': { displayName: 'Subnetwork', childKinds: ['school'] },
  school: { displayName: 'School', childKinds: ['teacher', 'classroom'] },
  teacher: { displayName: 'Teacher', childKinds: ['classroom', 'student'] },
  classroom: { displayName: 'Classroom', childKinds: ['student'] },
  student: { displayName: 'Student', childKinds: [] }
}

const parameterDefaults = () => ({
  includeSubOrgs: true,
  subOrgLimit: 10,  // TODO: different default limits for students vs. other types? Max value from number of sub orgs this org has?
  startDate: null,
  endDate: moment(new Date()).format('YYYY-MM-DD'),
  editing: me.isAdmin(),
})

export default {
  components: {
    OutcomesReportResultComponent,
  },

  data () {
    const obj = {
      kind: '',
      orgIdOrSlug: '',
      country: null,
      org: null,
      subOrgs: [],
      loading: true,
      earliestProgressDate: null,
    }
    const defaults = parameterDefaults()
    for (let key in defaults) {
      let value = this.$store.state.route.query[key]
      if (value === 'true') value = true
      if (value === 'false') value = false
      if (parseInt(value, 10).toString() === value) value = parseInt(value, 10)
      if (value === '' || typeof value === 'undefined')
        value = defaults[key]
      obj[key] = value
    }
    return obj
  },

  beforeRouteUpdate (to, from, next) {
    this.kind = to.params.kind || null  // TODO: needed, automatic, irrelevant?
    this.orgIdOrSlug = to.params.idOrSlug || null
    this.country = to.params.country || null
    this.org = null
    this.subOrgs = []
    this.editing = false
    next()
  },

  watch: {
    orgIdOrSlug (newSelectedOrg, lastSelectedOrg) {
      if (newSelectedOrg !== lastSelectedOrg) {  // TODO: is this diff check needed?
        this.addParametersToLocation()
        this.loadRequiredData()
      }
    },
    includeSubOrgs (newVal, lastVal) {
      if (newVal !== lastVal) {  // TODO: is this diff check needed?
        this.addParametersToLocation()
        this.loadRequiredData()
      }
    },
    startDate (newVal, lastVal) {
      if (newVal === '')
        return this.startDate = parameterDefaults().startDate
      if (newVal === null && lastVal !== null)
        null  // We do need to update, since we're nulling out the date
      else if (newVal === lastVal || !(new Date(newVal) >= new Date(this.earliestDate)) || !(new Date(newVal) <= new Date(this.latestDate)))
        return  // Return if invalid date
      this.addParametersToLocation()
      this.loadRequiredData()
    },
    endDate (newVal, lastVal) {
      if (newVal === '')
        return this.endDate = parameterDefaults().endDate
      if (newVal === lastVal)
        return  // No need to re-fetch, a null date value is the same as today's date
      if (newVal === null && lastVal !== null)
        null  // We do need to update, since we're nulling out the date
      else if (!(new Date(newVal) >= new Date(this.earliestDate)) || !(new Date(newVal) <= new Date(this.latestDate)))
        return  // Return if invalid date
      this.addParametersToLocation()
      this.loadRequiredData()
    },
    subOrgLimit (newVal, lastVal) {
      if (newVal !== lastVal) {  // TODO: is this diff check needed?
        this.addParametersToLocation()
      }
    },
    editing (newVal, lastVal) {
      if (newVal !== lastVal) {  // TODO: is this diff check needed?
        this.addParametersToLocation()
      }
    },
  },

  created () {
    this.kind = this.$route.params.kind || null
    this.orgIdOrSlug = this.$route.params.idOrSlug || null
    this.country = this.$route.params.country || null
    this.fetchCourses()
  },

  mounted () {

    // Scroll to the current hash, once everything in the browser is set up
    // TODO: Should this be a general thing we do in all top-level Vue views, like it is on CocoViews?
    let scrollTo = () => {
      let link = $(document.location.hash)
      if (link.length) {
        let scrollTo = link.offset().top - 100
        $('html, body').animate({ scrollTop: scrollTo }, 300)
      }
    }
    _.delay(scrollTo, 1000)
  },

  beforeDestroy() {
    
  },

  methods: {
    ...mapActions({
      fetchCourses: 'courses/fetch',
    }),

    //changeClanSelected (e) {
    //  let newSelectedClan = ''
    //  if (e.target.value === 'global') {
    //  newSelectedClan = ''
    //  } else {
    //  newSelectedClan = e.target.value
    //  }
    //
    //  const leagueURL = newSelectedClan ? `league/${newSelectedClan}` : 'league'
    //
    //  application.router.navigate(leagueURL, { trigger: true })
    //},

    async loadRequiredData () {
      if (!this.orgIdOrSlug) {
        // TODO: load the various orgs we could choose from...? Pick one...?
        this.loading = false
        return
      }
      this.loading = true
      // TODO: update the URL parameters according to this fetch
      // TODO: cache the results in case we query again for the same parameters
      // TODO: if we load again while one load is still in progress, abort the old one
      // TODO: if we go from loaded subOrgs true to false, don't need to re-fetch
      $('html, body').animate({ scrollTop: 0})
      await this.fetchOutcomesReportStats({ kind: this.kind, orgIdOrSlug: this.orgIdOrSlug, includeSubOrgs: this.includeSubOrgs, country: this.country, startDate: this.startDate, endDate: this.endDate })  // TODO: date range
      this.loading = false
    },

    // TODO: date range
    async fetchOutcomesReportStats ({kind, orgIdOrSlug, includeSubOrgs, country, startDate, endDate}) {
      console.log('gonna load stats for', kind, orgIdOrSlug, country)
      const stats = await getOutcomesReportStats(kind, orgIdOrSlug, { includeSubOrgs, country, startDate, endDate } )
      console.log(' ...', kind, orgIdOrSlug, country, 'got stats', stats)
      const orgs = stats[kind + 's']
      this.org = Object.freeze(orgs ? orgs[0] : null)
      console.log('   ... got our org', this.org)
      let subOrgs = []
      if (includeSubOrgs) {
        for (const childKind of orgKinds[kind].childKinds) {
          subOrgs = subOrgs.concat(stats[childKind + 's'] || [])
        }
        for (let [index, subOrg] of subOrgs.entries()) {
          subOrg.initiallyIncluded = Boolean(!subOrg.archived && index < this.subOrgLimit && subOrg.progress && subOrg.progress.programs)
        }
        console.log('    ... found suborgs', subOrgs, 'for child kinds', orgKinds[kind].childKinds)
      }
      this.subOrgs = Object.freeze(subOrgs)
    },

    kindName (kind) {
      return orgKinds[kind].name
    },

    onPrintButtonClicked (e) {
      window.print()
    },

    onEditButtonClicked (e) {
      this.editing = !this.editing
    },

    addParametersToLocation() {
      const nonDefaultParameters = {}
      const defaults = parameterDefaults()
      for (const key in defaults) {
        const value = this[key]
        if (value !== defaults[key]) {
          nonDefaultParameters[key] = value
        }
      }
      history.pushState({}, null, this.$route.path + '?' + Object.keys(nonDefaultParameters).map(key => {
        return encodeURIComponent(key) + '=' + encodeURIComponent(nonDefaultParameters[key])
      }).join('&'))
    },
  },

  computed: {
    ...mapGetters({
      
    }),

    ...mapState('courses', {
      coursesLoaded: 'loaded',
      courses: (state) => state.byId
    }),

    courseById () {
      return (courseId) => this.$store.state.courses.byId[courseId]
    },

    dateRangeDisplay () {
      const endDate = this.endDate || new Date()
      if (!this.startDate)
        return moment(endDate).format('MMM D, YYYY')
      return moment(this.startDate).format('MMM D, YYYY') + ' – ' + moment(endDate).format('MMM D, YYYY')
    },

    earliestDate () {
      if (this.startDate && this.earliestProgressDate)
        return this.earliestProgressDate
      if (!this.org || !this.org.progress || !this.org.progress.first || this.startDate)
        return '2013-02-28'  // First user creation
      // If we have fetched progress with no date filter, then we can remember when the first student played for when we do add a date filter
      this.earliestProgressDate = this.org.progress.first.slice(0, 10)
      return this.earliestProgressDate
    },

    latestDate () {
      return moment(new Date()).format('YYYY-MM-DD')
    },

    accountManager () {
      if (me.isAdmin() || /@codecombat\.com/i.test(me.get('email')))
        return { name: me.broadName(), email: me.get('email') }
      else
        return { email: 'schools@codecombat.com' }
    },

    childKind () {
      if (!this.kind) return null
      // TODO: filter out a kind if there's only one instance (one classroom for a teacher, maybe one teacher in a school)
      // TODO: filter out a kind if there are no instances (no subnetwork so go to schools)
      return orgKinds[this.kind].childKinds[0]
    },
  }
}
</script>


<template lang="pug">
main#page-outcomes-report
  #report-container
    img.header-art(src="/images/pages/admin/outcomes-report/arryn.png")

    .header
      div
        img.print-logo(src="/images/pages/base/logo.png")
      div
        //h4 Outcomes Report - {{kind}} {{orgIdOrSlug}}
        h4 Outcomes Report
        h5
          span= dateRangeDisplay
          label.edit-label.editing-only(v-if="editing" for="startDate") &nbsp; (edit)

    .org-results(v-if="org && !loading")
      outcomes-report-result-component(:org="org" v-bind:editing="editing")
      if includeSubOrgs
        outcomes-report-result-component.sub-org(v-for="subOrg, index in subOrgs" v-bind:index="index" v-bind:key="subOrg.kind + '-' + subOrg._id" v-bind:org="subOrg" v-bind:editing="editing" v-bind:isSubOrg="true")

    .loading-indicator(v-if="loading")
      h1= $t('common.loading')

    if org && org.insightsHtml
      .dont-break.block
        .rob-row
          .right-col
            h1 Insights
            // TODO: buffered
            //!= org.insightsHtml
            = org.insightsHtml

    .dont-break(v-if="!loading")
      img.anya(src="/images/pages/admin/outcomes-report/anya.png")
      .block.room-for-anya
        h1 Standards Coverage
        p.
          The full CodeCombat curriculum covers major programming standards in
          several widely-adopted frameworks, including those of the International
          Society for Technology in Education (ISTE), the Computer Science Teacher
          Association (CSTA), and the K-12 Computer Science Framework.

        p.
          At CodeCombat, we believe that students will be most prepared for both
          real-world computing jobs and further study of computer science by using
          real, typed code in full programming languages, so instead of using block-based
          visual programming languages for beginners, we teach Python and
          JavaScript – the same languages used widely today by companies ranging
          from Google to the New York Times.

      .bottom
        p Have questions or want more information? We'd be happy to help.
        p
          | Reach out to your Account Manager
          if accountManager.name
            span , #{accountManager.name},
          = " at "
          a(:href="'mailto:' + accountManager.email")= accountManager.email
          | .

    .clearfix

  form.menu.form-horizontal
    .print-btn.btn.btn-primary.btn-lg(@click="onPrintButtonClicked") {{ $t('courses.certificate_btn_print') }}
    .edit.btn.btn-primary.btn-lg(@click="onEditButtonClicked")
      if editing
        span Done Customizing
      else
        span Customize Report
    .edit-controls(v-if="editing")
      br
      .form-group
        label.control-label.col-xs-5(for="startDate")
          span  Start date
        .col-xs-7
          input#startDate.form-control(type="date" v-model="startDate" name="startDate" :min="earliestDate" :max="latestDate")
      .form-group
        label.control-label.col-xs-5(for="endDate")
          span  End date
        .col-xs-7
          input#endDate.form-control(type="date" v-model="endDate" name="endDate" :min="earliestDate" :max="latestDate")
      .form-group(v-if="childKind")
        label.control-label.col-xs-5(for="includeSubOrgs")
          //span  Include {{kindName(childKind)}}s
          span  Include #{childKind}s
        .col-xs-7
          input#includeSubOrgs.form-control(type="checkbox" v-model="includeSubOrgs" name="includeSubOrgs")
      .form-group(v-if="childKind && includeSubOrgs")
        label.control-label.col-xs-5(for="$store.state.query.subOrgLimit")
          //span  Max {{kindName(childKind)}}s
          span  Max #{childKind}s
        .col-xs-7
          input#subOrgLimit.form-control(type="number" v-model.number="subOrgLimit" name="subOrgLimit" min="1" step="1")
    .clearfix
</template>


<style lang="scss">
#page-outcomes-report {
  font-family: 'Open Sans', sans-serif;
  background: transparent url(/images/pages/play/portal-background.png);
  margin-bottom: -50px;
  padding: 1px 0 10px 0;

  #report-container {
    margin-top: 10px;
    padding-top: 0;
    box-shadow: 0px 0px 10px black;
    margin-left: auto;
    margin-right: auto;
    width: 8.5in;
    background: white;
  }

  @media print {
    margin-top: -75px;
    box-shadow: none;

    #report-container {
      margin-top: 0;
    }

    a[href]:after {
      // Remove the " (" attr(href) ")" that Bootstrap adds
      content: none !important;
    }

    .editing-only {
      display: none
    }
  }

  .menu {
    position: fixed;
    left: 15px;
    top: 80px;
    padding: 10px;
    box-shadow: 0px 0px 10px black;
    background: white;

    .edit-controls {
      min-width: 350px;
    }

    label {
      font-size: 14px;
      line-height: 1.428571429;
    }

    @media print {
      display: none;
    }
  }

  .editing {
    @media print {
      display: none;
    }
  }

  .edit-label {
    cursor: pointer;
    color: #0b63bc;

    @media print {
      display: none;
    }
  }

  .header-art {
    float: right;
    width: 2in;
    margin-top: 0.35in;
    margin-right: 0.4in;
    transform: scaleX(-1);
  }

  .header {
    height: 2.15in;
    padding-top: 0.1in;
    padding-left: 0.25in;
    padding-right: 0.25in;
    background-color: rgb(14, 76, 96);
    -webkit-print-color-adjust: exact !important;
    background: linear-gradient(rgb(14, 76, 96), rgb(14, 76, 96)) !important;

    .print-logo {
      margin: 0 0 0 0;
      width: 3.75in;
    }

    h4, h5, p {
      padding-left: 0.25in;
      bottom: 0px;
      color: white !important;

      span {
        color: white !important;
      }
    }

    h4 {
      font-size: 24pt;
      font-family: 'Arvo', serif;
    }

    h5 {
      font-family: 'Open Sans', sans-serif;
      font-size: 15pt;
      font-weight: 600;
    }

  }

  .loading-indicator {
    text-align: center;
    margin: 50px auto;
  }

  .block {
    margin-top: 0;
    margin-left: 0.5in;
    margin-right: 0.5in;

    h1, h2 {
      font-family: 'Open Sans', sans-serif;
      font-size: 22pt;
      font-weight: 100;
      margin-top: 0.5in;
      border-bottom: 1px solid #ccc;
      border-radius: 0px;
      margin-bottom: 0.1in;
    }
    h3, h4 {
      font-family: 'Open Sans', sans-serif;
      font-weight: 600;
    }
    h1 {
      font-size: 18pt;
      line-height: 18pt;
    }
    h2 {
      font-size: 14pt;
      line-height: 15pt;
    }
    h4 {
      font-size: 18pt;
      line-height: 18pt;
      font-weight: 600;
    }
    p {
      font-size: 14pt;
      line-height: 18pt;
    }
    .left-col {
      page-break-inside: avoid;
      float: left;
      width: 4in;
      margin-right: 1in;
    }
    .right-col {
      page-break-inside: avoid;
      float: left;
      width: 2.5in;
      font-size: 14pt;
      line-height: 18pt;
      ul {
        padding-left: 2ex;
      }
    }
    .row-row {
      page-break-inside: avoid;
    }
    .rob-row::after {
      page-break-inside: avoid;
      content: " ";
      display: table;
      clear: both;
    }
  }

  .dont-break {
    page-break-inside: avoid;
  }

  img.anya {
    margin-left: 0.5in;
    margin-top: 0.5in;
    float: left;
    width: 1.75in;
  }

  .room-for-anya {
    padding-top: .1in;
    margin-left: 2.5in;
  }

  .bottom {
    border-top: 2px solid black;
    padding-top: 0.1in;
    margin-top: 0.25in;
    padding-bottom: 0.25in;
    margin-left: 0.25in;
    margin-right: 0.25in;

    p {
      text-align: center;
      line-height: 15pt;
      font-weight: 600;
    }
  }
}
</style>

