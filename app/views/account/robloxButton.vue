<script>
import VueConfirmDialog from 'vue-confirm-dialog'
import roblox from 'core/api/roblox'
const OAuth2Identities = require('collections/OAuth2Identities')

Vue.use(VueConfirmDialog)
Vue.component('vue-confirm-dialog', VueConfirmDialog.default)

const SMALL = 'small'
const LARGE = 'large'

export default Vue.extend({
    props: {
        size: {
            type: String,
            default: LARGE,
            required: false,
            validator: (value) => {
                return [SMALL, LARGE].includes(value)
            }
        }
    },
    data () {
        return {
            nextURL: window.location.href,
            isAnonymous: me.isAnonymous(),
            robloxIdentities: [],
            counter: 3800,
            LARGE,
            SMALL
        }
    },

    mounted () {
        this.checkRobloxConnectionStatus();
        if (this.size === LARGE) {
            this.updateCounter();
        }
    },

    computed: {
        isConnected: {
            get () {
                return this.robloxIdentities.length > 0
            },
        },
        i18nData () {
            return {
                username: this.providerUsername,
                interpolation: { escapeValue: false }
            }
        }
    },

    methods: {
        async getRobloxIdentities () {
            const oAuth2Identities = new OAuth2Identities([])
            return oAuth2Identities.fetchForProvider('roblox')
        },
        async checkRobloxConnectionStatus () {
            this.robloxIdentities = await this.getRobloxIdentities();
        },

        async updateCounter () {
            const { count } = await roblox.getConnectionsCount()
            const MAX = 10000;
            const progress = Math.min(Math.floor(count / MAX * 100), 100)
            document.querySelector('.counter-container').style.setProperty('--progress-percent', `${progress}%`);
        },

        connectToRoblox () {
            if (me.isAnonymous()) {
                // login modal will appear because of the login-button class
                return;
            }
            window.open('/auth/oauth2/roblox', '_blank');

            // Listen for the roblox connection to be completed so we can 
            // update the UI after the user connects their roblox account
            var connectionTrackingKey = 'robloxConnectionTrackingKey';
            window.addEventListener('storage', (event) => {
                if (event.key === connectionTrackingKey) {
                    this.checkRobloxConnectionStatus()
                    localStorage.removeItem(connectionTrackingKey)
                }
            })
        },

        async disconnectFromRoblox (identity) {
            this.$confirm({
                message: $.i18n.t('account_settings.roblox_disconnect_confirm', { email: this.email }),
                button: {
                    no: $.i18n.t('modal.cancel'),
                    yes: $.i18n.t('modal.okay')
                },
                callback: async confirm => {
                    if (confirm) {
                        await identity.destroy()
                        this.checkRobloxConnectionStatus()
                    }
                }
            })
        }
    },
})
</script>

<template>
    <div class="roblox-button__container">
        <div v-if="size === LARGE" class="roblox-button__container__header">
            <h3 class="text-h3">{{ $t('roblox_landing.connect_button_header') }}</h3>

            <div class="counter-container">
                <div class="counter-item">
                    <div class="counter-item__image"><img src="/images/pages/roblox/podcast_social.png" /></div>
                    <div class="counter-item__name">{{ $t('roblox_landing.connect_button_linker_badge') }}</div>
                    <div class="counter-item__number">0</div>
                    <div class="counter-item__label">{{ $t('roblox_landing.connect_button_accounts_linked') }}</div>
                    <div class="progress"></div>
                </div>
                <div class="counter-item">
                    <div class="counter-item__image"><img src="/images/pages/roblox/podcast_social_2.png" /></div>
                    <div class="counter-item__name">{{ $t('roblox_landing.connect_button_pet_chroma') }}</div>
                    <div class="counter-item__number">5K</div>
                    <div class="progress"></div>
                </div>
                <div class="counter-item">
                    <div class="counter-item__image"><img src="/images/pages/roblox/podcast_social_3.png" /></div>
                    <div class="counter-item__name">{{ $t('roblox_landing.connect_button_exclusive_pet') }}</div>
                    <div class="counter-item__number">10K</div>
                    <div class="progress"></div>
                </div>
            </div>

            <h4 v-if="!isConnected" class="text-h4">{{ $t('roblox_landing.connect_button_blurb') }}</h4>
        </div>

        <div class="roblox-button__button">
            <img class="logo" src="/images/pages/roblox/roblox-logo.svg" />

            <div class="roblox-button__button__text">
                <div v-if="!isConnected && size === LARGE" class="list">
                    <ul>
                        <li>{{ $t('roblox_landing.connect_button_list_item_1') }}</li>
                        <li>{{ $t('roblox_landing.connect_button_list_item_2') }}</li>
                        <li>{{ $t('roblox_landing.connect_button_list_item_3') }}</li>
                        <li>{{ $t('roblox_landing.connect_button_list_item_4') }}</li>
                        <li>{{ $t('roblox_landing.connect_button_list_item_5') }}</li>
                        <li>{{ $t('roblox_landing.connect_button_list_item_6') }}</li>
                        <li>{{ $t('roblox_landing.connect_button_list_item_7') }}</li>
                        <li>{{ $t('roblox_landing.connect_button_list_item_8') }}</li>
                    </ul>
                </div>
                <p class="text-p" v-if="size === LARGE">
                    {{ isConnected
                        ? $t('roblox_landing.connect_button_connected_blurb')
                        : $t('roblox_landing.connect_button_not_connected_blurb')
                    }}
                </p>
                <div class="content">
                    <div v-if="isConnected" class="identities">
                        <div v-for="identity in robloxIdentities" :key="identity.sub" class="identity">
                            <p v-if="size === SMALL"
                                v-html="$t('account_settings.roblox_connected', { username: identity.get('profile').preferred_username })">
                            </p>
                            <button v-if="isConnected" @click="disconnectFromRoblox(identity)"
                                class="btn form-control btn-danger">
                                {{ $t('account_settings.disconnect_roblox_button') }}
                            </button>
                        </div>
                    </div>
                    <div v-else>
                        <p v-if="size === SMALL">
                            {{ $t('account_settings.roblox_not_connected') }}
                        </p>
                    </div>
                    <div class="buttons-container">
                        <button v-if="!isConnected" :class="{ 'login-button': isAnonymous }"
                            :data-login-message="$t('roblox_landing.login_message')" :data-next-url="nextURL"
                            @click="connectToRoblox" class="btn form-control btn-primary">
                            {{ $t('account_settings.connect_roblox_button') }}
                        </button>
                    </div>
                </div>
                <vue-confirm-dialog />
            </div>
        </div>
    </div>
