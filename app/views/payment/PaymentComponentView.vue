<template>
  <div id="payment-view">
		<template v-if="loading">
			<h2 >Loading</h2>
		</template>
		<template v-else-if="paymentGroup">
			<payment-student-licenses-view
				:price-data="paymentGroup.priceData"
				:slug="paymentGroup.slug"
				@buyNow="showPurchaseView"
			/>
		</template>
		<template v-else>
			<h2>{{paymentGroup._id}}</h2>
		</template>
		<payment-student-license-purchase-view
				v-if="isPurchaseViewEnabled"
				:price-data="paymentGroup.priceData"
		/>
  </div>
</template>

<script>
import PaymentStudentLicensesView from "./PaymentStudentLicensesView";
import PaymentStudentLicensePurchaseView from "./PaymentStudentLicensePurchaseView";
export default {
	name: "PaymentComponentView",
	components: {
		'payment-student-licenses-view': PaymentStudentLicensesView,
		'payment-student-license-purchase-view': PaymentStudentLicensePurchaseView,
	},
	data() {
		return {
			isPurchaseViewEnabled: false,
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
	},
	methods: {
		showPurchaseView() {
			console.log('show')
			this.isPurchaseViewEnabled = true;
		},
	}
}
</script>

<style scoped>

</style>
