# 更换网站图标（Favicon）

网站图标位于 `assets/img/favicons/`，由 Chirpy 主题自动引用，无需覆盖主题模板。

## 设计与源文件

`assets/img/favicons/favicon.svg` 是唯一的可编辑源文件，同时直接供支持 SVG favicon 的浏览器使用。当前设计为「猫耳终端」：猫耳呼应侧栏头像，`>_` 表达技术探索。

- 浏览器图标保持透明背景，黑色描边与白色外边框兼顾浅色、深色标签栏。
- Apple Touch 和 PWA 图标使用不透明的深石板蓝灰底色（`#2D3748`）。
- 光标动画保留在 SVG 注释中，默认静态显示；如需恢复可取消注释，但不同浏览器对 favicon 动画的支持不一致。
- 修改 SVG 后，重新生成其余图标，不单独编辑 PNG 或 ICO。

## 重新生成图标

需要 **librsvg**（提供 `rsvg-convert`）和 **ImageMagick**：

```shell
brew install librsvg imagemagick
```

在仓库根目录执行：

```shell
icons=assets/img/favicons
source="$icons/favicon.svg"
tmp_dir=$(mktemp -d)

# 现代浏览器 PNG，保留透明背景
rsvg-convert -w 96 -h 96 "$source" -o "$icons/favicon-96x96.png"

# 分别渲染各尺寸，再合并成多尺寸 ICO
for size in 16 32 48; do
  rsvg-convert -w "$size" -h "$size" "$source" -o "$tmp_dir/favicon-$size.png"
done
magick "$tmp_dir/favicon-48.png" "$tmp_dir/favicon-32.png" "$tmp_dir/favicon-16.png" \
  "$icons/favicon.ico"

# 主屏幕和普通 PWA 图标使用不透明背景
rsvg-convert -w 180 -h 180 -b '#2D3748' "$source" -o "$icons/apple-touch-icon.png"
rsvg-convert -w 192 -h 192 -b '#2D3748' "$source" -o "$icons/web-app-manifest-192x192.png"

# 512px 图标在 manifest 中标记为 maskable，需要额外的裁切安全边距
rsvg-convert -w 348 -h 348 --page-width 512 --page-height 512 --left 82 --top 82 \
  -b '#2D3748' "$source" -o "$icons/web-app-manifest-512x512.png"
```

512px 图标将图形缩小并居中放置，使当前猫耳终端完整落在安全圆内（以图像中心为圆心，半径为边长的 40%）。如果以后修改轮廓，需要重新检查安全边距，避免系统将图标裁成圆形等形状时切掉猫耳。

## 文件清单

| 文件 | 尺寸 | 用途 |
|------|------|------|
| `favicon.svg` | 矢量 | 可编辑源文件、现代浏览器图标 |
| `favicon.ico` | 16、32、48px | 经典浏览器图标 |
| `favicon-96x96.png` | 96×96 | 浏览器 PNG 图标、Feed 标志 |
| `apple-touch-icon.png` | 180×180 | iOS 主屏幕 |
| `web-app-manifest-192x192.png` | 192×192 | PWA 普通图标 |
| `web-app-manifest-512x512.png` | 512×512 | PWA 可裁切图标（`maskable`） |
| `site.webmanifest` | — | PWA 配置；图标路径和尺寸不变时无需修改 |

## 验证

1. 检查 PNG 和 ICO 尺寸：

   ```shell
   magick identify assets/img/favicons/*.png assets/img/favicons/favicon.ico
   ```

2. 按[环境搭建](environment-setup.md#本地预览)启动预览，检查浅色、深色标签栏和 16、32、48px 下的辨识度；另外确认主屏幕图标底色不透明，PWA 图标裁切后不丢失主体。
3. 运行构建、回归测试和内部链接检查：

   ```shell
   bash tools/test.sh
   ```

浏览器可能单独缓存 favicon，发布后若仍看到旧图标，先用无痕窗口核对。PWA 缓存与发布排查见[站点部署](deployment.md)。
