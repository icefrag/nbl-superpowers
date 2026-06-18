---
name: nbl.deploy
description: >
  Use when deploying guozhi-series services to dev environments. Triggers on
  "部署", "发布", "deploy", "发布到dev", "上线". Automates git commit/push,
  parallel jkd+jku, BFF passthrough check, and BFF deployment.
---

# 发布部署流程

将当前内部服务及对应的 BFF 层服务部署到用户选择的 dev 环境。

## 启动选项

流程启动时，用 **AskUserQuestion 同时询问两个问题**，不要分两次问：

### 问题 1：目标环境

**问题**：「部署到哪个环境？」

| 选项 | 说明 |
|---|---|
| dev1 | 开发环境 1 |
| dev2 | 开发环境 2 |
| dev3 | 开发环境 3 |

用户选择后，记为 `<env>`，后续所有命令中的环境参数都使用此值。

### 问题 2：BFF 服务

**问题**：「是否需要部署 BFF？」

| 选项 | 说明 |
|---|---|
| 不部署 BFF | 只部署当前内部服务，跳过 BFF 相关所有步骤 |
| ops-app | 部署到 ops-app BFF |
| edu-app | 部署到 edu-app BFF |

**选项由配置决定**：只展示配置文件中已配置的 BFF 项目 + "不部署 BFF" 选项。
例如用户只配置了 ops-app，则选项为：不部署 BFF / ops-app。

用户选"不部署 BFF" → 跳过步骤 3 和 4，步骤 1 完成后流程结束。

## BFF 项目配置

BFF 项目的本地路径不是写死在 skill 里的，而是存储在配置文件中，首次使用时引导用户完成配置。

**配置文件路径**: `~/.claude/skills/deploy/config.json`

**配置格式**:
```json
{
  "ops-app": "D:\\workspace\\guozhi-ops-app",
  "edu-app": "D:\\workspace\\guozhi-edu-app"
}
```

两个 BFF 项目只需配置至少一个即可。用户可能只用其中一个。

### 配置读取与初始化

启动选项中询问 BFF 时，按以下逻辑处理：

1. 读取 `~/.claude/skills/deploy/config.json`
2. 如果文件不存在或为空 → 进入配置引导流程（见下方），配置完成后继续
3. 如果文件存在 → 使用已配置的路径，但**要校验路径是否存在**（`test -d <path>`，用户可能迁移过项目目录）
4. 不存在的路径从选项中排除，并提示用户：
   > 配置中 <bff-name> 的路径 `<path>` 不存在，可能是项目目录已迁移。请更新配置文件 `~/.claude/skills/deploy/config.json` 后重新触发部署。

### 配置引导流程

当需要配置时，用 AskUserQuestion 逐个询问：

**问题 1**：「ops-app 的本地项目路径是什么？（留空表示不使用该 BFF）」
**问题 2**：「edu-app 的本地项目路径是什么？（留空表示不使用该 BFF）」

用户输入路径后：
- 校验路径是否存在（`test -d <path>`），不存在则提示重新输入
- 至少配置一个，两个都为空则报错
- 校验通过后，将配置写入 `~/.claude/skills/deploy/config.json`
- 确保目录存在：`mkdir -p ~/.claude/skills/deploy/`

## 进度跟踪

流程开始时（启动选项确认后），用 TaskCreate 创建以下任务清单，让用户在侧边栏实时看到部署进度：

| 任务 subject | 说明 |
|---|---|
| `0. 前置检查` | 检查工作区状态，提交推送 |
| `1. 部署当前服务` | 并行执行 jkd <env> + jku <env> |
| `2. BFF 透传检查` | BFF git pull → 识别变更接口 → 补写透传 → git commit/push（选了 BFF 时才有） |
| `3. 部署 BFF 服务` | 执行 jkd <env> 部署 BFF（选了 BFF 时才有） |

如果用户选了"不部署 BFF"，则只创建任务 0 和 1。

每进入一个步骤前，先 `TaskUpdate` 将对应任务设为 `in_progress`；完成时设为 `completed`。
如果某步骤失败，任务保持 `in_progress`，不标记完成。

