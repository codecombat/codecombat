<template lang="pug">
.container-fluid#star-page

  .row#jumbotron-container-fluid
    img.header-img(:src="baseURI + 'header.png'")
    h5.text-white.col-md-8
      | 为鼓励广大青少年学习计算机编程，扣哒世界每年同权威学术机构和技术机构开展面向青少年的人工智能创意和算法公益竞赛。本栏目收集从2019年开始历届比赛的扣哒之星获奖者，作为榜样的力量激励更多的青少年投入到代码编程、算法设计和人工智能学习中来，自强不息、精益求精、追求卓越！

  .part(v-for="event in events")
    .bobby-duke.row.width-container(v-if="event.ctype=='title'")
      h1.text-teal.title {{ event.title }}
      .row.title-row
        .title-part(v-for="part in event.data",  :class="{'margin-left': part[0].indexOf('margin-left') != -1, 'margin-left-2': part[0].indexOf('margin-2') != -1}")
          h1.value.text-forest(v-html="part[0]")
          h4.title.text-navy {{ part[1] }}
    .width-container(:class="{'row-dark': event.bg == 'dark', 'row': event.bg == 'light'}")
      .rank-row(v-if="event.ctype=='rank'")
        .champ-panel(v-for="(cp, i) in event.rank")
          img.rank-img(:src="baseURI + rankImgs[i]")
          div.flex-center
            h2.text-teal {{cp[0]}}
            | {{cp[1]}}
      .group-row.width-container.flex-center(v-if="event.ctype=='group'")
        h1.title.text-gradient {{event.title}}
        .group-panel
          .name.text-navy(v-for="m in event.members") {{m}}

      .group-desc-row.flex-center(v-if="event.ctype=='group-desc'")
        h1.title.text-gradient {{event.title}}
        .group-panel
          .name.text-navy(v-for="m in event.members")
            .username {{m[0]}}
            .desc {{m[1]}}

      .champion-group-row.flex-center(v-if="event.ctype=='champion-group'")
        h1.title.text-gradient {{event.title}}
        .champ-panel-row.flex-row
          .champ-panel(v-for="(cp, i) in event.rank")
            img.rank-img(:src="baseURI + champImgs[i]")
            div.flex-center
              h2.text-teal {{cp[0]}}
              | {{cp[1]}}
        .group-panel
          h2.text-teal {{event.rewards.title}}
          .names
            .name.text-navy(v-for="m in event.rewards.members") {{m}}

      .champion-row.flex-center(v-if="event.ctype=='champion'")
        h1.title.text-gradient {{event.title}}
        .champ-panel-row.flex-row
          .champ-panel(v-for="(cp, i) in event.rank")
            img.rank-img(:src="baseURI + champImgs[i]")
            div.flex-center(v-for="team in cp")
              h4.text-teal {{team.t}}
              div(v-for="m in team.n") {{m}}

      .row-dark(v-if="event.ctype == 'split-bar'", style="height: 60px; color:transparent;")
      .scroll-arrow(v-if="event.bg=='dark'")
        .left-arrow
        .right-arrow
</template>

