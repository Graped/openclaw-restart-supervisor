# openclaw-restart-supervisor

一个面向 OpenClaw 的轻量级重启恢复层，核心包括：任务账本、启动自检、以及“进度优先”的汇报机制。

它的目标很直接：当智能体在长任务中途遇到重启、异常中断或会话丢失时，尽量不要把任务静默丢掉，也不要让用户处于“你到底还在不在做事”的状态。

## 它解决什么问题

这套方案把三件简单但关键的事情组合在一起：

- 用持久化任务账本记录长任务状态
- 在启动时自动检查是否有未完成工作
- 在继续静默执行前，优先给用户一个简短进度说明

组合起来之后，恢复链路会变成这样：

```text
长任务开始
-> 写入账本
-> 中途发生重启 / 中断
-> 启动时读取未完成任务
-> 注入恢复提醒
-> 如果用户还没收到进度，先汇报
-> 再继续恢复执行
```

## 为什么需要它

很多时候，任务并不是“技术上失败”了，而是“沟通上消失”了。

文件还在，状态还在，运行时甚至已经恢复健康，但用户看到的表象却是：
- 机器人突然不回了
- 不知道任务做到哪一步了
- 重启后也没人主动解释

这个项目的意义，就是把这条恢复路径显式化、制度化，而不是靠运气。

## 最推荐的安装方式

如果你只是想尽快接入，优先用脚本安装。

```bash
bash scripts/install.sh /path/to/openclaw-workspace
```

如果你已经在目标工作区环境里，也可以这样：

```bash
OPENCLAW_WORKSPACE=/path/to/openclaw-workspace bash scripts/install.sh
```

卸载：

```bash
bash scripts/uninstall.sh /path/to/openclaw-workspace
```

## 给 AI 的安装说明

如果你是另一个 AI 智能体，并且你的目标是把本项目安装到某个 OpenClaw 工作区，请优先执行仓库内现成脚本，而不是手写复制命令。

### 安装目标

把本仓库内容接入“目标 OpenClaw 工作区”，而不是当前仓库自身。

目标工作区至少应包含这些路径：

```text
<workspace>/PENDING.md
<workspace>/scripts/task_ledger.py
<workspace>/hooks/restart-supervisor/HOOK.md
<workspace>/hooks/restart-supervisor/handler.js
<workspace>/.supervision/pending-jobs.json
```

### 默认安装目标

如果用户没有指定路径，默认把 `OPENCLAW_WORKSPACE` 视为安装目标；如果这个环境变量也没有设置，就必须显式传入工作区路径。

### AI 应优先执行的命令

安装：

```bash
bash scripts/install.sh /path/to/openclaw-workspace
```

卸载：

```bash
bash scripts/uninstall.sh /path/to/openclaw-workspace
```

### install.sh 会做什么

1. 确认目标工作区路径
2. 创建缺失目录：`scripts`、`hooks/restart-supervisor`、`.supervision`
3. 复制以下文件到目标工作区：
   - `PENDING.md`
   - `scripts/task_ledger.py`
   - `hooks/restart-supervisor/HOOK.md`
   - `hooks/restart-supervisor/handler.js`
4. 如果目标工作区还没有 `.supervision/pending-jobs.json`，就写入示例账本
5. 给 `scripts/task_ledger.py` 添加可执行权限
6. 安装并启用 hook
7. 重启 gateway
8. 执行 `openclaw hooks list` 和 `openclaw hooks check`

### 验证标准

安装完成后，至少验证以下几点：

- `openclaw hooks list` 中能看到 `restart-supervisor`
- `openclaw hooks check` 中 `restart-supervisor` 状态为 `ready`
- 目标工作区存在 `.supervision/pending-jobs.json`
- 目标工作区存在 `scripts/task_ledger.py`

### 回滚标准

卸载脚本会：

- 先尝试 `openclaw hooks disable restart-supervisor`
- 删除本项目接入时创建的核心文件
- 再尝试重启 gateway

如果目标工作区本来就有这些文件，请先审查差异，不要盲目覆盖或删除。

## 手动安装方式

如果你不想用脚本，也可以手动执行：

