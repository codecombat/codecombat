<template>
  <div
    v-if="campaigns && campaigns.length > 0"
    class="campaign-list"
  >
    <ul
      class="campaigns"
    >
      <li
        :class="{ arrow: true, 'left-active': isLeftArrowActive }"
        @click="onLeftArrowClick"
      >
        <img
          v-if="isLeftArrowActive"
          class="left-rotate"
          src="/images/pages/parents/dashboard/arrow-blue.png"
          alt="Move left"
        >
        <img
          v-else
          src="/images/pages/parents/dashboard/arrow-grey.png"
          alt="Move left"
        >
      </li>
      <li
        v-for="campaign in campaignsToShow"
        :key="campaign._id"
        class="campaign"
        @click="() => updateSelectedCampaign(campaign._id)"
      >
        <div
          :class="{ campaign__dot: true, 'complete-dot': completionStatusMap[campaign._id] === 'complete', 'in-progress-dot': completionStatusMap[campaign._id] === 'in-progress' }"
        />
        <div
          :class="{ campaign__name: true, campaign__name__sel: campaign._id === selectedCampaignId }"
        >
          {{ campaign.fullName || campaign.name }}
        </div>
      </li>
      <li
        :class="{ arrow: true, 'right-active': isRightArrowActive }"
        @click="onRightArrowClick"
      >
        <img
          v-if="isRightArrowActive"
          src="/images/pages/parents/dashboard/arrow-blue.png"
          alt="Move right"
        >
        <img
          v-else
          class="right-rotate"
          src="/images/pages/parents/dashboard/arrow-grey.png"
          alt="Move right"
        >
      </li>
    </ul>
  </div>
</template>

<script>
export default {
  name: 'CampaignListComponent',
  props: {
    campaigns: {
      type: Array
    },
    initialCampaignId: {
      type: String
    },
    completionStatusMap: { // TODO: this should be array of completion status but it is expensive to compute for all so leaving it for now
      type: Object,
      default () {
        return {}
      }
    }
  },
  data () {
    return {
      currentIndex: 0,
      selectedCampaignId: this.initialCampaignId
    }
  },
  computed: {
    campaignsToShow () {
      return this.campaigns.slice(this.currentIndex * 6, (this.currentIndex * 6) + 6)
    },
    isRightArrowActive () {
      const lastCampaign = this.campaignsToShow.length > 0 ? this.campaignsToShow[this.campaignsToShow.length - 1] : null
      if (!lastCampaign) return false
      return this.campaigns.findIndex(c => c._id === lastCampaign._id) < this.campaigns.length - 1
    },
    isLeftArrowActive () {
      return this.currentIndex > 0 && this.campaignsToShow.length > 0
    }
  },
  watch: {
    initialCampaignId: function (newVal, oldVal) {
      if (newVal !== oldVal) {
        this.selectedCampaignId = newVal
      }
    }
  },
  methods: {
    onLeftArrowClick () {
      this.currentIndex = Math.max(this.currentIndex - 1, 0)
    },
    onRightArrowClick () {
      this.currentIndex = Math.min(this.currentIndex + 1, Math.ceil(this.campaigns.length / 6) - 1)
    },
    updateSelectedCampaign (id) {
      this.selectedCampaignId = id
      this.$emit('selectedCampaignUpdated', id)
    }
  }
}
</script>

<style scoped lang="scss">
@import "../css-mixins/variables";
.campaign-list {
  background: $color-grey-2;
  box-shadow: 0 4px 1rem rgba(0, 0, 0, 0.25);
  padding-top: 1.5rem;
  padding-bottom: 1rem;
  position: relative;
}

.campaigns {
  list-style: none;
  display: flex;
  margin-bottom: 0;

  font-size: 1.4rem;
  line-height: 1.8rem;
  letter-spacing: 0.4px;
  text-transform: uppercase;
  color: #979797;

  .left-active, .right-active {
    cursor: pointer;
  }

  .left-rotate {
    transform: rotate(180deg);
  }

  .right-rotate {
    transform: rotate(180deg);
  }
}

.campaign {
  display: flex;
  flex-direction: column;
  align-items: center;

  cursor: pointer;

  position: relative;
  flex-grow: 1;

  &::before {
    content: "";
    height: 1px;
    width: 50%;
    display: block;
    background-color: $color-grey-3;
    position: absolute;
    right: 0;
    top: 10%;
  }

  &::after {
    content: "";
    height: 1px;
    width: 50%;
    display: block;
    background-color: $color-grey-3;
    position: absolute;
    left: 0;
    top: 10%;
  }

  &:nth-last-child(2) {
    &::before {
      width: 0;
    }
  }

  &:nth-child(2) {
    &::after {
      width: 0;
    }
  }

  &__dot {
    width: 1rem;
    height: 1rem;
    background: #FFFFFF;
    border: 1.5px solid $color-grey-3;
    border-radius: 1rem;
    margin-bottom: 1rem;
    z-index: 1;
  }

  .in-progress-dot {
    background-color: $color-blue-2;
  }

  .complete-dot {
    background-color: $color-green-3;
  }

  &__name {
    font-weight: 600;
    font-size: 1.4rem;
    line-height: 1.8rem;
    text-align: center;
    letter-spacing: 0.4px;
    text-transform: uppercase;

    &__sel {
      color: $color-twilight;
    }
  }
}
</style>
