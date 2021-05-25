<template>
	<div>
		<div class="container-fluid">
			<div class="container">
				<div class="text-center header">
					<h2>LIVE ONLINE CODING CLASSES PLANS & PAYMENT OPTIONS</h2>
					<h4>Your subscription purchase is <u>100% risk-free</u> within the first 30 days!</h4>
				</div>
				<payment-online-classes-plans-view
						:price-data="priceData"
					/>
				<div v-if="getSiblingPercentageOff() > 0" class="offer-view text-center">
					<h3>Get an extra {{ this.getSiblingPercentageOff() }}% off on purchase of sibling accounts</h3>
					<p class="auto-text">Applied at checkout automatically when selecting more than one student</p>
				</div>
			</div>
		</div>
		<div class="buy-now-view text-center">
			<button type="button" class="btn btn-success btn-buy-now" @click="enablePurchaseView">Buy Now</button>
			<div class="info-view">
				<p>If for any reason you decide not to continue, simply <a href="mailto:classes@codecombat.com">Contact Us</a> within 30 days of purchase and we will promptly refund 100% of your payment, no questions asked. All plans are automatically renewed at the same level and billing cycle unless otherwise changed or cancelled.</p>
			</div>
		</div>
		<payment-online-classes-purchase-view
			v-if="showPurchaseView"
			:price-data="priceData"
			:payment-group-id="paymentGroupId"
			:sibling-percentage-off="getSiblingPercentageOff()"
		/>
	</div>
</template>

<script>
import PaymentOnlineClassesPlansView from "./PaymentOnlineClassesPlansView";
import PaymentOnlineClassesPurchaseView from "./PaymentOnlineClassesPurchaseView";
export default {
	name: "PaymentOnlineClassesView",
	components: {
		'payment-online-classes-plans-view': PaymentOnlineClassesPlansView,
		'payment-online-classes-purchase-view': PaymentOnlineClassesPurchaseView,
	},
	data () {
		return {
			showPurchaseView: false,
		}
	},
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
	methods: {
		enablePurchaseView() {
			this.showPurchaseView = true;
		},
		getSiblingPercentageOff() {
			const tiers = [...this.priceData[0].tiers]
			tiers.sort((a, b) => b - a)
			return Math.round(((tiers[0].unit_amount - tiers[1].unit_amount) / tiers[0].unit_amount) * 100)
		}
	}
}
</script>

<style lang="scss" scoped>
.container-fluid {
	background-color: aliceblue;
}
.header {
	padding-bottom: 20px;
	padding-top: 10px;
	h2 {
		font-weight: bolder;
	}
	h4 {
		font-weight: bold;
	}
}
.buy-now-view {
	padding-top: 10px;

	.info-view {
		padding-top: 15px;
		padding-left: 20%;
		padding-right: 20%;
		font-size: small;
		text-align: initial;

		p {
			margin: 0;
			line-height: 150%;
		}
	}

	.btn-buy-now {
		padding: 15px 25px;
		font-size: 25px;
	}
}
.auto-text {
	font-size: small;
}
</style>
