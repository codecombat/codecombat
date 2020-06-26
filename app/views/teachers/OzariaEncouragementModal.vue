<script>
    import BaseModal from 'app/components/common/BaseModal'

    export default Vue.extend({
      data: () => ({
        show: true,

        hasPlayed: false,
        playerVars: {
          rel: 0
        }
      }),

      components: {
        BaseModal
      },

      computed: {
        tryOzariaLink () {
          if (me.useChinaServices()) {
            return "https://aojiarui.com/teachers/classes?utm_campaign=emodel&utm_medium=web&utm_source=codecombat"
          } else {
            return "https://www.ozaria.com/teachers/classes?utm_campaign=emodel&utm_medium=web&utm_source=codecombat"
          }
        },
        showChinaVideo () {
            return me.showChinaVideo()
        }
      },

      methods: {
        async startPlay () {
          if (this.hasPlayed) {
            return
          }

          this.hasPlayed = true
          const iframe = await this.$refs.player.player.getIframe()
          iframe.requestFullscreen()
        },

        close () {
          this.show = false
        },

        noThanksClicked () {
          window.tracker.trackEvent('Ozaria Encouragement Modal Declined', { category: 'Teachers' })
          this.close()
        },

        tryOzariaEvent () {
          window.tracker.trackEvent('Ozaria Encouragement Modal CTA Click', { category: 'Teachers' })
        }
      },

      mounted () {
        window.tracker.trackEvent('Ozaria Encouragement Modal Displayed', { category: 'Teachers' })
      }
    })
</script>

<template>
    <base-modal v-if="show" class="encouragement-modal">
        <template slot="header">
            <div class="header">
                <h1>
                    {{ $t('teacher_ozaria_encouragement_modal.title') }}
                </h1>

                <h2>
                    {{ $t('teacher_ozaria_encouragement_modal.sub_title') }}
                </h2>

                <div class="spacer"></div>
            </div>
        </template>

        <template slot="body">
            <div class="content">
                <div class="trailer">
                    <div class="player-container">
                        <div class="player-sizer">
                            <youtube
                                    v-if="!showChinaVideo"
                                    class="player"
                                    ref="player"
                                    video-id="prJJvvI3WJM"
                                    @playing="startPlay"
                                    :player-vars="playerVars"
                            />
                            <video
                                    v-if="showChinaVideo"
                                    controls
                                    class="player"
                                    poster="https://ozaria-assets.oss-cn-qingdao.aliyuncs.com/home-video-poster.jpg"
                                    preload="metadata"
                            >
                                <source
                                    src="https://ozaria-assets.oss-cn-qingdao.aliyuncs.com/aojiarui-home.mp4"
                                    type="video/mp4"
                                >
                            </video>
                        </div>
                    </div>
                </div>

                <ul>
                    <li>{{ $t('teacher_ozaria_encouragement_modal.bullet1') }}</li>
                    <li>{{ $t('teacher_ozaria_encouragement_modal.bullet2') }}</li>
                    <li>{{ $t('teacher_ozaria_encouragement_modal.bullet3') }}</li>
                    <li>{{ $t('teacher_ozaria_encouragement_modal.bullet4') }}</li>
                </ul>
            </div>
        </template>

        <template slot="footer">
            <div class="footer">
                <div class="top-row">
                    <a
                            href="#"
                            class="no-thanks"
                            @click="noThanksClicked"
                    >
                        {{ $t('teacher_ozaria_encouragement_modal.cancel') }}
                    </a>

                    <a
                            :href="tryOzariaLink"
                            class="try-ozaria"
                            @click="tryOzariaEvent"
                    >
                        {{ $t('teacher_ozaria_encouragement_modal.accept') }}
                    </a>
                </div>
                <div class="bottom-row">
                    <span>{{ $t('teacher_ozaria_encouragement_modal.you_can_return') }}</span>
                </div>
            </div>
        </template>
    </base-modal>
</template>

<style scoped lang="scss">
    .encouragement-modal {
        ::v-deep .modal-container {
            width: 70%;
        }

        ::v-deep .modal-content {
            padding: 30px;
        }
    }

    .header {
        padding: 0 136px;

        color: #476FB1;
        text-align: center;

        h1, h2 {
            display: block;
            font-family: "Work Sans", "Sans Serif";
            font-variant: normal;

            margin: 0;
        }

        h1 {
            font-weight: 600;
            font-size: 38px;

            letter-spacing: 1.81px;
            line-height: 40px;
            text-shadow: 0 2px 4px 0 #5DB9AC;
        }

        h2 {
            margin-top: 5px;

            font-size: 22px;
            text-transform: uppercase;

            line-height: 30px;
            letter-spacing: 0.55px;
            font-weight: 600;
        }

        .spacer {
            margin-top: 23px;
            width: 150px;
            background: linear-gradient(59.61deg, #D1B147 0%, #D1B147 20%, #F7D047 90.4%, #F7D047 100%);
        }
    }

    .content {
        display: flex;
        flex-direction: row;

        align-items: center;
        justify-content: center;

        width: 100%;

        .trailer {
            width: 50%;
            flex-grow: 1;

            .player-container{
                width: 100%;
                padding-top: 56.25%;
                position: relative;

                .player-sizer {
                    position: absolute;

                    top: 0;
                    bottom: 0;
                    left: 0;
                    right: 0;

                    ::v-deep .player {
                        width: 100%;
                        height: 100%;
                    }
                }
            }
        }

        ul {
            width: 50%;
            flex-grow: 1;

            font-family: "Work Sans";

            color: #131B25;
            font-size: 20px;
            letter-spacing: 0.33px;
            line-height: 24px;

            margin-left: 50px;
            padding-left: 40px;

            li {
                list-style: none;

                margin-bottom: 30px;

                &:last-of-type {
                    margin-bottom: 0;
                }

                &::before {
                    content: '';
                    background-color: #F7D047;
                    margin-right: 10px;
                    display: inline-block;
                    width: 9px;
                    height: 9px;
                    border-radius: 50% / 50%;

                    margin-left: -20px;
                }
            }
        }
    }

    .footer {
        width: 100%;
    }

    .footer .top-row {
        width: 100%;

        display: flex;
        flex-direction: row;
        justify-content: space-between;
        align-items: center;

        font-family: "Work Sans";
        font-size: 20px;
        letter-spacing: 0.4px;

        letter-spacing: 0.4px;
        line-height: 30px;

        font-weight: 600;

        .no-thanks {
            color: #D1B147;

            border: 2px solid #D1B147;
            border-radius: 1px;
            background: linear-gradient(131.58deg, rgba(255,255,255,0.77) 0%, rgba(255,255,255,0.89) 100%);

            padding: 14px 15px;

            height: 100%;
        }

        .try-ozaria {
            color: #131B25;
            padding: 14px;
            background-color: #F7D047;
            border-radius: 1px;
            height: 100%;

        }

        a:hover {
            text-decoration: none;
        }
    }

    .footer .bottom-row {
        height: 20px;
        text-align: right;
        width: 100%;
        font-size: 13px;
        margin-top: 2px;
        margin-bottom: -20px;
    }
</style>