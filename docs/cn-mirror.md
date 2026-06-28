# CN 镜像闭环(gtc / gitcode / mcpp-res)

给每个包配一个国内下载镜像,让 `mcpp add/build` 在中国也快。机制 = `xpm.<plat>.<ver>.url` 从单串变成
`{ GLOBAL = "<上游>", CN = "<gitcode 镜像>" }`,解析优先级 **GLOBAL > CN**(GLOBAL 仍是默认,死了才回落 CN)。
解析方是 **xlings**(xim 引擎),不是 mcpp 的 C++ parser —— 这是 spec 驱动、走既有引擎。

- CN 布局:gitcode org **`mcpp-res`**,一库一仓,资产挂在按版本号打的 release 上。
- **repo slug = 包名去 `compat.` / `mcpplibs.` 前缀**(`compat.eigen` → `eigen`,`compat.nlohmann?` 用 `nlohmann-json` 避免裸 `json` 歧义)。
- CN 资产公网 URL 约定:
  `https://gitcode.com/mcpp-res/<slug>/releases/download/<ver>/<slug>-<ver>.<ext>`

## 没有 `mcpp-res` 写权限时的回退

建镜像需要 gitcode `mcpp-res` org 的写权限(token)。**拿不到时不要硬凑镜像表** —— lint
(`check_mirror_urls.lua`)强制:`url` 一旦写成表,`CN` **必须**是 `https://gitcode.com/mcpp-res/…`,
所以 `{ GLOBAL=上游, CN=上游 }` 会直接挂 lint。正确回退是**用 plain-string 单串 url**(只填上游 release),
lint 对纯字符串 url 不做镜像约束:

```lua
-- 回退:无 CN 镜像,GLOBAL/CN 都等价于上游 release(单串即可)
["0.1.1"] = { url = "https://github.com/<owner>/<repo>/releases/download/v0.1.1/<repo>-0.1.1.tar.gz",
              sha256 = "…" },
```

- CN 用户会回落到上游源(慢一点但可用),功能不受影响。
- 真实先例:`pkgs/t/tensorvia-cpu.lua`(用户自有 mcpp 库,无 CN 镜像,三平台都是上游单串 url)。
- 后续拿到权限、或由维护者补上镜像后,再把该版本的 `url` 改成 `{ GLOBAL=…, CN=… }` 表即可(sha256 不变)。

> 想表达「GLOBAL 和 CN 都走上游」就用上面的单串写法,**不要**写成 `{GLOBAL=x, CN=x}` 表(过不了 CN 必须指向
> gitcode 的 lint)。

## gtc 工具

`gtc`(`tools/gtc`,亦在 `~/.local/bin/gtc`,python,gitcode API v5)。Token 在
`~/.config/gitcode-tool/config.json`(或 `GITCODE_TOKEN` / `--token`)。登录用户 `Sunrisepeak`。

```bash
gtc repo create  <owner>/<name> [--description …] [--private]   # owner==login 走 /user/repos 否则 /orgs/<owner>/repos;幂等(422 警告)
gtc repo push    <owner>/<name> <dir> [--branch main]
gtc release create  <owner>/<repo> --tag T [--name] [--body-file] [--target] [--prerelease]   # 幂等(tag 已存在则跳过)
gtc release upload  <owner>/<repo> --tag T <file…>              # 非幂等!上传前先查现有资产
gtc release publish <owner>/<repo> --tag T [--name] [--target] [--asset FILE]   # = create + upload
gtc pr create    <owner>/<repo> --title --head --base [--body-file]
```
> `gtc` **不能建 org**;`mcpp-res` 已存在。若要新 org:`POST /api/v5/orgs` 需同时带 `name` 和 `path`。

## 标准操作(以 slug=`eigen`、ver=`5.0.1` 为例)

```bash
# 0. 下 GLOBAL 上游 tarball,算 sha256(填进描述符三平台);复算两次确认稳定
curl -L -fsS -o eigen-5.0.1.tar.gz "https://gitlab.com/libeigen/eigen/-/archive/5.0.1/eigen-5.0.1.tar.gz"
sha256sum eigen-5.0.1.tar.gz

# 1. 建仓(幂等)
gtc repo create mcpp-res/eigen --description "Eigen — CN mirror for mcpp-index"

# 2. 新仓没有分支 → 先推一个 init commit,release 才能 target main
mkdir eigen-init && echo "# Eigen — CN mirror" > eigen-init/README.md
gtc repo push mcpp-res/eigen eigen-init --branch main

# 3. 发 release + 传资产(传 GLOBAL 同一个文件 → byte-identical → 同 sha)
gtc release publish mcpp-res/eigen --tag 5.0.1 --name "Eigen 5.0.1" --target main --asset eigen-5.0.1.tar.gz

# 4. 闭环校验:CN 200 + 与 GLOBAL 字节一致
CN="https://gitcode.com/mcpp-res/eigen/releases/download/5.0.1/eigen-5.0.1.tar.gz"
curl -fsSL -o cn.tar.gz -w 'CN http=%{http_code}\n' "$CN"
[ "$(sha256sum eigen-5.0.1.tar.gz|cut -d' ' -f1)" = "$(sha256sum cn.tar.gz|cut -d' ' -f1)" ] && echo "BYTE-IDENTICAL ✓"
```

## 踩坑(全部已被前人踩过)

- **gitcode API 限流 = 25 次/分/用户** → 调用间隔 ~3.2s,遇 429 退避。
- **同名 release 资产不可覆盖**:误传只能网页删 → 命名一次定死(`<slug>-<ver>.<ext>`)。
- **新仓无分支**:不先 push init,release `--target main` 会失败。
- **内容过滤**:某些库描述/仓名被 gitcode 文本过滤拒绝 → 换中性措辞。
- **务必传 GLOBAL 同一个包**:不要把"加了文件的包"传上去 → CN ≠ GLOBAL,破坏一致性(除 `mirror-cn-reachable` 外无人察觉)。
- **sha 漂移**:GitLab 归档偶尔重打包 → sha 变;描述符 sha 必须 = 当前 GLOBAL 实际字节(下载即用,且复算两次)。
- xlings 按 sha256 全局去重:CN 与 GLOBAL 同 sha 时,本地"切 CN 重测"会被去重命中、不真打 gitcode → 验 CN 用直接 `curl`(就是上面第 4 步,也是 CI `mirror-cn-reachable` 干的)。

## CI 兜底

`.github/workflows/validate.yml` 两道闸:
- `lint` 里 `tests/check_mirror_urls.lua`:url 写成表时 **GLOBAL+CN 都得有,且 CN 必须指向 gitcode `mcpp-res` 镜像**。
- `mirror-cn-reachable`:把所有 CN url 抽出来逐个 `curl`,非 200 即失败。
