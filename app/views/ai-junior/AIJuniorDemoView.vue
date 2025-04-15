<template>
  <div class="demo">
    <div
      v-if="hasAccess()"
      class="demo-primary"
    >
      <CTAButton
        href="/ai-junior/project/6600a6c23a9490c3f23997af"
        target=""
        size="medium"
      >
        Demo
      </CTAButton>
    </div>
    <div
      v-if="hasAccess()"
      class="demo-secondary"
    >
      <a
        class="btn btn-success"
        href="/ai-junior/curriculum"
        target="_blank"
      >
        Curriculum
      </a>
      <a
        class="btn btn-info"
        :href="`/ai-junior/project/6600a6c23a9490c3f23997af/${userId()}`"
      >
        Show Existing Projects
      </a>
    </div>
  </div>
</template>

<script>
import CTAButton from 'app/components/common/buttons/CTAButton.vue'
export default {
  name: 'AIJuniorDemoView',
  components: {
    CTAButton,
  },
  methods: {
    userId () {
      return me.id
    },
    hasAccess () {
      return me.hasAiJuniorAccess()
    },
  },
}
</script>

<style lang="scss" scoped>
.demo {
  padding: 3rem;

  &-primary {
    display: flex;
    justify-content: center;
    align-items: center;

    margin-bottom: 2rem;
  }
  &-secondary {
    display: flex;
    justify-content: space-around;
    align-items: center;
  }
}
</style>
