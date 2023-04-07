<template>
  <div class="campaign-list">
    <ul
      class="campaigns"
    >
      <li
        v-for="campaign in campaignsToShow"
        class="campaign"
        :key="campaign.id"
      >
        <div class="campaign__dot"></div>
        <div class="campaign__name">{{ campaign.name }}</div>
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
    }
  },
  data () {
    return {
      currentIndex: 0
    }
  },
  computed: {
    campaignsToShow () {
      return this.campaigns.slice(this.currentIndex * 4, (this.currentIndex * 4) + 4)
    }
  }
}
</script>

<style scoped lang="scss">
.campaign-list {
  background: #F2F2F2;
  box-shadow: 0 4px 1rem rgba(0, 0, 0, 0.25);
  padding-top: 1.5rem;
  padding-bottom: 1rem;
  position: relative;
}

.campaigns {
  list-style: none;
  display: flex;
  //justify-content: space-evenly;
  margin-bottom: 0;

  font-size: 1.4rem;
  line-height: 1.8rem;
  letter-spacing: 0.4px;
  text-transform: uppercase;
  color: #979797;
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
    background-color: #C8CDCC;
    position: absolute;
    right: 0;
    top: 10%;
  }

  &::after {
    content: "";
    height: 1px;
    width: 50%;
    display: block;
    background-color: #C8CDCC;
    position: absolute;
    left: 0;
    top: 10%;
  }

  &:last-child {
    &::before {
      width: 0;
    }
  }

  &:first-child {
    &::after {
      width: 0;
    }
  }

  &__dot {
    width: 1rem;
    height: 1rem;
    background: #FFFFFF;
    border: 1.5px solid #C8CDCC;
    border-radius: 1rem;
    margin-bottom: 1rem;
    z-index: 1;
  }
}
</style>
