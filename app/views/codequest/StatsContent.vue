<template>
  <div class="content">
    <div class="title">
      How it Works
    </div>
    <div class="data-text">
      <ContentBlock
        title="Apply"
        supporting-text="January-February"
        :steps="[
          'Students interested in participating will fill out an application.',
          'A skills assessment or evaluation may be needed to confirm your ability to participate.'
        ]"
        image-src="/images/pages/codequest/stats/confirm.svg"
        number="1"
      />
      <ContentBlock
        title="Confirm"
        supporting-text="March-April"
        :steps="[
          'If you are accepted, a program advisor will contact you to confirm the additional details.',
          'An initial deposit will be required to hold your spot in the program.',
          'Your travel will be coordinated and booked.',
          'A liability waiver will be required for all participants.'
        ]"
        image-src="/images/pages/codequest/stats/confirm.svg"
        number="2"
      />
      <ContentBlock
        title="Travel"
        supporting-text="July"
        :steps="[
          'Prior to departure you will receive a comprehensive travel packet with all the information you will need to know.',
          'Preparations have been made to shuttle participants from the airport to the hotel and to and from the activities throughout the week. Transportation back to the airport for departure will also be arranged.',
          'The full package fee will be due prior to travel, minus the initial deposit fee.'
        ]"
        image-src="/images/pages/codequest/stats/travel.svg"
        number="3"
      />
    </div>
  </div>
</template>

<script>
import ContentBlock from './StatsContentBlock.vue'

export default {
  name: 'ContentComponent',
  components: {
    ContentBlock
  }
}
</script>

<style scoped lang="scss">
.content {
  align-items: center;
  display: flex;
  flex-direction: column;
  gap: 80px;
  justify-content: center;
  padding: 100px 0px;
  position: relative;
  border-radius: 24px;
  background: #F0FDFD;
  box-shadow: 0px 4px 22px 0px rgba(0, 0, 0, 0.15);
}

.content .title {
  align-self: stretch;
  color: #4799A9;
  font-family: "Plus Jakarta Sans-Medium", Helvetica;
  font-size: 36px;
  font-weight: 500;
  letter-spacing: 0;
  line-height: 45px;
  margin-top: -1px;
  position: relative;
  text-align: center;
}

.content .data-text {
  align-items: flex-start;
  align-self: stretch;
  display: flex;
  gap: 40px;
  justify-content: center;
  position: relative;
  padding: 0 100px;
  width: 100%;
}

@media (max-width: 991px) {
  .content .data-text {
    flex-direction: column;
    align-items: center;
  }
}
</style>
