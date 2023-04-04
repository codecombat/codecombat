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
            <div class="detail__text detail__username">rorysmith09</div>
          </div>
          <div class="detail">
            <div class="detail__title">Online Status:</div>
            <div class="detail__text">Offline</div>
          </div>
          <div class="detail">
            <div class="detail__title">Email:</div>
            <div class="detail__text">rory.smith@gmail.com</div>
          </div>
          <div class="detail">
            <div class="detail__title">Last Active:</div>
            <div class="detail__text">Tues, Nov 29, 2022</div>
          </div>
          <div class="detail">
            <div class="detail__title">Learning In:</div>
            <div class="detail__text">Python</div>
          </div>
          <div class="detail">
            <div class="detail__title">Subscription Status:</div>
            <div class="detail__text">Free</div>
          </div>
        </div>
      </div>
    </div>
    <div class="helpers">
      <div class="helpers__btn">Login to Child Account</div>
      <div class="helpers__btn">Change Password</div>
      <div class="helpers__btn helpers__upgrade">Upgrade Subscription</div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ChildProfileComponent'
}
</script>

<style scoped lang="scss">
.profile {
  background: #FFFFFF;
  border: 1px solid #D8D8D8;
  box-shadow: 3px 0 8px rgba(0, 0, 0, 0.15), -1px 0px 1px rgba(0, 0, 0, 0.06);
  border-radius: 1.4rem;
  padding: 1rem;

  &__heading {
    font-weight: 600;
    font-size: 1.8rem;
    line-height: 3rem;

    letter-spacing: 0.444444px;
    text-transform: uppercase;
    color: #D4B235;

    &:after {
      content: "";
      height: 2px;
      display: block;
      width: 90%;
      background: #D4B235;
      margin-top: .5rem;
    }
  }

  &__info {
    display: grid;
    grid-template-columns: 2fr 1fr;
  }

  .info {
    display: grid;
    grid-template-columns: 1fr 3fr;
    grid-column-gap: 2rem;

    padding: 1rem;

    &__image {
      height: 19rem;

      img {
        border: 6px solid #F7D047;
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
          color: #545B64;

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
      border: 2px solid #379B8D;
      border-radius: 1px;

      font-weight: 600;
      font-size: 1.6rem;
      line-height: 1.7rem;
      display: flex;
      align-items: center;
      text-align: center;
      letter-spacing: 0.333333px;

      color: #379B8D;
      padding: .5rem 2rem;
    }

    &__upgrade {
      background: #5DB9AC;
      color: #000000;
    }
  }
}
</style>