## 执行步骤

### 0. 检查并提交推送代码（前置，必做）

部署前先确认当前分支工作区干净且已与远程同步，避免把过期或本地未推送的代码误带入部署包。

1. 运行 `git status --short` 和 `git status -sb`，判断：
   - **未提交变更**：`git status --short` 非空
   - **未推送提交**：`git status -sb` 中分支显示 `ahead N`
2. **工作区不干净时，AI 自动执行以下操作**：
   1. `git add -A` — 暂存所有变更（含新增、修改、删除）
   2. `git commit` — 提交，commit message 规则：
      - 读取 `git diff --cached --stat` 获取变更文件列表
      - 根据变更内容生成简洁的 commit message，格式：`deploy: <一句话概括变更>`（如 `deploy: 添加FuncNameManager，表单模板名称字段赋值`）
      - 如果变更文件较多难以概括，用 `deploy: 提交当前工作区变更`
   3. `git pull` — 拉取远端最新代码（处理可能的合并）
   4. `git push` — 推送到远端
   5. 每一步执行后检查退出码，**任何一步失败则立即停止**，向用户报告错误，不继续后续步骤
3. 状态干净 → 直接进入步骤 1。

### 1. 部署当前服务（并行）

在当前工作目录下，**并行**执行以下两个命令：

- `jkd <env>`
- `jku <env>`

两个命令必须同时启动，不要串行等待。用 `run_in_background` 或 `&` 并发执行。

**检查结果：**
- 两个都成功 → 进入步骤 2
- 任一失败 → **立即停止**，向用户报告失败命令及错误输出，**不继续后续步骤**

**如果启动时选了"不部署 BFF" → 流程到此结束。**

### 2. BFF 透传检查与部署准备

这是部署 BFF 之前的**关键环节**：确保 BFF 层已经透传了内部服务新增或变更的接口，并且代码已推送到远端。

记下用户在启动选项中选择的 BFF 名称和路径，本步骤及后续都在该 BFF 目录下操作。

#### 2a. BFF 前置同步

**在 BFF 项目中执行以下操作（与步骤 0 相同的逻辑）：**

1. 切换到 BFF 项目目录（bash 环境下用 `cd "<path>"`）
2. 执行 `git pull`，拉取远端最新代码
3. 如果 pull 失败 → 报告错误，不继续
4. 检查 `git status --short`，若有未提交变更：
   1. `git add -A`
   2. `git commit -m "deploy: 提交BFF当前工作区变更"`
   3. `git push`
   4. 任一步失败 → 报告错误，不继续

> **为什么先 pull 再写透传**：避免在旧代码基础上写透传，减少合并冲突风险。先同步到最新，再增量修改。

#### 2b. 识别变更接口

只关注**本会话中实际修改过的** api 文件，而非整个分支的 diff。长期功能分支的 diff 量通常很大，大部分是历史变更，与本次部署无关。

**识别方式：** 检查本会话中通过 Edit/Write 工具修改过的文件，筛选出路径匹配 `api/**/api/*.java` 的文件，提取其中的 Feign API 方法。

具体步骤：
1. 回顾本会话的 Edit/Write 操作记录，收集所有被修改过的 `api/**/api/*.java` 文件路径
2. 读取这些文件，提取所有 `@PostMapping` / `@GetMapping` 等注解标注的方法
3. 将这些方法与 BFF Controller 做对比，找出未透传的接口

**如果本会话没有修改过 api 文件** → 跳过 2c/2d，直接进入步骤 3。

> **为什么不用 git diff**：长期功能分支（如 `feature/sprint200`）相对 develop 的 diff 可能包含数百个文件变更，其中大部分是历史提交，与本次部署无关。聚焦本会话修改的文件，范围精准，避免噪音。

#### 2c. 询问透传状态

对每个变更接口，用 AskUserQuestion 询问用户：

**问题：「本次变更了以下接口，BFF 层是否已经透传？」**

