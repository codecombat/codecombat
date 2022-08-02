<script>
  const utils = require('core/utils')
  const { LICENSE_PRESETS } = require('core/constants')
  export default {
    data () {
	  return {
		licenseType: 'all',
		selectedCourses: [utils.courseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE]
	  }
    },
    computed: {
      utils() {
        return utils
      },
      licensePresets() {
        return LICENSE_PRESETS
      }
    },
    methods: {
      selectCourse (id) {
		let index = this.selectedCourses.indexOf(id)
		if(index > -1) {
		  this.selectedCourses.splice(index, 1)
		} else {
		  this.selectedCourses.push(id)
		}
		this.$emit('input-course', this.selectedCourses)
      }
    },
	watch: {
	  licenseType (val) {
		this.$emit('input-type', val)
	  }
	}
  }
</script>
<template lang="pug">
  .form-group
    label
      span Licenses Type
      =":"
      #license-type-select
        .radio
          label.license-type
            input(type="radio", name="licenseType", value="all", v-model="licenseType")
            span(data-i18n="admin.license_type_full")
        .radio(v-for="(v, preset) in licensePresets")
          label.license-type
            input(type="radio", name="licenseType", :value="preset", v-model="licenseType")
            span {{preset}}
        .radio
          label.license-type
            input(type="radio", name="licenseType", value="customize", v-model="licenseType")
            span(data-i18n="admin.license_type_customize")
        #select-courses(v-if="licenseType == 'customize'")
          label.course-name(v-for="(courseID, key) in utils.courseIDs")
            input(type="checkbox", name="includedCourseIDs", :value="courseID", :checked="selectedCourses.includes(courseID)" v-on:input="selectCourse(courseID)")
            span {{utils.courseAcronyms[courseID]}}
</template>

<style scoped>

</style>