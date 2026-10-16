# 本地预览与主题升级

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
git clone git@github.com:huangboming/huangboming.github.io.git
cd huangboming.github.io
bundle install
```

> **提示：** 项目根目录下的 `.ruby-version` 文件可以固定 Ruby 版本号。进入项目目录后，rbenv 会自动切换到该版本。你可以手动创建此文件：
> ```shell
> echo "3.4.1" > .ruby-version
> ```

## 本地预览

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

线上发布、部署排查与配置说明见 [站点部署](deployment.md)。

## 升级 Chirpy 主题

本博客基于 [`chirpy-starter`](https://github.com/cotes2020/chirpy-starter) 创建。升级步骤如下：

### 首次配置（只需一次）

添加 chirpy-starter 为上游仓库：

```shell
git remote add chirpy https://github.com/cotes2020/chirpy-starter.git
```

验证是否添加成功：

```shell
git remote -v
# 应看到：
# chirpy  https://github.com/cotes2020/chirpy-starter.git (fetch)
# chirpy  https://github.com/cotes2020/chirpy-starter.git (push)
```

### 每次升级

1. 拉取上游标签：

   ```shell
   git fetch chirpy --tags
   ```

2. 合并最新标签（将 `vX.Y.Z` 替换为目标版本号）：

   ```shell
   git merge vX.Y.Z --squash --allow-unrelated-histories
   ```

3. 解决冲突（如果有）。注意保留自己的自定义修改。

4. 提交升级：

   ```shell
   git add . && git commit -m "chore: upgrade to X.Y.Z"
   ```

5. 更新 gem 依赖：

   ```shell
   bundle update
   ```

### 查看当前版本

```shell
bundle info jekyll-theme-chirpy
```

## PWA 缓存说明

本博客启用了 PWA 离线缓存。这意味着：

- 浏览器首次访问后会缓存页面内容。
- 后续访问会先显示缓存内容，同时后台检查更新。
- 更新过程需要几十秒到几分钟。
- 如果想立即看到最新内容，使用浏览器的**隐私/无痕模式**。

> **提示：** 部署后如果看不到更新，不要慌，这不是 bug。
