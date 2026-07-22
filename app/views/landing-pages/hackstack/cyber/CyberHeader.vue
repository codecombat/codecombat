<template>
  <PageSection class="section">
    <template #body>
      <div class="hero">
        <div class="hero__text">
          <h1 class="header-title">
            {{ $t('hackstack_cyber_page.header') }}
          </h1>
          <div class="header-subtitle">
            <span class="header-subtitle__text">{{ $t('hackstack_cyber_page.header_powered_by') }}</span>
            <img
              class="header-subtitle__image"
              src="/images/pages/hackstack/hackstack-banner-black.png"
              alt="AI HackStack"
            >
          </div>
          <p class="content">
            {{ $t('hackstack_cyber_page.header_details') }}
          </p>
          <div class="aligned">
            <img
              class="aligned__badge"
              src="/images/pages/hackstack/cyber/comptia-security-plus.png"
              alt="CompTIA Security+"
            >
            <img
              class="aligned__badge"
              src="/images/pages/hackstack/cyber/ap-collegeboard.jpg"
              alt="AP College Board"
            >
            <span class="aligned__text">{{ $t('hackstack_cyber_page.header_aligned') }}</span>
          </div>
          <div class="btns">
            <CTAButton
              v-if="!isPaidTeacherAccount"
              class="cta-button"
              @clickedCTA="onGetSolution"
            >
              {{ $t('hackstack_cyber_page.cta_get_solution') }}
            </CTAButton>
            <CTAButton
              v-if="isAnonymous()"
              class="cta-button"
              @clickedCTA="onExplore"
            >
              {{ $t('hackstack_cyber_page.cta_explore') }}
            </CTAButton>
            <CTAButton
              v-else
              href="/teachers/guide/hackstack/cyber"
              class="cta-button"
            >
              {{ $t('hackstack_cyber_page.cta_explore') }}
            </CTAButton>
          </div>
        </div>
        <div class="hero__media">
          <img
            class="hero__image"
            src="/images/pages/hackstack/cyber/hero-simulation.png"
            alt="IT Help Desk Simulation"
          >
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
  name: 'CyberHeader',
  components: {
    PageSection,
    CTAButton,
  },
  computed: {
    ...mapGetters({
      isPaidTeacher: 'me/isPaidTeacher',
    }),
    isPaidTeacherAccount () {
      return this.isTeacher() && this.isPaidTeacher
    },
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
    isAnonymous () {
      return typeof me === 'undefined' || me.isAnonymous()
    },
    isTeacher () {
      return typeof me !== 'undefined' && me.isTeacher()
    },
    onGetSolution () {
      window.open('/schools?openContactModal=true', '_blank', 'noopener,noreferrer')
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
  // left gradient keeps text readable over the bright cubes at every width
  background:
    linear-gradient(to right, rgba(2, 30, 39, 0.9) 0%, rgba(2, 30, 39, 0.5) 40%, transparent 65%),
    linear-gradient(to top, #021e27 0%, transparent 30%),
    url(/images/pages/roblox/header-background.png) center top / cover no-repeat,
    #021e27;
  padding: 60px 60px 80px;

  @media (max-width: $screen-md-max) {
    padding: 60px 40px 80px;
  }

  @media (max-width: $screen-sm-max) {
    background:
      linear-gradient(rgba(2, 30, 39, 0.75), rgba(2, 30, 39, 0.75)),
      url(/images/pages/roblox/header-background.png) center top / cover no-repeat,
      #021e27;
  }

  @media screen and (max-width: $screen-sm) {
    padding-top: 60px;
    padding-bottom: 0;
  }

  ::v-deep .frame > div:empty {
    display: none;
  }

  ::v-deep .body {
    max-width: 1320px;
    padding-left: 0;
    padding-right: 0;
  }
}

.hero {
  display: flex;
  align-items: center;
  gap: 40px;
  width: 100%;

  @media (max-width: $screen-sm-max) {
    flex-direction: column;
  }
}

.hero__text {
  flex: 1;
  text-align: left;
}

.hero__media {
  flex: 1;
  min-width: 0;
}

.hero__image {
  width: 100%;
  height: auto;
  display: block;
  border-radius: 8px;
}

.header-title {
  @extend %font-64-80;
  color: white;
  margin-bottom: 8px;
}

.header-subtitle {
  display: flex;
  align-items: center;
  gap: 12px;

  &__text {
    @extend %font-40;
    color: white;
  }

  &__image {
    max-height: 72px;
    width: auto;

    @media screen and (max-width: $screen-sm) {
      max-height: 48px;
    }
  }
}

.content {
  @extend %font-24-30;
  color: #B4B4B4;
  margin: 24px 0 32px;
}

.aligned {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 40px;

  &__badge {
    height: 72px;
    width: auto;

    @media screen and (max-width: $screen-sm) {
      height: 56px;
    }
  }

  &__text {
    @extend %font-18-24;
    color: #B4B4B4;
    white-space: pre-line;
  }
}

.btns {
  display: flex;
  align-items: center;
  gap: 24px;
  flex-wrap: wrap;

  // keep the two CTAs side by side down to tablet widths
  @media (max-width: 1280px) {
    ::v-deep .CTA__button {
      min-width: unset;
    }
  }

  @media screen and (max-width: $screen-sm) {
    gap: 16px;
    margin-bottom: 24px;
  }
}
</style>
