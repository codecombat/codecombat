<template>
	<div>
		<div class="container text-center">
			<h1>{{$t('payments.student_licenses')}}</h1>
			<h2>{{$t('payments.great_courses')}}:</h2>
			<div class="row">
				<div class="col-xs-4">
					<div class="text-center">
						<img src='/images/pages/home/computer-science-2.png' />
						<p>{{$t('payments.computer_science')}}</p>
					</div>
				</div>
				<div class="col-xs-4">
					<div class="text-center">
						<img src='/images/pages/home/web-development-1.png' />
						<p>{{$t('payments.web_development')}}</p>
					</div>
				</div>
				<div class="col-xs-4">
					<div class="text-center">
						<img src='/images/pages/home/game-development-1.png' />
						<p>{{$t('payments.game_development')}}</p>
					</div>
				</div>
			</div>
			<div>
				<h3>{{$t('payments.just')}} {{this.getCurrency()}}{{this.getUnitPrice()}} {{$t('payments.per_student')}}</h3>
			</div>
			<div>
				<p>{{$t('payments.teachers_upto')}} {{this.licenseCap}} {{$t('payments.student_licenses')}}</p>
				<p>If you want to purchase more, <a href="#">Contact Us</a></p>
			</div>
		</div>
<!--		<p>Price: {{this.getCurrency()}} {{this.getUnitPrice()}}</p>-->
	</div>
</template>

<script>
export default {
	name: "PaymentStudentLicenseView",
	props: {
		currency: {
			type: String,
			required: true,
		},
		unitAmount: {
			type: Number,
			required: true,
		},
		priceId: {
			type: String,
			required: true,
		},
		licenseCap: {
			type: Number,
			required: true,
		},
		licenseValidityPeriodInDays: {
			type: Number,
			required: true,
		},
	},
	methods: {
		getUnitPrice() {
			return this.unitAmount / 100;
		},
		getCurrency() {
			return this.currency === 'usd' ? '$' : this.currency;
		},
	}
}
</script>

<style scoped>

</style>
