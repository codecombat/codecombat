<template>
  <div class="container-fluid text-center p-t-2">
    <div class="container">
      <div class="top-section">
        <div class="heading-row">
          <h1>{{$t(`payments.${this.i18nHeadingName}`)}}</h1>
          <h5>{{$t('payments.great_courses')}}</h5>
        </div>
        <div class="row info-row">
          <div class="col-md-3">
            <div class="text-center">
              <img src="/images/pages/home/type_real_code.png" />
            </div>
          </div>
          <div class="col-md-3 info-data">
            <h2>CodeCombat</h2>
            <ul class="info-list">
              <li>Computer Science 1-6</li>
              <li>Web Development 1-2</li>
              <li>Game Development 1-2</li>
            </ul>
          </div>
          <div class="col-md-3">
            <div class="text-center">
              <img src="/images/pages/home/ozaria_acodus.png" />
            </div>
          </div>
          <div class="col-md-3 info-data">
            <h2>Ozaria</h2>
            <ul class="info-list">
              <li>Comprehensive Introduction to Computer Science</li>
              <li>Chapters 1-4</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: "PaymentStudentLicenseHeadComponent",
  props: {
    i18nHeadingName: String,
  },
}
</script>

<style scoped lang="scss">
.container-fluid {
  background: linear-gradient(118.13deg, #0E4C60 0%, #20572B 100%);
  color: white;
}

.top-section {
  padding: 20px 20px 50px;

  h1, h3, h5 {
    font-weight: bold;
    color: white;
  }

  .info-row {
    padding: 20px 5px 5px;

    img {
      max-width:100%;
      max-height:100%;
    }
  }

  .info-data {
    text-align: left;

    h2 {
      color: lawngreen;
      font-weight: bold;
    }
    padding-left: 0;
  }
}


</style>
