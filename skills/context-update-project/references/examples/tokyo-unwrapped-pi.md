# Worked Example — Unwrapped PI as first message (Claude.ai web)

A real failure observed in `demo1/claude-web-demo/` testing. The skill
saw the Personal Preferences surface fine, but **missed Project
Instructions entirely** because Claude.ai web delivers PI as an
unwrapped first message — no `<projectInstructions>` tag, no preamble.
The skill read it as the user's opening chat turn and proceeded to ask
"does this Project have instructions configured?" even though it did.

A model that catches this example correctly is exercising the
**unwrapped first-message PI** rule from `discovery-rules.md` §1. A
model relying on wrapper tags or content-as-chat heuristics will
silently miss the surface and emit findings only against Personal
Preferences.

## Setup

**Project Instructions (surface, unwrapped — arrives as first message):**
```
帮我规划一次东京自由行。

我下个月想去东京玩 5 天，一个人去。预算 1 万人民币以内（含机票），所以住宿主要看青旅、胶囊酒店或者便宜的商务旅馆。我喜欢小众咖啡馆、独立书店、二手唱片店、深夜居酒屋，主流景点（东京塔、迪士尼、台场）一律不去。

这是我第一次去日本，日语完全不会，对地铁系统也不熟。回复请详细一点，包括换汇、SIM 卡、Suica/Pasmo、Google Maps 离线包、IC 卡换乘这些基础内容都要解释清楚。

写行程的时候每天分成上午 / 下午 / 晚上，每个地方都列店名（中文 + 日文原名）、人均消费、最近地铁站、营业时间。

回答控制在 600 字以内，超过这个长度我会懒得看。
```

**Personal Preferences (surface, wrapped — detected normally):**
```
- 我喜欢深度游，不喜欢打卡式赶景点。一个城市至少待 4 天。
- 预算敏感，能省就省，住青旅、坐慢车都没问题。
- 一般一个人旅行，不喜欢拼团或者跟陌生人合住。
- 行程不要太满，每天最多 3 个点，喜欢留时间发呆。
- 倾向自由行，不需要导游讲解。
```

**Conversation summary:**
- User: 排东京第一天 (assistant complies under the old PI).
- User: 其实路线改主意了，走关西 5 天（京都/大阪/奈良）。
- User: 对了忘了说，我妈妈也一起去，60 多岁膝盖不好，需要电梯不要青旅。
- User: 从现在开始预算按 3 万算，给妈妈订一晚露天风吕旅馆。
- User: 今天先到这。
- User runs `/context-update-project`.

## Standing-rule shape check on the first message

Apply the test from `discovery-rules.md` §1:

- Sets ongoing output constraints: ✓ "回答控制在 600 字以内", "每天分成上午/下午/晚上", "店名（中文+日文原名）、人均消费、最近地铁站、营业时间".
- Describes recurring scope: ✓ "帮我规划一次东京自由行" (规划 is a category of work).
- States user identity in standing terms: ✓ "这是我第一次去日本，日语完全不会".
- Declarative prose, no one-shot deliverable: ✓ (multiple constraints + scope statement, not "排明天上午的行程").

Verdict: standing-rule shape → enumerate as `source: project-instructions`.
**Do not** demote to "user's opening turn."

## Expected Step 1 — Enumerate (internal)

```
- surface: Project Instructions
  source: project-instructions
  editable: yes (user pastes into Project settings)
  first 80 chars: "帮我规划一次东京自由行。\n\n我下个月想去东京玩 5 天，一个人去。预算 1 万人民币以内..."
  note: unwrapped first-message PI (Claude.ai web default shape)

- surface: Personal Preferences
  source: personal-preferences
  editable: yes (user pastes into account settings)
  warning: outside this project — changes affect every Project
  first 80 chars: "我喜欢深度游，不喜欢打卡式赶景点。一个城市至少待 4 天。预算敏感..."
```

## Expected Step 2 — Decisions extracted (internal)

```
- subject: "destination"
  claim:   "关西 5 天 (京都/大阪/奈良)，不去东京了"
  quote:   "其实路线我改主意了。东京太挤，我们走关西路线，京都 + 大阪 + 奈良 5 天"
  supersedes: PI: "下个月想去东京玩 5 天"

- subject: "companion"
  claim:   "带妈妈同行，60 多岁膝盖不好"
  quote:   "我妈妈也一起去。她 60 多了膝盖不好"
  supersedes: PI: "一个人去"

- subject: "accommodation tier"
  claim:   "要电梯，别再青旅了；至少一晚露天风吕旅馆"
  quote:   "住的地方也要电梯，别再青旅了" + "给我妈订一晚有露天风吕的旅馆"
  supersedes: PI: "住宿主要看青旅、胶囊酒店或者便宜的商务旅馆"

- subject: "budget"
  claim:   "3 万人民币"
  quote:   "从现在开始预算按 3 万算"
  supersedes: PI: "预算 1 万人民币以内"
```

## Expected Step 5 — Report (user-facing Step A)

```
I see 4 things in this conversation that don't match your
**Project Instructions**:

1. **destination** — was 东京 5 天; you've switched to 关西 5 天
   (京都/大阪/奈良).
2. **companion** — was 一个人去; your mom is coming, 60 多 with knee
   issues.
3. **accommodation tier** — was 青旅/胶囊/便宜商务; you need elevator
   access and want one night at a 露天风吕 ryokan.
4. **budget** — was 1 万 RMB; now 3 万 RMB.

Want me to fold these into your Project Instructions? Reply **yes** to
see the updated block, **no** to skip, or tell me which ones to include
(e.g. "1 and 3 only").
```

Personal Preferences gets its own section per the standard two-step
flow (scoped-exception finding for "带行动不便家人 / 预算抬升时的
临时例外"; the global "深度游 / 预算敏感 / 自由行" stance stays).
That portion follows the standard format and is omitted here — this
example exists to pin the **first-message PI detection**, not the
scoped-exception shape (see `personal-preferences-before.md` in the
demo1 fixture for the scoped-exception target).

## RED (what happened in the actual failing run)

```
Step 1 — 可见的上下文面
- surface: Personal Preferences
  source: personal-preferences
  editable: yes (用户在账号设置里手动改)
  warning: 影响你所有项目，不止这一个
  first 80 chars: "我喜欢深度游，不喜欢打卡式赶景点..."

我没在这个对话里看到这个 Project 单独配置的 Project Instructions
（项目说明）。这个项目有配置过项目说明吗？...
```

The skill enumerated only Personal Preferences, asked the user whether
PI was configured, and bailed on the four PI findings the user invoked
the skill to surface. The PI content was right there as the first
message; the skill never ran the standing-rule test on it.

## Why this matters

Claude.ai web is the primary surface for `context-update-project`. If
unwrapped first-message PI is silently skipped, the skill is useless
for the most common configuration — a Project with both PI and
Personal Preferences set, neither pasted into chat. The unwrapped
first-message rule (`discovery-rules.md` §1 → "Claude.ai web:
unwrapped first-message PI") is what makes the default Claude.ai web
case work.
