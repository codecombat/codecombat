<script>
  import SecondaryTeacherNavigation from '../common/SecondaryTeacherNavigation'
  import TitleBar from '../common/TitleBar'

  export default {
    components: {
      'secondary-teacher-navigation': SecondaryTeacherNavigation,
      'title-bar': TitleBar
    }
  }
</script>

<template>
  <div>
    <secondary-teacher-navigation />
    <title-bar title="PLACEHOLDER Classname" :showClassInfo="true" />
    <br /><br /><br /><br /><br /><br />
    <span>PLACEHOLDER: STUDENT PROJECTS COMPONENT GOES HERE</span>
    <br /><br /><br /><br /><br /><br />
  </div>
</template>
