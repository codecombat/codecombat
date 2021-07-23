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
      />
    </template>
  </div>
</template>

<script>
import PaymentStudentLicensesView from './PaymentStudentLicensesView'
import PaymentStudentLicenseClassroomDistrictView from './PaymentStudentLicenseClassroomDistrictView'
import PaymentStudentLicenseHomeSchoolView from "./PaymentStudentLicenseHomeSchoolView";
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
