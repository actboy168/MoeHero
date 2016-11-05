# 我的英雄不可能那么萌

这是一张5v5的魔兽地图。由于版权的原因，没有放出资源(mdx/blp/mp3等)。

## 依赖项目

* [ydwe](https://github.com/actboy168/YDWE)
* [w3x2txt](https://github.com/syj2010syj/w3x2txt)
* [lni](https://github.com/actboy168/lni)
* [Model_Encrypt](https://github.com/syj2010syj/Model_Encrypt)

## 作者

* [actboy168](https://github.com/actboy168/)
* [最萌小汐](https://github.com/syj2010syj/)
* 幻雷
* 一文字鲲
* 德堪
* 裸奔的代码

## 编译

* 双击make.bat，生成debug版地图。debug版地图，不含script目录，地图会使用本目录内的脚本，默认开启作弊指令。
* 双击release.bat，生成release版地图。使用地图内的脚本。
* 将地图拖至make.bat，可以将地图解包。
* 对于没有resource目录的童鞋，我们准备了一个简易的模式——将模型都替换成了步兵。

## 运行&测试

* 准备好YDWE最新版本，建议在配置中，将YDWE关联w3x扩展名，这样可以通过右键地图文件来运行本地图。
* 使用make.bat打包地图，使用YDWE运行。
* 你可以在魔兽运行时修改脚本，-reload指令可以让大多数的脚本(技能、物品的脚本)立刻刷新；其余脚本可以重启游戏后生效(无须重启魔兽)。

## vscode的支持

* 确保你已经用YDWE关联了w3x文件
* ctrl+shift+b 运行地图 (在此之前，你需要先编译过地图)
* ctrl+p 输入task，会列出几个快捷操作，分别是 运行、配置、语法检查
* 安装推荐的插件
* status-bar-tasks task会出现在左下方状态栏，适合不想输入指令的人
* lua-debug 先运行地图，ctrl+shift+d可以启动调试
