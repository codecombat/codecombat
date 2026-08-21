
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
      required: true,
    },
    iconSrcAltText: {
      type: String,
      required: false,
      default: null,
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
  <div class="classroom-button-main">
    <button
      v-tooltip.bottom="{
        content: inactive ? inactiveMessage : null
      }"
      class="link-classroom-btn moon-btn"
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
        :alt="iconSrcAltText"
      >
      <span class="classroom-text"> {{ text }} </span>
    </button>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";
@import "ozaria/site/components/teacher-dashboard/common/moon-button";

.classroom-button-main {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  img {
     width: 30px;
  }
}
.link-classroom-btn {
  padding: 8px 12px;
}
</style>
