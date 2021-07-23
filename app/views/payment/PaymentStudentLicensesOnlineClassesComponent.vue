<template>
  <div class="online-classes">
    <div class="text-center learning">
      <img src="/images/pages/parents/personal_learning.png" class="learning-image" />
    </div>
    <div class="learning-text">
      <p class="bold">Online Classes Available</p>
      <p class="small">Combining the power of gameplay and personalized instruction, our live online classes deliver an experience your student will love.
        Our dedicated instructors offer individualized attention with a structured curriculum that teacher real Python and JavaScript. Try a 60 min trial class for free!</p>
    </div>
    <button type="button" class="btn btn-default more-info-btn" @click="moreInfo">More info</button>
  </div>
</template>

<script>
// online classes info shown in student classes payment page
export default {
  name: "PaymentStudentLicensesOnlineClassesComponent",
  methods: {
    moreInfo() {
      window.open('https://codecombat.com/parents', '_blank')
    },
  }
}
</script>

<style scoped lang="scss">
.online-classes {
  box-shadow: 0px 2px 4px rgba(0, 0, 0, 0.5);
  padding: 15px;
}
.learning {
  width: 60%;
  display: table-cell;
}
.learning-image {
  max-width: 100%;
  max-height: 100%;
  width: 65%;
}
.small {
  font-size: small;
  color: grey;
  margin-bottom: 5px;
}
.bold {
  font-weight: bold;
}
.learning-text {
  padding: 10px;
}
.more-info-btn {
  font-weight: bold;
  border: 1px solid black;
}
</style>
