<template>
  <div id="payment-classroom-district">
    <payment-student-license-head-component
      :i18n-heading-name="priceInfo.metadata.i18nName"
    />
    <payment-student-license-classroom-district-body-component
      :price-info="priceInfo"
      :payment-group-id="paymentGroupId"
    />
  </div>
</template>

<script>
import PaymentStudentLicenseHeadComponent from './PaymentStudentLicenseHeadComponent'
import PaymentStudentLicenseClassroomDistrictBodyComponent from "./PaymentStudentLicenseClassroomDistrictBodyComponent";
export default {
  name: "PaymentStudentLicenseClassroomDistrictView",
  components: {
    PaymentStudentLicenseHeadComponent,
    PaymentStudentLicenseClassroomDistrictBodyComponent,
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

<style scoped lang="scss">
</style>
