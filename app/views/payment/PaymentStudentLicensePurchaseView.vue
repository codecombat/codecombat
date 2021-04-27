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
			<p v-if="licenseNum && !errMsg">Total price: {{totalPrice}}</p>
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
export default {
	name: "PaymentStudentLicensePurchaseView",
	props: {
		priceData: Array,
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
		onPurchaseNow(e) {
			e.preventDefault();
			console.log('redirect to stripe');
		}
	},
	computed: {
		totalPrice() {
			const price = this.getSelectedPrice();
			return this.getUnitPrice(price) * this.licenseNum
		},
	}
}
</script>

<style scoped>

</style>
