<template>
	<form style="width: 60%; padding-left: 40%">
		<div class="form-group">
			<label for="licenseType">Select License</label>
			<select class="form-control" id="licenseType">
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
			<input type="text" class="form-control" id="licenseNum">
		</div>
		<button type="submit" class="btn btn-primary">Purchase Now</button>
	</form>
</template>

<script>
export default {
	name: "PaymentStudentLicensePurchaseView",
	props: {
		priceData: Array,
	},
	methods: {
		getCurrency(price) {
			return price.currency === 'usd' ? '$' : price.currency;
		},
		getUnitPrice(price) {
			return price.unit_amount / 100;
		},
	}
}
</script>

<style scoped>

</style>
