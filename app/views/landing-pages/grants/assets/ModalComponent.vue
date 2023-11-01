<template>
    <div @click="maybeClose">
        <modal ref="modal" @close="closeModal">
            <div class="container">
                <h1 class="text-h1">{{ title }}</h1>
                <h2 class="text-h2">{{ blurb }}</h2>
                <form class="form" @submit.prevent="onClickSubmit">
                    <div v-for="(input, index) in inputs" :key="index" class="form-group"
                        :class="{ 'is-checkbox': input.type === 'checkbox' }">
                        <label :for="'input-' + index" class="control-label">{{ input.label }}<span
                                v-if="input.validations.required">*</span></label>
                        <textarea v-if="input.type === 'textarea'" :id="'input-' + index" class="form-control"
                            v-model="$v[input.name].$model" :class="{ 'has-error': $v[input.name].$error }"></textarea>
                        <div v-else-if="input.type === 'label'"></div> <!-- no input field in case of just label type -->
                        <input v-else :type="input.type" :id="'input-' + index" class="form-control"
                            v-model="$v[input.name].$model" :class="{ 'has-error': $v[input.name].$error }" />

                    </div>
                    <div class="form-group row">
                        <div class="col-xs-6">
                            <a class="btn btn-lg btn-primary btn-cancel" @click="closeModal">
                                {{ $t('common.cancel') }}
                            </a>
                        </div>
                        <div class="col-xs-6 buttons">
                            <button class="btn btn-lg btn-primary btn-submit" v-if="!sendingInProgress" type="submit"
                                :disabled="!isFormValid">
                                {{ buttonLabel || $t('common.submit') }}
                            </button>
                            <button class="btn btn-lg btn-primary btn-submit" v-else-if="sendingInProgress" type="submit"
                                :disabled="true">
                                {{ $t('common.sending') }}
                            </button>
                        </div>
                    </div>
                </form>
            </div>
        </modal>
    </div>
</template>


<script>
import { validationMixin } from 'vuelidate'
import Modal from 'app/components/common/Modal'
import contact from 'core/contact'
export default {
    components: {
        Modal
    },
    mixins: [validationMixin],
    props: {
        title: {
            type: String,
            required: true
        },
        name: {
            type: String,
            required: true
        },
        blurb: {
            type: String,
            required: true
        },
        buttonLabel: {
            type: String,
            required: false,
            default: null
        },
        inputs: {
            type: Array,
            required: true
        },
    },
    validations() {
        return this.inputs.reduce((validations, input) => { // initialize validators  based on inputs from props
            return {
                ...validations,
                [input.name]: input.validations
            }
        }, {})
    },
    data() {
        return {
            sendingInProgress: false,
            formFields: this.inputs,
            ...this.inputs.reduce((inputsData, input) => { // initialize fields with empty values
                return {
                    ...inputsData,
                    [input.name]: ''
                }
            }, {})
        };
    },
    computed: {
        isFormValid() {
            return !this.$v.$invalid
        },
    },
    methods: {
        closeModal() {
            this.$emit('close');
        },
        maybeClose(e) {
            if ($(e.target).hasClass('modal-mask')) {
                this.$emit('close');
            }
        },
        async onClickSubmit() {
            if (this.isFormValid) {
                this.sendingInProgress = true
                try {
                    const response = await contact.sendGrantsContactMail({
                        title: this.title,
                        name: this.name,
                        fields: this.inputs.map((input) => {
                            return {
                                label: input.label,
                                name: input.name,
                                value: this[input.name]
                            }
                        })
                    })
                    if (response.url) {
                        window.open(response.url, '_blank')
                    }
                    this.sendingInProgress = false
                    noty({
                        text: 'Our team has received your request and will reach out to you shortly.',
                        type: 'success',
                        layout: 'center',
                        timeout: 2000
                    })
                    this.$emit('close')
                } catch (e) {
                    this.sendingInProgress = false
                    noty({ text: 'Couldnt send the message', type: 'error', layout: 'center', timeout: 2000 })
                }
            }
        }
    },
};
</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";

::v-deep {

    .teacher-modal-header {
        margin: 10px 10px 0 0;
    }

    .modal-container {

        border-radius: 35px;
        box-shadow-width: 4px;
        box-shadow: 0px 0px 0px 4px rgba(14, 76, 96, 1) inset;
        background-color: rgba(255, 255, 255, 1);
        box-sizing: border-box;
        min-height: 570px;
        width: 570px;

        .modal-content {
            border-radius: inherit;

            .modal-header {
                padding-bottom: 0;
            }
        }

        .is-checkbox {
            display: flex;
            flex-direction: row-reverse;
            justify-content: left;
            align-items: center;
            gap: 15px;

            input {
                width: auto;
                height: auto;
                margin: 0;
            }

            label {
                margin: 0;
            }
        }

        .modal-body {
            padding: 0 10px 10px 10px;

            .container {
                padding-top: 0px;
                padding-right: 30px;
                padding-left: 30px;
            }

            textarea.form-control {
                height: 140px;
            }

            .form-group.row {
                margin-top: 80px;
            }

            .text-h1 {
                color: #0E4C60;
                font-family: Arvo;
                font-size: 24px;
                font-style: normal;
                font-weight: 700;
                line-height: 34px;
                margin-bottom: 14px;
            }

            .text-h2 {
                color: #000;
                font-family: Open Sans;
                font-size: 18px;
                font-style: normal;
                font-weight: 700;
                line-height: 24px;
                margin-bottom: 36px;
            }

            .control-label {
                font-family: Open Sans;
                font-size: 18px;
                font-style: normal;
                font-weight: 400;
                line-height: 24px;
            }


            .btn {
                width: 100%;
                background-color: rgba(14, 76, 96, 1);
                border: 2px solid rgba(14, 76, 96, 1);
                color: white;
                border-radius: 7px;

                &.btn-cancel {
                    color: rgba(14, 76, 96, 1);
                    background-color: white;
                }
            }
        }
    }

    .has-error {
        border-color: $state-danger-text;
    }
}
</style>
