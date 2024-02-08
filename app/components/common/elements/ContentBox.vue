<template>
  <component
    :is="link ? 'a' : 'div'"
    :href="link"
    :class="{ box: true, horizontal: arrangement === 'horizontal', clickable: link}"
    :style="boxStyle"
  >
    <div
      v-if="hasMainImage"
      class="rectangle"
      :class="{ 'has-padding': hasPadding, 'has-bg': mainImageBg, 'original-size': mainImageOriginal }"
    >
      <slot name="image" />
    </div>
    <div
      v-if="!onlyMainImage"
      class="box__div"
    >
      <div class="info">
        <div
          v-if="hasSymbolImage"
          class="symbol-image"
        >
          <slot name="symbolImage" />
        </div>

        <div
          v-if="hasTitle"
          class="title"
        >
          <slot name="title" />
        </div>
        <slot name="text" />

        <p
          v-if="middleText && middleImage"
          class="middle-text"
        >
          <span>{{ middleText }}</span>
          <img
            :src="middleImage"
            :alt="middleImageAlt"
          >
        </p>
        <slot name="button" />
      </div>
      <div
        v-if="hasFrameImage"
        class="frame"
      >
        <slot name="frameImage" />
      </div>
    </div>
  </component>
</template>

<script>
const ARRANGEMENT_OPTIONS = ['horizontal', 'vertical']

export default {
  name: 'ContentBox',
  arrangementOptions: ARRANGEMENT_OPTIONS,
  props: {
    arrangement: {
      type: String,
      default: 'vertical',
      validator: function (value) {
        return ARRANGEMENT_OPTIONS.includes(value)
      }
    },
    hasPadding: {
      type: Boolean,
      default: false
    },
    mainImageBg: {
      type: Boolean,
      default: false
    },
    mainImageOriginal: {
      type: Boolean,
      default: false
    },
    equalWidth: {
      type: Boolean,
      default: false
    },
    link: {
      type: String,
      default: null
    },
    middleText: {
      type: String,
      default: null
    },
    middleImage: {
      type: String,
      default: null
    },
    middleImageAlt: {
      type: String,
      default: null
    }
  },
  computed: {
    hasMainImage () {
      return this.$slots.image?.length
    },
    hasSymbolImage () {
      return this.$slots.symbolImage?.length
    },
    hasFrameImage () {
      return this.$slots.frameImage?.length
    },
    hasTitle () {
      return this.$slots.title?.length
    },
    hasText () {
      return this.$slots.text?.length
    },
    onlyMainImage () {
      const hasOtherTemplate = Object.entries(this.$slots).some(([key, value]) => {
        return key !== 'image' && value.length
      })
      return !hasOtherTemplate
    },
    boxStyle () {
      if (this.arrangement === 'horizontal' && this.equalWidth) {
        return {
          '--rectangle-width': '50%',
          '--div-width': '50%'
        }
      } else {
        return {
          '--rectangle-width': '25%',
          '--div-width': '75%'
        }
      }
    }
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";
@import "app/styles/component_variables.scss";

.box {
  align-items: flex-start;
  box-shadow: 0px 6px 22px 0px rgba(0, 0, 0, 0.10);
  backdrop-filter: blur(2px);
  background: linear-gradient(90deg, rgb(245, 255, 255) 0%, rgb(255, 255, 255) 100%);
  display: flex;
  flex-direction: column;
  position: relative;
  border-radius: 24px;
  overflow: hidden;

  &.clickable:hover {
    text-decoration: none;
    box-shadow: 0px 6px 22px 0px rgba(0, 0, 0, 0.20);
  }

  &.horizontal {
    @media (min-width: $screen-sm) {
      flex-direction: row;
      align-items: stretch;
    }
  }
}

.rectangle {
  width: 100%;
  object-fit: cover;
  position: relative;
  flex: 1;

  .horizontal & {
    @media (min-width: $screen-sm) {
      width: auto;
      max-width: var(--rectangle-width);
      object-fit: cover;
      border-radius: 24px 0px 0px 24px;
      flex: 1;

      &.has-bg {
        >* {
          position: absolute;
          top: 0;
          left: 0;
          width: 100%;
          height: 100%;
          object-fit: cover;
        }
      }
    }
  }

  &.has-padding {
    >* {
      padding: 40px 0 40px 50px;

      @media (max-width: $screen-sm) {
        padding: 40px 50px 0 40px;
        object-fit: contain;
      }
    }
  }

  >* {
    max-width: 100%;
    max-height: 100%;
    width: 100%;
    aspect-ratio: 16 / 9;
    overflow: hidden;
    position: relative;
    object-fit: cover;
    object-position: top;

    @media (max-width: $screen-sm) {
      max-height: 210px;
      object-position: top;
      object-fit: cover;
    }
  }

  &.original-size {
    >* {
      object-fit: contain;
      max-height: 100%;
    }
  }
}

.box {
  &__div {
    align-items: center;
    border-radius: 0px 0px 24px 24px;
    display: inline-flex;
    flex-direction: column;
    gap: 20px;
    padding: 40px 50px;
    @media screen and (max-width: $screen-sm) {
      padding: 20px 25px;
    }
    position: relative;
    height: 100%;
    width: 100%;
    flex-grow: 1;

    .horizontal & {
      @media (min-width: $screen-sm) {
        width: auto;
        max-width: var(--div-width);
        height: 100%;
        border-radius: 0px 24px 24px 0px;
        flex: 1;
      }
    }
  }
}

.info {
  align-items: flex-start;
  align-self: stretch;
  display: flex;
  flex: 0 0 auto;
  flex-direction: column;
  gap: 12px;
  padding: 4px 0px 0px;
  position: relative;
  height: 100%;
  >:last-child{
    margin-top: auto;
  }

  .middle-text {
    display: flex;
    align-items: center;
    justify-content: space-between;
    width: 100%;
  }
}

.title {
  color: $dark-grey;
  font-family: "Plus Jakarta Sans-Bold", Helvetica;
  font-size: 20px;
  font-weight: 700;
  letter-spacing: 0;
  line-height: 20px;
}

.text {
  color: $dark-grey;
  font-family: "Plus Jakarta Sans-Regular", Helvetica;
  font-size: 18px;
  font-weight: 400;
  letter-spacing: 0;
  line-height: 24px;
  position: relative;
}

.symbol-image>* {
  height: 60px;
  position: relative;
}

.frame {
  align-items: center;
  align-self: stretch;
  display: flex;
  flex: 0 0 auto;
  gap: 20px;
  justify-content: flex-end;
  position: relative;

  >* {
    height: 30px;
    position: relative;
  }
}
</style>
