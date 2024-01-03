<template>
  <div class="testimonials">
    <p class="heading">
      This rare opportunity brings together students from around the globe. Here’s the student experience at a glance.
    </p>
    <div class="menu-content">
      <div class="list-item">
        <img
          class="vector"
          alt="Vector"
          src="/images/pages/codequest/testimonals/vector.svg"
        >
        <div class="text">
          Engaging Hackathons
        </div>
      </div>
      <div class="list-item">
        <img
          class="img"
          alt="Vector"
          src="/images/pages/codequest/testimonals/image.svg"
        >
        <div class="text">
          Insightful Speakers
        </div>
      </div>
      <div class="list-item">
        <img
          class="layer"
          alt="Layer"
          src="/images/pages/codequest/testimonals/layer-1.svg"
        >
        <div class="text">
          University Campus Visits
        </div>
      </div>
      <div class="list-item">
        <img
          class="layer-2"
          alt="Layer"
          src="/images/pages/codequest/testimonals/layer-1-2.svg"
        >
        <div class="text">
          Silicon Valley Experience
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'TestimonialsComponent'
}
</script>

<style scoped lang="scss">
.testimonials {
  align-items: center;
  display: flex;
  flex-direction: column;
  gap: 80px;
  justify-content: center;
  padding: 100px 135px;
  @media (max-width: 991px) {
    padding: 100px 20px;
  }
  position: relative;
}

.testimonials .heading {
  align-self: stretch;
  color: #4799A9;
  font-family: "Plus Jakarta Sans-Medium", Helvetica;
  font-size: 36px;
  font-weight: 500;
  letter-spacing: 0;
  line-height: 45px;
  margin-top: -1px;
  position: relative;
  text-align: center;
}

.testimonials .menu-content {
  align-items: flex-start;
  align-self: stretch;
  display: flex;
  flex: 0 0 auto;
  gap: 30px;
  justify-content: center;
  position: relative;
  width: 100%;
  @media (max-width: 785px) {
    flex-wrap: wrap;
    justify-content: space-between;
  }
}

.testimonials .list-item {
  align-items: center;
  display: flex;
  flex: 1;
  flex-direction: column;
  flex-grow: 1;
  gap: 40px;
  position: relative;
  @media (max-width: 785px) {
    width: calc(50% - 15px);
  }
}

.testimonials .vector {
  height: 70px;
  position: relative;
  width: 78.33px;
}

.testimonials .text {
  align-self: stretch;
  color: #4799A9;
  font-family: "Plus Jakarta Sans-Regular", Helvetica;
  font-size: 20px;
  font-weight: 400;
  letter-spacing: 0;
  line-height: 26px;
  position: relative;
  text-align: center;
}

.testimonials .img {
  height: 70px;
  position: relative;
  width: 74.23px;
}

.testimonials .layer {
  height: 70px;
  position: relative;
  width: 74.43px;
}

.testimonials .layer-2 {
  height: 70px;
  position: relative;
  width: 87.16px;
}
</style>
