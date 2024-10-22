<template>
  <ModalDynamicContent
    ref="modal"
    :auto-show="false"
  >
    <template #content>
      <div class="ozar-hs-modal-content">
        <h3 class="text-h3">
          {{ $t('teacher_dashboard.ozaria_ai_league_modal_title') }}
        </h3>
        <p>
          <mixed-color-label
            :text="$t('teacher_dashboard.ozaria_ai_league_modal_blurb')"
          />
        </p>
        <a
          href="https://codecombat.com/teachers/ai-league"
          target="_blank"
        >
          <img src="/images/ozaria/teachers/dashboard/png_img/import-classroom.webp">
        </a>
        <div class="continue">
          <a
            class="btn btn-primary btn-lg dusk-btn"
            href="https://codecombat.com/teachers/ai-league"
            target="_blank"
          >
            {{ $t('home_v3.try_it_now') }}
          </a>
        </div>
      </div>
    </template>
  </ModalDynamicContent>
</template>

<script>
import ModalDynamicContent from 'ozaria/site/components/teacher-dashboard/modals/ModalDynamicContent.vue'
import MixedColorLabel from 'app/components/common/labels/MixedColorLabel.vue'

export default {
  name: 'OzariaAILeagueModal',
  components: {
    ModalDynamicContent,
    MixedColorLabel
  },
  methods: {
    openModal () {
      this.$refs.modal.openModal()
    },
  },
}
</script>

<style lang="scss" scoped>
@import "ozaria/site/styles/common/variables.scss";
@import "ozaria/site/components/teacher-dashboard/common/_dusk-button";
.ozar-hs-modal-content {
  max-width: min(600px, 90vw);
  .text-h3 {
    font-size: 24px;
    margin: 10px auto 10px;
  }
  img {
    max-width: 100%;
  }

  .continue {
    display: flex;
    justify-content: center;
    margin-top: 20px;
  }
}
</style>
