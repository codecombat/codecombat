<script>
  import PrimaryButton from '../common/PrimaryButton'
  import ButtonCurriculumGuide from '../common/ButtonCurriculumGuide'
  import LicensesComponent from '../common/LicensesComponent'
  import NavSelectUnit from '../common/NavSelectUnit'

  export default {
    components: {
      'primary-button': PrimaryButton,
      'button-curriculum-guide': ButtonCurriculumGuide,
      'licenses-component': LicensesComponent,
      'nav-select-unit': NavSelectUnit
    },
    props: {
      title: {
        type: String,
        required: true
      },
      showClassInfo: {
        type: Boolean,
        default: false
      }
    }
  }
</script>

<template>
  <div class="teacher-title-bar">
    <div class="sub-nav">
      <h1>{{ title }}</h1>
      <div v-if="showClassInfo" class="stats-tab">
        <img src="/images/ozaria/teachers/dashboard/png_icons/Python.png" />
        <span>Python</span>
      </div>
      <div v-if="showClassInfo" class="stats-tab">
        <img src="/images/ozaria/teachers/dashboard/png_icons/MultipleUsers.png" />
        <span>13 Students</span>
      </div>
      <div v-if="showClassInfo" class="stats-tab">
        <img src="/images/ozaria/teachers/dashboard/svg_icons/calendar.svg" />
        <span>August 15, 2019</span>
      </div>
    </div>
    <div class="sub-nav">
      <licenses-component class="btn-margins-height" />
      <nav-select-unit v-if="showClassInfo" class="btn-margins-height" />
      <primary-button v-if="!showClassInfo" class="btn-title-padding btn-margins-height">Add New Class</primary-button>
      <button-curriculum-guide class="btn-margins-height" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

.stats-tab {
  img {
    height: 15px;
    width: auto;
    transform: translateY(-1px);
  }

  margin: 0 7.5px;
  @include font-p-4-paragraph-smallest-gray;
}

.btn-title-padding {
  padding: 8px 22px;
}

.btn-margins-height {
  margin: 0 12.5px;
  height: 35px;
}

.sub-nav {
  display: flex;
  flex-direction: row;
  align-items: center;

  &:last-child {
    margin-right: -12.5px;
  }
  &>h1:first-child {
    margin-right: 14.5px;
  }
}

.teacher-title-bar {
  height: 60px;
  background-color: white;

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
}

</style>
