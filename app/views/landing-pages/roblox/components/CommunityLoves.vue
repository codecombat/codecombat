<template>
  <PageSection>
    <template #heading>
      The Roblox community loves it!
    </template>
    <template #body>
      <div class="videos">
        Videos
      </div>
    </template>
  </PageSection>
</template>
<script>
import PageSection from '../../../../components/common/elements/PageSection'
export default {
  components: {
    PageSection
  },
  data () {
    return {
      title: 'Page Title',
      subtitle: 'Page Subtitle',
      content: 'Page Content'
    }
  }
}
</script>