<script>
export default Vue.extend({
  components: {
  },

  computed: {
    baseURI () {
      return 'https://assets.koudashijie.com/images/cocostar/'
    },
    rankImgs () {
      return ['champ1.png', 'champ2.png', 'champ3.png']
    },
    champImgs () {
      return ['champgold.png', 'champsli.png', 'champcop.png']
    },
    events () {
      return [
        {
          ctype: 'title',
          title: 'Code Quest全球青少年人工智能挑战活动总决赛',
          data: [['2022年8月', '比赛时间'],
                 ['扣哒世界', '技术支持'],
                 ['3977人', '参数人数'],
                 ['CodeCombat 斯坦福大学', '发起单位'],
                 ['72个国家和地区', '覆盖区域'],
                 ]
        },
        {
          ctype: 'rank',
          bg: 'dark',
          rank: [
            ['Venneth', '（印尼）'],
            ['李成',  '（中国）'],
            ['Shininglice', '（加拿大）']
          ]
        },
        {
          ctype: 'champion-group',
          bg: 'light',
          title: '小初组（小学1-3年级）',
          rewards: {
            title: '一等奖',
            members: [
              '姜秉呈（中国台湾）、',
              '官庭兆（中国）、',
              'Zhou Sihong Ethan（中国香港）、',
              '蔡畅叙（中国）、',
              'Tran Quyet Tien（越南）、',
              'quyettien2（越南）、',
              '胡博文（中国）、',
              'Zhou Andrew（中国香港）、',
              '黄嘉诚（中国）、',
              '宿栢诚（中国）、',
              '張宬暟（中国台湾）、',
              '朱迅冉（中国）、',
              '张乃文（中国）、',
              '王英恺（中国）、',
              '王子鑫（中国）、',
              '巢戈弋（中国）、',
              '叶沐晨（中国）、',
              '许江南（中国）、',
              '郑茗予（中国）、',
              'Chu Leong Sing Jamie（中国香港）、',
              'Zhou  Sihan Bruce（中国香港）、',
              '卜奕博（中国）、',
              'Aoi Oi Hang（中国澳门）、',
              '黄煜翔（中国）、',
              'Gianpk（荷兰）、',
              '张圃献（中国）、',
              '丁以乐（中国）、',
              '何牧之（中国）、',
              '林群翰（中国台湾）、',
              '賴鼎安（中国台湾）、',
              '陈雨博（中国）、',
            ]
          }
        },
        {
          ctype: 'champion-group',
          bg: 'dark',
          title: '中学组',
          rewards: {
            title: '一等奖',
            members: [
              'Venneth（印尼）、',
              '李成（中国）、',
              'Shininglice（加拿大）、',
              'DimaP123（俄罗斯）、',
              'Renegade Penguin（美国）、',
              'Yuwantat（中国）、',
              '杨欣蓥（中国）、',
              'Yung Sze Wai（中国香港）、',
              'Chan Ngo Wang（中国香港）、',
              'Leung Ching Hong（中国香港）、',
              'RedDragon9（美国）、',
              'Henri Cui（中国）、',
              'Tsang Tsz Hin（中国香港）、',
              '吳婕寧（中国台湾）、',
              'Buddeycc（美国）、',
              '范佳乐（中国）、',
              'gianghnt（越南）、',
              'Chan Chi Fung（中国香港）、',
              '束欣铭（中国）、',
              'Law Sau Ho（中国香港）、',
              'Ieong Cory Hoi Yip（中国澳门）、',
              '陈岐昊（中国）、',
              '梁哲浩（中国）、',
              'Kwan Cedric（中国香港）、',
              'Samuel422（英国）、',
              '宋铭灏（中国）、',
              '唐鹏宇（中国）、',
            ]
          }
        },
        {
          ctype: 'champion-group',
          bg: 'light',
          title: '开放组',
          rewards: {
            title: '一等奖',
            members: [
              'Miracle_Knight（美国）、',
              'hubowen（德国）、',
              'EthanChen2（美国）、',
              'ICanCode_Tutors（中国香港）、',
              'Hungtq（波兰）、',
              'Hieunh（以色列）、',
              'KANAU（日本）、',
              'Chriddy（美国）、',
              'StOrMbReAkEr2022（新西兰）、',
              'AmIGroot（加拿大）、',
              'PawełS1（波兰）、',
              'MinhHoàng（越南）、',
              'Smloh（美国）、',
              'Daveminh（美国）、',
              'hamsterparty5（美国）、',
              'Ori H（美国）、',
              'north626（泰国）、',
              'Lucas.Wu（中国台湾）、',
              'SzymonM_（波兰）、',
              'ceri_rj（英国）、',
            ]
          }
        },
        {
          ctype: 'title',
          title: '教育部白名单大赛少年硅谷AI算法竞技赛',
          data: [['2022年3月-2022年7月', '比赛时间'],
                 ['扣哒世界', '技术支持'],
                 ['10,328人', '参数人数'],
                 ['中华人民共和国教育部', '批准单位'],
                 ['中国下一代教育基金会', '主办单位']
          ]
        },
        {
          ctype: 'group-desc',
          bg: 'dark',
          title: '全国一等奖(小学组)',
          members: [
            ['徐逸帆', '斯坦星球（金牌）'],
            ['李祖安', '斯坦星球（银牌）'],
            ['董继豪', '清华大学附属小学清河分校（铜牌）'],
            ['孙海舜', '斯坦星球'],
            ['魏谦澄', '苏州工业园区景城学校'],
            ['金予', '苏州市实验小学校'],
            ['陈天就', '斯坦星球'],
            ['朱智平', '斯坦星球'],
            ['周彬涵', '斯坦星球'],
            ['陈贝嘉', '斯坦星球'],
            ['秦中泽', '斯坦星球'],
            ['蔡子恒', '福建省湖滨小学'],
            ['郝海洲', '斯坦星球'],
            ['金思齐', '斯坦星球'],
            ['孙一逸', '斯坦星球'],
            ['林宬宇', '斯坦星球'],
            ['孙浩云', '斯坦星球'],
            ['赵炫奇', '斯坦星球'],
            ['孙千淇', '斯坦星球'],
            ['李昱扬', '苏州市沧浪实验小学校'],
            ['胡博文', '河北省衡水市实验小学'],
            ['沈嘉皓', '斯坦星球'],
            ['黄一宸', '斯坦星球'],
            ['吴若谷', '中国人民大学附属小学'],
            ['袁壤', '斯坦星球'],
            ['虞浩阳', '斯坦星球'],
            ['孙逸萌', '斯坦星球'],
            ['卢天音', '斯坦星球']

          ]
        },
        {
          ctype: 'group-desc',
          bg: 'light',
          title: '全国一等奖(初中组)',
          members: [
            ['李成', '苏州中学相城实验项目（金牌）'],
            ['卜奕博', '斯坦星球（银牌）'],
            ['龙楚越', '上海浦东民办未来科技学校（铜牌）'],
            ['陈雨博', '上海浦东民办未来科技学校'],
            ['陈奕帆', '甘肃省兰州市第十一中学'],
            ['王奕宁', '北京师范大学实验中学丰台学校'],
            ['林宬宇', '斯坦星球'],
            ['何宇轩', '甘肃省兰州东方学校'],
            ['张阳', '斯坦星球'],
            ['高可钦', '江西省南昌市新建区第五中学'],
            ['陈寅轩', '斯坦星球'],
            ['杜唐啸', '斯坦星球'],
            ['杨梓麟', '斯坦星球'],
            ['谢恩熙', '斯坦星球'],
            ['程书豪', '斯坦星球'],
            ['吴铠涵', '深圳市育才二中']
          ]
        },
        {
          ctype: 'group-desc',
          bg: 'dark',
          title: '全国一等奖(高中组)',
          members: [
            ['万腾远', '广东实验中学深圳学校（金牌）'],
            ['王稞尧', '杭州蕙兰未来科技城学校（银牌）'],
            ['陈鉴朝', '山东省青岛二中（铜牌）'],
            ['梁灿', '山东省威海第二中学 '],
            ['姜昱名', '山东省威海第一中学']
          ]
        },
        {
          ctype: 'title',
          title: '第二届AI世青赛2020',
          data: [['2020年7月-2021年2月', '比赛时间'],
                 ['CodeCombat', '技术支持'],
                 ['65,332人', '参数人数'],
                 ['扣哒人工智能学院、CodeCombat、网易伏羲人工智能实验室', '主办单位']]
        },
        {
          ctype: 'group-desc',
          bg: 'dark',
          title: '全国一等奖(小学组)',
          members: [
            ['王奕宁', '北京市西马金润小学'],
            ['周晋宋', '苏州市沧浪区实验小学校'],
            ['陈雨翔', '北京市西马金润小学'],
            ['周游', '苏州工业园区第二小学'],
            ['宋思飞', '扣哒学堂花儿实验班'],
            ['强昕越', '苏州科技城外国语学校'],
            ['杨澍年', '扣哒学堂花儿实验班'],
            ['王竞扬', '苏州工业园青少年活动中心'],
            ['曹儒林', '昂立STEM'],
            ['房雨萱', '苏州工业园青少年活动中心'],
            ['陆胤辰', '昂立STEM'],
            ['陈道涵', '苏州工业园区蒌葑实验小学'],
            ['霍然', '上海嘉定新城实验学校'],
            ['景子珑', '扣哒学堂花儿实验班'],
            ['梁天营', '深圳市坪山实验学校'],
            ['赵诣', '杭州码爸爸编程创客中心'],
            ['崔铧为', '未提供'],
            ['于浩铭', '杭州码爸爸编程创客中心'],
            ['蒲思行', '重庆宣谷科技'],
            ['宋杭原', '扣哒学堂花儿实验班'],
            ['任西铭', '重庆宣谷科技'],
            ['陈奕帆', '兰州博佳机器人'],
            ['罗晨', '苏州市高新区实验小学'],
            ['程子墨', '兰州博佳机器人'],
            ['马致远', '苏州市高新区实验小学'],
            ['曹杨梓涵', '银川市兴庆区第十六小学'],
            ['李梓豪', '苏州市工业园区翰林小学'],
            ['惠颖轩', '银川市兴庆区回民第三小学'],
            ['钱明远', '苏州市工业园区翰林小学'],
            ['温承轩', '银川市第二十一小学'],
            ['章柴君', '苏州市沧浪区实验小学校'],
            ['龚敬之', '银川市西夏区实验小学'],
            ['范中涵', '苏州市沧浪区实验小学校'],
            ['解淳然', '银川市金凤区第十一小学'],
            ['于哲钧', '苏州市沧浪区实验小学校'],
            ['侯恩宇', '中卫市中宁县大战场镇完全小学']
          ]
        },
        {
          ctype: 'group-desc',
          title: '全国一等奖(中学组)',
          members: [
            ['隋顺意', '扣哒学堂花儿实验班'],
            ['刘岳杭', '码爸爸编程创客中心'],
            ['康景程', '重庆宣谷科技'],
            ['张恩彬', '山西省孝义中学校'],
            ['陈司旭', '广州市执信中学'],
            ['姚渊', '银川市唐徕回民中学南校区'],
            ['李杭臻', '未提供'],
            ['张晁铭', '银川市唐徕回民中学西校区'],
            ['王芊羽', '深圳大学附属中学/自学'],
            ['刘子皓', '银川市唐徕回民中学西校区'],
            ['许嘉航', '苏州中学园区校'],
            ['万好', '银川市唐徕回民中学西校区'],
            ['冯天祺', '苏州中学园区校'],
            ['李保淋', '宁夏长庆初级中学'],
            ['高致渊', '苏州市景范中学校'],
            ['吴锦诺', '宁夏长庆高级中学'],
            ['严子文', '苏州市景范中学校'],
            ['李炤彤', '宁夏长庆高级中学'],
            ['吴闻禹', '苏州市工业园区星湾学校'],
            ['许家凯', '银川市景博中学'],
            ['赵恒毅', '苏州市工业园区东沙湖实验中学'],
            ['陈子墨', '银川市第二十四中学 '],
            ['尤俊皓', '苏州中学相城实验项目'],
            ['邱怡欣', '银川市第二十四中学'],
            ['刘泽辛', '苏州工业园区星海实验中学'],
            ['邓毅飞', '银川市第三中学'],
            ['束欣铭', '西安交通大学苏州附属初级中学'],
            ['张祐畅', '银川市第十二中学'],
            ['高殊荣', '苏州大学实验学校'],
            ['包梓文', '银川市阅海中学'],
            ['陈元邦', '海宁市第一初级中学'],
            ['梁跃民', '银川市中关村中学'],
            ['许云开', '浙江省建兰中学'],
            ['王佳豪', '北京师范大学银川学校'],
            ['罗昕睿', '浙江省建兰中学']
          ]
        },
        {
          ctype: 'group-desc',
          bg: 'dark',
          title: '全国一等奖(教师组)',
          members: [
            ['闫晓迪', 'FunCoding'],
            ['林剑辉', '广州市执信中学']
          ]
        },
        {
          ctype: 'title',
          title: '苏州科技节暨AI世青赛苏州决赛',
          data: [['2020年11-12月', '比赛时间'],
                 ['苏州教育局', '主办单位'],
                 ['2049人', '参数人数'],
                 ['<div class="margin-left" style="font-size: 22px;">苏州中学园区校 “数字公民”课程基地联盟校</div>', '协办单位'],
                 ['扣哒世界', '技术支持']]
        },

        {
          ctype: 'rank',
          bg: 'dark',
          rank: [['袁梓程', '苏州东沙湖实验学校'],
                 ['常煜杰', '苏州中学园区校西交少年班'],
                 ['赵亿豪', '朝前路实验学校']]
        },
        {
          ctype: 'group',
          bg: 'light',
          title: '一等奖',
          members: ['张通', '姚之瀚', '范中涵', '高致渊', '李佳靖', '马苏沂', '陈若熙', '叶思齐', '李梓豪', '王荣祺', '李世杰', '王戎川', '李谦', '赵恒毅', '严子文', '邹陈皓', '吴启扬', '王竞扬', '倪欣禹', '高殊荣', '张语印', '陈道涵', '沈逸磊', '徐周昰', '李奇锦', '尹铭浚', '汪润轩', '王仁杰', '蔡天仪']
        },
        {
          ctype: 'split-bar',
          bg: 'dark'
        },
        {
          ctype: 'title',
          title: '第一届全球青少年图灵计划',
          data: [['2020年7-10月', '比赛时间'],
                 ['<div style="display: flex; flex-direction: column; align-items: center; font-size: 18px; line-height: 20px"><div>中国人民大学高瓴人工智能学院</div>' +
                  '<div>中国人民大学附属中学</div>' +
                  '<div>中国人民大学文化科技园</div>', '主办单位'],
                 ['2299人', '参数人数']]
        },
        {
          ctype: 'group-desc',
          bg: 'dark',
          title: '国内组获奖选手',
          members: [
            ['刘佳成', '北京市第三十五中学'],
            ['邱扬', '北京八中'],
            ['赵宇宸', '北京市第三十五中学'],
            ['魏伯岷', '普林斯顿数学和科学国际学校'],
            ['姚涵清', '北京师范大学附属中学'],
            ['吴习哲', '中国人民大学附属中学'],
            ['岳怒汀', '中国人民大学附属中学'],
            ['陈厚聪', '北京市三十五中学'],
            ['林煜翔', '澳门培正中学'],
            ['张宇辰', '北京理工大学附属中学'],
            ['卿晨', '北京八中'],
            ['张莙滟', '北京市第三十五中学'],
            ['高颢嘉', '对外经贸大学附属中学'],
            ['林艺涵', '中国人民大学附属中学'],
            ['陈林孝', '广州市第一中学'],
            ['李皓宇', '上海外国语大学附属外国语学校'],
            ['王奕霏', '中国人民大学附属中学'],
            ['侯博瀚', '北京十一学校'],
            ['李泓洺', '中国人民大学附属中学早培班'],
            ['杨文俊', '中国人民大学附属中学丰台学校'],
            ['陈亚明', '澳门培正中学'],
            ['王韬智', '首都师范大学附属中学']]
        },
        {
          ctype: 'group-desc',
          bg: 'light',
          title: '国际组获奖选手',
          members: [
            ['Gabriel Lice', '加拿大'],
            ['Kavin Umasankar', '美国'],
            ['Daniel Walters', '英国'],
            ['Sharon Rithika', '印度'],
            ['Eric Tavenner', '美国'],
            ['Charlie Wu', '新加坡'],
            ['Ethan Shih', '美国'],
            ['Raylene Wong', '新西兰'],
            ['Dosido', '加拿大']]
        },
        {
          ctype: 'split-bar',
          bg: 'dark'
        },
        {
          ctype: 'title',
          title: '第二届Code Quest全球赛',
          data: [['2020年4月', '比赛时间'],
                 ['CodeCombat', '主办单位'],
                 ['1507人', '参数人数（全球58个国家和地区）']]
        },
        {
          ctype: 'champion-group',
          bg: 'dark',
          title: '小初组（小学1-3年级）',
          rank: [['张芾', '（中国）'],
                 ['王楚烨', '（中国）'],
                 ['Homare Yamaguchi', '']],
          rewards: {
            title: '一等奖',
            members: [
              'wassupdoc12、', '董继豪（中国）、', 'codeslayer20、', 'Alice Hsu、',
              '杨林宇（中国）、', 'Raghuat2001'
            ]
          }
        },
        {
          ctype: 'champion-group',
          bg: 'light',
          title: '小高组 (小学4-6年级)',
          rank: [['马苏沂', '（中国）'],
                 ['Naomi Shih', ''],
                 ['洪秉承', '（中国）']],
          rewards: {
            title: '一等奖',
            members: [
              '申思博 (中国)、', 'SettePolli、', '隋顺意（中国）、', '赵梓豫（中国）、',
              '张峰若（中国）、', '束欣铭（中国）、', 'Harris Nrithika'
            ]
          }
        },
        {
          ctype: 'champion-group',
          bg: 'dark',
          title: '中学组(中学7-12年级)',
          rank: [['Gabriel Lice', '（加拿大）'],
                 ['Daniel Walters', '（英国）'],
                 ['Eric Tavenner', '（美国）']],
          rewards: {
            title: '一等奖',
            members: [
              'Sin Tsz Yin、', 'Hui Hoi Ming、', '严浩明（中国）、', 'Ethan Shih、', '吴闻禹、',
              'Mak Ho Ting、', 'Dosido'
            ]
          }
        },
        {
          ctype: 'title',
          title: '第一届AI世青赛',
          data: [['2019年9-12月', '比赛时间'],
                 ['扣哒世界', '技术支持'],
                 ['7020人', '参数人数'],
                 ['<div class="margin-2" style="font-size:28px;">工信部赛迪研究院 中国计算机行业协会 中国人工智能产业联盟</div>', '主办单位']]
        },
        {
          ctype: 'group',
          bg: 'dark',
          title: '扣哒之星',
          members: [
            '王竞扬', '洪秉承', '赵梓豫', '狄思怡', '张宇江', '束欣铭', '王栩哲', '寇家齐', '陈元邦', '陆载帆', '曾绅量', '王芊羽', '卢萧宇'
          ]
        },
        {
          ctype: 'title',
          title: '第一届Code Quest 全球决赛',
          data: [['2019年8月', '比赛时间'],
                 ['斯坦福大学 CodeCombat', '主办单位'],
                 ['5276人', '参数人数']]
        },
        {
          ctype: 'group',
          bg: 'dark',
          title: '白金综合奖',
          members: ['Team Anti Hackers（反黑客）： Zhangchi Wang, Siyi Di, Neal Chohan',
                    'Dream Chaser（追梦者）：Chenning Kang, Quynh-Anh Nguyen, Tianrui Feng']
        },
        {
          ctype: 'champion',
          bg: 'light',
          title: '创新创意奖',
          rank: [[{
            t: 'Team Code Hack',
            n: ['Feiran Zhang', 'Charlie Langendorf', 'Hongming Chen']
          }],
                 [{
                   t: 'Team Normal',
                   n: ['Hongyi Zeng', 'Jiaqi Zhang', 'Sabrina']
                 }],
                 [{
                   t: 'Team YKS',
                   n: ['Yining Wang，Zheyuan Li', 'Yariela Lizama-Diaz']
                 }, {
                   t: 'Team Winner',
                   n: ['Guofeng Liu, Ryan', 'Cobaxin, Ke Song']
          }]]
        },
        {
          ctype: 'champion',
          bg: 'dark',
          title: '计算思维奖',
          rank: [[{
            t: 'Team Code Hack',
            n: ['Feiran Zhang', 'Charlie Langendorf', 'Hongming Chen']
          }],
                 [{
                   t: 'Team Kings',
                   n: ['Owen Williams', 'Zhen Zhang', 'Minghao Wang']
                 }],
                 [{
                   t: 'Team Joker',
                   n: ['Zibo Jin', 'Kaustubh Pullea', 'Zifan Jia']

          }]]
        },
        {
          ctype: 'champion',
          bg: 'light',
          title: '项目合作奖',
          rank: [[{
            t: 'Thunder Team',
            n: ['Yiheng Lü', 'Langyue Wei']
          }],
                 [{
                   t: 'Team Joker',
                   n: ['Zibo Jin', 'Kaustubh Pullea', 'Zifan Jia']
                 }],
                 [{
                   t: 'Team Kings',
                   n: ['Owen Williams, Zhen', 'Zhang, Minghao Wang']
                 }, {
                   t: 'Team The X-Men',
                   n: [' Sebastian Vargas, Yipeng', 'Liu, Yeyi Chen']
          }]]
        },
        {
          ctype: 'champion',
          bg: 'dark',
          title: '演讲展示奖',
          rank: [[{
            t: 'Team Honor',
            n: ['Yiyang Liu', 'Tianci Nie', 'Anthony Rangel-Guerrero']
          }],
                 [{
                   t: 'Team YKS',
                   n: ['Yining Wang', 'Zheyuan Li', 'Yariela Lizama-Diaz']
                 }],
                 [{
                   t: 'Team ZH',
                   n: ['Yongming Zhu', 'Weicheng Hua']
                 }, {
                   t: 'Team Little Yellow Crab',
                   n: ['Guangxuan Wu, Jinhao Jin', 'Adam Zhuang']
          }]]
        }
]
    }
  },
  mounted () {
    window.localStorage.setItem('lastViewedCocoStarPage', Date.now())
  }
})
</script>

