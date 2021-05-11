<template>
	<div class="parent-details">
		<h4 class="parent-details-text">Parent Details</h4>
		<div class="form-group">
			<label for="parent-email">Email</label>
			<input type="text" class="form-control" id="parent-email" placeholder="Enter Email" @keydown="updateEmail" @keyup="updateEmail" />
		</div>
		<div class="form-group">
			<label for="parent-firstname">First Name</label>
			<input type="text" class="form-control" id="parent-firstname" placeholder="Enter First Name" @keydown="updateFirstName" @keyup="updateFirstName" />
		</div>
		<div class="form-group">
			<label for="parent-lastname">Last Name</label>
			<input type="text" class="form-control" id="parent-lastname" placeholder="Enter Last Name" @keydown="updateLastName" @keyup="updateLastName" />
		</div>
	</div>
</template>

<script>
export default {
	name: "PaymentOnlineClassesParentDetailsView",
	data () {
		return {
			email: null,
			firstName: null,
			lastName: null,
		};
	},
	methods: {
		updateEmail(e) {
			this.email = e.target.value;
			this.updateParentDetails();
		},
		updateFirstName(e) {
			this.firstName = e.target.value;
			this.updateParentDetails();
		},
		updateLastName(e) {
			this.lastName = e.target.value;
		},
		updateParentDetails() {
			// maybe use watch or something better to trigger this method
			if (this.email && this.firstName) {
				this.$emit('updateParentDetails', {
					email: this.email,
					firstName: this.firstName,
					lastName: this.lastName
				});
			}
		}
	},
}
</script>

<style scoped>
.parent-details {
	padding-top: 5px;
}
.parent-details-text {
	font-weight: bold;
	padding-bottom: 5px;
}
</style>
