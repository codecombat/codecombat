<template>
    <div class="btn-group" data-toggle="buttons" id="dashboard-toggle">
        <label class="btn btn-primary" :disabled="isNewDashboard" @click="setLocalStorage(true)">
            <input type="radio" name="options" id="option1" autocomplete="off"> On
        </label>
        <label class="btn btn-primary" :disabled="isOldDashboard" @click="setLocalStorage(false)">
            <input type="radio" name="options" id="option2" autocomplete="off"> Off
        </label>
    </div>
</template>
  
<script>
export default {
    name: 'DashboardToggle',
    methods: {
        setLocalStorage (newValue) {
            localStorage.setItem('newDT', newValue ? 'true' : 'false');
            window.location.reload();
        }
    },
    computed: {
        isOldDashboard () {
            return localStorage.getItem('newDT') !== 'true'
        },
        isNewDashboard () {
            return localStorage.getItem('newDT') === 'true'
        }
    },
    mounted () {
        if (this.isNewDashboard) {
            document.getElementById('option1').checked = true;
        } else {
            document.getElementById('option2').checked = true;
        }
    }
}
</script>
<style scoped lang="scss">
#dashboard-toggle {
    label {
        margin-left: 0;
    }
}
</style>