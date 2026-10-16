# 升级 Chirpy 主题

执行前先按 [环境搭建](environment-setup.md) 准备环境，确认项目可以正常预览和构建。

本博客基于 [`chirpy-starter`](https://github.com/cotes2020/chirpy-starter) 创建。升级步骤如下：

## 首次配置（只需一次）

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

## 每次升级

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

## 查看当前版本

```shell
bundle info jekyll-theme-chirpy
```
