# 站点部署

博客由 Cloudflare Pages 托管，正式地址为 **https://huangboming.com**。源码保存在 GitHub，推送到 `main` 后会自动构建并发布，无需手动上传文件。

## 发布更新

1. 在本地预览，确认文章或配置修改无误。环境准备与预览命令见 [环境搭建](environment-setup.md)。
2. 建议在仓库根目录运行构建和内部链接检查，与 GitHub Actions 保持一致：

   ```shell
   bash tools/test.sh
   ```

3. 按 [Git 规则](../rules/git.md) 提交修改，再推送：

   ```shell
   git push origin main
   ```

Cloudflare 会自动安装依赖、构建并发布站点；构建失败时不会替换当前线上版本。

> Cloudflare 只负责构建和发布，GitHub Actions 负责构建和内部链接检查。两者独立运行，**CI 失败不会阻止发布**。发布后也应查看 GitHub Actions 的检查结果。

## 确认发布成功

1. 在 Cloudflare 控制台进入 **Workers & Pages → 博客项目 → Deployments**。
2. 找到本次提交对应的 **Production** 部署，确认提交记录正确、状态为成功。
3. 打开正式网址，检查本次更新的页面，以及涉及的图片、样式或评论。

站点启用了 PWA 离线缓存：首次访问会缓存页面内容，后续访问可能先显示缓存，同时在后台检查更新。

部署成功后若仍看到旧内容，先用**无痕窗口**核对线上版本，排除缓存影响，不必立即重新部署。

## 部署出问题时

| 情况 | 先检查什么 |
| --- | --- |
| 构建失败 | 打开该次部署日志，找到第一处报错，按[生产环境构建](environment-setup.md#生产环境构建)在本地复现。缺少依赖时，核对下方环境变量。 |
| 推送后没有新部署 | 确认提交已推送到 `main`，并检查 Pages 项目的 Git 仓库关联与自动部署设置。 |
| 部署成功但内容没变 | 核对部署对应的提交，再用无痕窗口排除 PWA 缓存。 |
| `pages.dev` 可访问，正式域名不可访问 | 检查项目 **Custom domains** 中的域名状态、证书和 DNS，参照 [自定义域名说明](https://developers.cloudflare.com/pages/configuration/custom-domains/)。 |

如果本次更新导致线上异常，可在 **Deployments** 中找到之前成功的生产部署，打开其操作菜单，选择 **Rollback to this deployment**。操作细节见 [回滚说明](https://developers.cloudflare.com/pages/configuration/rollbacks/)。

回滚后仍需修复仓库中的问题，再正常提交和发布。

## 配置速查

以下用于检查配置或重建部署环境，日常发布不需要修改。

| 配置项 | 值 |
| --- | --- |
| Git 仓库 | `huangboming/huangboming.github.io` |
| Production branch | `main` |
| Framework preset | `Jekyll` |
| Build output directory | `_site` |
| Root directory | 留空，使用仓库根目录 |
| 自定义域名 | `huangboming.com` |

**Build command**（整行复制到 Cloudflare）：

```shell
if [ "$(git rev-parse --is-shallow-repository)" = true ]; then git fetch --unshallow; fi && bundle exec jekyll build
```

前半段只在浅克隆时补齐 Git 历史，供文章最后修改时间使用；后半段执行 Jekyll 构建，不运行测试。

Production 和 Preview 环境变量：

| 变量 | 值 |
| --- | --- |
| `JEKYLL_ENV` | `production` |
| `RUBY_VERSION` | 与仓库 `.ruby-version` 一致，当前为 `3.4.1` |
| `BUNDLE_WITHOUT` | `development:test` |

`BUNDLE_WITHOUT` 让依赖安装和构建都跳过测试依赖。使用 Pages 默认的自动依赖安装，**不设置 `SKIP_DEPENDENCY_INSTALL`**。

升级 Ruby 时，同步更新 `.ruby-version` 和 Pages 的 `RUBY_VERSION`。构建环境的其他选项见 [Cloudflare 构建环境说明](https://developers.cloudflare.com/pages/configuration/build-image/)。

站点地址在 `_config.yml` 中配置为 `url: "https://huangboming.com"`、`baseurl: ""`。如需重新绑定域名，应从 Pages 项目的 **Custom domains** 操作，而不是只手动添加 DNS 记录。
