<template>
	<div class="content table-responsive">
		<table class="table">
			<thead>
				<tr>
					<th class="heading" v-for="col in getColumns" :key="col">
						{{getI18n(col)}}
					</th>
				</tr>
			</thead>
			<tbody>
				<tr v-for="(row, ind) in getRows" :key="ind">
					<td class="data-row" v-for="(elem, index) in row" :key="typeof elem === 'string' ? elem : elem.id">
						<div class="interval" v-if="typeof elem === 'string'">
							<p>{{getI18n(elem)}}</p>
							<p class="recurring-interval">{{getI18n(`recurring.${elem}`)}}</p>
							<p class="percent-off" v-if="getPercentOff(row)">{{getPercentOff(row)}}% Off</p>
						</div>
						<div class="price-box" v-else>
							<p class="display-price price">{{getDisplayPrice(elem)}}</p>
							<p
								class="comparing-price price"
								v-if="getComparingPrice(elem, index)"
							>
								{{getComparingPrice(elem, index)}}
							</p>
							<p
								class="sub-label"
								v-if="elem.metadata.subLabel"
							>
								{{getI18n(elem.metadata.subLabel)}}
							</p>
						</div>
					</td>
				</tr>
			</tbody>
		</table>
	</div>
</template>

<script>
import _ from 'lodash'
export default {
	name: "PaymentOnlineClassesPlansView",
	props: {
		priceData: {
			type: Array,
			required: true,
		},
	},
	computed: {
		getColumns() {
			const colKeys = _.uniq(this.priceData.map((price) => price.metadata.groupKey)).sort()
			if (this.shouldChangeOrderOfData) {
				return [
						...colKeys.slice(0, parseInt(colKeys.length / 2)),
						'#',
						...colKeys.slice(parseInt(colKeys.length / 2))
				]
			} else {
				return ['#', ...colKeys];
			}
		},
		getRows() {
			const rowKey = price => `${price.recurring.interval}_${price.recurring.interval_count}`
			const intervals = _.uniq(this.priceData.map(rowKey))
			const rows = [];
			intervals.forEach((interval) => {
				const rowWithSameInterval = this.priceData.filter(price => interval === rowKey(price))
				const rowWithSameIntervalSorted = _.sortBy(rowWithSameInterval, function (row) {
					return row.metadata.groupKey;
				})
				let row
				if (this.shouldChangeOrderOfData) {
					row = [
							...rowWithSameIntervalSorted.slice(0, parseInt(rowWithSameIntervalSorted.length / 2)),
							interval,
							...rowWithSameIntervalSorted.slice(parseInt(rowWithSameIntervalSorted.length / 2))
					]
				} else {
					row = [interval, ...rowWithSameIntervalSorted]
				}
				rows.push(row)
			})
			return rows;
		},
		shouldChangeOrderOfData() {
			const colKeys = _.uniq(this.priceData.map((price) => price.metadata.groupKey)).sort()
			return (colKeys.length % 2 === 0)
		}
	},
	methods: {
		getDisplayPrice(price) {
			return `${this.getCurrency(price)}${this.getTieredPrice(price)}`
		},
		getCurrency(price) {
			return price.currency === 'usd' ? '$' : price.currency;
		},
		getTieredPrice(price) {
			const tier = price.tiers.find(tier => tier.up_to === 1)
			return tier.unit_amount / 100;
		},
		getComparingPrice(currentPrice, index) {
			const priceStr = this.getComparingNumber(currentPrice, index)
			if (!priceStr)
				return
			return `${this.getCurrency(currentPrice)}${priceStr}`
		},
		getComparingNumber(currentPrice, index) {
			const firstPrice = this.getRows[0][index]
			const multiplier = (price) => price.recurring.interval === 'year' ? 12 : 1;
			const currentIntervalCount =  multiplier(currentPrice) * currentPrice.recurring.interval_count;
			const firstIntervalCount = multiplier(firstPrice) * firstPrice.recurring.interval_count;
			const intervalMultiplier = currentIntervalCount / firstIntervalCount;
			if (intervalMultiplier <= 1)
				return
			const actualPrice = intervalMultiplier * this.getTieredPrice(firstPrice)
			return parseFloat(actualPrice.toFixed(2)); // parseFloat to remove trimming remove zeros after dot
		},
		getI18n(key) {
			const paymentKey = `payments.${key}`
			const data = this.$t(paymentKey)
			if (data === paymentKey)
				return key;
			return data;
		},
		getPercentOff(row) {
			let percentages = []
			row.forEach((elem, index) => {
				if (typeof elem !== 'string') {
					const tier1 = elem.tiers.find((el) => el.up_to === 1)
					const tier2 = this.getComparingNumber(elem, index)
					if (!tier2)
						return
					const tier1Amount = tier1.unit_amount / 100
					const off = (tier2 - tier1Amount) / tier2
					const percentOff = Math.round(off * 100)
					percentages.push(percentOff);
				}
			})
			let allPercentSame = true
			for (let i = 1; i < percentages.length; i++) {
				if (allPercentSame) {
					allPercentSame = percentages[i] === percentages[i - 1]
				}
			}
			if (allPercentSame && percentages.length)
				return percentages[0]
		}
	},
}
</script>

<style lang="scss" scoped>
.comparing-price {
	text-decoration: line-through;
	padding-top: 5%;
}
.price {
	font-size: 130%;
	font-weight: 500;
}
th {
	font-size: 150%;
}
.heading {
	text-align: center;
}
.interval {
	font-size: 120%;
	text-align: center;
	padding: 4%;
}
.price-box {
	border: 1px solid lightgrey;
	margin: 2% 32% 2% 32%;
	padding: 3%;
	text-align: center;
	background-color: white;
}
p {
	margin: 0;
}
.data-row {
	padding: 1px;
	background-color: floralwhite;
}
.percent-off {
	color: goldenrod;
}
.recurring-interval {
	font-size: small;
}
.sub-label {
	color: goldenrod;
}
</style>
