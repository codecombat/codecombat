<script>
    import BaseModal from 'app/components/common/BaseModal'

    export default Vue.extend({
      components: {
        BaseModal
      }
    })
</script>

<template>
    <base-modal class="encouragement-modal">
        <template slot="header">
            <div class="header">
                <h1>
                    {{ $t('teacher_ozaria_encouragement_modal.title') }}
                </h1>

                <h2>
                    {{ $t('teacher_ozaria_encouragement_modal.sub_title') }}
                </h2>
            </div>
        </template>

        <template slot="body">
            <div class="content">
                <div class="player">
                    <iframe src="https://www.youtube.com/embed/prJJvvI3WJM?modestbranding=1&amp;rel=0" ></iframe>
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
                <a
                        href="#"
                        class="no-thanks"
                >
                    {{ $t('cancel') }}
                </a>

                <a
                        href="#"
                        class="try-ozaria"
                >
                    {{ $t('accept') }}
                </a>
            </div>
        </template>
    </base-modal>
</template>

<style scoped lang="scss">
    .encouragement-modal {
        .modal-container {
            width: 70%;
        }
    }

    .header {
        h1, h2 {
            display: block;
        }
    }

    .content{
        display: flex;
        flex-direction: row;

        align-items: center;
        justify-content: center;

        .player {
            width: 50%;
            flex-grow: 1;

            padding-bottom: 52.25%; /* 16:9 */

            iframe {
                width: 100%;
            }
        }

        ul {
            width: 50%;
            flex-grow: 1;
        }
    }

    .footer {
        width: 100%;
        height: 100px;

        display: flex;
        flex-direction: row;
        justify-content: space-between;
        align-items: center;
    }
</style>