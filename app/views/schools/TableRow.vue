<template>
  <div class="row-content">
    <div
      v-for="(content, index) in contents"
      :key="index"
      class="features__column"
    >
      <div
        v-if="content!==null"
        class="group"
      >
        <div
          class="text-wrapper"
          :class="{header:header}"
        >
          {{ content }}
        </div>
      </div>
    </div>
  </div>
</template>

  <script>
export default {
  name: 'TableRow',
  props: {
    header: {
      type: Boolean,
      required: false,
      defaultValue: false
    },
    contents: {
      type: Array,
      required: true
    }
  }
}
  </script>

  <style scoped lang="scss">
  @import "app/styles/component_variables.scss";

  .row-content {
      align-items: flex-start;
      border-color: transparent;
      border-radius: 24px;
      display: flex;
      overflow: hidden;
      position: relative;
      width: 100%;

      .features {
          align-items: flex-start;
          align-self: stretch;
          background-color: $purple;
          display: flex;
          flex: 1;
          flex-grow: 1;
          padding: 0px 30px;
          position: relative;
      }

      .features {
          &__column {
              align-items: center;
              align-self: stretch;
              display: flex;
              flex: 1;
              flex-grow: 1;
              gap: 16px;
              justify-content: center;
              padding: 0px 30px;
              position: relative;
              min-height: 70px;
              border-right: 2px solid $middle-purple;

              &:first-child {
                  .text-wrapper {
                      color: $purple;
                      font-weight:700;
                  }
              }

              &:last-child {
                  border-right: none;
              }

          }
      }

      .group {
          position: relative;
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 16px;
      }

      .text-wrapper {
          @extend %font-18-24;
          color: $dark-grey-2;
          position: relative;
          text-align: center;
          width: fit-content;
          font-weight: 300;
          &.header {
            font-weight: 700;
          }
      }
  }
  </style>
