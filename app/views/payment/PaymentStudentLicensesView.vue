<template>
	<span>
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
		<div class="text-center footer">
			<button type="button" class="btn btn-success btn-lg btn-buy-now" @click="onBuyNow()">Buy Now</button>
		</div>
	</div>
	<payment-student-license-purchase-view
			v-if="isPurchaseViewEnabled"
			:price-data="priceData"
			:payment-group-id="paymentGroupId"
	/>
	</span>
</template>

<script>
import PaymentStudentLicenseView from "./PaymentStudentLicenseView";
import PaymentStudentLicensePurchaseView from "./PaymentStudentLicensePurchaseView";
export default {
	name: "PaymentStudentLicensesView",
	props: {
		priceData: {
			type: Array,
			required: true,
		},
		paymentGroupId: {
			type: String,
			required: true,
		},
	},
	data () {
		return {
			isPurchaseViewEnabled: false,
		}
	},
	components: {
		'payment-student-license-view': PaymentStudentLicenseView,
		'payment-student-license-purchase-view': PaymentStudentLicensePurchaseView,
	},
	methods: {
		onBuyNow() {
			this.isPurchaseViewEnabled = true
		},
	}
}
</script>

<style lang="scss" scoped>
.light-text {
	font-weight: 200!important;
	margin: 0;
	font-size: small;
}

.footer {
	padding-top: 15px;
}

.btn-buy-now {
	padding: 15px 25px;
	font-size: 25px;
}
</style>
