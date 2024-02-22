<template>
  <modal>
    <div class="promo teacher-modal">
      <div class="promo__header text-center">
        {{ $t('teacher.student_end_of_completion_free') }}
      </div>
      <div class="promo__body">
        <div class="promo__head text-center">
          {{ $t('teacher.unlock_licenses_for_student') }}
        </div>
        <div class="container promo__content">
          <div class="row">
            <div class="col-sm-6 text-center promo__content__title">
              {{ $t('teacher.core_curriculum') }}
            </div>
            <div class="col-sm-6 text-center promo__content__title">
              {{ $t('teacher.practice_apply') }}
            </div>
          </div>
          <div class="row">
            <div class="col-sm-6 promo__content__box text-center">
              <div class="promo__container">
                <picture class="promo__img">
                  <source
                    srcset="/images/common/modal/oz-promo.webp"
                    type="image/webp"
                  >
                  <img
                    src="/images/common/modal/oz-promo.png"
                    alt="Ozaria classroom"
                  >
                </picture>
                <div class="promo__content__text">
                  {{ $t('nav.ozaria_classroom') }}
                </div>
              </div>
              <div class="promo__container">
                <picture class="promo__img">
                  <source
                    srcset="/images/common/modal/coco-promo.webp"
                    type="image/webp"
                  >
                  <img
                    src="/images/common/modal/coco-promo.png"
                    alt="CodeCombat classroom"
                  >
                </picture>
                <div class="promo__content__text">
                  {{ $t('nav.codecombat_classroom') }}
                </div>
              </div>
            </div>
            <div class="col-sm-6 promo__content__box text-center">
              <div class="promo__container">
                <picture class="promo__img">
                  <source
                    srcset="/images/common/modal/ai-league-promo.webp"
                    type="image/webp"
                  >
                  <img
                    src="/images/common/modal/ai-league-promo.png"
                    alt="AI League Esports"
                  >
                </picture>
                <div class="promo__content__text">
                  {{ $t('teacher.ai_league_esports') }}
                </div>
              </div>
              <div class="promo__container">
                <picture class="promo__img">
                  <source
                    srcset="/images/roblox/live_background.webp"
                    type="image/webp"
                  >
                  <img
                    src="/images/roblox/live_background.png"
                    alt="CodeCombat Worlds"
                  >
                </picture>
                <div class="promo__content__text">
                  {{ $t('new_home.coco_worlds_header') }}
                </div>
              </div>
            </div>
          </div>
        </div>
        <div class="promo__content">
          <div class="row">
            <div class="promo__content__title text-center">
              {{ $t('teacher.student_acceleration') }}
            </div>
          </div>
          <div class="row">
            <div class="promo__content__box promo__content__box-2">
              <div class="promo__container text-center">
                <picture class="promo__img promo__img-2">
                  <source
                    srcset="/images/common/modal/ai-hackstack-promo.png"
                    type="image/webp"
                  >
                  <img
                    src="//images/common/modal/ai-hackstack-promo.png"
                    alt="AI Hackstack"
                  >
                </picture>
                <div class="promo__content__text">
                  {{ $t('teacher.ai_hackstack') }}
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="promo__info text-center">
          <div class="promo__info__text">
            {{ $t('teacher.gain_access_assist') }}
          </div>
        </div>
      </div>

      <div class="promo__footer text-center">
        <div class="promo__footer__container">
          <button
            class="promo__request btn yellow-btn-black-text"
            @click="$emit('requestedQuote')"
          >
            {{ $t('payments.request_quote') }}
          </button>
        </div>
      </div>
    </div>
  </modal>
</template>
<script>
import Modal from 'app/components/common/Modal'
export default Vue.extend({
  name: 'TeacherStudentsCompletionCoursePromotionModal',
  components: {
    Modal
  }
})
</script>
<style lang="scss" scoped>
$teal-light-2: #6AE8E3;
$teal-dark: #0e4c60;
$yellow: #f2be19;
$color-yellow-1: #F7D047;
.promo {
  margin: -5px;
  &__header {
    background-color: $teal-light-2;
    padding: 10px;
    font-size: 25px;
    font-weight: bold;
    color: $teal-dark;
  }

  &__body {
    padding: 15px;
  }

  &__head {
    color: $teal-dark;
    &::after {
      content: "";
      height: 1px;
      background: $teal-light-2;
      display: block;
      width: 100%;
      margin-top: 5px;
    }
  }

  &__img {
    & > * {
      width: 165px;
    }
  }

  &__content {
    padding: 10px !important;
    &__box {
      display: flex;
      justify-content: space-between;

      &-2 {
        display: flex;
        justify-content: center;
      }
    }

    & > * {
      margin-bottom: 5px;
    }

    &__title {
      color: $teal-dark;
      font-size: 18px;
    }

    &__text {
      font-size: 14px;
      font-weight: bold;
      background: $yellow;
      padding-top: 5px;
      padding-bottom: 5px;
    }
  }

  &__container {
    margin-right: 10px;

    &-2 {
      display: flex;
      justify-content: center;
    }
  }

  &__info {
    display: flex;
    justify-content: center;
    margin-top: 5px;
    &__text {
      width: 650px;
      font-size: 15px;
      color: $teal-dark;
    }
  }

  &__footer {
    padding: 10px;
    background-color: $teal-light-2;
    display: flex;
    justify-content: center;
    margin-top: -10px;
  }
}

.text-center {
  text-align: center;
}
.yellow-btn-black-text {
  background: $color-yellow-1;
  border-radius: 1px;
  font-weight: 600;
  font-size: 1.6rem;
  line-height: 1.7rem;
  letter-spacing: 0.333333px;
  color: #131B25;
  padding: 1rem 2.5rem;
  border-color: #ffffff;
}
</style>
