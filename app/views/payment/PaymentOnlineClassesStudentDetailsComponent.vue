<template>
	<div class="student-details">
		<h4 class="student-details-text">Student Details</h4>
		<div
			class="form-group"
			v-for="index in numOfStudents"
			:key="index"
		>
			<h5 class="student-index-text">Student {{index}}</h5>
			<div class="form-group">
				<label :for="`student-firstname-${index}`">First Name<span class="required-field"> *</span></label>
				<input type="text" class="form-control" :id="`student-firstname-${index}`" placeholder="Enter First Name" @keydown="updateFirstName($event, index)" @keyup="updateFirstName($event, index)" />
			</div>
			<div class="form-group">
				<label :for="`student-lastname-${index}`">Last Name<span class="required-field"> *</span></label>
				<input type="text" class="form-control" :id="`student-lastname-${index}`" placeholder="Enter Last Name" @keydown="updateLastName($event, index)" @keyup="updateLastName($event, index)" />
			</div>
			<div class="form-group">
				<label :for="`student-email-${index}`">Email</label>
				<input type="text" class="form-control" :id="`student-email-${index}`" placeholder="Enter Email" @keydown="updateEmail($event, index)" @keyup="updateEmail($event, index)" />
				<div class="small-tip">*Enter student's CodeCombat account email if they have an account on CodeCombat</div>
			</div>
		</div>
		<p class="error">{{errorMsg}}</p>
	</div>
</template>

<script>
export default {
	name: "PaymentOnlineClassesStudentDetailsComponent",
	props: {
		numOfStudents: {
			type: Number,
			required: true,
		},
	},
	data() {
		const initial = [...Array(this.numOfStudents).keys()].map(_k => new Object())
		return {
			students: initial,
			errorMsg: null,
		};
	},
	methods: {
		updateEmail(e, index) {
			const student = this.students[index - 1]
			student.email = e.target.value;
			this.students[index - 1] = student;
			this.updateStudentDetails();
		},
		updateFirstName(e, index) {
			const student = this.students[index - 1]
			student.firstName = e.target.value;
			this.students[index - 1] = student;
			this.updateStudentDetails();
		},
		updateLastName(e, index) {
			const student = this.students[index - 1]
			student.lastName = e.target.value;
			this.students[index - 1] = student;
			this.updateStudentDetails();
		},
		updateStudentDetails() {
			// validate all data is filled properly
			let err = null;
			this.errorMsg = '';
			this.students.forEach((student, index) => {
				if (err)
					return;
				if (student.email && !this.validateEmail(student.email)) {
					err = `${student.email} is an invalid email for Student ${index + 1}`;
				}
				if (!student.lastName)
					err = `Student ${index + 1} lastName is empty`
				if (!student.firstName)
					err = `Student ${index + 1} firstName is empty`
			})
			if (err) {
				this.errorMsg = err;
				this.$emit('updateStudentDetails', null);
				return;
			}
			this.$emit('updateStudentDetails', this.students);
		},
		validateEmail(email) {
			const re = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
			return re.test(String(email).toLowerCase());
		},
	},
}
</script>

<style scoped>
.student-details-text {
	font-weight: bold;
	padding-bottom: 5px;
}
.student-index-text {
	padding-bottom: 5px;
	color: grey;
}
.error {
	color: red;
}
.required-field {
	color: red;
}
.small-tip {
	font-size: x-small;
	color: grey;
}
</style>
