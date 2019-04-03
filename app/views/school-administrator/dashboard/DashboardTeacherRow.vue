<style scoped>
    .teacher-row {
        display: flex;
        flex-direction: row;
        align-items: center;

        padding: 15px;

        height: 100px;

        line-height: normal;
    }

    .teacher-row:nth-child(2n) {
        background-color: #F5F5F5;
    }

    .teacher-row:nth-child(2n + 1) {
        background-color: #EBEBEB;
    }

    .teacher-info {
        width: 25%;
        flex-grow: 0;
        flex-shrink: 0;

        display: flex;
        flex-direction: column;

        justify-content: center;
    }

    .teacher-email {
        display: block;
        color: #000;

        text-decoration: underline;
        font-size: 18px
    }

    .last-login {
        font-size: 14px
    }

    .stats {
        flex-grow: 1;

        display: flex;
        flex-direction: row;

        align-items: center;
        justify-content: center;

        list-style: none;

        padding: 0;
    }

    .stats li {
        text-align: center;
        font-size: 12px;

        width: 140px
    }

    .stats li span {
        display: block;

        font-size: 24px;
    }

    .dashboard-link {
        margin-left: auto;
        color: #999;

        line-height: normal;
    }

    .dashboard-link:hover {
        text-decoration: none;
    }
</style>

<template>
    <li class="teacher-row">
        <div class="teacher-info">
            <h4>{{ teacher.firstName }} {{ teacher.lastName }}</h4>
            <a class="teacher-email" :href="`mailto:${teacher.email}`">{{ teacher.email }}</a>
            <span class="last-login">{{ $t('school_administrator.last_login') }}: {{ teacher.lastLogin }}</span>
        </div>
        <ul class="stats">
            <li>
                <span>100 / 200</span>
                {{ $t('school_administrator.licenses_used') }}
            </li>

            <li>
                <span>50</span>
                {{ $t('school_administrator.total_students') }}
            </li>

            <li>
                <span>30</span>
                {{ $t('school_administrator.active_students') }}
            </li>

            <li>
                <span>28</span>
                {{ $t('school_administrator.projects_created') }}
            </li>
        </ul>

        <router-link
                class="dashboard-link glyphicon glyphicon-chevron-right"
                :to="`/school-administrator/teacher/${teacher._id}`"
        ></router-link>
    </li>
</template>

<script>
    export default {
      props: [
        'teacher'
      ]
    }
</script>