</template>

<style lang="scss" scoped>
.roblox-button {

    &__container {
        padding: 20px;
        border-radius: 20px;
        background-color: white;

        .text-h3,
        .text-h4 {
            text-align: center;
        }

        .text-p {
            text-align: center;
        }

        .list {
            display: flex;
            justify-content: space-evenly;
            align-items: center;
            gap: 20px;
            margin-top: 10px;
            margin-bottom: 5px;

            @media screen and (min-width: 768px) {
                ul {
                    column-count: 2;
                }
            }
        }

        .counter-container {

            --progress-percent: 0%;


            display: flex;
            justify-content: space-evenly;
            align-items: center;
            position: relative;
            margin-bottom: 60px;

            .counter-item {
                display: flex;
                flex-direction: column;
                align-items: center;
                padding: 0 20px;
                flex-grow: 1;

                position: relative;


                &:before {
                    content: "";
                    position: absolute;
                    bottom: -16px;
                    left: 0;
                    right: 0;
                    height: 2px;
                    background-color: black;
                    z-index: 1;
                }

                &:first-child:before {
                    left: calc(50% - 5px);
                }

                &:last-child:before {
                    right: calc(50% - 5px);
                }


                .progress {
                    content: "";
                    position: absolute;
                    bottom: -40px;
                    left: 0;
                    right: 0;
                    height: 10px;
                    background-color: rgb(0, 252, 254);
                    z-index: 1;
                    border-radius: 5px;
                    width: calc((var(--progress-percent) - 25%) * 2);
                }

                &:first-child .progress {
                    left: calc(50% - 5px);
                    width: calc(min(100%, 2 * var(--progress-percent)));
                }

                &:last-child .progress {
                    right: calc(50% - 5px);
                    width: calc((var(--progress-percent) - 75%) * 2);
                }


                &:after {
                    // bullet point
                    content: "";
                    position: absolute;
                    bottom: -20px;
                    /* adjust as needed */
                    left: 50%;
                    transform: translateX(-50%);
                    width: 10px;
                    height: 10px;
                    border-radius: 50%;
                    background-color: rgb(0, 252, 254);
                    z-index: 2;
                }



                &__image {
                    width: 100px;
                    height: 100px;
                    /* Placeholder color, replace with actual image */
                    margin-bottom: 10px;

                    img {
                        width: 100%;
                    }
                }

                &__name {
                    font-size: 14px;
                    font-weight: bold;
                    margin-bottom: 5px;
                }

                &__number {
                    font-size: 16px;
                    font-weight: bold;
                    position: absolute;
                    bottom: -48px;
                }

                &__label {
                    position: absolute;
                    width: min-content;
                    right: calc(50% + 25px);
                    bottom: -35px;
                    line-height: 1.2;
                    text-align: center;
                    font-size: 14px;
                }
            }
        }
    }

    &__button {

        display: flex;
        align-content: center;
        justify-content: space-around;
        align-items: center;
        gap: 20px;

        .logo {
            max-width: min(20%, 100px);
        }

        &__text {
            flex-grow: 1;
        }

        .content {
            flex-grow: 1;

            p {
                text-align: center;
            }
        }

        .buttons-container {
            display: flex;
            gap: 10px;
            justify-content: flex-end;
        }

        .identities {
            display: flex;
            flex-direction: column;
            gap: 10px;
            justify-content: space-around;
            align-items: stretch;
            margin-bottom: 10px;
        }

        .identity {
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-direction: column;
            gap: 10px;

            p {
                margin: 0;
            }
        }

        .btn-primary {
            background-color: #FF9406;
            border-color: #FF9406;

            &:hover {
                background-color: #fcd200;
            }
        }
    }
}
</style>
