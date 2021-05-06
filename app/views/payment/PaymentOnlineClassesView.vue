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
	padding-bottom: 25px;
	padding-top: 10px;
	h2 {
		font-weight: bolder;
	}
	h4 {
		font-weight: bold;
	}
}
</style>
