<template>
	<div class="student-licenses">
		<payment-student-license-view
			v-for="price in priceData"
			:currency="price.currency"
			:unit-amount="price.unit_amount"
			:price-id="price.id"
			:license-cap="parseInt(price.metadata.licenseCap)"
			:license-validity-period-in-days="parseInt(price.metadata.licenseValidityPeriodInDays)"
			:i18n-name="price.metadata.i18nName"
		/>
		<div class="text-center">
			<button type="button" class="btn btn-success btn-lg" @click="onBuyNow()">Buy Now</button>
			<p class="light-text">*Teacher License are free</p>
		</div>
	</div>
</template>

<script>
import PaymentStudentLicenseView from "./PaymentStudentLicenseView";
export default {
	name: "PaymentStudentLicensesView",
	props: {
		priceData: {
			type: Array,
			required: true,
		},
		slug: String,
	},
	components: {
		'payment-student-license-view': PaymentStudentLicenseView,
	},
	methods: {
		onBuyNow() {
			console.log('cliecked')
			this.$emit('buyNow');
		},
	}
}
</script>

<style scoped>

</style>
