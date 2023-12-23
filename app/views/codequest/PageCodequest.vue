<template>
  <div>
    <div class="codequest container">
      <HeaderItem />
    </div>
    <div class="container-fluid">
      <div class="codequest container">
        <Testimonals />
      </div>
    </div>
    <div class="codequest container">
      <ContentItem />
      <CtaWrapper />
      <Stats />
      <div class="CTA">
        <ButtonA
          class="button-a-instance"
          text="Join Us"
          href="https://docs.google.com/forms/d/e/1FAIpQLSf-Hq5e5COINPxh5soG0XIF0UNH9HjnAjXKz4EBinLmcmp2sw/viewform"
        />
      </div>
    </div>
    <div class="container-fluid">
      <div class="codequest container">
        <FrameItem />
      </div>
    </div>
    <div class="codequest container">
      <AccessibilityRep />
      <div class="CTA">
        <ButtonA
          class="button-a-instance"
          text="Start Application"
          href="https://docs.google.com/forms/d/e/1FAIpQLSf-Hq5e5COINPxh5soG0XIF0UNH9HjnAjXKz4EBinLmcmp2sw/viewform"
        />
      </div>
    </div>
    <div class="container-fluid">
      <div class="codequest container">
        <Faq />
      </div>
    </div>
    <div class="codequest container">
      <Partners />
    </div>
  </div>
</template>

<script>
import HeaderItem from './Header'
import Testimonals from './Testimonals'
import ContentItem from './Content'
import CtaWrapper from './CtaWrapper'
import Stats from './Stats'
import ButtonA from './ButtonA'
import FrameItem from './Frame'
import AccessibilityRep from './AccessibilityRep'
import Faq from './Faq'
import Partners from './Partners'

export default Vue.extend({
  name: 'CodeQuest',
  components: {
    HeaderItem,
    Testimonals,
    ContentItem,
    CtaWrapper,
    Stats,
    ButtonA,
    FrameItem,
    AccessibilityRep,
    Faq,
    Partners
  }
})
</script>

<style>
#page-container {
  max-width: 100vw;
  overflow-x: hidden;
}
</style>

<style scoped lang="scss">
.container-fluid {
  background: #f0fdfd;
  box-shadow: 0px 4px 22px 0px rgba(122, 101, 252, 0.15);
}

.codequest {
  max-width: 1280px;
  width: auto;
}

.CTA {
  align-items: center;
  display: flex;
  flex-direction: column;
  gap: 8px;
  justify-content: center;
  padding: 80px 0px 160px;
  position: relative;
}

.CTA .button-a-instance {
  flex: 0 0 auto !important;
  width: 258px !important;
}
</style>
