<template>
	<form class="purchase-form">
		<div class="form-group">
			<label for="licenseType">Select License</label>
			<select
					class="form-control"
					id="licenseType"
					@change="updateSelectedPrice"
			>
				<option
						v-for="price in priceData"
						:value="price.id"
						:key="price.id"
				>
					{{$t(`payments.${price.metadata.i18nName}`)}} - {{getCurrency(price)}}{{getUnitPrice(price)}}
				</option>
			</select>
		</div>
		<div class="form-group">
			<label for="licenseNum">Number of Licenses</label>
			<input type="text" class="form-control" id="licenseNum" @keydown="updateLicenseNum" @keyup="updateLicenseNum">
			<p v-if="licenseNum && !errMsg" class="total-price">Total price: {{selectedCurrency}}{{totalPrice}}</p>
			<p class="error">{{errMsg}}</p>
		</div>
		<div class="form-group">
			<button
					type="submit"
					class="btn btn-primary btn-lg purchase-btn"
					:class="licenseNum && !errMsg ? '' : 'disabled'"
					@click="onPurchaseNow"
			>
				Purchase Now
			</button>
		</div>
	</form>
</template>

<script>
import { getStripeLib } from '../../lib/stripeUtil';
import { createPaymentSession } from '../../core/api/payment-session';

export default {
	name: "PaymentStudentLicensePurchaseView",
	props: {
		priceData: Array,
		paymentGroupId: String,
	},
	data() {
		return {
			licenseNum: 0,
			selectedPrice: this.priceData[0].id,
			errMsg: '',
		}
	},
	methods: {
		getCurrency(price) {
			return price.currency === 'usd' ? '$' : price.currency;
		},
		getUnitPrice(price) {
			return price.unit_amount / 100;
		},
		updateSelectedPrice(e) {
			this.selectedPrice = e.target.value;
		},
		updateLicenseNum(e) {
			this.errMsg = '';
			const licenseNum = parseInt(e.target.value);
			if (isNaN(licenseNum)) {
				this.errMsg = 'Invalid number';
				return
			}
			const price = this.getSelectedPrice();
			const licenseCap = price.metadata.licenseCap
			if (licenseNum > licenseCap) {
				this.errMsg = `Sorry, you cannot purchase more than ${licenseCap} licenses`;
				return;
			}
			this.licenseNum = licenseNum;
		},
		getSelectedPrice() {
			return this.priceData.find((p) => p.id === this.selectedPrice)
		},
		async onPurchaseNow(e) {
			e.preventDefault();
			const stripe = await getStripeLib()
			const sessionOptions = {
				stripePriceId: this.selectedPrice,
				paymentGroupId: this.paymentGroupId,
				numberOfLicenses: this.licenseNum,
				email: me.get('email'),
				userId: me.get('_id'),
				totalAmount: this.totalPrice
			}
			try {
				const session = await createPaymentSession(sessionOptions);
				const sessionId = session.data.sessionId;
				const result = await stripe.redirectToCheckout({ sessionId });
				if (result.error) {
					console.error('resErr', result.error);
				}
			} catch (err) {
				this.errMsg = err.message;
				console.error('paymentSession creation failed', err);
			}
		}
	},
	computed: {
		totalPrice() {
			const price = this.getSelectedPrice();
			return (this.getUnitPrice(price) * this.licenseNum).toFixed(2)
		},
		selectedCurrency() {
			const price = this.getSelectedPrice();
			return this.getCurrency(price);
		}
	}
}
</script>

<style lang="scss" scoped>
.purchase-form {
	width: 60%;
	padding-left: 40%;
	padding-top: 15px;
}
.purchase-btn {
	color: #fff;
	background-color: #007bff;
	border-color: #007bff;
}

.total-price {
	padding-top: 5px
}

.error {
	color: red;
}
</style>
