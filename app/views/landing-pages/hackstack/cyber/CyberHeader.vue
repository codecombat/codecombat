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
              src="/images/pages/hackstack/cyber/hackstack-logo.png"
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
  position: relative;
  isolation: isolate;
  overflow: hidden;
  background: #021e27;
  padding: 60px 60px 80px;

  // source image is a 1440x1440 square with transparent wedges top and bottom;
  // proportional right-aligned crop keeps the opaque cube band covering the
  // section and the bright glow right-of-center at all desktop widths
  &::before {
    content: "";
    position: absolute;
    inset: 0;
    z-index: 0;
    pointer-events: none;
    background-image: url(/images/pages/roblox/header-background.png);
    background-repeat: no-repeat;
    background-position: right -21.6vw;
    background-size: 120vw auto;
  }

  &::after {
    content: "";
    position: absolute;
    inset: 0;
    z-index: 0;
    pointer-events: none;
    background: linear-gradient(to top, rgba(2, 30, 39, 0.72), transparent 25%);
  }

  ::v-deep .frame {
    z-index: 1;
  }

  @media (max-width: $screen-md-max) {
    padding: 60px 40px 80px;
  }

  @media (max-width: $screen-sm-max) {
    &::before {
      // crop the central opaque band; mirror so the glow sits away from the text
      top: -30%;
      bottom: -30%;
      background-size: auto 100%;
      background-position: 15% center;
      transform: scaleX(-1);
    }
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
    gap: 24px;
  }
}

.hero__text {
  flex: 1;
  text-align: left;
  position: relative;
  isolation: isolate;

  // localized contrast backstop instead of a broad wash over the whole image
  &::before {
    content: "";
    position: absolute;
    inset: -32px -48px;
    z-index: -1;
    pointer-events: none;
    background: radial-gradient(
      ellipse at center,
      rgba(2, 30, 39, 0.58) 0 55%,
      rgba(2, 30, 39, 0.2) 72%,
      transparent 100%
    );
  }
}

.hero__media {
  flex: 1.1;
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
    max-height: 52px;
    width: auto;

    @media screen and (max-width: $screen-sm) {
      max-height: 40px;
    }
  }
}

.content {
  @extend %font-28;
  color: #B4B4B4;
  margin: 24px 0 32px;
}

.aligned {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 40px;

  @media (max-width: $screen-sm-max) {
    flex-wrap: wrap;
  }

  &__text {
    @media (max-width: $screen-sm-max) {
      flex-basis: 100%;
    }
  }

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
  gap: 40px;
  flex-wrap: wrap;

  ::v-deep .CTA__button {
    font-size: 20px;
  }

  // keep the two CTAs side by side down to tablet widths
  @media (max-width: 1280px) {
    gap: 24px;

    ::v-deep .CTA__button {
      min-width: unset;
    }
  }

  @media screen and (max-width: $screen-sm) {
    gap: 16px;
    justify-content: center;
    margin-bottom: 8px;
  }
}
</style>
