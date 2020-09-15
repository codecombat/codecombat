<script>
  import ButtonCurriculumGuide from '../../teacher-dashboard/common/ButtonCurriculumGuide'
  import NavSelectUnit from '../../teacher-dashboard/common/NavSelectUnit'
  import BreadcrumbComponent from 'app/views/common/BreadcrumbComponent'

  import { mapActions } from 'vuex'

  export default {
    components: {
      'button-curriculum-guide': ButtonCurriculumGuide,
      'nav-select-unit': NavSelectUnit,
      BreadcrumbComponent
    },

    props: {
      title: {
        type: String,
        default: ''
      },
      breadcrumbList: {
        type: Array,
        default: () => []
      },
      showBreadCrumbs: {
        type: Boolean,
        default: false
      },
      showCourseDropdown: {
        type: Boolean,
        default: false
      },
      selectedCourseId: {
        type: String,
        default: ''
      },
      courses: {
        type: Array,
        default: () => []
      }
    },

    methods: {
      ...mapActions({
        toggleCurriculumGuide: 'baseCurriculumGuide/toggleCurriculumGuide'
      }),

      clickBreadCrumbsLink (text) {
        if (text.length > 0) {
          const textArr = text.split(" ")
          const eventName = textArr[textArr.length - 1] // Take last word of the breadcrumbs' text
          window.tracker?.trackEvent(`BreadCrumbs: ${eventName} Clicked`, { category: 'SchoolAdmin', label: this.$route.path })
        }
      },

      clickCurriculumGuide () {
        window.tracker?.trackEvent('Curriculum Guide Clicked', { category: 'SchoolAdmin', label: this.$route.path })
        this.toggleCurriculumGuide()
      }
    }
  }
</script>

<template>
  <div class="school-admin-title-bar">
    <div class="sub-nav">
      <h1 v-if="!showBreadCrumbs && title"> {{ title }} </h1>
      <breadcrumb-component
        v-else-if="showBreadCrumbs && breadcrumbList.length > 0"
        :links="breadcrumbList"
        @click="(text) => clickBreadCrumbsLink(text)"
      />
    </div>
    <div class="sub-nav">
      <nav-select-unit
        v-if="showCourseDropdown"
        class="btn-margins-height"
        :courses="courses"
        :selected-course-id="selectedCourseId"
        @change-course=" (courseId) => $emit('change-course', courseId)"
      />
      <div style="display: flex;">
        <button-curriculum-guide
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

.school-admin-title-bar {
  height: 60px;
  background-color: white;
  min-width: 1260px;

  display: flex;
  flex-direction: row;
  justify-content: space-between;
  align-items: center;

  padding-left: 30px;
  padding-right: 30px;

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
