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
              v-for="(line, lineIndex) in $t(item.text).split('[NEWLINE]')"
              :key="`line-${lineIndex}`"
            >
              {{ line }}
            </div>
          </div>
        </div>
      </div>
      <div class="cta">
        <CTAButton
          v-if="me.isTeacher()"
          @clickedCTA="$emit('clickCreateCTA')"
        >
          {{ $t('league_v2.create_cta') }}
          <template #description>
            {{ $t('league_v2.for_educators') }}
          </template>
        </CTAButton>
        <CTAButton
          v-else
          :class="me.isAnonymous() ? 'signup-button' : ''"
          @clickedCTA="$emit('clickJoinCTA')"
        >
          {{ $t('league_v2.join_cta') }}
          <template #description>
            {{ $t('league_v2.free_to_play') }}
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
        text: 'league_v2.get_start_list_1',
      }, {
        src: '/images/pages/league/v2/code-points.png',
        text: 'league_v2.get_start_list_2',
      }, {
        src: '/images/pages/league/v2/team-up.png',
        text: 'league_v2.get_start_list_3',
      }, {
        src: '/images/pages/league/v2/prizes.png',
        text: 'league_v2.get_start_list_4',
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
@import "app/styles/component_variables.scss";
.section {
  background: #021E27;
}

.cta {
  display: flex;
  align-items: center;
  margin-top: 50px;
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

@media (max-width: $screen-md-min) {
  .menu-content {
    width: 100%;
    flex-direction: column;
  }
  .video {
    max-width: 80%;
  }
}
</style>