```bash
mkdir -p /path/to/workspace/.supervision
mkdir -p /path/to/workspace/scripts
mkdir -p /path/to/workspace/hooks/restart-supervisor
cp PENDING.md /path/to/workspace/PENDING.md
cp scripts/task_ledger.py /path/to/workspace/scripts/task_ledger.py
cp hooks/restart-supervisor/HOOK.md /path/to/workspace/hooks/restart-supervisor/HOOK.md
cp hooks/restart-supervisor/handler.js /path/to/workspace/hooks/restart-supervisor/handler.js
cp examples/.supervision/pending-jobs.json /path/to/workspace/.supervision/pending-jobs.json
chmod +x /path/to/workspace/scripts/task_ledger.py
openclaw hooks install /path/to/workspace/hooks/restart-supervisor
openclaw hooks enable restart-supervisor
openclaw gateway restart
openclaw hooks list
openclaw hooks check
```

## 工作原理

```text
1. 智能体开始执行一个长任务
2. 任务状态被写入 .supervision/pending-jobs.json
3. 工作被重启、崩溃或人工中断打断
4. 下次 bootstrap 时，hook 会扫描未完成任务
5. 恢复提醒被注入启动上下文
6. 如果 userUpdated=false，先给用户发进度
7. 再恢复、关闭或升级处理这个任务
```

## 核心设计

### 1. 任务账本

账本文件位于：`.supervision/pending-jobs.json`

每个任务至少记录这些字段：

- `id`
- `title`
- `status`
- `startedAt`
- `lastUpdatedAt`
- `lastAction`
- `nextStep`
- `userUpdated`
- `chatId`

这让“任务状态”从会话上下文中剥离出来，落到磁盘上。

### 2. 启动自检

`restart-supervisor` hook 运行在 `agent:bootstrap` 阶段。

它会读取账本，筛出未完成任务，并把恢复提醒注入启动上下文，让智能体在处理新任务之前，先看到被中断的旧任务。

### 3. 进度优先汇报

如果某个任务仍处于活跃状态，且 `userUpdated=false`，智能体应该先给用户一条简短进度说明，再继续安静做事。

这条规则本身很简单，但它决定了“恢复”是对用户可见，还是继续静默失联。

## 仓库结构

```text
hooks/restart-supervisor/HOOK.md
hooks/restart-supervisor/handler.js
scripts/install.sh
scripts/uninstall.sh
scripts/task_ledger.py
examples/.supervision/pending-jobs.json
PENDING.md
docs/design.md
docs/state-machine.md
docs/github-release-checklist.md
```

## 账本命令示例

```bash
python3 scripts/task_ledger.py add install-skills "Finish installing requested skills"
python3 scripts/task_ledger.py update install-skills lastAction "Installed 3 of 6 skills"
python3 scripts/task_ledger.py update install-skills nextStep "Resume the remaining installs after restart"
python3 scripts/task_ledger.py update install-skills userUpdated false
python3 scripts/task_ledger.py list
```

## 推荐运行规则

- 预计超过 2 分钟的任务，应该先记到账本
- 持续更新 `lastAction`、`nextStep`、`userUpdated`
- 在重启 gateway 之前，如果用户正在等待，应先发一条简短进度
- 重启后先检查未完成任务，再接新的长任务
- 不再活跃的任务应及时标记为 `done`、`cancelled` 或 `superseded`

## 注意事项

- 这个项目本身不会强制自动发消息
- 它做的是：在启动阶段注入恢复提醒，并把“先汇报再恢复”变成一种规则
- 如果你想要真正无人值守的自动发送，需要再叠一层 message-sending layer，去读取同一份账本并主动发信
- `install.sh` 默认不会覆盖已有账本，只会在目标工作区缺失 `.supervision/pending-jobs.json` 时写入示例文件

## 适合谁

如果你正在用 OpenClaw 做这些事情，这个项目会特别有用：

- 长时间运行的安装、迁移、整理任务
- 重启后需要接着干的自动化流程
- 希望智能体“别闷头做事，先汇报”的团队协作场景
- 需要把恢复逻辑做成可复用工作区规范的人

## License

MIT
