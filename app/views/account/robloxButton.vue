<script>
import VueConfirmDialog from 'vue-confirm-dialog'
const OAuth2Identities = require('collections/OAuth2Identities')

Vue.use(VueConfirmDialog)
Vue.component('vue-confirm-dialog', VueConfirmDialog.default)

export default Vue.extend({
    data() {
        return {
            nextURL: window.location.href,
            isAnonymous: me.isAnonymous(),
            robloxIdentities: [],
        }
    },

    mounted() {
        this.checkRobloxConnectionStatus();
    },

    computed: {
        isConnected: {
            get() {
                return this.robloxIdentities.length > 0
            },
        },
        i18nData() {
            return {
                username: this.providerUsername,
                interpolation: { escapeValue: false }
            }
        }
    },

    methods: {
        async getRobloxIdentities() {
            const oAuth2Identities = new OAuth2Identities([])
            await oAuth2Identities.fetch()
            const robloxIdentities = oAuth2Identities.filter(i => i.get('provider') === 'roblox');
            return robloxIdentities;
        },
        async checkRobloxConnectionStatus() {
            this.robloxIdentities = await this.getRobloxIdentities();
        },

        connectToRoblox() {
            if (me.isAnonymous()) {
                return;
            }
            window.open('/auth/oauth2/roblox', '_blank');

            // Listen for the roblox connection to be completed so we can 
            // update the UI after the user connects their roblox account
            var connectionTrackingKey = 'robloxConnectionTrackingKey';
            window.addEventListener('storage', (event) => {
                if (event.key === connectionTrackingKey) {
                    this.checkRobloxConnectionStatus();
                    localStorage.removeItem(connectionTrackingKey);
                }
            })
        },

        async disconnectFromRoblox(identity) {
            this.$confirm({
                message: $.i18n.t('account_settings.roblox_disconnect_confirm', { email: this.email }),
                button: {
                    no: $.i18n.t('modal.cancel'),
                    yes: $.i18n.t('modal.okay')
                },
                callback: async confirm => {
                    if (confirm) {
                        await identity.destroy()
                        this.checkRobloxConnectionStatus();
                    }
                }
            })
        }
    },
})
</script>

<template>
    <div class="roblox-button">
        <img class="logo" src="/images/roblox/roblox-icon.png" />
        <div class="content">
            <div v-if="isConnected" class="identities">
                <div v-for="identity in robloxIdentities" :key="identity.sub" class="identity">
                    <p
                        v-html="$t('account_settings.roblox_connected', { username: identity.get('profile').preferred_username })">
                    </p>
                    <button v-if="isConnected" @click="disconnectFromRoblox(identity)" class="btn form-control btn-danger">
                        {{ $t('account_settings.disconnect_roblox_button') }}
                    </button>
                </div>
            </div>
            <div v-else>
                <p>
                    {{ $t('account_settings.roblox_not_connected') }}
                </p>
            </div>
            <div class="buttons-container">
                <button v-if="!isConnected" :class="{ 'login-button': isAnonymous }"
                    data-login-message="You need to login before connecting your account to Roblox" :data-next-url="nextURL"
                    @click="connectToRoblox" class="btn form-control btn-primary">
                    {{ $t('account_settings.connect_roblox_button') }}
                </button>
            </div>
        </div>
        <vue-confirm-dialog />
    </div>
</template>

<style lang="scss">
.roblox-button {
    padding: 20px;
    border-radius: 20px;
    background-color: white;
    display: flex;
    align-content: center;
    justify-content: flex-start;
    align-items: center;
    gap: 20px;

    .logo {
        max-width: 20%;
    }

    .content {
        flex-grow: 1;
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
}
</style>
