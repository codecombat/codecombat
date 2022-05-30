<template>
  <div class="base-resource-hub">
    <raw-pug-component :pug="teacherDashboardNavTemplate"></raw-pug-component>
    <base-resource-hub />
  </div>
</template>

<script>
import BaseResourceHub from './index'
import teacherDashboardNavTemplate from 'app/templates/courses/teacher-dashboard-nav.pug'
import RawPugComponent from 'app/views/common/RawPugComponent'

export default {
  name: 'BaseResourceHubMainComponent',
  data () {
    return {
      teacherDashboardNavTemplate
    }
  },
  components: {
    BaseResourceHub,
    RawPugComponent
  }
}
</script>

<style scoped>

</style>