<style lang='scss' scoped>
@import "app/styles/bootstrap/variables";
@import "app/styles/mixins";
@import "app/styles/style-flat-variables";

.row-dark {
  background: linear-gradient(118.13deg, #0E4C60 0%, #20572B 100%);
}

// style-flat overwrites
h1, .text-h1 {
  font-family: $headline-font;
  font-weight: bold;
  font-size: 46px;
  line-height: 62px;
  letter-spacing: 2px;
  margin-bottom: -6px;
}

.part .camp{
  margin-top: 20px;
  width: 900px;
}

h2, .text-h2 {
  font-family: $headline-font;
  font-weight: bold;
  font-size: 33px;
  line-height: 62px;
  letter-spacing: 2.58px;
}

h3, .text-h3 {
  font-family: $headline-font;
  font-weight: bold;
  font-size: 24px;
  line-height: 32px;
  letter-spacing: 0.52px;
}

h4, .text-h4 {
  font-family: $body-font;
  font-weight: bold;
  font-size: 24px;
  line-height: 40px;
  letter-spacing: 0.56px;
}

h5, .text-h5 {
  font-family: $body-font;
  font-size: 20px;
  line-height: 28px;
  letter-spacing: 0.48px;
  font-weight: normal;
}

p, .text-p {
  font-family: $body-font;
  font-size: 18px;
  font-weight: 300;
  letter-spacing: 0.75px;
  line-height: 26px;
}

.btn-primary, .btn-navy, .btn-teal {
  background-color: $teal;
  border-radius: 4px;
  color: $gray;
  text-shadow: unset;
  text-transform: uppercase;
  font-weight: bold;
  letter-spacing: 0.71px;
  line-height: 24px;
  width: 247px;
  &:hover {
    background-color: #2DCEC8;
    transition: background-color .35s;
  }
}

.btn-primary-alt, .btn-navy-alt, .btn-teal-alt {
  background-color: transparent;
  border: 2px solid $teal;
  color: $teal;
  border-radius: 4px;
  text-shadow: unset;
  text-transform: uppercase;
  font-weight: bold;
  letter-spacing: 0.71px;
  line-height: 24px;
  width: 247px;
  &:hover {
    background-color: $teal;
    box-shadow: unset;
    color: $gray;
    transition: color .35s, background-color .35s, box-shadow .35s;
  }
}

#jumbotron-container-fluid {
  background-image: url(/images/pages/impact/BannerImage.png);
  background-size: cover;
  background-repeat: no-repeat;
  background-position: center center;
  height: 580px;
  width: 100%;
  margin: auto;

  display: flex;
  align-items: center;
  justify-content: center;
  flex-direction: column;
  text-align: center;

  & > h1 {
    font-size: 45px;
    letter-spacing: 1.96px;
    line-height: 62px;
    max-width: 801px;
    margin: 100px auto 25px;
  }
  .header-img {
    width: 25em;
    margin-bottom: 1.8em;
  }
}

