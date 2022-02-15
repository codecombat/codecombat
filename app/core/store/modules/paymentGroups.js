import { getPaymentGroup } from '../../api/payment-group'

export default {
	namespaced: true,
	state: {
		loading: true,
		paymentGroup: {}
	},
	mutations: {
		setPaymentGroup(state, paymentGroup) {
			state.paymentGroup = { ...paymentGroup };
		},
		setLoading(state, loading) {
			state.loading = loading;
		},
	},
	getters: {
		paymentGroup(state) {
			return state.paymentGroup;
		},
		loading(state) {
			return state.loading;
		},
	},
	actions: {
		async fetch({ commit }, slug) {
			let paymentGroup;
			try {
				paymentGroup = await getPaymentGroup(slug);
			} catch (err) {
				console.error('GET paymentGroup failed', err);
				return
			}
			commit('setPaymentGroup', paymentGroup.data);
			commit('setLoading', false);
		}
	}
}
