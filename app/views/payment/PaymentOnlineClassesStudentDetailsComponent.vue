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
				<label :for="`student-firstname-${index}`">First Name</label>
				<input type="text" class="form-control" :id="`student-firstname-${index}`" placeholder="Enter First Name" @keydown="updateFirstName($event, index)" @keyup="updateFirstName($event, index)" />
			</div>
			<div class="form-group">
				<label :for="`student-lastname-${index}`">Last Name</label>
				<input type="text" class="form-control" :id="`student-lastname-${index}`" placeholder="Enter Last Name" @keydown="updateLastName($event, index)" @keyup="updateLastName($event, index)" />
			</div>
			<div class="form-group">
				<label :for="`student-email-${index}`">Email</label>
				<input type="text" class="form-control" :id="`student-email-${index}`" placeholder="Enter Email" @keydown="updateEmail($event, index)" @keyup="updateEmail($event, index)" />
			</div>
			<hr
				v-if="index !== numOfStudents"
			/>
		</div>
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
		};
	},
	methods: {
		updateEmail(e, index) {
			const student = this.students[index - 1]
			student.email = e.target.value;
			this.students[index - 1] = student;
		},
		updateFirstName(e, index) {
			const student = this.students[index - 1]
			student.firstName = e.target.value;
			this.students[index - 1] = student;
		},
		updateLastName(e, index) {
			const student = this.students[index - 1]
			student.lastName = e.target.value;
			this.students[index - 1] = student;
		},
		updateStudentDetails() {
			// validate all data is filled properly
			this.$emit('updateStudentDetails', this.students);
		}
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
</style>
