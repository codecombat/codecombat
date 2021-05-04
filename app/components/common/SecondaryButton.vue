<script>
export default Vue.extend({
	props: {
		inactive: {
			type: Boolean,
			default: false
		}
	},
	methods: {
		onClick () {
			if (!this.inactive) {
				this.$emit('click')
			}
		}
	}
})
</script>

<template>
	<button
			:class="{ disabled: inactive }"
			:disabled="inactive"
			@click="onClick"
	>
		<slot />
	</button>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "app/styles/modal";

button {
	background-color: $dusk;
	border-radius: 1px;
	border-width: 0;
	color: $gray;
	text-shadow: unset;
	font-weight: bold;
	@include font-p-3-small-button-text-black;
	background-image: unset;

	&:hover {
		background-color: $dusk-dark;
		color: #ffffff;
		transition: background-color .35s;
	}

	&.disabled {
		background: #ADADAD;
		color: #000000;
		cursor: default;
	}
}
</style>
