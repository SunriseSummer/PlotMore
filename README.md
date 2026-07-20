# PlotMore/泼墨：仓颉科学绘图库

基于仓颉图形库 [`CangjieSDL`](https://github.com/SunriseSummer/CangjieSDL) 构建的科学绘图库，提供 15 类常用图表绘制能力，以现代优雅的视觉
设计生动呈现，并提供一套可选的交互组件。

泼墨的图表描述与渲染完全分离：`Figure` 建立图表数据模型，`PlotWindow` 作为绘图容器。`Figure` 不持有窗口和渲染器等资源，既可以在窗口中交互展示，也可以导出为图像内存数据或文件使用。

## 开发环境

- Cangjie SDK `1.0.5`
- Windows/Mac/Linux
- 参阅 [`CangjieSDL`](https://github.com/SunriseSummer/CangjieSDL) 项目文档，根据目标平台规格配置 SDL 和 SDL_ttf 动态库

执行单元测试，确认开发环境和项目可正常使用：

```shell
cjpm test
```

## 快速开始

执行 `cjpm init` 新建仓颉项目，在 `cjpm.toml` 中配置依赖本包，然后在 `src/main.cj` 中写入代码：

```cangjie
import plot.{Figure, PlotWindow}
import plot.series.LineSeries

main() {
    let (figure, axes) = Figure.single(title: "阻尼振荡")
    axes.xLabel = "时间 (s)"
    axes.yLabel = "振幅"

    let series = LineSeries(times, values, label: "通道 1")
    series.fillTo = Some(0.0)
    axes.add(series)

    let window = PlotWindow(figure)
    let _ = window.addStandardToolbar()   // 保存 / 缩放 / 平移 / 复位 / 网格 / 主题
    window.show()
}
```

执行 `cjpm run` 即可运行查看效果。

也可以将 `Figure` 导出为 PNG 图片文件，无需窗口：

```cangjie
FigureExport.renderToPng(figure, "figure.png", width: 1200, height: 800)
```

## 文档与示例

- [入门指南](docs/guide/index.md)
- [API 参考](docs/api/index.md)
- [示例集合](examples/)：28 个典型图表绘制示例，快速参考复用。