#star-page {
  .width-container {
    max-width: 1170px;
    float: unset;
    margin: 0 auto;
    display: flex;
    flex-direction: column;
    align-items: center;
  }

  .champion-group-row {
    padding-top: 40px;
    .champ-panel{
      text-align: center;
      border: #1C5439 1px solid ;
      box-shadow: #68D321 0 0 5px 2px;
    }
    .group-panel{
      max-width: 1070px;
      margin-top: 10px;
      flex-direction: column;
      align-items:center;

      .names {
        margin-top: 20px;
        display: flex;
        flex-wrap: wrap;
      }
    }
  }
  .champion-row {
    padding-top: 40px;
    .champ-panel{
      text-align: center;
      border: #1C5439 1px solid ;
      box-shadow: #68D321 0 0 5px 2px;
    }
  }
  .row-dark .champion-group-row .champ-panel{
    border: none;
    box-shadow: none;
  }
  .row-dark .champion-row .champ-panel{
    border: none;
    box-shadow: none;
  }
  .title.text-gradient {
    color: #FFAE00;
    background: -webkit-linear-gradient(-80deg, #FFE600, #FFAE00);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
  }
  .title-row {
    display: flex;
    flex-wrap: wrap;
    justify-content: space-around;
    align-items: center;
    width: 1000px;
  }
  .rank-row {
    display: flex;
    align-items: center;
    justify-content: center;

  }
  .group-row{
    padding-top: 60px;
  }

  .group-desc-row {
    padding-top: 40px;
    .group-panel{
      max-width: 1070px;
      justify-content: space-between;
      .name{
        width: 45%;
        display: flex;
        .username{
          width: 4em;
        }
      }
    }
  }
  .group-panel{
    max-width: 1070px;
    width: 80vw;
    margin-top: 60px;
    margin-bottom: 50px;
    border-radius: 5px;
    border: #1C5439 1px solid ;
    padding: 50px 35px;
    box-shadow: #68D321 0 0 5px 2px;
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    font-size: 22px;

    .name{
      margin-left: 4px;
      margin-right: 4px;
    }
  }
  .row-dark .group-panel {
    max-width: 1070px;
    background-color: white;
    border: none;
    box-shadow: none;
  }
  .flex-row{
    display: flex;
  }
  .flex-center {
    display: flex;
    flex-direction: column;
    align-items: center;
  }
  .champ-panel {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: space-around;
    background-color: white;
    margin-left: 20px;
    margin-right: 20px;
    margin-top: 100px;
    margin-bottom: 80px;
    border-radius: 5px;
    height: 360px;
    width: 300px;
    .rank-img{
      width: 160px;
    }
  }

  .title-part {
    min-width: 25%;
    display: flex;

    flex-direction: column;
    align-items: center;

    .value{
      border-left: 0;
      border-right: 0;
      font-size: 30px;
      font-family: bold;
      position: relative;

    }
    &.margin-left{
      margin-left: 10%;
    }
    &.margin-left-2{
      margin-left: 8%;
    }
    .value::after{
      content: ' ';
      position: absolute;
      left: 0;
      bottom: -6px;
      width: 100%;
      height: 5px;
      background-color: #FF6473;
    }

    .title {
      font-size: 20px;
      text-align: center;
    }
  }

  & > .row {
    padding-top: 62px;
  }

  overflow: hidden;
}
.scroll-arrow {
  height: 32px;
  width: 100%;
  display: flex;
  .left-arrow {
    border-bottom: 32px solid white;
    border-right: 50px solid transparent;
    height: 0;
    width: 50%;
  }
  .right-arrow {
    border-bottom: 32px solid white;
    border-left: 50px solid transparent;
    height: 0;
    width: 50%;
  }
}

