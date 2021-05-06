<template>
	<div class="content table-responsive">
		<table class="table">
			<thead>
				<tr>
					<th v-for="col in getColumns" :key="col">
						{{getI18n(col)}}
					</th>
				</tr>
			</thead>
			<tbody>
				<tr v-for="row in getRows" :key="row[0]">
					<td v-for="(elem, index) in row" :key="index === 0 ? elem : elem.id">
						<div class="interval" v-if="index === 0">
							{{getI18n(elem)}}
						</div>
						<div v-else>
							<p class="display-price price">{{getDisplayPrice(elem)}}</p>
							<p class="comparing-price price" v-if="getComparingPrice(elem, index)">{{getComparingPrice(elem, index)}}</p>
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
			console.log(colKeys)
			return ['#', ...colKeys];
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
				// const intervalDuration = rowWithSameIntervalSorted[0].recurring.interval
				const row = [interval, ...rowWithSameIntervalSorted]
				rows.push(row)
			})
			// console.log(intervals);
			return rows;
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
			const firstPrice = this.getRows[0][index]
			const multiplier = (price) => price.recurring.interval === 'year' ? 12 : 1;
			const currentIntervalCount =  multiplier(currentPrice) * currentPrice.recurring.interval_count;
			const firstIntervalCount = multiplier(firstPrice) * firstPrice.recurring.interval_count;
			const intervalMultiplier = currentIntervalCount / firstIntervalCount;
			if (intervalMultiplier <= 1)
				return
			const actualPrice = intervalMultiplier * this.getTieredPrice(firstPrice)
			const priceStr = parseFloat(actualPrice.toFixed(2)); // parseFloat to remove trimming remove zeros after dot
			return `${this.getCurrency(currentPrice)}${priceStr}`
		},
		getI18n(key) {
			const paymentKey = `payments.${key}`
			const data = this.$t(paymentKey)
			if (data === paymentKey)
				return key;
			return data;
		}
	},
}
</script>

<style lang="scss" scoped>
.comparing-price {
	text-decoration: line-through;
}
.price {
	padding-left: 15%;
	padding-right: 15%;
	font-size: 120%;
}
th {
	font-size: 25px;
}
.interval {
	font-size: 120%;
}
</style>
