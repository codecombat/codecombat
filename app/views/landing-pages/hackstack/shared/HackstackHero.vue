<template>
  <PageSection :class="['section', `section--${variant}`]">
    <template #heading>
      <template v-if="variant === 'algebra'">
        <h1 class="header-title">
          {{ title }}
        </h1>
        <div class="header-subtitle">
          <span class="header-subtitle__text">{{ poweredByLabel }}</span>
          <img
            class="header-subtitle__image"
            :src="logoSrc"
            :alt="logoAlt"
          >
        </div>
      </template>
    </template>
    <template #body>
      <div
        v-if="variant === 'cyber'"
        class="hero"
      >
        <div class="hero__text">
          <h1 class="header-title">
            {{ title }}
          </h1>
          <div class="header-subtitle">
            <span class="header-subtitle__text">{{ poweredByLabel }}</span>
            <img
              class="header-subtitle__image"
              :src="logoSrc"
              :alt="logoAlt"
            >
          </div>
          <p class="content">
            {{ description }}
          </p>
          <div
            v-if="badges.length || alignmentText"
            class="aligned"
          >
            <img
              v-for="badge in badges"
              :key="badge.src"
              class="aligned__badge"
              :src="badge.src"
              :alt="badge.alt"
            >
            <span
              v-if="alignmentText"
              class="aligned__text"
            >{{ alignmentText }}</span>
          </div>
          <div class="btns">
            <slot name="actions" />
          </div>
        </div>
        <div
          v-if="mediaSrc"
          class="hero__media"
        >
          <img
            class="hero__image"
            :src="mediaSrc"
            :alt="mediaAlt"
          >
        </div>
      </div>
    </template>
    <template #tail>
      <template v-if="variant === 'algebra'">
        <p class="content">
          {{ description }}
        </p>
        <div class="btns-group">
          <div class="btns">
            <slot name="actions" />
          </div>
        </div>
      </template>
    </template>
  </PageSection>
</template>

<script>
import PageSection from 'app/components/common/elements/PageSection.vue'

export default {
  name: 'HackstackHero',
  components: {
    PageSection,
  },
  props: {
    variant: {
      type: String,
      required: true,
      validator: value => ['algebra', 'cyber'].includes(value),
    },
    title: {
      type: String,
      required: true,
    },
    poweredByLabel: {
      type: String,
      required: true,
    },
    logoSrc: {
      type: String,
      required: true,
    },
    logoAlt: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: true,
    },
    badges: {
      type: Array,
      default: () => [],
    },
    alignmentText: {
      type: String,
      default: null,
    },
    mediaSrc: {
      type: String,
      default: null,
    },
    mediaAlt: {
      type: String,
      default: '',
    },
  },
}
</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";
@import "app/styles/component_variables.scss";

.section--algebra {
  background: linear-gradient(to top, #05262f 0%, #021e27 3%, #021e27 20%, transparent 50%),url(/images/pages/roblox/header-background.png) 0px -400px / 120% no-repeat, #021e27;
  text-align: center;

  @media (max-width: 768px) {
    background: linear-gradient(to top, #05262f 0%, #021e27 3%, #021e27 20%, transparent 50%),url(/images/pages/roblox/header-background.png) center -200px / 250% no-repeat, #021e27;
  }

  @media screen and (max-width: $screen-sm) {
    padding-top: 60px;
    padding-bottom: 0;
  }

  ::v-deep .frame {
    gap: 30px;

    @media screen and (max-width: $screen-sm) {
      gap: 16px;
    }
  }

  .header-title {
    @extend %font-44;
  }

  .header-subtitle {
    justify-content: center;

    &__image {
      max-height: 72px;

      @media screen and (max-width: $screen-sm) {
        max-height: 48px;
      }
    }
  }

  .content {
    @extend %font-24-30;
    max-width: 700px;
    margin: 0 auto 40px;

    @media screen and (max-width: $screen-sm) {
      margin-bottom: 24px;
    }
  }

  .btns-group {
    display: flex;
    justify-content: center;
    margin-bottom: 20px;
  }

  .btns {
    max-width: 700px;
    width: 100%;
    justify-content: center;
    gap: 50px;

    @media screen and (max-width: $screen-sm) {
      gap: 16px;
    }
  }
}

.section--cyber {
  position: relative;
  isolation: isolate;
  overflow: hidden;
  background: #021e27;
  padding: 60px 60px 80px;

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

  .header-title {
    @extend %font-64-80;
  }

  .header-subtitle {
    &__image {
      max-height: 52px;

      @media screen and (max-width: $screen-sm) {
        max-height: 40px;
      }
    }
  }

  .content {
    @extend %font-28;
    margin: 24px 0 32px;
  }

  .btns {
    gap: 40px;

    ::v-deep .CTA__button {
      font-size: 20px;
    }

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
    width: auto;
  }
}

.content {
  color: #B4B4B4;
}

.aligned {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 40px;

  @media (max-width: $screen-sm-max) {
    flex-wrap: wrap;
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

    @media (max-width: $screen-sm-max) {
      flex-basis: 100%;
    }
  }
}

.btns {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
}
</style>