#featured-partner-story {
  text-align: center;
  min-height: 193px;
  &.row {
    padding-top: 52px;
  }

  display: flex;
  flex-direction: column;

  & > h2 {
    flex-grow: 1;
  }

}

.bobby-duke {
  padding-top: 60px;
  padding-bottom: 60px;
  .title {
    margin-bottom: 40px;
  }
  h1 {
    margin-bottom: 12px;
  }
  h2 {
    letter-spacing: 0.66px;
    line-height: 30px;
    font-family: $body-font;
  }

  img {
    max-width: 165px;
  }
}

#body-text-content > p {
  margin-bottom: 24px;
  margin-left: 12px;
}

.row.teacher-quote {
  text-align: center;

  img {
    height: 33px;
    width: 35px;
    margin-bottom: 24px;
  }

  h3 {
    letter-spacing: 0.48px;
    margin-bottom: 10px;
  }

  p {
    font-size: 16px;
    line-height: 30px;
    letter-spacing: 0.32px;
    font-weight: 600;
  }
}

.quote-flex-container {
  display: flex;
  & > div {
    display: flex;
    flex-direction: column;
  }

  & > div:first-child {
    margin-right: 15px;
  }
}

.read-full-story {
  text-align: center;

  & > a.btn-primary {
    background-color: $gold;
    color: $gray;
    font-size: 18px;
    letter-spacing: 0.71px;

    &:hover {
      background-color: #FDD147;
    }
  }
}

