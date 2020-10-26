<script>
  import IconButton from '../common/buttons/IconButton'
  import { mapGetters } from 'vuex'

  export default {
    components: {
      'icon-button': IconButton
    },
    props: {
      title: {
        type: String,
        default: ''
      },
      courseName: {
        type: String,
        default: ''
      },
      exemplarProjectUrl: {
        type: String,
        default: ''
      },
      exemplarCodeUrl: {
        type: String,
        default: ''
      },
      projectRubricUrl: {
        type: String,
        default: ''
      }
    },
    computed: {
      ...mapGetters({
        getTrackCategory: 'teacherDashboard/getTrackCategory'
      })
    },
    methods: {
      trackEvent (eventName) {
        if (eventName) {
          window.tracker?.trackEvent(eventName, { category: this.getTrackCategory, label: this.courseName })
        }
      }
    }
  }
</script>

<template>
  <div class="capstone-project-title-bar">
    <div class="sub-nav">
      <span class="capstone-title"> {{ title }} </span>
      <span class="capstone-sub-title"> {{ $t('teacher_dashboard.capstone_proj_for', { courseName }) }} </span>
    </div>
    <div class="sub-nav">
      <div class="exemplar-div">
        <span class="text-margin"> {{ $t('teacher_dashboard.exemplar_project') }} </span>
        <icon-button
          v-tooltip.top="{
            content: `Annotated solution code for the Exemplar Project`,
            classes: 'dark-teacher-dashboard'
          }"

          icon-name="IconExemplarCode"
          :link="exemplarCodeUrl"
          @click.native="trackEvent('Student Projects: View Annotated Code Clicked')"
        />
        <icon-button
          v-tooltip.top="{
            content: `View Exemplar Project`,
            classes: 'dark-teacher-dashboard'
          }"
          icon-name="IconViewProject_Black"
          icon-style="margin-right: -8px; margin-top: -3px;"
          :link="exemplarProjectUrl"
          @click.native="trackEvent('Student Projects: View Exemplar Project Clicked')"
        />
      </div>
      <div class="project-rubric">
        <span class="text-margin">{{ $t('teacher_dashboard.project_rubric') }}</span>
        <icon-button
          v-tooltip.top="{
            content: `View Project Rubric`,
            classes: 'dark-teacher-dashboard'
          }"
          icon-name="IconRubric"
          icon-style="margin-right: -3px;"
          :link="projectRubricUrl"
          @click.native="trackEvent('Student Projects: View Project Rubric Clicked')"
        />
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

.sub-nav {
  display: flex;
  flex-direction: row;
  align-items: center;
}

.capstone-project-title-bar {
  background: #545B64;
  height: 50px;

  display: flex;
  flex-direction: row;
  justify-content: space-between;
  align-items: center;

  padding-left: 30px;
  padding-right: 30px;

  /* Drop shadow bottom ref: https://css-tricks.com/snippets/css/css-box-shadow/ */
  -webkit-box-shadow: 0px 2px 4px rgba(0, 0, 0, 0.12);
    -moz-box-shadow: 0px 2px 4px rgba(0, 0, 0, 0.12);
        box-shadow: 0px 2px 4px rgba(0, 0, 0, 0.12);
}

.capstone-title {
  @include font-h-4-navbar-uppercase-white;
}

.capstone-sub-title {
  @include font-p-3-paragraph-small-white;
  margin-left: 10px;
}

.exemplar-div {
  @include font-p-3-small-button-text-black;
  color: $moon;
  display: flex;
  justify-content: center;
  align-items: center;
}

.project-rubric {
  @include font-p-3-small-button-text-black;
  color: $dusk;
  margin-left: 10px;
  display: flex;
  justify-content: center;
  align-items: center;
}

.text-margin {
  margin: 5px;
}

</style>

<style lang="scss">
@import "ozaria/site/styles/common/variables.scss";
.project-rubric button {
  background-color: $dusk;
  &:hover {
    background-color: $dusk-dark;
    transition: background-color .35s;
  }
}
</style>
