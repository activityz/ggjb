# ggjb 项目规则（工作区级）

> 与全局 `C:/Users/25852/.dsh/AGENTS.md` 冲突时，以本文件为准。
> 与任何 skill 的默认流程冲突时，以本文件为准。
> 环境事实、版本锁、踩过的坑放 `docs/agent/memory.md`；本文件只放硬性约束。

## 0. 入口：每条需求默认走 dev-god

用户每发一条新需求，默认按 `/dev-god`（`C:/Users/25852/.agents/skills/dev-god/SKILL.md`）的方法论接管：
先读现场（项目约定 / 目标代码 / 调用入口 / 工作区改动）→ 按目标行动 → 只问关键缺口 → 用证据判断。

**但 dev-god 允许「小改动不必建计划文件」，这条在本项目不适用。** 任何改代码都要有 OpenSpec
change 作为提案载体，见第 1 条。

## 1. SDD 开发流程（严格遵守，由 OpenSpec 承载）

OpenSpec 1.13.2 已初始化在 `openspec/`（`config.yaml`：schema=spec-driven，语言 zh-CN）。
一个 change = 一次需求/改动的完整提案，落在 `openspec/changes/<kebab-name>/`，
四个 artifact 按依赖推进：**proposal → specs + design → tasks**。

任何代码改动 —— 包括返工、续作、修 bug —— 都按 1.1 → 1.6 顺序走完，不得跳步。

### 1.1 澄清

- 先读现场：`openspec list --specs` 看已有能力清单，
  `openspec show "<spec-id>" --type spec` 读相关 spec 全文（含 scenario）。
- 歧义点列成 Q1..Qn，一次问清。能从代码/库里查到的不问；有多种后果的给选项 + 推荐，
  只等依赖该答案的部分。

### 1.2 提案（「计划」的唯一载体）

```bash
openspec new change <kebab-name>
openspec status --change <kebab-name>          # 看 artifact 完成度与阻塞关系
openspec instructions <artifact> --change <kebab-name>   # 取该 artifact 的写作要求
```

依次产出：

| artifact | 文件 | 必须包含 |
| --- | --- | --- |
| proposal | `proposal.md` | Why / What Changes / Capabilities（New + Modified，用既有 spec 路径）/ Impact / 非目标 |
| specs | `specs/<capability>/spec.md` | `### Requirement:` + 正文含 `SHALL`/`MUST`（关键字保留英文）+ 每条配 `#### Scenario:` |
| design | `design.md` | 口径依据、关键决策及理由、被否掉的备选方案与原因 |
| tasks | `tasks.md` | 可勾选实现清单，逐条对应验收条件 |

`openspec validate <kebab-name>` 必须通过，才算提案完成。

**`docs/plan/000N-*.md` 只保留历史（0001–0010），新需求不再往那里加文件** —— 两套计划必然漂移。
没有 spec 层变化的小改动（纯视觉、内部重构）也照建 change，允许 specs delta 为空，
但 proposal 与 tasks 不能省。

### 1.3 批准

`openspec validate` 通过后停下，等用户明确说「开始执行」「按这个做」。
**沉默、催问、「这是上一轮需求的续作」「需求原文很短」都不构成批准。**

### 1.4 编码

```bash
openspec instructions apply --change <kebab-name>   # 取执行指引
```

按 `tasks.md` 逐项落地并勾选，**TDD 强制**（见 §2：先红后绿、一次一个切片）。
不顺手重构任务外模块；冒出计划外的设计决定先报备再改。

### 1.5 验证

`analyze` 必跑（§4 的 SDK 绝对路径）；`test` 能跑就跑；`openspec validate <name>` 复跑；
结果写回 `tasks.md` 与当轮汇报。

### 1.6 归档与汇报

验收通过后：

```bash
openspec archive <kebab-name>     # 归档进 changes/archive/，delta 合进 openspec/specs/
```

`openspec/specs/` 是「当前真相」，`openspec/changes/` 只放未归档提案。
汇报按「文件变更展示」硬规则：逐文件贴 diff，末尾单独写「改动清单：」。
生成长文档（proposal / design / 汇报正文）后，先给 3–5 行短总结——做什么、关键取舍、代价、当前状态——再贴全文或 diff。用户原话：「以后每次生成文档后总结一下，太长了看不完」。

### 1.7 违规处理