#more-partner-stories {
  margin-top: 62px;
  h1 {
    text-align: center;
    padding-bottom: 45px;
  }

  #partner-story-tiles {
    padding-bottom: 62px;
    display: flex;
    @media (max-width: $screen-md-min) {
      flex-direction: column;
    }
    .partner-story-tile {
      background-color: white;

      display: flex;
      flex-direction: column;
      justify-content: space-between;
      align-items: center;

      margin: 0 14px;
      padding: 30px;
      border-radius: 6px;

      img.tile-header-img {
        margin-bottom: 22px;
        padding: 0 14px;
      }

      .inner-tile-school {
        &>div:first-child {
          padding-right: 0;
        }

        p {
          font-size: 14px;
          letter-spacing: 0.58px;
          line-height: 19px;
          color: $gray;
          margin-bottom: 26px;
        }
      }
    }

    h4 {
      font-size: 18px;
      line-height: 22px;
      letter-spacing: 0.75px;
    }
  }
}

#teachers-love-codecombat {
  padding-bottom: 62px;

  h1.text-teal {
    margin-bottom: 45px;
  }

  h4 {
    line-height: 30px;
    letter-spacing: 0.48px;
    margin: 0 auto 45px;
    max-width: 320px;
  }

  img {
    margin-bottom: 20px;
  }

  .mcrel-blurb {
    font-size: 18px;
    letter-spacing: 0.75px;
    line-height: 26px;
    font-style: italic;
    margin-bottom: 0;
  }

  .btn.btn-primary.btn-lg {
    width: unset;
    margin-bottom: 45px
  }

}

