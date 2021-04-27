<template>
  <div>
		<h2 v-if="loading">Loading</h2>
		<h2 v-else>{{paymentGroup._id}}</h2>
  </div>
</template>

<script>
export default {
	name: "PaymentComponentView",
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

</style>
