# 搜索引擎收录

在 Google Search Console（GSC）和 Bing Webmaster Tools 中添加站点，需要先验证所有权，再提交站点地图（Sitemap）。这些操作通常每个站点只需做一次，日常发文不必重复添加站点。

**验证成功或 Sitemap 提交成功，不代表文章已经收录，也不保证一定收录。** 后续用各平台的网址检查工具查看具体页面的状态。

## 提交前确认

先确认以下地址无需登录即可访问：

| 内容 | 地址 |
| --- | --- |
| 正式站点 | https://huangboming.com/ |
| Sitemap | https://huangboming.com/sitemap.xml |
| 爬虫规则 | https://huangboming.com/robots.txt |

项目已通过 `jekyll-sitemap` 自动生成 Sitemap 和 `robots.txt`，不需要手工创建。Sitemap 中的网址应以 `https://huangboming.com/` 开头；如不正确，检查 `_config.yml` 的 `url` 和 `baseurl`，再按 [站点部署](deployment.md) 发布。

## Google Search Console

### 添加网域资源并验证

推荐使用 **网域资源（Domain property）**，覆盖该域名的所有协议和子域名。

1. 登录 [Google Search Console](https://search.google.com/search-console/)，在资源选择器中点击 **添加资源（Add property）**。
2. 选择 **网域（Domain）**，填写 `huangboming.com`，不要带 `https://` 或路径。
3. 选择手动添加 **TXT 记录**，复制 GSC 给出的完整验证字符串。
4. 在 Cloudflare 中选择域名 `huangboming.com`，进入 **DNS → Records → Add record**，新增以下记录：

   | 字段 | 值 |
   | --- | --- |
   | Type | `TXT` |
   | Name | `@`，表示根域名 |
   | Content | GSC 提供的完整字符串，形如 `google-site-verification=...` |
   | TTL | `Auto` |

5. 保存记录，回到 GSC 点击 **验证（Verify）**。如果暂时找不到记录，等待 DNS 生效后重试。

只新增验证用的 TXT 记录，不要修改 Pages 正在使用的域名解析。**验证成功后也要保留 TXT 记录**，Google 会定期复核所有权。Cloudflare 操作细节见 [DNS 记录管理](https://developers.cloudflare.com/dns/manage-dns-records/how-to/create-dns-records/)。

### 提交 Sitemap

1. 在 GSC 中选择刚验证的 `huangboming.com` 资源。
2. 打开 **站点地图（Sitemaps）**，提交完整地址 `https://huangboming.com/sitemap.xml`。
3. 等待处理，确认状态为 **成功（Success）**。这个状态只表示 Sitemap 可以被读取，不表示其中的所有页面已收录。

## Bing Webmaster Tools

### 从 GSC 导入（推荐）

先完成上面的 GSC 验证和 Sitemap 提交，再操作：

1. 登录 [Bing Webmaster Tools](https://www.bing.com/webmasters/)。
2. 选择 **从 Google Search Console 导入（Import from Google Search Console）**，登录拥有该资源权限的 Google 账号，按提示授权读取站点和 Sitemap。
3. 选择对应 `huangboming.com` 的站点并导入。导入成功的站点会自动完成 Bing 所有权验证，无需再添加验证码。
4. 打开该站点的 **Sitemaps**，确认已包含 `https://huangboming.com/sitemap.xml`；如果没有，手动提交这个完整地址，并确认处理结果无错误。

Bing 会通过 GSC 定期复核所有权。如果以后撤销授权，需要重新连接，或改用其他验证方式。

### 手动添加与 HTML 标签验证（备用）

不想授权 GSC、导入失败或找不到对应站点时，可以使用项目已有的验证标签配置：

1. 在 Bing 选择手动添加站点，填写 `https://huangboming.com/`。
2. 选择 **HTML Meta Tag** 验证方式，复制 `<meta name="msvalidate.01" content="...">` 中的 **`content` 值**，不要复制整个标签。
3. 将该值填入 `_config.yml` 已有的 `webmaster_verifications.bing` 字段。以下仅展示相关字段，保留同一节点下的 `google` 等其他配置：

   ```yaml
   webmaster_verifications:
     bing: "替换为 Bing 提供的 content 值"
   ```

4. 如果修改了配置，按 [站点部署](deployment.md) 提交并发布。查看线上首页的网页源代码，确认 `<head>` 中的 `msvalidate.01` 标签与 Bing 要求的值一致，再回到 Bing 点击 **Verify**。
5. 验证成功后，在 **Sitemaps** 提交 `https://huangboming.com/sitemap.xml`。继续保留验证配置，避免后续复核失败。

> `_config.yml` 已有 Google 和 Bing 验证码，但这不等于当前域名已在你的账号中通过验证，应以平台结果为准。`webmaster_verifications.google` 生成的是 HTML 验证标签，只适用于 GSC 的**网址前缀资源**，不能代替上面的网域 DNS 验证。

## 日常检查与排查

- 正常发文、推送和部署后，Sitemap 会自动更新，不必每篇文章都重新提交 Sitemap。
- 想检查某篇文章时，在 GSC 的 **网址检查（URL inspection）** 或 Bing 的 **URL Inspection** 中输入文章完整网址；需要时再按平台提示请求编入索引。
- 抓取、索引和报表更新需要时间，不以提交后立即能否搜索到文章作为成功标准。

| 情况 | 先检查什么 |
| --- | --- |
| GSC 找不到 TXT 记录 | 确认记录加在 `huangboming.com` 的 DNS 中、名称为 `@`，内容与 GSC 完全一致；可用 `dig +short TXT huangboming.com` 检查，再等待生效。 |
| Bing 找不到 HTML 标签 | 确认配置已发布到正式域名，并检查首页源代码，不只看本地文件或浏览器缓存。 |
| Sitemap 抓取失败 | 确认提交地址正确，返回的是 XML 而非登录页、错误页或 Cloudflare 挑战页，并检查 `robots.txt` 是否阻止抓取。 |
| Sitemap 成功但文章未收录 | 用网址检查工具查看该文章的具体原因，区分尚未抓取、被禁止索引或规范网址不同等情况。 |

## 官方说明

- [Google：验证网站所有权](https://support.google.com/webmasters/answer/9008080?hl=zh-Hans)
- [Google：站点地图报告](https://support.google.com/webmasters/answer/7451001?hl=zh-Hans)
- [Bing：从 GSC 导入已验证站点](https://blogs.bing.com/webmaster/2019/9/Import-sites-from-Search-Console-to-Bing-Webmaster-Tools/)
- [Bing：添加站点、验证与提交 Sitemap](https://blogs.bing.com/webmaster/June-2025/Start-Using-Bing-Webmaster-Tools-to-Improve-Your-Site-Visibility)
