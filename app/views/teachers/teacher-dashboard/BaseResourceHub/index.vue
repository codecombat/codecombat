<script>
  import teacherDashboardNavTemplate from 'app/templates/courses/teacher-dashboard-nav.pug'
  import BaseResourceHub from 'ozaria/site/components/teacher-dashboard/BaseResourceHub/index.vue';
  import RawPugComponent from '../../../common/RawPugComponent'

  const CocoResourceHub = {
    name: 'CocoResourceHub',
    extends: BaseResourceHub,
    computed: {
      relevantCategoryIds() {
        return {
          1500001145602: 'CodeCombat for Educators',
        }
      }
    }
  }

  export default {
    data () {
      return {
        teacherDashboardNavTemplate
      }
    },

    components: {
      CocoResourceHub,
      RawPugComponent
    }
  }
</script>

<template>
  <div class="base-resource-hub">
    <raw-pug-component :pug="teacherDashboardNavTemplate"></raw-pug-component>
    <coco-resource-hub />
  </div>
</template>

<style lang="scss" scoped>
  ::v-deep .aside {
    margin-top: -20px;
  }

  ::v-deep .resource-hub {
    padding: 10px 30px 40px;
  }
</style>
