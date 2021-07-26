<template>
  <div id="payment-view" class="p-y-2">
    <template v-if="loading">
      <div>
        <h2 class="text-center">Loading...</h2>
      </div>
    </template>
    <template v-else-if="paymentGroup && paymentGroup.groupType ==='studentLicenses' &&
      me && !me.anonymous">
      <payment-student-licenses-component
        :payment-group="paymentGroup"
      />
    </template>
    <template v-else-if="paymentGroup && paymentGroup.groupType ==='onlineClasses'">
      <payment-online-classes-view
        :price-data="paymentGroup.priceData"
        :payment-group-id="paymentGroup._id"
      />
    </template>
    <template v-else>
      <div>
        <h2 class="text-center">You must be logged in to view this page</h2>
      </div>
    </template>
  </div>
</template>

<script>
import PaymentOnlineClassesView from "./PaymentOnlineClassesView";
import PaymentStudentLicensesComponent from './PaymentStudentLicensesComponent'
export default {
  name: "PaymentComponentView",
  components: {
    PaymentOnlineClassesView,
    PaymentStudentLicensesComponent,
  },
  data() {
    return {
      me: me.attributes,
    };
  },
  created() {
    this.$store.dispatch('paymentGroups/fetch', this.$route.params.slug);
  },
  computed: {
    paymentGroup() {
      return this.$store.getters['paymentGroups/paymentGroup'];
    },
    loading() {
      return this.$store.getters['paymentGroups/loading'];
    }
  }
}
</script>

<style scoped>
/* add css here */
</style>
