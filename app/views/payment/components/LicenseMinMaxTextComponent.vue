<template>
  <span>
    <template
      v-if="minLicenses && maxLicenses && (maxLicenses < maxValueToShow)"
    >
      Between {{ minLicenses }} - {{ maxLicenses }} Licenses
    </template>
    <template
      v-else-if="maxLicenses && maxLicenses < maxValueToShow"
    >
      Up to {{ maxLicenses }} Licenses
    </template>
    <template
      v-else-if="minLicenses && (!maxLicenses || (maxLicenses > maxValueToShow))"
    >
      Minimum {{ minLicenses }} Licenses
    </template>
  </span>
</template>

<script>
export default {
  name: 'PaymentLicenseMinMaxTextComponent',
  props: {
    minLicenses: {
      type: Number
    },
    maxLicenses: {
      type: Number
    },
    maxValueToShow: {
      type: Number,
      default: 1000
    }
  }
}
</script>

<style scoped>

</style>
