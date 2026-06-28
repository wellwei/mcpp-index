# mcpp-index 文档

给本仓贡献者(人 / agent 共用)的参考文档。新增一个包的**端到端 SOP** 在 agent skill
[`add-mcpp-index-package`](../.agents/skills/add-mcpp-index-package/SKILL.md);下面是各环节的细节参考。

| 文档 | 内容 |
|------|------|
| [package-types.md](package-types.md) | 四种库形态(C 源 compat / header-only / C++23 module wrapper / 外部 Form-A 模块仓)的描述符模板 + 真实样例 |
| [cn-mirror.md](cn-mirror.md) | GitCode `mcpp-res` CN 镜像闭环(`gtc` 工具、闭环校验、踩坑),含**无 `mcpp-res` 写权限时的回退**(plain-string 上游 url) |
| [repository-and-schema.md](repository-and-schema.md) | 仓库布局、描述符 schema 速查、`validate.yml` CI 行为、一把梭本地 lint、真实案例表 |

> 包的**字段规范**(`mcpp = { … }` 扩展)以上游为准:
> [mcpp docs/04-schema-xpkg-extension.md](https://github.com/mcpp-community/mcpp/blob/main/docs/04-schema-xpkg-extension.md)。
