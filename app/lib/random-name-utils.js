const { uniqueNamesGenerator, adjectives, colors, animals } = require('unique-names-generator')

const randomEnName = () => uniqueNamesGenerator({ dictionaries: [adjectives, colors, animals] }) // big_red_donkey

const cnAdjs = [
  '秃头的', '摆烂的', '咸鱼的', '傲娇的', '脆皮的', '精神的', '佛系的', '进击的', '潜水的', '破防的',
  '软萌的', '脸红的', '芝士的', '糯叽叽', '馋嘴的', '治愈的', '甜甜的', '冒泡的', '奶思的', '勇敢的',
  '赛博', '极客', '霓虹', '虚幻的', '暴躁的', '暗黑的', '像素', '硬核', '蓝光的', '机械',
  '森林的', '迷雾的', '微醺的', '炽热的', '清新的', '慵懒的', '逐风的', '晚霞的', '浪漫的', '孤傲的',
  '疯狂的', '闪耀的', '绝版的', '无敌的', '快乐的', '暴走的', '飞天的', '满级的', '逆天的', '欧气的',
]

const cnNouns = [
  '熊猫', '柴犬', '锦鲤', '兔兔', '树懒', '仓鼠', '企鹅', '小象', '橘猫', '考拉',
  '奶茶', '饭团', '冰淇淋', '拿铁', '小龙虾', '蛋挞', '烧烤', '煎蛋', '甜筒', '薯条',
  '程序员', '饲养员', '观察员', '飞行员', '艺术家', '锦鲤王', '打工人', '收藏家', '梦想家', '体验生',
  '仙人掌', '盲盒', '唱片', '气泡', '信号灯', '纸飞机', '罐头', '尤克里里', '魔方', '望远镜',
  '极光', '孤岛', '宇宙', '银河', '星辰', '晚风', '回声', '碎冰', '极星', '烟火',
]

const randomChineseName = () => uniqueNamesGenerator({
  dictionaries: [cnAdjs, cnNouns],
  separator: '', // No space for Chinese names
  length: 2,
})

export const randomName = () => {
  if (features?.chinaInfra) {
    return randomChineseName()
  } else {
    return randomEnName()
  }
}