<script>
  import BaseModalTeacherDashboard from './BaseModalTeacherDashboard'
  import SecondaryButton from '../common/buttons/SecondaryButton'
  import BaseCloudflareVideo from '../../common/BaseCloudflareVideo'

  export default Vue.extend({
    components: {
      BaseModalTeacherDashboard,
      BaseCloudflareVideo,
      SecondaryButton
    },
    data: () => {
      return {
        videoId: '662aa9aebd3abee032a3a908fe8d58cf' // cloudflare id, TODO: Update to new video id, using 1fh video for now
      }
    }
  })
</script>

<template>
  <base-modal-teacher-dashboard
    title="Welcome to the new Ozaria Teacher Dashboard"
    @close="$emit('close')"
  >
    <div class="onboarding-video-modal">
      <span class="sub-title"> Watch this brief video for best practices and tips on how to make the most of your dashboard. You can always re-watch it in the <a href="/teachers/resources" @click="$emit('close')"> Resource Hub. </a> </span>
      <div class="video">
        <base-cloudflare-video
          :video-cloudflare-id="videoId"
        />
      </div>
      <div class="buttons">
        <secondary-button
          @click="$emit('close')"
        >
          {{ $t("common.done") }}
        </secondary-button>
      </div>
    </div>
  </base-modal-teacher-dashboard>
</template>

<style lang="scss" scoped>
@import "app/styles/ozaria/_ozaria-style-params.scss";

.onboarding-video-modal {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  margin: 20px;
  width: 800px;
}

.sub-title {
  @include font-p-2-paragraph-medium-gray;
}

.video {
  width: 100%;
  padding: 20px 0px;
}

.buttons {
  align-self: flex-end;
  display: flex;
  margin-top: 30px;

  button {
    width: 150px;
    height: 35px;
    margin: 0 10px;
  }
}

</style>
