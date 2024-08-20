<script>
import ModalDynamicContent from './ModalDynamicContent'
import trackable from 'app/components/mixins/trackable.js'

export default Vue.extend({
  components: {
    ModalDynamicContent
  },
  mixins: [trackable],
  props: {
    href: {
      type: String,
      required: true
    }
  },
  computed: {
    showModal () {
      const twoDaysAgo = new Date(new Date() - 2 * 24 * 60 * 60 * 1000)
      return new Date(me.get('dateCreated')) < twoDaysAgo
    }
  },
  methods: {
    onTryItNow () {
      this.$emit('tryClicked')
      this.$refs.modal.onClose()
      this.trackEvent('AI HackStack Promo Modal: Try It Now clicked', { category: 'Teachers' })
    },
  }
})
</script>

<template>
  <div>
    <ModalDynamicContent
      v-if="showModal"
      ref="modal"
      seen-promotions-property="hackstack-beta-release-modal"
    >
      <template #content>
        <div class="ai-modal-content-container">
          <h2 class="text-h2">
            {{ $t('teachers.start_teaching_ai_today') }}
          </h2>
          <img
            src="/images/common/modal/ai-hs-beta.webp"
            :alt="$t('teachers.hackstack_beta_release')"
          >
          <p class="text-p">
            {{ $t('teachers.introducing_ai_hackstack') }}
          </p>
          <p class="text-p">
            {{ $t('teachers.our_curriculum_empowers_students') }}
          </p>

          <a
            class="btn btn-primary btn-lg btn-moon"
            :href="href"
            @click="onTryItNow()"
          >
            {{ $t('home_v3.try_it_now') }}
          </a>
        </div>
      </template>
    </ModalDynamicContent>
  </div>
</template>

<style lang="scss" scoped>
@import 'app/styles/core/variables.scss';
@import 'app/styles/common/_button.scss';

.ai-modal-content-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 10px 60px;
  text-align: center;

  .text-h2 {
    font-weight: bold;
  }

  >* {
    max-width: 800px;
  }

  img {
    width: 100%;
    max-width: 600px;
    margin: 10px auto;
  }
}
</style>