违反 1.1–1.6 中任何一步而先动了代码，必须：在该 change 的 `proposal.md` 里写明违规 →
给出逐个 hunk 的回滚方案 → 等用户裁决（保留 or 撤回）。
不得用 `git checkout -- <file>` 回滚，工作区里有大量未提交改动会被一起冲掉。

## 2. TDD：编码阶段必须 test-first

加载 `tdd` skill（`C:/Users/25852/.agents/skills/tdd/SKILL.md`，本机已全局安装，无需再装）。
它是 red → green 循环的判据清单，每个 cycle 都适用，不是写完再回看的文档。

**测试来源**：OpenSpec 的 `#### Scenario:` 就是测试用例来源 —— 一个 scenario 对应至少一个测试，
测试名直接读作规格（「用户可用有效购物车结账」），不读作实现。

**Seam 先报备**：动手前把「测哪些 public 边界、每处抓住什么 / 漏掉什么」写进 `tasks.md`，
等用户确认后再写第一个测试。未确认的 seam 不写测试。

**循环规则**：
- **Red before green**：先写失败测试，再只写够它通过的最小实现。不预判后续测试。
- **一次一个切片**：一个 seam、一个测试、一次最小实现。
- **垂直切片**：禁止先写完全部测试再写实现 —— 那是在验证想象中的行为。
- **重构不属于循环**，放 code-review 阶段做。
- 断言值必须来自独立来源（spec 里的 worked example、已知字面量），
  不得按实现同样的算法重算一遍（tautological 测试永远不可能说代码错）。
- 只测 public 接口：不 mock 内部协作者、不测 private 方法、不靠查库代替接口验证。

**Flutter 落地**：
- 测试放 `app/test/`（现有 `data/`、`domain/`、`widget_test.dart`），文件名 `*_test.dart`。
- widget 测试用 `pumpWidget` + `ProviderScope(overrides: [...])`；drift 用内存库
  （`NativeDatabase.memory()`），不要碰用户的真实库文件。
- 金额一律整数分断言，不写浮点近似。

红与绿都要在汇报里贴 `flutter test` 的输出摘要（哪条先红、改了什么之后转绿）。

## 3. 构建必须等用户开口

`flutter build apk` / `flutter build windows` / 任何产出安装包的命令，一律不主动执行，
必须用户明确要求。
`build_runner` / `analyze` / `test` 属本地校验，可以自行执行，但必须在汇报里列出命令与结果。

## 4. 只用 fvm 3.47.1

所有 flutter / dart 命令写死绝对路径：

```
D:/develop/flutter/fvm/versions/3.47.1/bin/flutter.bat
```

PATH 上的 `flutter` 是 3.35.4，是旧 SDK：`pub get` 解算不过（intl 0.20.2 vs 0.20.3），
它的 lint 结论（如 `RegExp deprecated`）不可信、不得写进汇报结论。

同一时间只允许一个构建；Gradle wrapper 报
`Timeout of 120000 reached waiting for exclusive access to file` 是并发抢锁，不是网络问题。

## 5. 不许 commit

除非用户明确要求，不 `git commit`、不 `git push`。工作区里的未提交改动属于用户。

## 6. 文档分工，别三处重复写

| 文件 | 放什么 |
| --- | --- |
| `openspec/changes/<name>/` | 未归档提案：proposal / specs delta / design / tasks |
| `openspec/specs/<capability>/spec.md` | 已归档的行为契约（当前真相） |
| `docs/plan/000N-*.md` | **仅历史**：0001–0010，不再新增 |
| `docs/design/000N-*.md` | 架构层面的长期设计 |
| `docs/agent/memory.md` | 环境 / 版本锁 / 踩坑（长期事实） |
| `docs/agent/evolution-log.md` | 可自主记录的进化动作，只读不生效 |
| `AGENTS.md`（本文件） | 硬性约束与流程门槛，每次会话自动注入 |

新增一条规则前先判断属于哪一类；流程纪律进本文件，环境事实进 `memory.md`，
行为契约进 `openspec/specs/`。
**例外**：`AGENTS.md`、`docs/agent/*`、`openspec/config.yaml` 的修订属于「规则变更」，
用户即时指令即可直接改，不必先建 change —— 否则改规则本身要先有 change，会自锁。
规则变更同样要在当轮汇报里列出 diff。
