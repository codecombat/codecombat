
<script>
  import LicenseCard from 'ozaria/site/components/teacher-dashboard/BaseTeacherLicenses/common/LicenseCard'
  import PrimaryButton from 'ozaria/site/components/teacher-dashboard/common/buttons/PrimaryButton'
  import IconHelp from 'ozaria/site/components/teacher-dashboard/common/icons/IconHelp'
  import ButtonResourceIcon from 'ozaria/site/components/teacher-dashboard/BaseResourceHub/components/ButtonResourceIcon'
  import { mapGetters } from 'vuex'
  import utils from 'app/core/utils'

  export default {
    components: {
      LicenseCard,
      PrimaryButton,
      ButtonResourceIcon,
      IconHelp
    },
    props: {
      activeLicenses: {
        type: Array,
        required: true,
        default: () => []
      },
      expiredLicenses: {
        type: Array,
        required: true,
        default: () => []
      },
      teacherId: {
        type: String,
        required: true
      }
    },
    computed: {
      ...mapGetters({
        getUserById: 'users/getUserById',
        allAdministratedClassrooms: 'schoolAdminDashboard/getAllAdministratedClassrooms'
      }),
      howToLicensesResourceData () {
        return {
          icon: 'Slides',
          label: 'Admin Licenses How-To Guide',
          link: 'https://docs.google.com/presentation/d/15qF8nezX-7agTT_WOgG5o0sLhL_fpzFNdtP7nD-KrDQ/edit?usp=sharing',
        }
      },
      classroomsWithPaidCourses () {
        // classrooms that have more than 1 course or if the first course isnt the free course (might not be needed but keeping it same as coco)
        return (this.allAdministratedClassrooms || []).filter((c) => c?.courses?.length > 1 || (c?.courses?.length === 1 && c?.courses[0]._id !== utils.courseIDs.CHAPTER_ONE))
      },
      // Count total students in classrooms (both active and archived) created between
      // July 1-June 30 as the cut off for each school year (e.g. July 1, 2019-June 30, 2020)
      membershipHistory () { // similar to logic in coco
        const history = {}
        this.allAdministratedClassrooms.forEach(({ _id, members, deletedMembers }) => {
          const allMembers = [...members, ...deletedMembers]
          if (allMembers?.length > 0) {
            const creationDate = moment(this.dateFromObjectId(_id))
            const year = this.yearRangeForClassroom(creationDate)
            if (!history[year]) {
              history[year] = new Set(allMembers)
            } else {
              const yearSet = history[year]
              allMembers.forEach(yearSet.add, yearSet)
            }
          }
        })
        const sortedHistory = {}
        // sort by year in reverse order
        Object.keys(history).sort().reverse().forEach((key) => {
          sortedHistory[key] = history[key];
        })
        return sortedHistory
      },
      showMembershipHistory () {
        return Object.keys(this.membershipHistory).length > 0
      }
    },
    methods: {
      trackEvent (eventName) {
        if (eventName) {
          window.tracker?.trackEvent(eventName, { category: 'SchoolAdmin' })
        }
      },
      dateFromObjectId (objectId) {
        return new Date(parseInt(objectId.substring(0, 8), 16) * 1000)
      },
      // TODO Can be moved to some utility file or Classroom static methods to make this re-usable
      // Taking July 1-June 30 as the range for each school year (e.g. July 1, 2019-June 30, 2020)
      yearRangeForClassroom (momentDate) {
        const year = momentDate.year()
        const shortYear = year - 2000
        const start = `${year}-06-30` // One day earlier to ease comparison
        const end = `${year + 1}-07-01` // One day later to ease comparison

        let displayStartDate = ''
        let displayEndDate = ''
        if (moment(momentDate).isBetween(start, end)) {
          displayStartDate = `7/1/${shortYear}`
          displayEndDate = `6/30/${shortYear + 1}`
        } else if (moment(momentDate).isBefore(start)) {
          displayStartDate = `7/1/${shortYear - 1}`
          displayEndDate = `6/30/${shortYear}`
        } else if (moment(momentDate).isAfter(end)) {
          displayStartDate = `7/1/${shortYear + 1}`
          displayEndDate = `6/30/${shortYear + 2}`
        }

        return `${displayStartDate} - ${displayEndDate}`
      }
    }
  }
</script>

