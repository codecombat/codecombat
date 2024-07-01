<template>
  <two-column-block
    :reverse="block.reverse"
    class="block"
  >
    <template #column-two>
      <content-box :main-image-bg="true">
        <template #image>
          <img
            v-if="block.image"
            :src="block.image.src"
            :alt="block.image.alt || `Image to illustrate ${block.colTwo?.title}`"
          >
        </template>
      </content-box>
    </template>
    <template #column-one>
      <div
        class="col-two"
        :class="{reverse: !block.reverse}"
      >
        <div class="img-group">
          <img
            v-for="img in block.colTwo.images"
            :key="img.src"
            :src="img.src"
            :style="img.style"
            class="character-image"
          >
        </div>
        <div class="content">
          <!-- eslint-disable vue/no-v-html -->
          <div
            class="svg"
            v-html="block.colTwo.vector"
          />
          <!--eslint-enable-->
          <div class="title">
            {{ block.colTwo.title }}
          </div>
          <div class="description">
            {{ block.colTwo.description }}
          </div>
        </div>
      </div>
    </template>
  </two-column-block>
</template>
<script>
import TwoColumnBlock from '../../../../components/common/elements/TwoColumnBlock'
import ContentBox from '../../../../components/common/elements/ContentBox'
export default {
  components: {
    TwoColumnBlock,
    ContentBox
  },
  props: {
    block: {
      type: Object,
      required: true
    }
  },
}
</script>
<style scoped lang="scss">
@import "app/styles/bootstrap/variables";
@import "app/styles/component_variables.scss";

.block {
  width: 100%;
  ::v-deep .column-one {
    flex-basis: calc(50% - 15px);
  }
  ::v-deep .column-two {
    flex-basis: calc(50% - 15px);
  }

  .col-two {
    height: 100%;
    position: relative;
    display: flex;
    flex-direction: row;

    &.reverse {
      flex-direction: row-reverse;

      .img-group {
        justify-content: flex-start;
        right: unset;
        left: 5%;

        img:n-th-child(2) {
          marign-left: unset;
          margin-right: -10%;
        }
      }

      .content {
        align-items: flex-end;
      }
    }
    margin: unset;

    .img-group {
      position: absolute;
      bottom: 40%;
      right: 5%;
      display: flex;
      align-items: flex-end;
      justify-content: flex-end;

      img:n-th-child(2) {
        margin-left: -10%;
      }
    }

    .content {
      align-self: stretch;
      display: flex;
      flex-direction: column;
      align-items: flex-start;
      justify-content: space-around;

      .title {
        @extend %font-36;
      }
      .description {
        @extend %font-18-24;
      }
    }
  }
}
</style>