<template>
  <PageSection class="section">
    <template #heading>
      <mixed-color-label
        class="header-title"
        :text="$t('hackstack_page.header')"
      />
    </template>
    <template #body>
      <content-box class="video-box">
        <template #image>
          <base-cloudflare-video
            video-cloudflare-id="fe31e99a3b8c473590001bacb5029fca"
            :sound-on="false"
            preload="none"
            :loop="true"
            :autoplay="true"
            :controls="false"
            :play-when-visible="true"
            class="video"
          />
        </template>
      </content-box>
    </template>
    <template #tail>
      <p class="content">
        {{ isTeacher() ? $t('hackstack_page.header_details_teacher') : $t('hackstack_page.header_details') }}
      </p>
      <div class="btns-group">
        <div class="btns">
          <CTAButton
            v-if="isTeacher() && isPaidTeacher"
            class="cta-button"
            @clickedCTA="CTAClicked"
          >
            {{ $t('schools_page.get_my_solution') }}
          </CTAButton>
          <CTAButton
            class="cta-button"
            @clickedCTA="exploreClicked"
          >
            {{ $t('hackstack_page.explore_hackstack') }}
          </CTAButton>
        </div>
      </div>
    </template>
  </PageSection>
</template>
<script>
import PageSection from 'app/components/common/elements/PageSection.vue'
import CTAButton from 'app/components/common/buttons/CTAButton.vue'
import MixedColorLabel from 'app/components/common/labels/MixedColorLabel.vue'
import BaseCloudflareVideo from 'app/components/common/BaseCloudflareVideo.vue'
import ContentBox from 'app/components/common/elements/ContentBox'

import { mapGetters, mapActions } from 'vuex'

export default {
  name: 'HeaderSection',
  components: {
    PageSection,
    CTAButton,
    MixedColorLabel,
    ContentBox,
    BaseCloudflareVideo,
  },
  data () {
    return {
      header: '/images/pages/roblox/header.png',
      logo: '/images/pages/roblox/coco-worlds-no-desc.png',
    }
  },
  computed: {
    ...mapGetters({
      isPaidTeacher: 'me/isPaidTeacher',
    }),
  },
  async created () {
    if (this.isTeacher()) {
      await this.fetchTeacherPrepaids({ teacherId: me.get('_id') })
    }
  },
  methods: {
    ...mapActions({
      fetchTeacherPrepaids: 'prepaids/fetchPrepaidsForTeacher',
    }),
    exploreClicked () {
      window.location = '/ai'
    },
    CTAClicked () {
      window.open('/schools?openContactModal=true', '_blank', 'noopener,noreferrer')
    },
    isTeacher () {
      return me.isTeacher()
    },
  },
}
</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";
@import "app/styles/component_variables.scss";

$primary-color: #4DECF0;
$primary-background: #31636F;

.section {
  background: linear-gradient(to top, #05262f 0%, #021e27 3%, #021e27 20%, transparent 50%),url(/images/pages/roblox/header-background.png) 0px -400px / 120% no-repeat, #021e27;

  .video-box {
    width: 850px;
    background: linear-gradient(to top, #05262f 0%, #021e27 3%, #021e27 20%, transparent 50%),url(/images/pages/roblox/header-background.png) center -200px / 250% no-repeat, #021e27;
  }
}

.header-title {
  @extend %font-44;

  ::v-deep .mixed-color-label__normal {
    color: white;
  }
  ::v-deep .mixed-color-label__highlight {
    color: $primary-color !important;
  }

}

.content {
  @extend %font-24-30;
  color:  #B4B4B4;
  margin-bottom: 40px;
}
.btns-group {
  display: flex;
  justify-content: center;
}
.btns {
  max-width: 700px;
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 50px;
  flex-wrap: wrap;
}
.cta-button {
  margin-bottom: 80px;
}
</style>
