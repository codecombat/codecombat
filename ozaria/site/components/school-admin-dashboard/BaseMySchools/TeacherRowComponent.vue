<script>
  import IconButtonWithTextTwilight from '../common/buttons/IconButtonWithTextTwilight'
  import User from 'app/models/User'

  export default {
    components: {
      IconButtonWithTextTwilight
    },

    props: {
      teacher: {
        type: Object,
        default: () => ({})
      },
      userStats: {
        type: Object,
        default: () => ({})
      }
    },

    computed: {
      teacherName () {
        return User.broadName(this.teacher)
      },
      teacherLastLogin () {
        const teacher = this.$props.teacher || {}
        const teacherActivity = teacher.activity || {}
        const loginActivity = teacherActivity.login || {}

        return loginActivity.last
      },
      licenseStats () {
        const teacherStats = this.teacher.stats || {}
        const licenseStats = teacherStats.licenses || {}
        const usageStats = licenseStats.usage || {}

        return {
          licensesUsed: usageStats.used || 0,
          licensesTotal: usageStats.total || 0,
          licensesUsedInActiveClassrooms: this.userStats.stats?.licenses?.appliedInActiveClassrooms || 0,
        }
      },
      displayStats () {
        const teacherStats = this.teacher.stats || {}
        return [
          {
            value: this.licenseStats.licensesTotal,
            label: 'Licenses'
          },
          {
            value: this.userStats.stats?.students?.totalInActiveClassrooms || 0,
            label: 'Students Enrolled',
            subLabel: 'active classes'
          },
          {
            value: this.licenseStats.licensesUsedInActiveClassrooms,
            label: 'Licenses in use',
            subLabel: 'active classes'
          }
        ]
      }
    },
    methods: {
      trackEvent (eventName) {
        if (eventName) {
          window.tracker?.trackEvent(eventName, { category: 'SchoolAdmin' })
        }
      }
    }
  }
</script>

<template>
  <div class="teacher-row-container">
    <li class="teacher-row">
      <div class="teacher-name">
        <span>{{ teacherName }}</span>
      </div>
      <div class="vertical-line" />
      <div class="teacher-info">
        <div class="teacher-email">
          <img src="/images/ozaria/school-admins/dashboard/svg_icons/IconEnvelope.svg">
          <span class="overflow-ellipsis"> {{ teacher.email }} </span>
        </div>
        <div class="last-login">
          <img src="/images/ozaria/school-admins/dashboard/svg_icons/IconLastLogin.svg">
          <span class="overflow-ellipsis">{{ $t('school_administrator.last_login') }}: {{ teacherLastLogin | moment("MM/DD/YY") }}</span>
        </div>
      </div>
      <div class="vertical-line" />
      <ul class="stats">
        <li
          v-for="stats in displayStats"
          :key="stats.label"
        >
          <span class="stats-value">{{ stats.value }} </span>
          <span class="stats-label">{{ stats.label }} </span>
          <span v-if="stats.subLabel" class="stats-sub-label">{{ stats.subLabel }} </span>
        </li>
      </ul>
    </li>
    <div class="teacher-buttons">
      <icon-button-with-text-twilight
        text="View Classes"
        iconUrl="/images/ozaria/school-admins/dashboard/svg_icons/IconClasses_Moon.svg"
        :link="`/school-administrator/teacher/${teacher._id}`"
        @click="trackEvent('My Schools: View Classes Clicked')"
      />
      <icon-button-with-text-twilight
        text="License Details"
        iconUrl='/images/ozaria/school-admins/dashboard/svg_icons/IconLicenses_Moon.svg'
        :link="`/school-administrator/teacher/${teacher._id}/licenses`"
        @click="trackEvent('My Schools: License Details Clicked')"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

.teacher-row-container {
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: center;
  background: #FFFFFF;
  border: 0.5px solid #D8D8D8;
  box-shadow: 0px 4px 4px rgba(0, 0, 0, 0.06);
  height: 100px;
}

.teacher-row {
  width: 85%;
  height: 100%;
  display: flex;
  flex-direction: row;
  align-items: center;
  padding: 15px;
  justify-content: space-around;
}

.vertical-line {
  background: linear-gradient(59.36deg, #D1B147 -5.07%, #D1B147 16.64%, #F7D047 93.04%, #F7D047 103.46%);
  width: 3px;
  height: 65px;
}

.teacher-name {
  width: 20%;
  @include font-h-4-nav-uppercase-black;
  line-height: 24px;
  color: $color-tertiary-brand;
  text-align: left;
}

.teacher-info {
  width: 20%;
  display: flex;
  flex-direction: column;

  justify-content: center;
  @include font-p-4-paragraph-smallest-gray;
  color: $color-tertiary-brand;

  .teacher-email {
    margin-bottom: 7px;
  }
  img {
    margin-right: 5px;
  }
}

.teacher-name, .teacher-email, .last-login {
  display: flex;
  flex-direction: row;
}

.overflow-ellipsis {
  overflow: hidden;
  white-space: nowrap;
  text-overflow: ellipsis;
}

.stats {
  width: 40%;

  display: flex;
  flex-direction: row;

  align-items: flex-start;
  justify-content: space-around;

  list-style: none;

  padding: 0;

  li {
    margin: 0px 10px;
    span {
      display: block;
    }
  }
}

.stats-value {
  @include font-h-2-subtitle-black;
  color: $color-tertiary-brand;
  text-align: center;
}

.stats-label {
  @include font-p-3-small-button-text-black;
  color: $color-tertiary-brand;
  text-align: center;
  font-weight: 500;
}

.stats-sub-label {
  font-family: 'Roboto Mono', monospace;
  font-style: normal;
  font-weight: normal;
  font-size: 12px;
  line-height: 18px;
  text-align: center;
  letter-spacing: 0.266667px;
  color: #3EA1BF;
}

.teacher-buttons {
  width: 15%;
  height: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: space-evenly;
  border-left: 0.5px solid #D8D8D8;
  button {
    width: 172px;
  }
}
</style>
