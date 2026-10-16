# RSS 订阅

订阅地址为 **https://huangboming.com/feed.xml**。格式是 Atom，常见 RSS 阅读器可以直接订阅。

## 提供的内容

- 最近 20 篇已发布文章，按发布时间倒序排列；不足 20 篇时提供全部文章。
- 每篇同时提供摘要、完整正文、原文链接和作者信息。
- 图片和正文链接转换为绝对地址，不依赖博客网页的脚本或样式。

读者可以点击侧栏的 RSS 图标，或在支持自动发现的阅读器中直接输入博客网址。正常发布文章后 Feed 自动更新，无需单独维护。

## 维护位置

| 内容 | 位置 |
| --- | --- |
| Feed 模板与篇数限制 | `assets/feed.xml`，覆盖 Chirpy 的同名模板 |
| 图片与链接地址处理 | `_plugins/feed-content.rb` |
| 阅读器自动发现 | `_includes/metadata-hook.html` |
| 作者姓名、个人页面 | `_config.yml` 的 `author`；`social.name` 通过 YAML 引用共享姓名 |
| Feed 逻辑测试 | `tests/feed_test.rb` |
| 构建产物检查 | `tests/site_metadata_test.rb` |

修改域名时，除了 `url`，也要更新作者个人页面的 `author.url`。保留 `/feed.xml` 地址和以文章原文地址作为 ID 的规则，避免已有订阅失效或文章被重复识别。

Nokogiri 用于解析 Feed 正文中的 HTML，是构建依赖，不属于仅供 CI 使用的测试依赖。升级主题时保留上述覆盖文件，并检查生成结果。

## 验证修改

在仓库根目录运行：

```shell
bash tools/test.sh
```

该入口会构建站点，运行 `tests/` 中的逻辑测试和构建产物检查，再检查内部链接。测试覆盖 Feed 模板与 XML、图片及链接处理、作者结构化数据和自动发现标签，不逐段比较主题渲染后的正文。

只检查 Feed 逻辑、不重新构建站点时，可以运行：

```shell
bundle exec ruby tests/feed_test.rb
```

`tests/` 已从站点构建中排除，不会发布到线上。涉及 Mermaid、MathJax 等依赖 JavaScript 的内容时，阅读器不一定能呈现网页效果，需打开原文查看。
