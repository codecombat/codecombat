<template>
  <div class="content">
    <p class="heading">
      {{ $t('codequest_page.frame_content_heading') }}
    </p>
    <div class="data-text">
      <div class="data">
        <div class="div">
          <div class="frame">
            <img
              class="flight"
              alt="Flight"
              src="/images/pages/codequest/frame/flight.svg"
            >
            <div class="title">
              {{ $t('codequest_page.frame_content_flight_title') }}
            </div>
          </div>
          <p class="supporting-text">
            {{ $t('codequest_page.frame_content_flight_text') }}
          </p>
        </div>
      </div>
      <div class="data">
        <div class="div">
          <div class="frame">
            <img
              class="hotel"
              alt="Hotel"
              src="/images/pages/codequest/frame/hotel.svg"
            >
            <div class="title">
              {{ $t('codequest_page.frame_content_hotel_title') }}
            </div>
          </div>
          <p class="supporting-text">
            {{ $t('codequest_page.frame_content_hotel_text') }}
          </p>
        </div>
      </div>
      <div class="data">
        <div class="div">
          <div class="frame">
            <img
              class="meal"
              alt="Meal"
              src="/images/pages/codequest/frame/meal.svg"
            >
            <div class="title">
              {{ $t('codequest_page.frame_content_meal_title') }}
            </div>
          </div>
          <p class="supporting-text">
            {{ $t('codequest_page.frame_content_meal_text') }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ContentComponent'
}
</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";
.content {
  align-items: center;
  display: flex;
  flex-direction: column;
  gap: 40px;
  justify-content: center;
  position: relative;

  .heading {
    color: #000000;
    font-family: "Plus Jakarta Sans-Medium", Helvetica;
    font-size: 28px;
    font-weight: 500;
    letter-spacing: 0;
    line-height: 36px;
    margin-top: -1px;
    position: relative;
    text-align: center;
  }

  .data-text {
    align-items: stretch;
    display: flex;
    gap: 30px;
    justify-content: center;
    padding: 0px 40px;
    position: relative;

    @media (max-width: $screen-md-max) {
      flex-direction: column;
      align-items: center;
      gap: 60px;
    }

    >div {
      flex: 1;
    }
  }

  .data {
    align-items: flex-start;
    display: inline-flex;
    flex-direction: column;
    gap: 30px;
    justify-content: center;
    position: relative;
    width: 100%;
  }

  .div {
    align-items: flex-start;
    display: inline-flex;
    flex-direction: column;
    gap: 20px;
    justify-content: center;
    position: relative;
  }

  .frame {
    align-items: center;
    display: inline-flex;

    gap: 20px;
    position: relative;
  }

  .flight {
    height: 70px;
    position: relative;
    width: 69.24px;
  }

  .title {
    color: var(--dark);
    font-family: "Plus Jakarta Sans-Bold", Helvetica;
    font-size: 20px;
    font-weight: 700;
    letter-spacing: 0;
    line-height: 36px;
    position: relative;
    width: fit-content;
  }

  .supporting-text {
    color: #000000;
    font-family: "Plus Jakarta Sans-Regular", Helvetica;
    font-size: 18px;
    font-weight: 400;
    letter-spacing: 0;
    line-height: 24px;
    position: relative;
  }

  .hotel {
    height: 70px;
    position: relative;
    width: 96.96px;
  }

  .meal {
    height: 70px;
    position: relative;
    width: 105.08px;
  }
}
</style>
