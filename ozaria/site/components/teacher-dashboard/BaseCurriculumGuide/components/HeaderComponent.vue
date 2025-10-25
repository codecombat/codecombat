<template>
  <div class="header">
    <div class="header-icon">
      <img src="/images/ozaria/teachers/dashboard/svg_icons/IconCurriculumGuide.svg">
      <h2>{{ $t('teacher_dashboard.curriculum_guide') }}</h2>
    </div>
    <div
      class="header-right"
    >
      <CodeLanguageSelector
        v-if="showLanguage"
        :course-name="courseName"
        @change-language="onChangeLanguage"
      />
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'
import CodeLanguageSelector from '../../common/CodeLanguageSelector'
export default {
  name: 'HeaderComponent',
  components: {
    CodeLanguageSelector,
  },
  computed: {
    ...mapGetters({
      getTrackCategory: 'teacherDashboard/getTrackCategory',
      getCurrentCourse: 'baseCurriculumGuide/getCurrentCourse',
    }),
    courseName () {
      return this.getCurrentCourse?.name || ''
    },
    showLanguage () {
      return !['AI HackStack'].includes(this.courseName)
    },
  },
  methods: {
    onChangeLanguage () {
      window.tracker?.trackEvent('Curriculum Guide: Language Changed from dropdown', { category: this.getTrackCategory, label: this.courseName })
    },
  },
}
</script>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

.header {
  height: 60px;

  background-color: #f2f2f2;
  border: 1px solid #d8d8d8;
  /* Drop shadow bottom ref: https://css-tricks.com/snippets/css/css-box-shadow/ */
  -webkit-box-shadow: 0 8px 6px -6px #D2D2D2;
  -moz-box-shadow: 0 8px 6px -6px #D2D2D2;
  box-shadow: 0 8px 6px -6px #D2D2D2;

  display: flex;
  flex-direction: row;
  justify-content: space-between;

  .header-icon {
    display: flex;
    flex-direction: row;
    align-items: center;

    img {
      margin-left: 25px;
      margin-right: 10px;
    }
  }

  h2 {
    @include font-h-2-subtitle-white-24;
    color: black;
    line-height: 28px;
    letter-spacing: 0.56px;
  }

  .header-right {
    display: flex;
    justify-content: center;
    align-items: center;
    margin-right: 12px;
  }

  ::v-deep .code-language-dropdown {
    select {
      background: $twilight;
      border: 1.5px solid #355EA0;
      border-radius: 4px;
      color: $moon;
      width: 150px;
      padding: 8px 5px;
      font-family: Work Sans;
      font-style: normal;
      font-weight: 600;
      font-size: 14px;
      line-height: 20px;
    }

    .select-language {
      font-family: Work Sans;
      font-weight: 600;
      font-size: 12px;
      line-height: 16px;
      color: #545B64;
      padding: 8px;
    }
  }

  .close-btn {
    cursor: pointer;
    margin-left: 30px;
    padding: 10px;
  }
}
</style>