<template>
  <div class="licenses-page">
    <div class="side-bar">
      <div class="classroom-membership-history" v-if="showMembershipHistory">
        <span class="side-bar-title"> Classroom Membership History </span>
        <icon-help
          v-tooltip.bottom="{
            content: `<p><b>The Classroom Membership History</b> displays the total number of unique students who were enrolled across all classrooms.</p>
                      <p><b>Remember:</b> Classes may be archived and licenses may be reused throughout the school year, so these numbers represent how many students truly participated in the program.</p>`,
            classes: 'teacher-dashboard-tooltip'
          }"
        />
        <ul class="membership-history-list">
          <li
            v-for="(members, year) in membershipHistory"
            :key="year"
          >
            <b> {{ year }}: </b> {{ members.size }} {{ members.size > 1 ? "students" : "student" }}
          </li>
        </ul>
      </div>
      <div class="help-div">
        <span class="side-bar-title"> {{ $t("common.help") }} </span>
        <div class="side-bar-text">
          Have license related questions?
        </div>
        <button-resource-icon
          class="pdf-btn"
          :icon="howToLicensesResourceData.icon"
          :label="howToLicensesResourceData.label"
          :link="howToLicensesResourceData.link"
          track-category="SchoolAdmin"
          from="Admin Licenses"
        />
        <div class="side-bar-text">
          {{ $t('teacher_dashboard.need_more_licenses') }}
        </div>
        <primary-button
          class="get-licenses-btn"
          @click="$emit('getLicenses')"
          @click.native="trackEvent('Admin Licenses: Get More Licenses Clicked')"
        >
          {{ $t("courses.get_enrollments") }}
        </primary-button>
      </div>
    </div>
    <div class="license-cards">
      <div class="active-licenses row" v-if="activeLicenses.length > 0">
        <span class="col-md-12"> {{ $t("teacher_licenses.active_licenses") }} </span>
        <license-card
          v-for="license in activeLicenses"
          :key="license._id"
          class="card col-md-2"
          :disable-apply-licenses="true"
          :total="license.maxRedeemers"
          :used="(license.redeemers || []).length"
          :start-date="license.startDate"
          :end-date="license.endDate"
          :owner="getUserById(license.creator)"
          :teacher-id="teacherId"
          @share="$emit('share', license)"
        />
      </div>
      <div class="expired-licenses row" v-if="expiredLicenses.length > 0">
        <span class="col-md-12"> {{ $t("teacher_licenses.expired_licenses") }} </span>
        <license-card
          v-for="license in expiredLicenses"
          :key="license._id"
          class="card col-md-2"
          :disable-apply-licenses="true"
          :total="license.maxRedeemers"
          :used="(license.redeemers || []).length"
          :start-date="license.startDate"
          :end-date="license.endDate"
          :owner="getUserById(license.creator)"
          :teacher-id="teacherId"
          :expired="true"
        />
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

.licenses-page {
  display: flex;
}

.side-bar {
  background: #F2F2F2;
  box-shadow: -1px 0px 1px rgba(0, 0, 0, 0.06), 3px 0px 8px rgba(0, 0, 0, 0.15);
  width: 21%;
  padding: 30px;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  justify-content: flex-start;
  margin-top: 3px;
}

.side-bar-title {
  @include font-h-4-nav-uppercase-black;
}

.side-bar-text {
  @include font-p-3-paragraph-small-gray;
  color: $pitch;
  margin: 15px 0px;
}

.classroom-membership-history {
  margin-bottom: 40px;
}

.membership-history-list {
  padding: 0;
  list-style: none;
  margin-top: 20px;
  font-family: Work Sans;
  font-style: normal;
  font-size: 14px;
  line-height: 20px;
  color: #545B64;
}

.help-div {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  justify-content: flex-start;
}

.pdf-btn {
  align-self: center;
  margin: 10px 0px;
}

.get-licenses-btn {
  width: 100%;
  max-width: 220px;
  height: 50px;
  margin: 20px 0px;
}

.license-cards {
  width: 79%;
  padding: 30px 0px;
}

.active-licenses, .expired-licenses {
  margin: 0px 20px 30px 20px;
  span {
    @include font-h-5-button-text-black;
    color: $twilight;
    text-align: left;
  }
}
.card  {
  margin: 10px;
}
</style>
