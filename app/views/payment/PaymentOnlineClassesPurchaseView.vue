<template>
	<form class="purchase-form">
		<div class="form-group">
			<label for="plans">Select Plan</label>
			<select
				class="form-control"
				id="plans"
				@change="updateSelectedPlan"
			>
				<option
					v-for="plan in getPlans"
					:key="plan"
					:value="plan"
				>
					{{getI18n(plan)}}
				</option>
			</select>
		</div>
		<div class="form-group">
			<label for="intervals">Select Interval</label>
			<select
				id="intervals"
				class="form-control"
				@change="updateSelectedInterval"
			>
				<option
					v-for="interval in getIntervals"
					:key="interval"
					:value="interval"
				>
					{{getI18n(interval)}}
				</option>
			</select>
		</div>
		<div class="form-group">
			<label for="licenseNum">Number of Students</label>
			<input type="text" class="form-control" id="licenseNum" @keydown="updateLicenseNum" @keyup="updateLicenseNum">
			<div class="price-info-view">
				<p v-if="licenseNum && !errMsg" class="total-price">Total price: {{selectedCurrency}}{{totalPrice}}</p>
				<p class="error">{{errMsg}}</p>
			</div>
		</div>
		<div class="form-group">
			<payment-online-classes-parent-details-component
				v-if="licenseNum && !errMsg"
				@updateParentDetails="updateParentDetails"
			/>
		</div>
		<div class="form-group">
			<payment-online-classes-student-details-component
				:num-of-students="licenseNum"
				v-if="licenseNum > 0"
				@updateStudentDetails="updateStudentDetails"
			/>
		</div>
	</form>
</template>

<script>
import _ from "lodash";
import PaymentOnlineClassesParentDetailsComponent from "./PaymentOnlineClassesParentDetailsComponent";
import PaymentOnlineClassesStudentDetailsComponent from "./PaymentOnlineClassesStudentDetailsComponent";
export default {
	name: "PaymentOnlineClassesPurchaseView",
	components: {
		PaymentOnlineClassesParentDetailsComponent,
		PaymentOnlineClassesStudentDetailsComponent,
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
	data () {
		return {
			licenseNum: 0,
			errMsg: null,
			selectedPlan: null,
			selectedInterval: null,
			parentDetails: null,
			studentDetails: null,
		};
	},
	computed: {
		getPlans() {
			const plans = _.uniq(this.priceData.map(this.getPlanKey)).sort()
			this.selectedPlan = plans[0]
			return plans;
		},
		getIntervals() {
			const intervals = _.uniq(this.priceData.map(this.getIntervalKey))
			this.selectedInterval = intervals[0]
			return intervals;
		},
		totalPrice() {
			const price = this.selectedPrice;
			const tiers = price.tiers;
			const reverseTiers = [...tiers].reverse();
			let selectedTier = null
			reverseTiers.forEach((tier) => {
				if (tier.up_to === null) {
					selectedTier = tier;
				} else if (tier.up_to >= this.licenseNum) {
					selectedTier = tier;
				}
			})
			return (this.licenseNum * (selectedTier.unit_amount / 100)).toFixed(2);
		},
		selectedCurrency() {
			const price = this.selectedPrice;
			return this.getCurrency(price);
		},
		selectedPrice() {
			return this.priceData.find((price) => {
				return this.getPlanKey(price) === this.selectedPlan &&
						this.getIntervalKey(price) === this.selectedInterval;
			})
		},
	},
	methods: {
		getI18n(key) {
			const paymentKey = `payments.${key}`
			const data = this.$t(paymentKey)
			if (data === paymentKey)
				return key;
			return data;
		},
		updateLicenseNum(e) {
			this.errMsg = '';
			const licenseVal = parseInt(e.target.value)
			if (isNaN(licenseVal)) {
				this.errMsg = 'Invalid value';
				return;
			}
			this.licenseNum = licenseVal;
		},
		updateSelectedPlan(e) {
			this.selectedPlan = e.target.value;
		},
		updateSelectedInterval(e) {
			this.selectedInterval = e.target.value;
		},
		getIntervalKey(price) {
			return `${price.recurring.interval}_${price.recurring.interval_count}`;
		},
		getPlanKey(price) {
			return price.metadata.groupKey;
		},
		getCurrency(price) {
			return price.currency === 'usd' ? '$' : price.currency;
		},
		updateParentDetails(details) {
			this.parentDetails = details;
		},
		updateStudentDetails(details) {
			this.studentDetails = details;
		}
	}
}
</script>

<style lang="scss" scoped>
.purchase-form {
	width: 60%;
	padding-left: 25%;
	margin-top: 10px;
}
.error {
	color: red;
}
.price-info-view {
	padding-top: 5px;
}
</style>
