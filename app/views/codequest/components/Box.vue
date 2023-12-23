<template>
  <div :class="{ box: true, horizontal: arrangement === 'horizontal' }">
    <div
      class="rectangle"
      :class="{ 'has-padding': hasPadding, 'has-bg': mainImageBg }"
    >
      <img
        alt="Rectangle"
        :src="image"
      >
    </div>
    <div class="div">
      <div class="info">
        <img
          v-if="symbolImage"
          class="symbol-image"
          :src="symbolImage"
        >

        <div
          v-if="title"
          class="title"
        >
          {{ title }}
        </div>
        <p
          class="text"
          v-html="text"
        ></p>
      </div>
      <div
        v-if="frameImage"
        class="frame"
      >
        <img
          class="frame-image"
          alt="Img"
          :src="frameImage"
        >
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'BoxComponent',
  props: {
    arrangement: {
      type: String,
      default: 'vertical'
    },
    image: {
      type: String,
      required: true
    },
    hasPadding: {
      type: Boolean,
      default: false
    },
    symbolImage: {
      type: String,
      default: null
    },
    frameImage: {
      type: String,
      default: null
    },
    title: {
      type: String,
      default: null
    },
    text: {
      type: String,
      default: null
    },
    mainImageBg: {
      type: Boolean,
      default: false
    }
  }
}
</script>

<style scoped lang="scss">
.box {
    align-items: flex-start;
    box-shadow: 0px 0px 22px #00000026;
    background: linear-gradient(90deg, rgb(245, 255, 255) 0%, rgb(255, 255, 255) 100%);
    display: flex;
    flex-direction: column;
    position: relative;
    border-radius: 24px;
    overflow: hidden;

    .horizontal & {
        @media (min-width: 768px) {
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
        @media (min-width: 768px) {
            width: auto;
            max-width: 25%;
            object-fit: cover;
            border-radius: 24px 0px 0px 24px;
            flex: 1;

            &.has-bg {
                img {
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
        padding: 40px 0 40px 50px;
        @media (max-width: 768px) {
            padding: 40px 50px 0 40px;
        }
        img {
            @media (max-width: 768px) {
                object-fit: contain;
            }
        }
    }

    img {
        max-width: 100%;
        max-height: 100%;
        width: 100%;
        @media (max-width: 768px) {
            max-height: 210px;
            object-position: top;
            object-fit: cover;
        }
    }
}

.div {
    align-items: center;
    border-radius: 0px 0px 24px 24px;
    display: inline-flex;
    flex-direction: column;
    gap: 20px;
    padding: 40px 50px;
    position: relative;
    height: 100%;
    justify-content: space-between;

    .horizontal & {
        @media (min-width: 768px) {
            width: auto;
            max-width: 75%;
            height: 100%;
            border-radius: 0px 24px 24px 0px;
            flex: 1;
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
}

.title {
    color: #0a2239;
    font-family: "Plus Jakarta Sans-Bold", Helvetica;
    font-size: 20px;
    font-weight: 700;
    letter-spacing: 0;
    line-height: 20px;
}

.text {
    color: #0a2239;
    font-family: "Plus Jakarta Sans-Regular", Helvetica;
    font-size: 18px;
    font-weight: 400;
    letter-spacing: 0;
    line-height: 24px;
    position: relative;
}

.symbol-image {
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
}

.frame-image {
    height: 30px;
    position: relative;
}
</style>
