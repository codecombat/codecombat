<script>
  import SecondaryTeacherNavigation from '../common/SecondaryTeacherNavigation'
  import TitleBar from '../common/TitleBar'
  import Guidelines from './Guidelines'
  import ViewAndMange from './ViewAndManage'
  import TableClassFrame from './table/TableClassFrame'

  import _ from 'lodash'

  export default {
    components: {
      'secondary-teacher-navigation': SecondaryTeacherNavigation,
      'title-bar': TitleBar,
      'guidelines': Guidelines,
      'view-and-manage': ViewAndMange,
      'table-class-frame': TableClassFrame
    },

    data: () => ({
      isGuidelinesVisible: true
    }),

    methods: {
      clickGuidelineArrow: _.throttle(function () {
        this.isGuidelinesVisible = !this.isGuidelinesVisible
      }, 300)
    }
  }
</script>

<template>
  <div>
    <secondary-teacher-navigation />
    <title-bar title="Intro to CS" :showClassInfo="true" />
    <guidelines :visible="isGuidelinesVisible" v-on:click-arrow="clickGuidelineArrow" />
    <view-and-manage :arrow-visible="!isGuidelinesVisible" v-on:click-arrow="clickGuidelineArrow" />

    <table-class-frame />
  </div>
</template>
