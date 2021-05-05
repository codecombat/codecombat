<template>
	<div>
		Online Classes
	</div>
</template>

<script>
export default {
	name: "PaymentOnlineClassesView",
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

<style scoped>

</style>
