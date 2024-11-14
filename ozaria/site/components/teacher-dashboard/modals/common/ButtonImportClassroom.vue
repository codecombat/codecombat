
<script>
export default Vue.extend({
  props: {
    inactive: {
      type: Boolean,
      default: false
    },
    inProgress: {
      type: Boolean,
      default: false
    },
    text: {
      type: String,
      required: true,
      default: 'Link Google Classroom'
    },
    inactiveMessage: {
      type: String,
      required: false,
      default: 'Disabled'
    },
    iconSrc: {
      type: String,
      required: true
    },
    iconSrcInactive: {
      type: String,
      required: true
    }
  },
  methods: {
    onClick () {
      if (!this.inactive && !this.inProgress) {
        this.$emit('click')
      }
    }
  }
})
</script>

<template>
  <div class="google-classroom-button">
    <div
      v-tooltip.bottom="{
        content: inactive ? inactiveMessage : null
      }"
      class="link-google-classroom"
      :class="{ disabled: inactive || inProgress }"
      @click="onClick"
    >
      <img
        v-if="inactive"
        :src="iconSrcInactive"
      >
      <img
        v-else
        :src="iconSrc"
      >
      <span class="google-classroom-text"> {{ text }} </span>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/ozaria/_ozaria-style-params.scss";
.google-classroom-button {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  img {
     width: 30px;
  }
}
.link-google-classroom {
  cursor: pointer;
  background: #FFFFFF;
  box-shadow: -2px -2px 5px rgba(0, 0, 0, 0.11), 2px 4px 5px rgba(0, 0, 0, 0.11);
  display: inline-block;
  padding: 5px;

  &.disabled {
    background: #D8D8D8;
    border-color: #DADADA;
    cursor: default;
    color: #757575;
  }
}
.google-classroom-text {
  font-family: Roboto;
  font-style: normal;
  font-weight: 500;
  font-size: 16px;
  line-height: 18px;
  margin-left: 10px;
}
</style>
