<template>
  <div class="carousel-component">
    <div
      class="content-template-carousel"
      :class="{ 'has-background': hasBackground }"
    >
      <div
        v-if="showTabs"
        class="carousel-tabs content-tabs"
      >
        <button
          v-for="(item, index) in items"
          :key="'tab' + index"
          class="content-point"
          @click="goTo(index)"
        >
          <div
            class="content-bg"
            :class="{ active: currentIndex === index }"
          >
            <div
              v-if="item.tabImage"
              class="content-image"
            >
              <img
                :src="item.tabImage"
                :alt="item.title"
              >
            </div>
            <div
              v-else
              class="content-text"
            >
              <div
                v-for="(line, lineIndex) in String(item.title).split('[NEWLINE]')"
                :key="`line-${lineIndex}`"
              >
                {{ line }}
              </div>
            </div>
          </div>
        </button>
      </div>

      <div class="carousel-item-container">
        <div
          v-for="(item, index) in items"
          :key="'item' + index"
          class="carousel-item"
          :class="{ active: currentIndex === index }"
          :style="currentIndex === index ? 'order: 1;' : `order: ${index + 2};`"
        >
          <div
            class="content-details"
            :class="{ 'has-background': hasBackground }"
          >
            <div
              v-if="item.image"
              class="content-icon-container"
            >
              <img
                class="content-icon"
                :src="item.image"
                :alt="item.alt || item.title"
              >
            </div>
            <div class="content-text">
              <p class="content-title">
                {{ String(item.title).replace('[NEWLINE]', ' ') }}
              </p>
              <div class="content-text">
                <slot :name="item.key" />
              </div>
            </div>
          </div>
        </div>
      </div>

      <div :class="{ 'carousel-dots': true, 'carousel-tabs-default': showDots }">
        <img
          :src="`/images/components/arrow${currentIndex <= 0 ? '-light' : ''}.svg`"
          :alt="`Arrow to go to the previous item in the carousel${currentIndex <= 0 ? ' - disabled' : ''}`"
          @click="goTo(currentIndex - 1)"
        >
        <button
          v-for="(item, index) in items"
          :key="'dot' + index"
          :class="{ active: currentIndex === index }"
          @click="goTo(index)"
        >
          {{ index + 1 }}
        </button>
        <img
          :src="`/images/components/arrow${currentIndex >= items.length - 1 ? '-light' : ''}.svg`"
          :alt="`Arrow to go to the next item in the carousel${currentIndex >= items.length - 1 ? ' - disabled' : ''}`"
          @click="goTo(currentIndex + 1)"
        >
      </div>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    showTabs: {
      type: Boolean,
      default: false
    },
    showDots: {
      type: Boolean,
      default: false
    },
    hasBackground: {
      type: Boolean,
      default: true
    }
  },
  data () {
    return {
      currentIndex: 0
    }
  },
  computed: {
    items () {
      return Object.entries(this.$slots).map(([key, value]) => {
        return {
          key,
          title: value[0].componentOptions.propsData.title,
          image: value[0].componentOptions.propsData.image,
          tabImage: value[0].componentOptions.propsData.tabImage,
        }
      })
    }
  },
  methods: {
    goTo (index) {
      if (index >= 0 && index < this.items.length) {
        this.currentIndex = index
      }
    }
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/component_variables.scss";

.carousel-tabs>button.active,
.carousel-dots {
  width: 100%;
  justify-content: center;
  gap: 16px;
  display: none;

  @media screen and (max-width: 768px) {
    display: flex;
  }

  &.carousel-tabs-default {
    display: flex;
  }

  img {
    cursor: pointer;

    &:first-child {
      transform: rotate(180deg);
    }
  }

  >button {
    display: block;
    width: 16px;
    height: 16px;
    border-radius: 16px;
    border: none;
    color: transparent;
    background-color: $light-purple;

    &.active {
      background-color: $purple;
    }
  }
}

.content-template-carousel {
  position: relative;
  justify-content: center;
  display: flex;
  box-sizing: border-box;
  min-height: 365px;
  margin-bottom: 20px;
  width: 100%;

  &.has-background {
    gap: 40px;
  }

  flex-direction: column;

  @media screen and (max-width: 768px) {
    padding-top: 33px;
  }
}

.content-details {
  padding-top: 60px;
  padding-bottom: 60px;
  padding-right: 70px;
  padding-left: 70px;
  height: 100%;
  box-sizing: border-box;
  width: 100%;
  text-align: left;
  border-radius: 24px;

  &.has-background {
    background: #F9F9FF;
    box-shadow: 0px 4px 24px 0px rgba(0, 0, 0, 0.12);
  }

  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 40px;

  @media screen and (max-width: 768px) {
    padding-left: 0px;
    padding-right: 0px;
  }

  @media screen and (max-width: 768px) {
    flex-direction: column;
  }

  >* {
    flex: 1;

    @media screen and (max-width: 768px) {
      margin-right: 30px;
      margin-left: 30px;
    }
  }
}

.content-icon-container {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 10px;

  @media screen and (max-width: 768px) {
    width: calc(100% - 60px);
  }
}

.content-icon {
  width: 100%;
  border-radius: 24px;
}

.content-text {
  @extend %font-18-24;

  width: 100%;
  position: relative;
  font-weight: 400;
  align-items: flex-start;
  flex-direction: column;
  display: flex;
  height: 100%;

  @media screen and (max-width: 768px) {
    gap: 14px;
    width: auto;
  }

  p {
    @extend %font-18-24;
    display: inline;
  }

  .content-title {
    @extend %font-32-46;
    font-style: normal;
    font-weight: 500;
    width: 100%;
  }
}

.content-tabs {
  font-weight: 700;
  text-align: center;
  align-items: flex-start;
  display: flex;
  gap: 0;
  width: 100%;

  @media (max-width: 768px) {
    display: none;
  }

  .content-point {
    color: rgba(14, 76, 96, 1);
    align-items: center;
    justify-content: center;
    display: flex;
    border-top-right-radius: 14px;
    border-top-left-radius: 14px;
    box-sizing: border-box;
    height: 70px;
    border: none;
    flex: 1;
    padding: 0;
    background: none;

    @media (max-width: 768px) {
      height: 20px;
    }

    .content-bg {
      width: 100%;
      align-items: center;
      justify-content: center;
      display: flex;
      color: #878787;
      font-weight: 500;
      font-feature-settings: 'clig' off, 'liga' off;
      border-bottom: 2px solid $light-purple;
      font-style: normal;
      font-size: 20px;

      &.active {
        color: #170f49;
        font-weight: 700;
        border-bottom-color: $purple;
      }

      &:not(.active):hover {
        color: #170f49;
      }

      box-sizing: border-box;
      height: 100%;

      @media (max-width: 768px) {
        width: 20px;
        height: 20px;
        border-radius: 20px;
        border: 2px solid $light-purple;
        background: $light-purple;

        &.active {
          border-color: $purple;
          background: $purple;
        }
      }

      .content-text {
        @extend %font-18-24;
        display: flex;
        align-items: center;
        justify-content: center;
        height: 70px;
        text-align: center;
        font-style: normal;
        color: inherit;
        font-weight: 500;

        @media (max-width: 768px) {
          display: none;
        }
      }

      .content-image {
        img {
          height: 70px;
          width: 100px;
          object-fit: contain;
          margin-bottom: 16px;
          opacity: 50%;
        }
      }

      &.active .content-image img {
        opacity: 100%;
      }

      &:hover:not(.active) .content-image img {
        opacity: 75%;
      }

    }
  }
}

.carousel-item-container {
  display: flex;
  max-width: calc(100vw - 45px);
  flex-direction: row;
}

.carousel-item {
  min-width: 100%;
  opacity: 1;

  &:not(.active) {
    opacity: 0.0;
  }
}
</style>
