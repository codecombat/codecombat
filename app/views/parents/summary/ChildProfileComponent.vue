<template>
  <div class="profile">
    <div class="profile__heading">
      Child Profile
    </div>
    <div class="profile__info">
      <div class="info">
        <div class="info__image">
          <img src="/images/pages/parents/dashboard/profile-photo.png" alt="Profile photo" />
        </div>
        <div class="info__details">
          <div class="detail">
            <div class="detail__title">Child Username:</div>
            <div class="detail__text detail__username">{{ child.name }}</div>
          </div>
          <div
            v-if="child.isOnline !== null && child.isOnline !== undefined"
            class="detail"
          >
            <div class="detail__title">Online Status:</div>
            <div class="detail__text">Offline</div>
          </div>
          <div class="detail">
            <div class="detail__title">Email:</div>
            <div class="detail__text">{{ child.email }}</div>
          </div>
          <div
            v-if="child.lastVisit"
            class="detail"
          >
            <div class="detail__title">Last Active:</div>
            <div class="detail__text">{{ new Date(child.lastVisit).toDateString() }}</div>
          </div>
          <div
            v-if="child.learningIn"
            class="detail"
          >
            <div class="detail__title">Learning In:</div>
            <div class="detail__text">Python</div>
          </div>
          <div class="detail">
            <div class="detail__title">Subscription Status:</div>
            <div class="detail__text">{{ child.isPremium ? 'Premium' : 'Free' }}</div>
          </div>
        </div>
      </div>
    </div>
    <div class="helpers">
      <div
        @click="onLoginToChildAccount"
        class="helpers__btn"
      >
        Login to Child Account
      </div>
      <div
        @click="onChangePassword"
        class="helpers__btn"
      >
        Change Password
      </div>
      <div
        v-if="!child.isPremium"
        @click="onUpgradeSub"
        class="helpers__btn helpers__upgrade"
      >
        Upgrade Subscription
      </div>
    </div>
    <change-password-modal
      :user-id-to-change-password="child.userId"
      v-if="showChangePasswordModal"
      @close="showChangePasswordModal = false"
    />
    <backbone-modal-harness
      :modal-view="SubscribeModal"
      :open="showSubscribeModal"
      @close="showSubscribeModal = false"
      :modal-options="{ forceShowMonthlySub: true, purchasingForId: child.userId }"
    />
  </div>
</template>

<script>
import switchUserMixin from '../../user/switch-account/switchUserMixin'
import ChangePasswordModal from '../../user/ChangePasswordModal'
import BackboneModalHarness from '../../common/BackboneModalHarness'
import SubscribeModal from '../../core/SubscribeModal'
import getPremiumForChildMixin from '../mixins/getPremiumForChildMixin'
export default {
  name: 'ChildProfileComponent',
  props: {
    child: {
      type: Object,
      required: true
    }
  },
  data () {
    return {
      showChangePasswordModal: false,
      showSubscribeModal: false,
      SubscribeModal
    }
  },
  components: {
    ChangePasswordModal,
    BackboneModalHarness
  },
  mixins: [
    switchUserMixin,
    getPremiumForChildMixin
  ],
  methods: {
    onLoginToChildAccount () {
      this.onSwitchUser({ email: this.child.email, location: '/' })
    },
    onChangePassword () {
      this.showChangePasswordModal = true
    },
    onUpgradeSub () {
      this.onChildPremiumPurchaseClick()
      this.showSubscribeModal = true
    }
  }
}
</script>

<style scoped lang="scss">
@import "../css-mixins/variables";
.profile {
  background: #FFFFFF;
  border: 1px solid $color-grey-1;
  box-shadow: 3px 0 8px rgba(0, 0, 0, 0.15), -1px 0px 1px rgba(0, 0, 0, 0.06);
  border-radius: 1.4rem;
  padding: 1rem;

  &__heading {
    font-weight: 600;
    font-size: 1.8rem;
    line-height: 3rem;

    letter-spacing: 0.444444px;
    text-transform: uppercase;
    color: $color-yellow-3;

    &:after {
      content: "";
      height: 2px;
      display: block;
      width: 90%;
      background: $color-yellow-3;
      margin-top: .5rem;
    }
  }

  .info {
    display: grid;
    grid-template-columns: 1fr 3fr;
    grid-column-gap: 2rem;

    padding: 1rem;

    &__image {
      height: 19rem;

      img {
        border: 6px solid $color-yellow-1;
        border-radius: 50%;
      }
    }

    &__details {
      display: grid;
      grid-template-columns: 1fr 1fr;

      .detail {
        display: flex;
        flex-direction: column;
        align-items: flex-start;
        &__title {
          font-weight: 400;
          font-size: 1.4rem;
          line-height: 1.8rem;
          letter-spacing: 0.266667px;
          color: $color-grey-dark-1;

          margin-bottom: .5rem;
        }

        &__text {
          font-weight: 400;
          font-size: 1.8rem;
          line-height: 2.2rem;
        }

        &__username {
          font-weight: 600;
          font-size: 2.4rem;
          line-height: 2.8rem;
          letter-spacing: 0.56px;
        }
      }
    }
  }

  .helpers {
    display: flex;
    justify-content: space-around;

    margin-top: 2rem;

    &__btn {
      background: #FFFFFF;
      border: 2px solid $color-green-2;
      border-radius: 1px;

      font-weight: 600;
      font-size: 1.6rem;
      line-height: 1.7rem;
      display: flex;
      align-items: center;
      text-align: center;
      letter-spacing: 0.333333px;

      color: $color-green-2;
      padding: .5rem 2rem;

      cursor: pointer;
    }

    &__upgrade {
      background: $color-green-1;
      color: #000000;
    }
  }
}
</style>
