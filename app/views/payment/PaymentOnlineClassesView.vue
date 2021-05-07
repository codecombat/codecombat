<template>
	<div>
		<div class="container-fluid">
			<div class="container">
				<div class="text-center header">
					<h2>Live Online Coding Classes Plans</h2>
					<h4>Invest in your child's future while they have fun</h4>
				</div>
				<payment-online-classes-plans-view
						:price-data="priceData"
					/>
				<div class="offer-view text-center">
					<h3>OFFER: Get extra 15% off on purchase of sibling accounts</h3>
					<p>Select for more than one student after clicking Buy Now to automatically get 15% discount</p>
				</div>
			</div>
		</div>
		<div class="buy-now-view text-center">
			<button type="button" class="btn btn-success btn-lg" @click="">Buy Now</button>
			<div class="info-view">
				<p>*All plans are automatically renewed at the same level and billing cycle unless otherwise changed or cancelled.</p>
				<p>**Your purchase is 100% risk free within the first 30 days. If for any reason you decide not to continue, simply <a>Contact Us</a> within 30 days of purchase and we will promptly refund 100% of your payment, no questions asked.</p>
			</div>
		</div>
	</div>
</template>

<script>
import PaymentOnlineClassesPlansView from "./PaymentOnlineClassesPlansView";
export default {
	name: "PaymentOnlineClassesView",
	components: {
		'payment-online-classes-plans-view': PaymentOnlineClassesPlansView,
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
		padding-top: 5px;
		padding-left: 25%;
		padding-right: 25%;
		font-size: small;

		p {
			margin: 0;
		}
	}
}
</style>
