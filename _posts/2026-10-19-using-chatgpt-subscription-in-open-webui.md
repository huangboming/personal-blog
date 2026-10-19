---
layout: post
title: 在 Open WebUI 中接入 ChatGPT 订阅
date: 2026-10-19
categories: 教程
tags: [AI, 自建服务]
description: 通过 ChatGPT Connect Function 将 ChatGPT Plus/Pro 订阅接入 Open WebUI
media_subpath: /assets/images/using-chatgpt-subscription-in-open-webui/
---

## 背景

我经常在 [Open WebUI](https://docs.openwebui.com/) 中与 AI 闲聊，手头上正好有 ChatGPT Plus 订阅。很早之前我就在想：能不能直接通过 ChatGPT 订阅，在 Open WebUI 中调用 GPT 模型？

最近使用 [`pi`](https://github.com/earendil-works/pi) 时，我发现登录方式里多了一个 OpenAI provider，而之前的 OpenAI Codex provider 被标记为 legacy。

让 AI 对比两者的实现后，我发现新的 OpenAI provider 背后使用的是 [SIWC（Sign in with ChatGPT）](https://developers.openai.com/siwc)。这是 OpenAI 在 2026 年 9 月底推出的新功能，允许用户授权第三方应用使用自己的 ChatGPT 订阅额度。

我顺着这个思路做了个小实验，发现确实可行。于是，我 vibe coding 了两个 Open WebUI Function：[ChatGPT Connect](https://github.com/huangboming/openwebui-chatgpt-connect)。

主 Function 支持文本和图片对话；安装辅助 Filter 后，还可以上传原始文档、连续调用工具，并使用 OpenAI 原生网络搜索。

这篇文章来讲讲怎么安装和使用它。

## 准备

在开始之前，你需要准备：
- 一个已订阅 ChatGPT Plus 或 Pro 的 OpenAI 账号
- 一个 0.11.4 或更高版本（更低版本的我没试过）、以单 worker 运行的 Open WebUI 服务，且你拥有管理员权限
- 一台带有浏览器和终端、且能通过 SSH 连接 Open WebUI 所在主机的电脑（下文称为本机）

## 安装和配置

### 1. 导入并配置主 Function

进入 Open WebUI `Admin Panel` -> `Functions` 页面，创建 Function，选择 `Import from link`，在 `URL` 中输入：`https://github.com/huangboming/openwebui-chatgpt-connect/releases/latest/download/openwebui_chatgpt_connect.py`

![Open WebUI Functions 页面的链接导入菜单](1.png){: w="2566" h="1782" .shadow }
*从链接导入主 Function*

主 Function 是一个嵌入 Open WebUI 的轻量模型代理，它在 Open WebUI 中注册了 `/siwc/v1/responses` 路由。如果 Open WebUI 端口对外开放，这条路由可能会被外部直接请求，因此需要配置内部 API Key，防止路由被滥用。

导入后，打开 Function 的值设置，配置以下两项：

- `SSH Target`：Open WebUI 主机的 SSH 地址，例如 `user@example.com`。
- `Internal Api Key`：一个超过 32 字符的随机密钥，可以用 `openssl rand -hex 32` 生成。

配置完成后保存。后面配置 Responses API 连接时，还会用到这个密钥。

![ChatGPT Connect 主 Function 的值设置](2.png){: w="968" h="816" .shadow }
*主 Function 的值设置*

然后，在浏览器中输入 `<Open WebUI 地址>/siwc/admin`，进入 `Admin` 页面，准备登录 ChatGPT 账号。

![ChatGPT Connect 登录页面中的 SSH 命令与授权按钮](3.png){: w="2568" h="1788" .shadow }
*ChatGPT Connect 登录页面*

### 2. 建立回调通道

授权完成后，OpenAI 会将结果回调到本机的 `127.0.0.1:1455`。处理回调的接口运行在 Open WebUI 中，因此登录前需要建立一条临时的 SSH 通道，把发送到这个端口的请求转发给 Open WebUI。

在 `ChatGPT Connect Admin` 页面复制 `Open the callback tunnel` 下方的命令，然后在本机终端中运行。默认命令类似：

```shell
ssh -N -o ExitOnForwardFailure=yes -L 127.0.0.1:1455:127.0.0.1:8080 user@example.com
```

运行后保持终端窗口打开，再继续登录 ChatGPT。

> 如果 Open WebUI 运行在 Docker 中，命令右侧应填写宿主机发布的端口。例如使用 `-p 3000:8080` 启动容器时，应将命令中的最后一个 `8080` 改为 `3000`。
{: .prompt-info }

### 3. 授权 ChatGPT 账号

运行命令之后，回到浏览器中的 `Admin` 页面，点击 `Continue with ChatGPT` 按钮，跳转到 OpenAI 登录界面，登录你的 OpenAI 账号，确认授权第三方应用，完成授权。

![ChatGPT 账号授权成功页面](4.png){: w="2578" h="1786" .shadow }
*ChatGPT 账号授权成功*

授权成功后，回到 `Admin` 页面，能看到登录成功的状态。到这一步，你可以关掉之前建立的 SSH 端口映射。

### 4. 选择模型

接下来，在 `Admin` 页面选择你想要导入的模型。选好之后，点击 `Save changes` 按钮。

![ChatGPT Connect 的账号状态与模型列表](5.png){: w="2562" h="2208" .shadow }
*选择要导入的 GPT 模型*

值得注意的是，每个 Open WebUI 实例只能连接一个 ChatGPT 账号。其他用户使用这些模型时，也会消耗该账号的套餐额度。如果你的 Open WebUI 有多个用户，记得在 Open WebUI `Settings` -> `Models` 配置模型访问权限。

可用模型和使用额度取决于你的 ChatGPT 套餐，你可以在 [ChatGPT Usage](https://chatgpt.com/settings/usage) 页面查看当前用量、设置每个应用可以使用多少额度。

### 5. 配置 Responses API 连接

进入 `Settings` -> `Connections` 部分，添加一个 `OpenAI API Connections`，`URL` 填写 `http://localhost:8080/siwc/v1`，`Auth` 选择 `Bearer`，填写第 1 步配置的内部 API Key，`API Type` 改成 `Responses`，最后点击 `Save`，就搞定了。

![Open WebUI 的 Responses API 连接设置](6.png){: w="962" h="560" .shadow }
*配置 Responses API 连接*

### 6. 启用文档、工具调用和网络搜索（可选）

要上传原始文档、连续调用工具和使用 OpenAI 原生网络搜索，还需要安装辅助 Filter。进入 Open WebUI `Admin Panel` -> `Functions` 页面，选择 `Import from link`，在 `URL` 中输入：`https://github.com/huangboming/openwebui-chatgpt-connect/releases/latest/download/chatgpt_responses_history.py`

这个 Filter Function 有三个作用：
- 保留推理上下文，让工具调用能连续进行
- 将上传文档的原始文件传给模型
- 将聊天的 `Web Search` 开关接到 OpenAI 原生联网

安装辅助 Filter 后，模型能直接接收文档原文件，也可以调用 Open WebUI 中的工具；打开 Open WebUI 的 `Web Search` 开关，可以使用 OpenAI 原生搜索，不需要单独配置其他搜索引擎。

导入后保存并启用 Filter，打开 `Global` 开关。最后，在浏览器中访问 `<Open WebUI 地址>/api/models?refresh=true` 刷新模型，再重新加载 Open WebUI 页面。

## 验证连接

返回 Open WebUI 对话页面，选择刚刚导入的 GPT 模型并发送一条消息。如果模型正常回复，说明连接已经配置成功。

## 最终效果

大功告成，开始在 Open WebUI 中使用 GPT 模型吧。Enjoy!

![GPT 模型调用时间工具并搜索科技新闻](7.png){: w="2566" h="2200" .shadow }
*工具调用与网络搜索*