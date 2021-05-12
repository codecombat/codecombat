<template>
	<div class="parent-details">
		<hr />
		<h4 class="parent-details-text">Parent Details</h4>
		<div class="form-group">
			<label for="parent-email">Email<span class="required-field"> *</span></label>
			<input type="text" :class="`form-control ${this.emailErrorClass}`" id="parent-email" placeholder="Enter Email" @keydown="updateEmail" @keyup="updateEmail" />
		</div>
		<div class="form-group">
			<label for="parent-firstname">First Name<span class="required-field"> *</span></label>
			<input type="text" class="form-control" id="parent-firstname" placeholder="Enter First Name" @keydown="updateFirstName" @keyup="updateFirstName" />
		</div>
		<div class="form-group">
			<label for="parent-lastname">Last Name</label>
			<input type="text" class="form-control" id="parent-lastname" placeholder="Enter Last Name" @keydown="updateLastName" @keyup="updateLastName" />
		</div>
		<hr />
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
			emailErrorClass: null,
		};
	},
	methods: {
		updateEmail(e) {
			this.emailErrorClass = '';
			const val = e.target.value;
			if (!this.validateEmail(val)) {
				this.emailErrorClass = 'error-border';
				return;
			}
			this.email = val;
			this.updateParentDetails();
		},
		updateFirstName(e) {
			this.firstName = e.target.value;
			this.updateParentDetails();
		},
		updateLastName(e) {
			this.lastName = e.target.value;
			this.updateParentDetails();
		},
		updateParentDetails() {
			// maybe use watch or something better to trigger this method
			if (this.email && this.firstName) {
				this.$emit('updateParentDetails', {
					email: this.email,
					firstName: this.firstName,
					lastName: this.lastName
				});
			} else {
				this.$emit('updateParentDetails', null);
			}
		},
		validateEmail(email) {
			const re = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
			return re.test(String(email).toLowerCase());
		},
	},
}
</script>

<style lang="scss" scoped>
.parent-details-text {
	font-weight: bold;
	padding-bottom: 5px;
}
.error-border {
	border-color: red;
}
.required-field {
	color: red;
}
</style>
