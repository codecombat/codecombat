<template>
  <PageSection class="section">
    <template #heading>
      <h1 class="header-title">
        {{ $t('hackstack_algebra_page.header') }}
      </h1>
      <div class="header-subtitle">
        <span class="header-subtitle__text">{{ $t('hackstack_algebra_page.header_powered_by') }}</span>
        <img
          class="header-subtitle__image"
          src="/images/pages/hackstack/hackstack-banner-black.png"
          alt="AI Hackstack"
        >
      </div>
    </template>
    <template #tail>
      <p class="content">
        {{ isTeacher() ? $t('hackstack_algebra_page.header_details_teacher') : $t('hackstack_algebra_page.header_details') }}
      </p>
      <div class="btns-group">
        <div class="btns">
          <CTAButton
            class="cta-button"
            @clickedCTA="onGetSolution"
          >
            {{ $t('hackstack_algebra_page.cta_get_solution') }}
          </CTAButton>
          <CTAButton
            class="cta-button"
            @clickedCTA="onExplore"
          >
            {{ $t('hackstack_algebra_page.cta_explore') }}
          </CTAButton>
        </div>
      </div>
    </template>
  </PageSection>
</template>

<script>
import PageSection from 'app/components/common/elements/PageSection.vue'
import CTAButton from 'app/components/common/buttons/CTAButton.vue'
import { mapGetters, mapActions } from 'vuex'

export default {
  name: 'AlgebraHeader',
  components: {
    PageSection,
    CTAButton,
  },
  computed: {
    ...mapGetters({
      isPaidTeacher: 'me/isPaidTeacher',
    }),
  },
  async created () {
    if (typeof me !== 'undefined' && me.isTeacher()) {
      await this.fetchTeacherPrepaids({ teacherId: me.get('_id') })
    }
  },
  methods: {
    ...mapActions({
      fetchTeacherPrepaids: 'prepaids/fetchPrepaidsForTeacher',
    }),
    isTeacher () {
      return typeof me !== 'undefined' && me.isTeacher()
    },
    onGetSolution () {
      this.$emit('open-modal')
    },
    onExplore () {
      this.$emit('open-signup-modal')
    },
  },
}
</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";
@import "app/styles/component_variables.scss";

.section {
  background: linear-gradient(to bottom, var(--color-section-bg-70) 0%, var(--color-section-bg) 100%), url(/images/pages/hackstack/header-background.png) center / cover no-repeat, var(--color-section-bg);
  text-align: center;
}

.header-title {
  @extend %font-44;
  color: white;
  margin-bottom: 8px;
}

.header-subtitle {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;

  &__text {
    @extend %font-40;
    color: white;
  }

  &__image {
    max-height: 72px;
    width: auto;
  }
}

.content {
  @extend %font-24-30;
  color: #B4B4B4;
  max-width: 700px;
  margin: 0 auto 40px;
}

.btns-group {
  display: flex;
  justify-content: center;
}

.btns {
  max-width: 700px;
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 50px;
  flex-wrap: wrap;
}

.cta-button {
  margin-bottom: 80px;
}
</style>
