<template>
  <modal
    :title="$t('new_home.try_ozaria')"
    @close="$emit('close')"
  >
    <div class="try-oz-modal">
      <div
        class="heading"
      >
        <h3>
          {{ $t('teacher.ozaria_intro') }}
        </h3>
      </div>
      <div class="cta">
        <ozaria-c-t-a />
        <a
          class="btn dusk-btn try-ozaria-btn"
          href="https://ozaria.com"
          rel="external noopener noreferrer"
          target="_blank"
          @click="trackEvent"
        >
          {{ $t("teacher.try_ozaria_free") }}
        </a>
      </div>
    </div>
  </modal>
</template>

<script>
import Modal from 'app/components/common/Modal.vue'
import OzariaCTA from './OzariaCTA.vue'

export default Vue.extend({
  name: 'TryOzariaModal',
  components: {
    Modal,
    OzariaCTA
  },
  methods: {
    trackEvent () {
      window.tracker.trackEvent('Try ozaria cta clicked')
    }
  }
})
</script>

<style lang="scss" scoped>
@import "ozaria/site/styles/common/variables.scss";
@import "ozaria/site/components/teacher-dashboard/common/_dusk-button";
.try-oz-modal {
  background-color: #F7D047;
  background: linear-gradient(59.36deg, #D1B147 -5.07%, #D1B147 16.64%, #F7D047 93.04%, #F7D047 103.46%);

  .heading {
    display: flex;
    align-items: center;
    flex-direction: column;
    margin-bottom: 10px;
    padding: 10px;

    h3 {
      font-size: 20px;
      line-height: 24px;
    }
  }

  .try-ozaria-btn {
    padding: 25px;
    font-size: 20px;
  }
}
</style>