#teacher-student-spotlight {
  & > div:nth-child(1) {
    display: flex;
    flex-direction: column;
  }

  padding-bottom: 62px;

  h2 {
    margin-bottom: 45px;
  }
  #teacher-student-tiles {
    display: flex;

    @media (max-width: $screen-md-min) {
      flex-direction: column;
    }

    .teacher-student-tile {
      margin: 15px;
      background-color: white;
      border-radius: 6px;
      padding: 9px 45px 10px;

      display: flex;
      flex-direction: column;
      justify-content: space-between;

    }
  }

  .teacher-description {
    display: flex;
    align-items: center;

    min-height: 133px;
    margin-bottom: 20px;
    border-bottom: 2.59px $teal solid;

  }

  h3 {
    font-size: 20px;
    line-height: 30px;
    letter-spacing: 0.4px;
  }

  h5 {
    font-size: 18px;
    line-height: 24px;
    letter-spacing: 0.36px;
  }

  .teacher-thumbnail {
    padding: 0;
  }

  .teacher-bio {
    padding: 0 0 0 10px;
  }

  .continue-reading-link {
    font-size: 14px;
    line-height: 19px;
    letter-spacing: 0.58px;
  }
}

#global {
  &.row {
    padding-top: 0;
    padding-bottom: 12px;
  }
  .row {
    padding: 62px 15px 0;
  }
  img {
    height: 82px;
  }
  h2.text-teal {
    margin-bottom: 30px;
  }
  h2.text-navy {
    margin-top: 14px;
    margin-bottom: -14px;
  }
  h5 {
    font-weight: normal;
  }
  .col-xs-6 {
    padding: 10px 15px;
  }
}

</style>
