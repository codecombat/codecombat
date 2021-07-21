<template>
  <div>
    <template v-if="this.paymentGroup.subType === 'classroom-and-school-district'">
      <payment-student-license-classroom-district-view
        :price-info="paymentGroup.priceData[0]"
        :payment-group-id="paymentGroup._id"
      />
    </template>
    <template v-else>
      <payment-student-licenses-view
        :price-data="paymentGroup.priceData"
        :payment-group-id="paymentGroup._id"
      />
    </template>
  </div>
</template>

<script>
import PaymentStudentLicensesView from './PaymentStudentLicensesView'
import PaymentStudentLicenseClassroomDistrictView from './PaymentStudentLicenseClassroomDistrictView'
export default {
  name: "PaymentStudentLicensesComponent",
  components: {
    PaymentStudentLicensesView,
    PaymentStudentLicenseClassroomDistrictView,
  },
  props: {
    paymentGroup: {
      type: Object,
      required: true,
    },
  },
}
</script>

<style scoped>

</style>
