<template>
  <div
    v-if="campaigns && campaigns.length > 0"
    class="campaign-list"
  >
    <ul
      class="campaigns"
    >
      <li
        @click="onLeftArrowClick"
        :class="{ arrow: true, 'left-active': isLeftArrowActive }"
      >
        <img v-if="isLeftArrowActive" class="left-rotate" src="/images/pages/parents/dashboard/arrow-blue.png" alt="Move left" />
        <img v-else src="/images/pages/parents/dashboard/arrow-grey.png" alt="Move left" />
      </li>
      <li
        v-for="campaign in campaignsToShow"
        class="campaign"
        :key="campaign._id"
        @click="() => updateSelectedCampaign(campaign._id)"
      >
        <div class="campaign__dot"></div>
        <div
          :class="{ campaign__name: true, campaign__name__sel: campaign._id === selectedCampaignId }"
        >
          {{ campaign.fullName || campaign.name }}
        </div>
      </li>
      <li
        @click="onRightArrowClick"
        :class="{ arrow: true, 'right-active': isRightArrowActive }"
      >
        <img v-if="isRightArrowActive" src="/images/pages/parents/dashboard/arrow-blue.png" alt="Move right" />
        <img v-else class="right-rotate" src="/images/pages/parents/dashboard/arrow-grey.png" alt="Move right" />
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
  },
  watch: {
    campaigns: function (newVal, oldVal) {
      if (newVal && newVal.length) {
        this.selectedCampaignId = newVal[0]._id
        this.$emit('selectedCampaignUpdated', this.selectedCampaignId)
      }
    },
    initialCampaignId: function (newVal, oldVal) {
      if (newVal !== oldVal) {
        this.selectedCampaignId = newVal
      }
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
