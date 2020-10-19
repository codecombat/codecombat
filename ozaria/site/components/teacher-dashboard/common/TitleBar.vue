<script>
  import PrimaryButton from '../common/buttons/PrimaryButton'
  import ButtonCurriculumGuide from '../common/ButtonCurriculumGuide'
  import LicensesComponent from '../common/LicensesComponent'
  import NavSelectUnit from '../common/NavSelectUnit'
  import ClassInfoRow from './ClassInfoRow'
  import moment from 'moment'

  import { mapActions } from 'vuex'

  export default {
    components: {
      'primary-button': PrimaryButton,
      'button-curriculum-guide': ButtonCurriculumGuide,
      'licenses-component': LicensesComponent,
      'nav-select-unit': NavSelectUnit,
      'class-info-row': ClassInfoRow
    },

    props: {
      title: {
        type: String,
        required: true
      },
      showClassInfo: {
        type: Boolean,
        default: false
      },
      classroom: {
        type: Object,
        default: () => {}
      },
      selectedCourseId: {
        type: String,
        default: ''
      },
      courses: {
        type: Array,
        default: () => []
      },
      allClassesPage: {
        type: Boolean,
        default: false
      }
    },

    computed: {
      classroomCreationDate () {
        if ((this.classroom || {})._id) {
          return moment(parseInt(this.classroom._id.substring(0, 8), 16) * 1000).format('ll')
        } else {
          return ''
        }
      },
      classroomLanguage () {
        return (this.classroom.aceConfig || {}).language
      },
      classroomStudentsLength () {
        return (this.classroom.members || []).length
      }
    },

    methods: {
      ...mapActions({
        toggleCurriculumGuide: 'baseCurriculumGuide/toggleCurriculumGuide'
      }),

      clickNewClass () {
        window.tracker?.trackEvent('Add New Class Clicked', { category: 'Teachers', label: this.$route.path })
        this.$emit('newClass')
      },

      clickCurriculumGuide () {
        window.tracker?.trackEvent('Curriculum Guide Clicked', { category: 'Teachers', label: this.$route.path })
        this.toggleCurriculumGuide()
      }
    }
  }
</script>

<template>
  <div class="teacher-title-bar">
    <div class="sub-nav">
      <h1>{{ title }}</h1>
      <class-info-row
        v-if="showClassInfo"
        class="class-info-row"
        :language="classroomLanguage"
        :num-students="classroomStudentsLength"
        :date-created="classroomCreationDate"
      />
    </div>
    <div class="sub-nav">
      <licenses-component class="btn-margins-height" />
      <nav-select-unit
        v-if="showClassInfo"
        class="btn-margins-height"
        :courses="courses"
        :selected-course-id="selectedCourseId"
        @change-course=" (courseId) => $emit('change-course', courseId)"
      />

      <div style="display: flex;">
        <primary-button
          v-if="!showClassInfo"
          id="new-class-btn-shepherd"
          class="btn-title-padding btn-margins-height"
          @click="clickNewClass"
        >
          Add New Class
        </primary-button>
        <button-curriculum-guide
          id="curriculum-guide-btn-shepherd"
          class="btn-margins-height"

          @click="clickCurriculumGuide"
        />
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

.btn-title-padding {
  padding: 8px 22px;
}

.btn-margins-height {
  margin: 0 12.5px;
}

.sub-nav {
  display: flex;
  flex-direction: row;
  align-items: center;

  &:last-child {
    margin-right: -12.5px;
  }

  &>h1:first-child {
    margin-right: 4.5px;
  }

  @media (max-width: 1280px) {
    .class-info-row {
      display: none;
    }

    h1 {
      max-width: 600px
    }
  }
}

.teacher-title-bar {
  height: 60px;
  background-color: white;
  min-width: 1260px;

  display: flex;
  flex-direction: row;
  justify-content: space-between;
  align-items: center;

  padding-left: 30px;
  padding-right: 30px;

  position: relative;
  z-index: 11;

  /* Drop shadow bottom ref: https://css-tricks.com/snippets/css/css-box-shadow/ */
  -webkit-box-shadow: 0 8px 6px -6px #D2D2D2;
    -moz-box-shadow: 0 8px 6px -6px #D2D2D2;
        box-shadow: 0 8px 6px -6px #D2D2D2;
}

h1 {
  @include font-h-2-subtitle-twilight;
  max-width: 290px;
  overflow-y: hidden;
  white-space: nowrap;
  text-overflow: ellipsis;
}

</style>
