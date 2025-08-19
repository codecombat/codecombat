<template>
  <page-section class="section">
    <template #heading>
      <mixed-color-label
        class="header-title"
        :text="$t('league_v2.headline')"
      />
    </template>
    <template #body>
      <div class="image">
        <content-box
          :main-image-bg="true"
          :transparent="true"
        >
          <template #image>
            <video-box video-id="d0ea8486d87f3d998564fd48445bc965" />
          </template>
        </content-box>
      </div>
      <div
        class="content"
      >
        <p
          v-for="line in subheads"
          :key="line"
          class="description"
        >
          {{ line }}
        </p>
      </div>
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
    </template>
    <template #tail>
      <div class="background">
        <div class="compete">
          <div class="logo">
            <img
              class="ai-league-logo"
              alt="ai-league-logo"
              src="/images/pages/league/logo_badge.png"
            >
          </div>
          <div class="main">
            <mixed-color-label
              class="main-title"
              :text="$t('league_v2.code_to_compete')"
            />
            <div class="desc">
              {{ $t('league_v2.compete_desc') }}
            </div>
          </div>
        </div>
      </div>
    </template>
  </page-section>
</template>

<script>
import PageSection from '../../../../components/common/elements/PageSection.vue'
import MixedColorLabel from '../../../../components/common/labels/MixedColorLabel.vue'
import VideoBox from '../../../../components/common/image-containers/VideoBox.vue'
import CTAButton from '../../../../components/common/buttons/CTAButton.vue'
import ContentBox from '../../../../components/common/elements/ContentBox'

export default {
  name: 'LeagueHeader',
  components: {
    PageSection,
    MixedColorLabel,
    VideoBox,
    CTAButton,
    ContentBox,
  },
  data () {
    return {
      showContactModal: false,
    }
  },
  computed: {
    me () {
      return window.me
    },
    subheads () {
      return $.i18n.t('league_v2.subhead').split('[NEWLINE]')
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

  @media (max-width: 768px) {
    background: linear-gradient(to top, #05262f 0%, #021e27 3%, #021e27 20%, transparent 50%),url(/images/pages/roblox/header-background.png) center -200px / 250% no-repeat, #021e27;
  }
}

::v-deep .heading {
  max-width: 1440px !important;
}

.header-title {
  @extend %font-44;
}
.header-title {
  ::v-deep .mixed-color-label__normal {
    color: white;
  }
  ::v-deep .mixed-color-label__highlight {
    color: $primary-color !important;
  }
}

.image {
  width: 70%;
}
.content {
  width: 70%;
}

.cta-button {
  margin-bottom: 80px;
}

.background {
  background-image: url('/images/pages/league/v2/compete-background.png');
  width: 1200px;
  background-size: 60%;
  background-position: top center;
  display: flex;
  justify-content: center;

  .compete {
    display: flex;
    width: 750px;
    background: rgb(240, 253, 253);
    color: black;
    border-radius: 20px;
    align-items: center;
    justify-content: space-around;
    padding-top: 20px;
    padding-bottom: 20px;

    .ai-league-logo {
      width: 120px;
    }

    .main {
      width: 490px;
      text-align: left;

      .desc {
        font-size: 16px;
        color: black;
        text-align: left;
      }
    }
  }

}
</style>