<script>
    import { mapGetters } from 'vuex'

    export default {
      props: {
        backButtonLink: {
          type: String,
          required: true
        }
      },

      data () {
        return {
          showAccountDropdown: false
        }
      },

      computed: {
        ...mapGetters({
          isAnonymous: 'me/isAnonymous'
        })
      },

      methods: {
        onMyAccountClicked () {
          this.showAccountDropdown = !this.showAccountDropdown
        },

        onBackToDashboard () {
          return application.router.navigate(this.backButtonLink, { trigger: true })
        },

        onAccountSettings () {
          return application.router.navigate('/account/settings', { trigger: true })
        },

        onLogout () {
          return application.router.navigate('/logout', { trigger: true })
        }
      }
    }
</script>

<template>
    <nav class="unit-map-nav">
        <ul class="unit-map-navbar">
            <li v-if="!isAnonymous" class="account-icon">
                <img src="/images/ozaria/unit-map/account_generic.png" />
            </li>
            <li v-if="!isAnonymous">
                <button @click="onMyAccountClicked">
                    {{ $t('nav.my_account') }}
                    <span :class="{ caret: true, flip: showAccountDropdown }"></span>
                </button>

                <ul v-if="showAccountDropdown" class="dropdown">
                    <li>
                        <button @click="onAccountSettings">
                            {{ $t('play.account_settings') }}
                        </button>
                    </li>
                    <li>
                        <button @click="onLogout">
                            {{ $t('common.logout') }}
                        </button>
                    </li>
                </ul>
            </li>
            <li>
                <button @click="$emit('customizeHero')">
                    {{ $t('play.customize_hero') }}
                </button>
            </li>
            <li>
                <button @click="onBackToDashboard">
                    <span v-if="isAnonymous"> {{ $t("play.back_to_ozaria") }} </span>
                    <span v-else> {{ $t("play.back_to_dashboard") }} </span>
                </button>
            </li>
        </ul>
    </nav>
</template>

<style scoped lang="scss">
    .unit-map-nav {
        position: absolute;
        top: 0;
        left: 0;
        right: 0;

        padding-top: 10px;
        padding-left: 30px;

        ul.unit-map-navbar {
            display: flex;
            flex-direction: row;

            align-items: center;
            justify-content: flex-start;

            padding: 0;
            margin: 0;

            & > li {
                list-style: none;
                padding-right: 20px;

                &:last-of-type {
                    padding-right: 0;
                }

                & > button {
                    background: transparent;
                    border: 0 none;

                    font-size: 18px;
                    font-family: "Work Sans";
                    font-weight: 600;
                    letter-spacing: 0.4px;
                    line-height: 30px;

                    color: #FFF;
                    text-transform: uppercase;

                    padding: 0;

                    &:focus {
                        outline: none;
                    }
                }
            }

            .account-icon {
                img {
                    width: 55px;
                    height: 55px;
                }
            }
        }

        ul.dropdown {
            display: block;
            box-shadow: 4px 4px 15px 0 rgba(0,0,0,0.5);
            background-color: #EEECED;

            position: absolute;

            padding: 18px 14px;
            margin: 0;

            min-width: 145px;

            li {
                padding-bottom: 7px;
                list-style: none;

                button {
                    background: transparent;
                    border: 0 none;

                    color: #401A1A;
                    font-family: "Work Sans";
                    font-size: 16px;
                    letter-spacing: 0.27px;
                    line-height: 20px;

                }

                &:last-of-type {
                    padding-bottom: 0;
                }
            }
        }
    }

    .flip {
        transform: rotate(180deg);
    }
</style>