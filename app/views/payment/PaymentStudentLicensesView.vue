<template>
	<div>
		<payment-student-license-view
			v-for="price in priceData"
			:currency="price.currency"
			:unit-amount="price.unit_amount"
			:price-id="price.id"
			:license-cap="parseInt(price.metadata.licenseCap)"
			:license-validity-period-in-days="parseInt(price.metadata.licenseValidityPeriodInDays)"
		/>
		<div class="text-center">
			<a class="btn btn-forest">Buy Now</a>
			<p>*Teacher License are free</p>
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
}
</script>

<style scoped>

</style>
