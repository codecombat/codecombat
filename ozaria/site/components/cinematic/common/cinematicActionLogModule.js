export default {
  namespaced: true,
  state: {
    logs: [],
    currentPrompt: null,
    startTime: Date.now(), // used to calculate time spent
  },
  getters: {
    logs(state) {
      return state.logs;
    }
  },
  mutations: {
    addLog(state, log) {
      state.logs.push(log);
    },
    setCurrentPrompt(state, prompt) {
      state.currentPrompt = prompt;
    },
    updateStartTime(state) {
      state.startTime = Date.now();
    },
    reset(state) {
      state.logs = [];
      state.currentPrompt = null;
      state.startTime = Date.now();
    },
  },
  actions: {
    addLog({ commit, state }, { skip, next }) {
      if (!state.currentPrompt) return;
      const spent = Date.now() - state.startTime; // in millis
      const log = {
        skip,
        prompt: state.currentPrompt,
        spent,
        next,
      };
      commit('addLog', log);
      commit('updateStartTime');
    },
    changeCurrentPrompt({ commit }, prompt) {
      commit('setCurrentPrompt', prompt);
    },
    resetState({ commit }) {
      commit('reset');
    },
  },
};
