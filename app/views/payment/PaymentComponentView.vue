<template>
  <div id="payment-view" class="p-y-2">
		<template v-if="loading">
			<div>
				<h2 class="text-center">Loading...</h2>
			</div>
		</template>
		<template v-else-if="paymentGroup && paymentGroup.groupType==='studentLicenses' &&
			me && !me.anonymous">
			<payment-student-licenses-view
				:price-data="paymentGroup.priceData"
				:slug="paymentGroup.slug"
				@buyNow="showPurchaseView"
			/>
		</template>
		<template v-else>
			<div>
				<h2 class="text-center">You must be logged in to view this page</h2>
			</div>
		</template>
		<payment-student-license-purchase-view
			v-if="isPurchaseViewEnabled"
			:price-data="paymentGroup.priceData"
			:payment-group-id="paymentGroup._id"
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
	},
	methods: {
		showPurchaseView() {
			this.isPurchaseViewEnabled = true;
		},
	}
}
</script>

<style scoped>

</style>
