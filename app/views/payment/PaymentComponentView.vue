<template>
  <div>
		<template v-if="loading">
			<h2 >Loading</h2>
		</template>
		<template v-else-if="paymentGroup">
			<payment-student-licenses-view
				:price-data="paymentGroup.priceData"
				:slug="paymentGroup.slug"
			/>
		</template>
		<template v-else>
			<h2>{{paymentGroup._id}}</h2>
		</template>
  </div>
</template>

<script>
import PaymentStudentLicensesView from "./PaymentStudentLicensesView";
export default {
	name: "PaymentComponentView",
	components: {
		'payment-student-licenses-view': PaymentStudentLicensesView,
	},
	created() {
		this.$store.dispatch('paymentGroups/fetch', this.$route.params.slug);
	},
	computed: {
		paymentGroup() {
			console.log('group', this.$store.getters['paymentGroups/paymentGroup'])
			return this.$store.getters['paymentGroups/paymentGroup'];
		},
		loading() {
			console.log('loading', this.$store.getters['paymentGroups/loading'])
			return this.$store.getters['paymentGroups/loading'];
		}
	}
}
</script>

<style scoped>

</style>
