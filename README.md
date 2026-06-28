# mcpp-index

> [`mcpp`](https://github.com/mcpp-community/mcpp) 构建工具的默认包索引仓库
> · 在线浏览所有包 **https://mcpplibs.github.io/mcpp-index/**

收录可被 `mcpp` 直接 `add` 的 C++23 包:既有 `import` 即用的模块化库,也有以 `compat` 形态从上游源码/头
构建的第三方 C/C++ 库。每个包是一个 `pkgs/<首字母>/<包名>.lua` 描述文件。

## 使用

```bash
mcpp add ftxui@6.1.9            # 添加依赖到 mcpp.toml
mcpp build                     # 自动拉取源码 + 构建(依赖沿链路自动传递)

mcpp search <keyword>          # 搜索 / 刷新索引
mcpp self config --mirror CN   # 切到国内镜像(默认走 GLOBAL 上游源)
```

完整包列表见 **[在线索引站](https://mcpplibs.github.io/mcpp-index/)**。

## 包生态与贡献

收录两类包:

- **原生 mcpp 模块库** — 以 C++23 模块发布、`import` 即用(如 `mcpplibs.*`、`nlohmann.json`、`imgui`)。
  上游多自带 `mcpp.toml`,描述文件只声明元数据与下载地址。
- **第三方 C/C++ 库(`compat`)** — 上游无 mcpp 支持,在描述文件里内联构建信息:header-only、纯 C 源码、
  C++23 module wrapper 等不同形态,可选组件经 `features` 门控,并配 GitCode CN 镜像。

**新增一个包** → 参考 agent skill [`add-mcpp-index-package`](.agents/skills/add-mcpp-index-package/SKILL.md):
完整 SOP —— 四种库形态模板、`gtc` CN 镜像闭环、`features` 门控、本地 + CI 验证。字段规范见
[mcpp 扩展字段文档](https://github.com/mcpp-community/mcpp/blob/main/docs/04-schema-xpkg-extension.md)。

> 开 PR 后 `validate` 自动 lint + 按改动库选跑示例;合入后 `deploy-site` 发布到浏览站。

## 相关链接

| 项目 | 说明 |
|------|------|
| [mcpp](https://github.com/mcpp-community/mcpp) | 现代 C++23 构建 & 包管理工具 |
| [xlings](https://github.com/d2learn/xlings) | mcpp 底层包安装引擎 + 沙箱 |
| [xpkg V1 spec](https://github.com/d2learn/xim-pkgindex/blob/main/docs/V1/xpackage-spec.md) | 包描述文件规范 |
| [mcpplibs](https://github.com/mcpplibs) | mcpp 生态的模块化 C++23 库 |
| [mcpp-res](https://gitcode.com/mcpp-res) | 包资源 CN 镜像组织(gitcode) |

## 社区

[mcpp issues](https://github.com/mcpp-community/mcpp/issues) · [d2learn 论坛](https://forum.d2learn.org)

## License

包描述文件 CC0;各上游库保留其自身许可证。
