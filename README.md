<div style="white-space: nowrap; display:inline; overflow-x: auto; white-space: nowrap;">
  <img src="https://github.com/user-attachments/assets/957d9a84-e81e-4d67-8b9e-50c2149c3ae0" alt="playstore-icon" width="64" height="64" style="display: inline-block;">
  <h1 style="display: inline-block;">RankHub</h1>
</div>

>**25.2.18 更新**
>
>目前正在着手进行对 MuseDash(喵斯快跑) 的支持，一方面是想写点新东西了，另一方面是一直写 mai 一个相关的东西，很多地方耦合性有点强了，做一下解耦。

>**25.1.26 更新**
>
>成绩同步方面已经被内建代理服务器打败了（当然还是会探索这方面的可能性），打算直接上落雪的代理了（水鱼的话应该是用 bakapiano 的代理），iOS App 建立 VPN 连接需要 ADP 账号，在纠结要不要花这 688...
><br><br>曲绘识别相关的问题仍然没有头绪，有没有大神帮帮我😭（暂时剔除相关功能，有突破了再说）
><br><br>还有就是主播临近期末，更新会比较慢，计划 2025 年三月前发布一个含稳定功能的初版

- 部分界面优化
- (maimai) 添加个人信息页
- 正在进行对 MuseDash 的支持
- 计划重构 Assets 的管理
- 计划添加 Simai 谱面下载功能

有任何问题可以提交 Issue 反馈

---

学习下的产物，存在大量可见的未完工的地方。

待项目重构后，未来有计划打造一个音游查分聚合平台（幻想）。

你可以在 [这里](https://github.com/qianmo2233/RankHub/actions/workflows/build_app.yml) 下载最新的构建（包括 Android & iOS）（iOS 端需自行签名后安装）

> 25.2.19 通知：目前 Android 平台因 [这个问题](https://github.com/mafreud/gallery_saver_plus/issues/7) 暂时无法构建，有需要的可以参考 [这个 PR](https://github.com/mafreud/gallery_saver_plus/pull/8) 自行修复后构建。

> ~vivo 688 我上架 TestFight 和 AppStore，以及添加更多功能~

> [!WARNING]
> 目前项目仍在开发，你可能会看到一些意义不明的按钮，或没有实际功能的界面，无需理会

> [!NOTE]
> 部分代码使用 AI 辅助编写

## 目前支持

- 舞萌 DX (落雪查分器)
  - B50图生成
  - 成绩查询
  - 曲目查询
  - 谱面确认搜索
  - 成绩同步
  - 游玩统计 Heatmap
  - ~~曲绘识别（但存在较大的问题，勉强能用）~~(暂时就先别用了，搞好其他的再说)
  - （TODO）进度查询
  - （TODO）Rating 趋势
  - （TODO）推分建议
  - ~~（TODO）更方便的成绩同步~~（？）
  > 所谓 **”更方便的成绩同步“** 大概率是不会搞的，写这功能自己还要维护一个后端，被滥用还有可能会暴毙

- MuseDash (musedash.moe) **(In Progress)**
  - 曲目查询
  - 排行榜查询
  - MOE PTT 相关
  - MD RAT 相关
  - more...

项目重构后计划支持更多游戏。


## 部分截图

<div style="overflow-x: auto; white-space: nowrap;">
    <img src="https://github.com/user-attachments/assets/33d3f0dd-d90e-4b99-8bc0-6dc8f805b116" alt="089E5066-4639-45DC-8560-823DE0812AE5" style="width: 19%; display: inline-block; margin-right: 10px;">
    <img src="https://github.com/user-attachments/assets/eef1f5ad-c5fc-442b-a35e-3780de26966e" alt="9250E369-6509-44D8-A2E5-5C64FF26B064" style="width: 19%; display: inline-block; margin-right: 10px;">
    <img src="https://github.com/user-attachments/assets/bcdc77f0-2cdd-464b-8575-7f29f99a642f" alt="DB8DAF82-B0E2-4F7B-8D44-5990FF10E70F" style="width: 19%; display: inline-block; margin-right: 10px;">
    <img src="https://github.com/user-attachments/assets/8833e0dc-23d7-4ffc-a4d6-5c0a99c2cf42" alt="IMG_4200" style="width: 19%; display: inline-block; margin-right: 10px;">
    <img src="https://github.com/user-attachments/assets/fdc440e5-dd1f-40c6-920c-41f7cb554aed" alt="IMG_4201" style="width: 19%; display: inline-block; margin-right: 10px;">
</div>


