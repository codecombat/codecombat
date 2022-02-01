<template>
  <div>
    <template v-if="this.paymentGroup.subType === 'classroom-and-school-district'">
      <payment-student-license-classroom-district-view
        :price-info="paymentGroup.priceData[0]"
        :payment-group-id="paymentGroup._id"
      />
    </template>
    <template v-else-if="this.paymentGroup.subType === 'home-school'">
      <payment-student-license-home-school-view
        :price-info="paymentGroup.priceData[0]"
        :payment-group-id="paymentGroup._id"
      />
    </template>
    <template v-else>
      <payment-student-licenses-view
        :price-data="paymentGroup.priceData"
        :payment-group-id="paymentGroup._id"
        :payment-group-metadata="paymentGroup.metadata"
      />
    </template>
  </div>
</template>

<script>
import PaymentStudentLicensesView from './StudentLicensesView'
import PaymentStudentLicenseClassroomDistrictView from './ClassroomDistrictView'
import PaymentStudentLicenseHomeSchoolView from "./HomeSchoolView";
export default {
  name: "PaymentStudentLicensesComponent",
  components: {
    PaymentStudentLicensesView,
    PaymentStudentLicenseClassroomDistrictView,
    PaymentStudentLicenseHomeSchoolView,
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
