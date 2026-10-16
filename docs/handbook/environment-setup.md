# 环境搭建

## 环境准备

本博客使用 Chirpy Jekyll 主题，基于 `chirpy-starter` 构建。

### 前置依赖

- **Git**
- **Ruby**（推荐使用 rbenv 管理，见下文）
- **Bundler**
- **ImageMagick** — 图片格式转换与裁剪（`brew install imagemagick`）
- **pngquant** — PNG 截图压缩（`brew install pngquant`）
- **webp** — 照片转 WebP 格式（`brew install webp`）

### 安装 Ruby（rbenv）

推荐使用 [rbenv](https://github.com/rbenv/rbenv) 来管理 Ruby 版本，它为每个项目锁定独立的 Ruby 版本，不受系统级变更影响。

**安装 rbenv**：

```shell
brew install rbenv ruby-build
```

**配置 shell 环境**（写入 `~/.zshrc`）：

```shell
# 将以下内容追加到 ~/.zshrc
eval "$(rbenv init - zsh)"
```

然后执行 `source ~/.zshrc` 或重新打开终端。

**安装 Ruby**：

先查看可用的 Ruby 版本：

```shell
rbenv install -l
```

选择最新的稳定版本（以 `3.4` 为例），安装并设为全局默认：

```shell
rbenv install 3.4.1
rbenv global 3.4.1
```

验证安装：

```shell
ruby -v
# 应输出类似：ruby 3.4.1 ...
which ruby
# 应指向 ~/.rbenv/shims/ruby
```

**安装 Bundler**：

```shell
gem install bundler
```

### 克隆并安装项目依赖

```shell
git clone git@github.com:huangboming/personal-blog.git
cd personal-blog
bundle install
```

> **提示：** 项目根目录下的 `.ruby-version` 文件可以固定 Ruby 版本号。进入项目目录后，rbenv 会自动切换到该版本。你可以手动创建此文件：
> ```shell
> echo "3.4.1" > .ruby-version
> ```

## 验证环境

### 本地预览

```shell
bundle exec jekyll serve
```

浏览器访问 `http://127.0.0.1:4000`。

> **注意：** 如果修改了 `_config.yml`，需要重启服务才能生效。

### 生产环境构建

如果需要查看生产环境效果（压缩的 CSS/JS、PWA 等）：

```shell
JEKYLL_ENV=production bundle exec jekyll build
```

生成的静态文件在 `_site/` 目录下。

## 相关操作

- [站点部署](deployment.md)：线上发布、部署排查及缓存说明。
- [升级 Chirpy 主题](theme-upgrade.md)：同步上游模板和更新主题依赖。
