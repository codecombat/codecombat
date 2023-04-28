<script>
export default {
  props: {
    iconName: {
      type: String,
      required: false,
      default: ''
    },
    text: {
      type: String,
      required: true,
      default: ''
    },
    active: {
      type: Boolean,
      required: false,
      default: false
    },
    disabled: {
      type: Boolean,
      default: false,
      required: false,
    }
  },
  methods: {
    onClick () {
      if (!this.disabled) {
        this.$emit('click')
      }
    }
  }
}
</script>

<template>
  <div class="level-access-status-button">
    <div
        class="btn-icon-text"
        :class="{ disabled,active }"
        :disabled="disabled"
        @click="onClick"
    >
      <img v-if="iconName" :src="'/images/ozaria/teachers/dashboard/svg_icons/'+iconName+'.svg'">
      <span> {{ text }} </span>
    </div>
    <slot></slot>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

.level-access-status-button {

  .btn-icon-text {
    display: flex;
    align-items: center;
    cursor: pointer;
    height: 100%;
    min-height: 33px;
    background: #F2F2F2;

    &:hover {
      background: #b6b6b5;
    }

    padding: 5px;

    img {
      width: 23px;
      height: 18px;
      margin: 0 4px;
    }

    span {
      font-family: 'Work Sans';
      font-style: normal;
      font-weight: 500;
      font-size: 12px;
      line-height: 100%;

      display: flex;
      align-items: center;
      letter-spacing: 0.333333px;

      color: #131B25;
    }

    &.active {
      background: rgba(93, 185, 172, 0.5);
    }

    &.disabled {
      cursor: default;

      span {
        color: #ADADAD;
      }
    }
  }

  .active {
    background: #F2F2F2;
  }
}
</style>
