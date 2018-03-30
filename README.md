# 我的英雄不可能那么萌

这是一张5v5的魔兽地图。由于版权的原因，没有放出资源(mdx/blp/mp3等)。

## 依赖项目

* [ydwe](https://github.com/actboy168/YDWE)
* [w3x2lni](https://github.com/sumneko/w3x2lni)
* [lni](https://github.com/actboy168/lni)

## 作者

* [actboy168](https://github.com/actboy168/)
* [最萌小汐](https://github.com/sumneko/)
* 幻雷
* 一文字鲲
* 德堪
* 裸奔的代码

## 开发环境

* YDWE，请使用最新的版本，并且确保你已经用YDWE关联了w3x文件。
* VSCode，构建支持。
* **非必选** VSCode插件`lua-debug`，提供调试地图的功能。
* **非必选** VSCode插件`status-bar-tasks`，task会出现在左下方状态栏，适合不想输入指令的人。

## 编译&运行

在VSCode中，`ctrl+p`，输入`task`，会列出可用的Task。使用`status-bar-tasks`的情况下，Task会直接出现在下方的状态栏上。

* 运行。测试地图，注意这个操作不会重新打包地图。
* 配置。打开YDWE的配置界面。
* 语法检查。检查地图脚本是否有语法错误。这个最好不要用插件来运行，因为这样会丢失一部分功能。
* 🔍。同样是语法检查，并且它会一直检测所有脚本是否有语法错误。
* Obj。打包Obj格式的地图，以便供YDWE打开来编辑物编、供魔兽运行地图。
* Lni。打包Lni格式的地图，用YDWE编译过Obj格式的地图后，需要打包成Lni来提交Git。
* Slk。打包Slk格式的地图，用于发布的版本。

地图的打包流程使用`w3x2lni`完成，同时我们做了几个插件以实现一些特殊的功能，包括：

* 我们会对resource目录的包做特殊处理(因为有些人可能没有resource目录)。对于没有resource目录的人，我们会帮你把模型全部替换成步兵。
* 打包成Obj格式时，我们不会打包脚本文件，同时给地图注入一些代码，以便地图可以在运行时读取本地硬盘上的脚本(而不是地图内的)。这样你可以实时修过脚本，并通过-reload指令让它立刻生效。

## 调试

安装`lua-debug`之后，按F5可以直接运行地图，并激活调试。