选项设计为三级：
1. **已透传** — BFF 层已有对应 Controller 方法，无需改动
2. **需要补充，已有对应类** — BFF 有相关 Controller，但缺少这个方法。用户提供类名（如 `TenantDictController`）
3. **需要补充，新建类** — BFF 还没有相关 Controller，需要新建。用户提供包路径（如 `com.guozhi.api.opsapp.controller.configcenter`）

如果用户选 2 或 3，追问：
- **选 2**：用户提供已有的 Controller 类名，AI 在 BFF 项目中找到该类，补写透传方法
- **选 3**：用户提供包路径，AI 在 BFF 项目中创建新 Controller 类，写入所有需要的透传方法

#### 2d. 补写透传代码

根据用户的选择，在 BFF 项目中补充开发：

**BFF 透传代码编写规范：**

1. 在 BFF 项目目录下操作
2. 读取 BFF 项目中已有的同类 Controller（选 2 时）作为模板，保持风格一致
3. 透传方法的固定模式：

```java
@PostMapping("/xxx")
@Operation(summary = "xxx")
public XxxResp xxx(@Valid @RequestBody XxxReq request) {
    request.setOperatorId(UserHolder.getUserId());  // 写操作必加
    request.setTenantId(UserHolder.getTenantIdLong()); // 读操作必加（写操作也加）
    return xxxApi.xxx(request);
}
```

4. **关键要点**：
   - BFF Controller 不实现 Feign Api 接口，是独立的 REST Controller
   - BFF 的 URI 路径前缀为 `/guozhi-op/`（ops-app）或 `/guozhi-edu/`（edu-app），加上内部服务的路径
   - 写操作必须通过 `UserHolder` 设置 `operatorId` 和 `tenantId`
   - 读操作必须设置 `tenantId`
   - 透传方法直接调用注入的 Feign Api，不包含业务逻辑

5. 写完后确认 BFF 项目编译通过：`mvn compile -pl app -am`（编译失败也继续 2e，但需向用户说明）

#### 2e. 提交推送透传代码

**透传代码写完后，必须自动提交并推送到远端**，否则 Jenkins 构建时拉不到新代码，部署就是旧版本。

在 BFF 项目目录下执行：

1. `git add -A`
2. `git commit -m "deploy: 透传<接口描述>接口"`（如 `deploy: 透传表单模板规则CRUD接口`）
3. `git push`
4. 每一步检查退出码，**失败则立即停止**，报告错误

> 这和步骤 0 的逻辑一致：不推送到远端的代码，Jenkins 无法构建。

### 3. 部署 BFF 服务

步骤 2e 已将透传代码推送到远端，现在触发 Jenkins 构建。

1. 切换到用户选择的 BFF 目录（从配置中读取的路径，bash 环境下用 `cd "<path>"`，不要用 `cd /d`，bash 不识别）
2. 执行 `jkd <env>`
3. 等待执行完成，报告结果

**如果失败 → 报告错误，流程结束。**

## 注意事项

- 启动时必须同时询问环境选择和 BFF 选择，不要分两次交互
- `<env>` 变量由用户在启动选项中选择，贯穿整个流程，不硬编码
- 步骤 0 是硬性前置：未推送到远端的代码不会被镜像构建包含，部署 = 浪费一次构建名额。AI 会自动提交推送，无需手动操作
- 选了"不部署 BFF" 时，步骤 1 完成即结束，不创建步骤 2/3 的任务
- 步骤 2a 先在 BFF 项目中 git pull，确保在最新代码基础上写透传，减少冲突
- 步骤 2e 自动提交推送透传代码：BFF 和内部服务一样，代码必须推到远端才能被 Jenkins 构建
- 步骤 2b 是防漏检：BFF 没透传新接口 → 前端调不到 → 白部署。只聚焦本会话修改的 api 文件，避免历史变更噪音
- 并行是关键：步骤 1 的两个命令务必同时启动，节省等待时间
- 任何环节失败都必须停下，不要自动重试或跳过
- 向用户清晰展示每一步的执行状态和结果
- BFF 透传代码只做"搬运"（注入上下文 + 调用 Feign），不写业务逻辑
- BFF 项目路径从 `~/.claude/skills/deploy/config.json` 读取，不硬编码在 skill 中
