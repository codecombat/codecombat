<template>
  <modal
    :title="$t('parents_landing_2.live_classes')"
    @close="$emit('close')"
  >
    <div
      class="loc-modal"
    >
      <div class="header row">
        {{ $t('parents_landing_2.get_free_coding_class') }}
      </div>
      <div class="row body">
        <div class="promo col-md-6">
          <img
            src="/images/pages/parents/personal_learning.png"
            alt="teacher and student playing codecombat"
            class="promo-img"
          >
        </div>
        <div class="col-md-6">
          <ul class="points">
            <li class="point">
              {{ $t('parents_landing_2.personalized_coding') }}
            </li>
            <li class="subpoint">
              {{ $t('parents_landing_2.tailored_guidance') }}
            </li>
            <li class="point">
              {{ $t('parents_landing_2.premium_access') }}
            </li>
            <li class="subpoint">
              {{ $t('parents_landing_2.enjoy_all_games') }}
            </li>
            <li class="point">
              {{ $t('parents_landing_2.focus_choice') }}
            </li>
            <li class="subpoint">
              {{ $t('parents_landing_2.choice_of_path') }}
            </li>
          </ul>
        </div>
      </div>
      <div class="row footer">
        <div class="classes-lang">
          {{ $t('parents_landing_2.classes_in_spanish_english') }}
        </div>
        <div class="book">
          <a
            href="/parents"
            target="_blank"
          >
            <button
              class="btn btn-success btn-lg"
            >
              {{ $t('parents_landing_2.free_class') }}
            </button>
          </a>
        </div>
      </div>
    </div>
  </modal>
</template>
<script>
import Modal from 'app/components/common/Modal'

export default Vue.extend({
  name: 'LiveOnlineClassesPromotionModal',
  components: {
    Modal
  },
  methods: {
    onBookClass () {
      window.tracker?.trackEvent('Post-pay loc class clicked')
    }
  }
})
</script>
<style scoped lang="scss">
@import "app/styles/bootstrap/variables";
.loc-modal {
  width: 700px;

  @media screen and (min-width: $screen-lg) {
    width: 900px;
  }
  .header {
    text-align: center;
    font-size: 25px;
    font-weight: bold;
    padding: 15px;
  }

  .promo {
    display: flex;
    justify-content: center;
  }

  .promo-img {
    width: 400px;
  }
  .subpoint {
    list-style-type: circle;
    margin-left: 15px;
  }
  .point {
    font-weight: bold;
  }
  .classes-lang {
    font-weight: bold;
  }

  .footer {
    padding: 10px;

    & > * {
      display: flex;
      justify-content: center;
    }
  }

  .book {
    margin-top: 10px;
  }
}
</style>
