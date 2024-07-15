<template>
  <PageSection class="section">
    <template #heading>
      <mixed-color-label
        class="header-title"
        :text="$t('roblox.header_title')"
      />
    </template>
    <template #body>
      <two-column-block>
        <template #column-one>
          <content-box :main-image-bg="true">
            <template #image>
              <img :src="header">
            </template>
          </content-box>
        </template>
        <template #column-two>
          <div class="col-two">
            <img :src="logo">
          </div>
        </template>
      </two-column-block>
    </template>
    <template #tail>
      <p class="content">
        {{ $t('roblox.header_content') }}
      </p>
      <CTAButton
        class="cta-button"
        href="https://www.roblox.com/games/11704713454/CodeCombat-Worlds"
      >
        {{ $t('new_home.play_now') }}
      </CTAButton>
    </template>
  </PageSection>
</template>
<script>
import PageSection from '../../../../components/common/elements/PageSection'
import CTAButton from '../../../../components/common/buttons/CTAButton.vue'
import MixedColorLabel from '../../../../components/common/labels/MixedColorLabel.vue'
import TwoColumnBlock from '../../../../components/common/elements/TwoColumnBlock'
import ContentBox from '../../../../components/common/elements/ContentBox'

export default {
  name: 'HeaderSection',
  components: {
    PageSection,
    CTAButton,
    TwoColumnBlock,
    ContentBox,
    MixedColorLabel
  },
  data () {
    return {
      header: '/images/pages/roblox/header.png',
      logo: '/images/pages/roblox/coco-worlds-no-desc.png'
    }
  }
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

.header-title {
  @extend %font-44;

  ::v-deep .mixed-color-label__normal {
    color: white;
  }
  ::v-deep .mixed-color-label__highlight {
    color: $primary-color !important;
  }

}

::v-deep .column-one {
  flex-basis: 60% !important;
}
::v-deep .column-two {
  flex-basis: 30% !important;
}

.col-two {
  height: 100%;
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;

  img {
    width: 80%;
    filter: drop-shadow(1px 2px 3px rgba(77, 236, 240, 0.8));
  }
}

.content {
  @extend %font-24-30;
  color:  #B4B4B4;
  margin-bottom: 40px;
}
.cta-button {
  margin-bottom: 80px;
}
</style>