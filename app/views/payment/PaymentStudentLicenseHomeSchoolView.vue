<template>
  <div>
    <payment-student-license-head-component
      :i18n-heading-name="priceInfo.metadata.i18nName"
      title="Homeschooling Licenses"
      sub-title="For at-home learning groups with 5 or fewer students"
    />
    <payment-student-license-home-school-body-component
      :price-info="priceInfo"
      :payment-group-id="paymentGroupId"
    />
  </div>
</template>

<script>
import PaymentStudentLicenseHeadComponent from "./PaymentStudentLicenseHeadComponent";
import PaymentStudentLicenseHomeSchoolBodyComponent from "./PaymentStudentLicenseHomeSchoolBodyComponent";
export default {
  name: "PaymentStudentLicenseHomeSchoolView",
  components: {
    PaymentStudentLicenseHeadComponent,
    PaymentStudentLicenseHomeSchoolBodyComponent,
  },
  props: {
    priceInfo: {
      type: Object,
      required: true,
    },
    paymentGroupId: {
      type: String,
      required: true,
    }
  }
}
</script>

<style scoped>

</style>
