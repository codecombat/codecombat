<template>
  <page-section class="section">
    <template #heading>
      {{ $t('league_v2.get_start') }}
    </template>
    <template #body>
      <div class="menu-content">
        <div
          v-for="(item, index) in items"
          :key="`item-${index}`"
          class="list-item"
        >
          <img
            class="vector"
            :src="item.src"
            :alt="`Vector image to illustrate ${item.text}`"
            loading="lazy"
          >
          <div
            class="text-wrapper"
          >
            <div
              v-for="(line, lineIndex) in item.text.split('[NEWLINE]')"
              :key="`line-${lineIndex}`"
            >
              {{ line }}
            </div>
          </div>
        </div>
      </div>
      <div class="cta">
        <CTAButton
          v-if="me.isAnonymous()"
          class="contact-solution signup-button"
          data-start-on-path="teacher"
        >
          {{ $t('league_v2.join_cta') }}
          <template #description>
            {{ $t('league_v2.free_to_play') }}
          </template>
        </CTAButton>
        <CTAButton
          v-else
          class="contact-solution"
          @clickedCTA="showContactModal = true"
        >
          {{ $t('league_v2.create_cta') }}
          <template #description>
            {{ $t('league_v2.for_educators') }}
          </template>
        </CTAButton>
      </div>
    </template>
    <template #tail>
      <div class="video">
        <YoutubeBox
          :video-id="videoId"
        />
      </div>
    </template>
  </page-section>
</template>
<script>
import PageSection from 'app/components/common/elements/PageSection.vue'
import YoutubeBox from 'app/components/common/image-containers/YoutubeBox.vue'
import CTAButton from 'app/components/common/buttons/CTAButton.vue'
export default {
  components: {
    PageSection,
    CTAButton,
    YoutubeBox,
  },
  data () {
    return {
      showContactModal: false,
      videoId: 'Q2sIG0ROrYY',
      items: [{
        src: '/images/pages/league/v2/global.png',
        text: 'Join global coding[NEWLINE]championships',
      }, {
        src: '/images/pages/league/v2/code-points.png',
        text: 'Earn codepoints in[NEWLINE]head-to-head[NEWLINE]matches',
      }, {
        src: '/images/pages/league/v2/team-up.png',
        text: 'Team up with friends[NEWLINE]or classmates',
      }, {
        src: '/images/pages/league/v2/code-points.png',
        text: 'Showcase your skills[NEWLINE]and win prizes',
      }],
    }
  },
  computed: {
    me () {
      return window.me
    },
  },
}
</script>

<style scoped lang="scss">
.section {
  background: #021E27;
}

.cta {
  display: flex;
  align-items: center;
  margin-top: 10px;
}
.video {
  width: 800px;
}

.menu-content {
  display: flex;
  width: 80%;
  justify-content: space-around;

  .list-item {
    text-align: center;
    flex-basis: 20%;

    img {
      height: 102px;
    }
  }
}

</style>