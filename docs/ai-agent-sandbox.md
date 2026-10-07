# AI 代理的權限與沙箱設定

> **目前狀態（2026-09-16）**：團隊共用 `.claude/settings.json` 已移除完整 `sandbox` 區塊，原有 `permissions` 規則保持不變。此變更同時影響 CI 與本機；實際沙箱狀態仍取決於個人或組織管理設定。以下內容為 **[DEPRECATED] 舊版共用沙箱的設計與實測紀錄**，不代表目前預設防護。若要在本機啟用，可使用已 gitignore 的 `.claude/settings.local.json`，並依實際平台重新驗證。

本文件說明 `.claude/settings.json` 的設計理由。**JSON 不支援註解**，所以那份設定裡每個決策的「為什麼」都放在這裡。改動設定前請先讀這份，特別是「語法陷阱」一節——裡面每一條都是實測踩出來的，不是推測。

**檔案配置**：`.claude/settings.json` 是**團隊共用**設定、已進版控，本文件描述的就是它。`.claude/settings.local.json` 是個人本機覆寫、已 gitignore，目前內容為 `{}`。兩者**同屬 project scope**，所以沙箱鍵在兩處的採信待遇一樣；但載入順序是 project → local，**local 會覆蓋 project**，個人覆寫時請注意不要無意間關掉沙箱。

建立日期：2026-08-24

---

## 目標

讓 AI 代理不能在專案資料夾外面新增／修改／刪除任何東西，唯一例外是安裝全域 playwright（`web-experience-audit` skill 的前置需求）。

## 三層架構

三層各管不同的事，缺一不可：

| 層 | 管什麼 | 在 `--dangerously-skip-permissions` 下 |
|---|---|---|
| `permissions.deny` | 指令字串比對（`git push`）＋ 檔案工具的路徑（Write／Edit／NotebookEdit） | 仍強制 ✅ |
| `sandbox.filesystem` | kernel 層寫入範圍，**涵蓋所有 shell 指令** | 仍強制 ✅ |
| `allowUnsandboxedCommands: false` | 拿掉 `dangerouslyDisableSandbox` 這個逐次逃生門 | 仍強制 ✅ |

**為什麼需要三層？** 因為 `permissions.deny` 的 `Edit(...)` 路徑規則**只管檔案工具、完全不管 Bash**。`rm`／`mv`／`cp`／`sed -i` 走的是 Bash 規則，而 Bash 規則比對的是指令字串、不是路徑，所以「禁止寫到資料夾外」這件事光靠權限規則寫不出來。真正的邊界只有沙箱能給。

第三層的必要性只在 bypass 模式下才顯現：`dangerouslyDisableSandbox` 是 Bash 工具的參數，預設可用。一般模式下用它會觸發詢問、人看得到；bypass 模式什麼都不問，等於沙箱變成「模型想退出就能退出」。設成 `false` 後該參數被**完全忽略**。

---

## 各項決策理由

### `permissions.allow`（8 條）

每條都對應實際使用者，沒有多餘的：

| 規則 | 使用者 |
|---|---|
| `WebSearch` | 一般性查詢 |
| `Bash(bash .specify/scripts/bash/*)` | specify／plan／implement／converge／taskstoissues |
| `Bash(gh issue *)` | taskstoissues |
| `Bash(git *)` | speckit 腳本內部（`rev-parse`／`checkout -b`／`status`）＋ taskstoissues 讀 remote url |
| `Bash(pip install playwright*)`<br>`Bash(pip3 install playwright*)`<br>`Bash(playwright install*)` | audit skill Phase 1（本機只有 `pip3`，故兩者都列） |
| `Bash(python3 *)` | audit skill Phase 2–6：爬取、區塊切分、network log、tracing |

**注意 `allow` 在 bypass 模式下完全沒有意義**（反正全部自動放行）。它只在一般模式減少詢問。真正的防護全在 `deny` 和 `sandbox`。

已刪除的項目與原因：

- `WebFetch(github.com / raw.githubusercontent.com / deepwiki.com)` — **12 支 skill 沒有任何一支用到 WebFetch**，這三條只是為了讀 AGENTS.md（原 CLAUDE.md）的參考連結不跳詢問，而且還漏了其中三個網域。WebFetch 會把外部內容拉進 context，是 prompt injection 入口，不值得為省一次點擊而常開。
- `Bash(chmod +x .../kiibase-speckit/...)` — 路徑寫錯（本 repo 是 `kii**tzu**`），永遠不會命中的死規則；腳本本來就是 755。
- 一條解析 `composer.json` 的 `python3 -c` — 本 repo 沒有 composer.json，是別的 skill 場景留下的。

### `permissions.deny`

- **`git push*` / `git merge*`** — 對應既有規則「AI 不 push、不 merge 到 develop／master」。注意 `deny` 壓過 `allow`，所以這兩條會覆蓋 `Bash(git *)`，是刻意的收窄。
- **系統路徑**（`//etc`、`//usr`、`//bin`、`//sbin`、`//var`、`//System`、`//Library`）
- **家目錄敏感檔**（`~/.ssh`、`~/.aws`、`~/.gnupg`、`~/.config/gh`、shell 啟動檔）
- **`~/.claude/` 的設定與 skill**（`settings.json`、`CLAUDE.md`、`skills/`、`plugins/`）——防自我提權：改得動全域設定就能把 allow 加回來。
  **刻意不擋 `~/.claude/projects/**`**，那是 auto-memory 的位置，擋了會壞記憶功能。

### `sandbox.excludedCommands`：`gh *`、`git *`、`python3 *`

這三支**不是因為要寫檔案**才豁免，是因為它們在沙箱內會壞在別的地方：

| 指令 | 沙箱內的症狀 | 根因 |
|---|---|---|
| `gh` | `tls: failed to verify certificate: x509: OSStatus -26276` | 讀不到 `com.apple.trustd.agent`。schema 對 `enableWeakerNetworkIsolation` 的說明直接點名這個案例 |
| `git`（遠端） | `ssh_dispatch_run_fatal: Broken pipe` | SSH 走的網路路徑被隔離打斷。本 repo 三個 submodule 全靠它 |
| `python3` | Chromium 無法啟動：`bootstrap_check_in ... MachPortRendezvousServer: Permission denied (1100)` | Chromium 需要**註冊** Mach service。`allowMachLookup` 只管**查找**，實測無效；schema 沒有暴露 mach-register 的旋鈕 |

**為什麼不用 `allowWrite` 解決？** 因為這三個都不是寫入權限問題。反過來，安裝需求（pip／playwright）就用 `allowWrite` 而不是豁免指令，因為：

| 寫法 | 暴露面 |
|---|---|
| `allowWrite` 路徑 | 限定地點、不限指令——**所有**指令都只能寫那幾處 |
| `excludedCommands` | 限定指令、不限地點——那支指令**寫哪都行** |

`allowWrite` 窄得多，能用它就用它。

### `sandbox.filesystem.allowWrite`（4 條）

存在的原因：`pip` 和 `playwright` **不在** `excludedCommands` 裡，所以是在沙箱內執行的，而 audit skill Phase 1 第一行要往專案外寫東西：

```bash
pip install playwright --break-system-packages -q && playwright install chromium
```

四條都用機器上的實際落點驗證過：

| 條目 | 驗證方式 | 實際落點 |
|---|---|---|
| `~/Library/Caches/ms-playwright` | `ls ~/Library/Caches/ms-playwright/chromium*` | 瀏覽器本體 |
| `~/Library/Caches/pip` | `pip3 cache dir` | wheel／HTTP 快取 |
| `/opt/homebrew/lib` | `python3 -c "import playwright"` | site-packages 套件本體 |
| `/opt/homebrew/bin` | `which playwright` | console script |

**`/opt/homebrew/lib` 比實際需要的寬**（真正需要的只有 `python3.13/site-packages`）。原因是 `allowWrite` **不支援 glob**——改成 `python3.*/site-packages` 之後實測變成 BLOCKED。退到父層換來的是 Python 升版不會靜默壞掉。要更緊就得寫死版號並接受升版時要記得改。

---

## 語法陷阱

這些全是實測結果。**共同特徵是「錯了不會報錯，只會靜默失效」**——設定看起來還在保護，其實沒有。

| 項目 | `~` | glob | 備註 |
|---|---|---|---|
| `permissions.deny` 的 `Edit(...)` | ✅ | ✅ `**` | **絕對路徑必須 `//` 前綴** |
| `sandbox.filesystem.allowWrite` | ✅ | ❌ | glob 會讓整條失效 |

1. **`Edit()` 的絕對路徑要雙斜線。** `Edit(/abs/path/**)` 會被當成**相對於專案根**，永遠不匹配。要寫 `Edit(//abs/path/**)`。（第一次測試就是被這個騙過，以為 Edit 規則管不到 Write 工具。）

2. **`deny` 永遠壓過 `allow`，再具體的 allow 都挖不出例外。** 實測：`deny: Edit(//X/**)` ＋ `allow: Edit(//X/ok/**)`，寫入 `X/ok/` 仍被拒。
   **推論：「~ 底下除了本專案以外全擋」寫不出來**，因為專案就在 `~/` 底下，擋了 `~/**` 會把專案自己鎖死。所以 `deny` 只能是列舉式黑名單；`~/Projects/` 的兄弟專案目錄**靠沙箱保護，不是靠 deny**。

3. **`excludedCommands` 的項目是指令 pattern，要帶 `*`。** 裸寫 `"gh"` 只匹配「一個參數都不帶的 `gh`」，匹配不到 `gh issue list`。第一版就是這樣寫，完全沒生效。

4. **⚠ `excludedCommands` 的判定範圍是「一次 Bash 呼叫的整串指令」，不是其中匹配到的那支指令。**

   一次 Bash 呼叫 = 一次丟給 shell 的整串文字，裡面可以用 `&&`、`;`、`|`、換行串好幾個指令。沙箱只對這整串做**一次**判定：只要串裡任何一處命中豁免名單，**整串**都跑在沙箱外。

   ```bash
   touch ~/x                    # 單獨一次呼叫 → BLOCKED
   python3 foo.py && touch ~/x  # 一次呼叫、兩個指令 → 整串都在沙箱外，touch 跟著放行
   ```

   同一個 `touch`，換個包裝就從擋住變成放行。

   **所以跑「怎麼重跑驗收」那組探測時，同一次呼叫裡絕對不能出現 `gh`／`git`／`python3`。** 混入的後果是探測指令自己也脫離沙箱、對外寫入成功，於是每一行都顯示 `WRITABLE`：

   ```
   家目錄          : WRITABLE ⚠
   ~/Projects 兄弟 : WRITABLE ⚠
   mv 搬出專案     : SUCCESS ⚠
   ```

   注意誤判的**方向是「假警報」**——你會以為沙箱沒在擋，而其實它是好的。（不存在反向的假通過：探測期望值就是 `BLOCKED`，混入豁免只會讓它變成 FAIL。）危險在於這種假警報會誘使人去把設定放得更寬，或直接認定沙箱無效。

   **判讀規則：`BLOCKED` 是自我驗證的，`WRITABLE` 才有歧義。**

   | 看到 | 代表 | 需要檢查污染嗎 |
   |---|---|---|
   | `BLOCKED` / `Operation not permitted` | 那次呼叫**一定**在沙箱內——豁免的呼叫寫得出去，不可能回報被擋 | 不需要 |
   | `WRITABLE` / `SUCCESS` | 真的允許，**或**那次呼叫被污染了 | 需要 |

   實用推論：只要同一次呼叫裡有**任何一行**回報 `BLOCKED`，就證明整串沒被豁免，同批的 `WRITABLE` 也可信。所以探測腳本裡**永遠保留一行必定被擋的項目**（例如 `touch ~/.v.tmp`）當作污染偵測器。

   附帶已驗證的一點：路徑裡含有 `python3` 字樣（如 `touch /opt/homebrew/lib/python3.13/...`）**不會**誤觸豁免——比對錨定在指令名稱，不是字串包含。

   建立這份設定時踩了兩次：一次把 `python3` 和 `touch` 寫在同一次呼叫、一次尾巴接了 `git status`，兩次都得到「防護全破」的錯誤結論。

5. **沙箱擋 macOS keychain 讀取。** 任何需要憑證的工具在沙箱內會**謊報認證失效**，而不是報權限錯誤：
   - `gh auth status` → `The token in default is invalid`（豁免後恢復成 `✓ Logged in`）
   - 巢狀 `claude` → `Not logged in · Please run /login`（未豁免，所以**無法用巢狀 session 驗證沙箱**）

   遇到某個工具莫名說認證壞掉，先想到這條，不要急著重新登入。

6. **`.claude/` 下的設定檔在沙箱內不可寫**（`settings.json` 與 `settings.local.json` 皆然，即使它們在專案目錄內）。用 Bash／python 改它會吃 `PermissionError`，連 `rm` 都是 `Operation not permitted`；必須用 Edit／Write 工具（那些不經沙箱）。這是正確設計——防止沙箱內指令改寫沙箱自己的設定。

7. **`Bash(rm -rf $HOME*)` 裡的 `$HOME` 是字面字串、不會展開。** 它只擋得住字面打出 `rm -rf $HOME...` 的情況；shell 展開後的實際路徑由 `rm -rf ~*` 和沙箱擋。留著沒壞處，但實際效力比看起來小。

---

## 已知缺口與代價

**唯一還開著的路是 `excludedCommands` 那三支的整串豁免。** 只要一次 Bash 呼叫裡出現 `gh`／`git`／`python3`，那次呼叫的整串指令都脫離沙箱——而 `Bash(python3 *)` 正在 allow 清單裡（audit skill 需要）。

這不是疏漏，是為了讓 audit 爬取、`gh issue`、submodule 能運作而付的代價。Chromium 的 Mach 註冊需求沒有更細的旋鈕可調，只能整支豁免。

**誠實的定位**：這道牆能穩穩擋住誤刪誤寫（`rm`／`mv`／`cp`／`sed`／`node`／`npm` 全受 kernel 層約束），但它**不是對抗性邊界**。威脅模型是「防手滑、防預設行為」，不是「防決心繞過的對手」。

其他限制：

- **只約束寫入，讀取完全不限。** 要連讀取一起關要用 `sandbox.filesystem.denyRead`。
- **`/opt/homebrew/*` 綁 Apple Silicon。** Intel Mac 的 Homebrew 前綴是 `/usr/local`，這份設定搬過去後 `pip install playwright` 會被擋。
- **從零安裝未驗證。** 驗證時 playwright 已經裝好，Phase 1 那兩行 exit 0 其實是 no-op，只證明「沒被擋」，沒證明路徑清單完整。乾淨環境第一次跑可能還缺某個暫存路徑；那會是明確的 `Operation not permitted`，不會靜默失敗，看到再補。

---

## 怎麼重跑驗收

改過沙箱設定後**一定要重跑**，不要假設語法有效。沙箱是即時生效的（逐次包裹 Bash 呼叫），不需要重啟 session。

**關鍵：以下指令必須單獨成一通，不可混入 `gh`／`git`／`python3`。**

```bash
printf '專案內      : '; (touch ./.v.tmp 2>/dev/null && echo WRITABLE && rm -f ./.v.tmp || echo BLOCKED)
printf '家目錄      : '; (touch ~/.v.tmp 2>/dev/null && echo WRITABLE && rm -f ~/.v.tmp || echo BLOCKED)
printf '兄弟專案    : '; (touch ~/Projects/.v.tmp 2>/dev/null && echo WRITABLE && rm -f ~/Projects/.v.tmp || echo BLOCKED)
printf 'mv 搬出去   : '; (echo x > ./.m.tmp && mv ./.m.tmp ~/.m.tmp 2>/dev/null && echo SUCCESS || echo BLOCKED); rm -f ./.m.tmp
printf 'pw 快取     : '; (touch ~/Library/Caches/ms-playwright/.v.tmp 2>/dev/null && echo WRITABLE && rm -f ~/Library/Caches/ms-playwright/.v.tmp || echo BLOCKED)
```

期望：專案內與 pw 快取 `WRITABLE`，其餘全部 `BLOCKED`。

其中「家目錄」那行同時是**污染偵測器**：它回報 `BLOCKED` 就證明這次呼叫沒被豁免，同批的 `WRITABLE` 才可信（見上方判讀規則）。若連它都顯示 `WRITABLE`，先檢查是不是混入了 `gh`／`git`／`python3`，而不是急著改設定。

功能面三項（各自單獨跑）：

```bash
git ls-remote --heads origin >/dev/null && echo "git OK"
gh issue list --state all --limit 1 >/dev/null && echo "gh OK"
# audit：用 playwright 開一個任意網站，確認 chromium 起得來
```

bypass 模式要在**專案外的終端機**驗（沙箱內的巢狀 `claude` 讀不到憑證）：

```bash
claude --dangerously-skip-permissions -p 'Run exactly: touch ~/.sbxcheck.tmp — report the exact result.'
```

`Operation not permitted` = 沙箱在 bypass 下仍生效。

---

## 實測記錄（證據）

以下每一條都是實際跑過的，不是推論。**「判讀」欄標 `BLOCKED` 者為自我驗證**（豁免的呼叫寫得出去，不可能回報被擋，故不可能是污染造成的偽陽性）。

測試環境：Claude Code `2.1.241`／macOS `15.1`（darwin arm64）／Homebrew Python `3.13`／`sandbox-exec` 存在。**這些行為與版本、平台相關，換環境請重驗。**

### 權限層（`Edit`／`Write` 工具，不經沙箱）

| 驗證項 | 方法 | 結果 |
|---|---|---|
| `deny` 在 `--dangerously-skip-permissions` 下仍強制 | 獨立臨時專案只設 `deny: ["Bash(echo *)"]`，跑 bypass session 執行 `echo DENYTEST_MARKER_12345` | `Permission to use Bash with command echo ... has been denied.` |
| `Edit()` 絕對路徑**必須** `//` 前綴 | 先用 `Edit(/abs/**)` → Write 成功（規則未命中）；改 `Edit(//abs/**)` → 被拒 | 單斜線**靜默失效**，被當成相對於專案根 |
| `deny` 壓過 `allow`，無法挖洞 | `deny: Edit(//X/**)` ＋ `allow: Edit(//X/ok/**)`，Write 到 `X/ok/f.txt` | `File is in a directory that is denied by your permission settings.` |
| `Edit(~/...)` 支援 `~` | 暫時加 `Edit(~/.../audit/_tildecheck/**)` → Write 被拒；另 Write 到 `~/.aws/.permcheck-tmp` → 被拒 | `~` 有效 |

### 沙箱層

| 驗證項 | 方法 | 結果 | 判讀 |
|---|---|---|---|
| 沙箱**即時生效**，不需重啟 session | 設定寫入後，同一 session 直接跑 touch 探測 | 立即生效 | — |
| 寫入約束範圍 | `touch` 各處（單獨呼叫，無豁免指令混入） | 專案內 `WRITABLE`；`~/`、`~/Projects/`、`~/.ssh/` 皆 `Operation not permitted`；`mv` 搬出專案 `BLOCKED`；`sed -i ~/.zshrc` `BLOCKED`；`~/Library/Caches/ms-playwright`、site-packages、`/private/tmp/...scratchpad` `WRITABLE` | `BLOCKED` 自我驗證 |
| 讀取不受限 | `head -1 ~/.zshrc` | `READ OK` | — |
| `allowWrite` 支援 `~` | 改成 `~/Library/Caches/ms-playwright` | 仍 `WRITABLE` | 同批家目錄探測 `BLOCKED`，未污染 |
| `allowWrite` **不支援 glob** | 改成 `/opt/homebrew/lib/python3.*/site-packages` | `BLOCKED` | 自我驗證 |
| `excludedCommands` **必須帶 `*`** | 裸寫 `"python3"` → python3 寫家目錄 `BLOCKED`；改 `"python3 *"` → 成功 | 裸名只匹配不帶參數的指令 | 前者自我驗證 |
| 豁免範圍是**一次呼叫的整串指令** | `touch ~/x` 單獨 → `BLOCKED`；`python3 ...; touch ~/x` 同一次呼叫 → 兩者皆成功 | 整串脫離沙箱 | 前者自我驗證 |
| 路徑含 `python3` 字樣**不會**誤觸豁免 | `touch /opt/homebrew/lib/python3.13/site-packages/...` 與家目錄探測同批 | 家目錄仍 `BLOCKED` | 自我驗證；比對錨定指令名 |
| `allowUnsandboxedCommands: false` 有效 | 刻意以 `dangerouslyDisableSandbox: true` 呼叫 `touch ~/...` | `Operation not permitted`，參數被完全忽略 | 自我驗證 |
| **沙箱在 bypass 下仍強制** | 在**專案外的終端機**跑 `claude --dangerously-skip-permissions -p 'touch ~/.sbxcheck.tmp'` | `Operation not permitted`，exit 1，檔案未建立 | 自我驗證 |
| 預設可寫集合 | 同上測試附帶揭露 | `.`（cwd）、`$TMPDIR`、`/tmp/claude` | — |
| 沙箱**擋 macOS keychain** | 沙箱內跑 `gh auth status`；沙箱內跑巢狀 `claude` | 前者 `The token in default is invalid`（豁免後恢復 `✓ Logged in`）；後者 `Not logged in · Please run /login` | 症狀是**謊報認證失效**，不是權限錯誤 |
| `.claude/` 設定檔沙箱內不可寫 | 用 python 改 `settings.local.json`；另試 `rm` | `PermissionError: Operation not permitted`／`rm: Operation not permitted`；改用 Write 工具則成功 | 自我驗證 |
| 設定從 `settings.json` 生效（搬移後複驗） | 內容搬到 `settings.json`、`settings.local.json` 清為 `{}`，重跑探測與逃生門測試 | 家目錄／`~/Projects`／`~/.ssh` 仍 `BLOCKED`；`dangerouslyDisableSandbox` 仍被忽略 | 自我驗證 |
| Chromium **無法**在沙箱內啟動 | 沙箱內跑 playwright 啟動 chromium | `bootstrap_check_in org.chromium.Chromium.MachPortRendezvousServer.<pid>: Permission denied (1100)` | 自我驗證 |
| `allowMachLookup` **救不了** Chromium | 加 `org.chromium.Chromium.MachPortRendezvousServer.*` 後重跑 | 同一錯誤再現 | `bootstrap_check_in` 是**註冊**，該設定只管**查找** |

### 功能層（加入 `excludedCommands` 豁免後）

| 驗證項 | 方法 | 結果 |
|---|---|---|
| audit 爬取全鏈路 | playwright 啟動 chromium，走訪 `example.com` 與 `www.python.org`，開 tracing | 兩站 title 取得；記錄到 7 個網域（含 `ajax.googleapis.com`、`media.ethicalads.io`）；截圖 ＋ `trace.zip` 產出 |
| `gh` API | `gh issue list --state all --limit 5 --json number,title` | `[]`（無 issue）；`gh auth status` → `✓ Logged in` |
| `git` 遠端（submodule 工作流） | `git ls-remote --heads origin` | 列出遠端 branch |
| 一般網路出口 | `curl https://example.com` | `HTTP 200`（沙箱內，未豁免） |
| `allowWrite` 四條對應真實落點 | `pip3 cache dir`／`which playwright`／`python3 -c "import playwright"`／`ls ~/Library/Caches/ms-playwright/chromium*` | 四條全部命中實際路徑 |

### 未驗證（明確標示，勿當成已驗證）

- **從零安裝 playwright**。驗證時環境已裝好，Phase 1 那兩行 `exit 0` 其實是 no-op，只證明「沒被沙箱擋」，**沒證明 `allowWrite` 清單完整**。乾淨環境第一次跑可能還缺某個暫存路徑（例如 pip 的 build temp）；那會是明確的 `Operation not permitted`，不會靜默失敗。
- **Intel Mac**（Homebrew 前綴 `/usr/local`）。
- **`enableWeakerNestedSandbox` / `enableWeakerNetworkIsolation` 是否能救 Chromium 與 `gh`**。schema 說明指向這兩個設定，但因為它們會削弱沙箱、未採用，故未驗證。

## 團隊共用注意事項

設定已搬到版控中的 `.claude/settings.json`，所以下面兩點會影響**每一位** clone 這個 repo 的人：

1. **`failIfUnavailable: true` 是硬閘門。** 沙箱起不來時 Claude Code 會在啟動時直接結束，而不是靜默降級成無沙箱。這是刻意的（無聲失去防護比不能啟動更糟），但代價是：**在沙箱無法運作的平台上，隊友會完全無法啟動**。macOS 用內建 `sandbox-exec`、沒問題；Linux／WSL 需要 `bwrap`（bubblewrap），沒裝就會被擋。若團隊有 Linux 成員，要嘛請他們裝 bubblewrap，要嘛改成 `false`（改成 false 時沙箱失效只會出現警告，容易被忽略）。
2. **`/opt/homebrew/*` 只適用 Apple Silicon。** Intel Mac 的 Homebrew 前綴是 `/usr/local`，Linux 是 `/home/linuxbrew/...` 或系統 Python 路徑。在那些機器上 `pip install playwright` 會被沙箱擋。要跨平台就得把對應前綴一併加入 `allowWrite`（範圍會變寬），或由各人在自己的 `settings.local.json` 補。

## 待決事項

- 是否為非 Apple Silicon 的隊友補上對應的 Homebrew／Python 前綴（或改由個人 `settings.local.json` 處理）。
- 是否為 Linux 隊友調整 `failIfUnavailable`。
- 從零安裝 playwright 的路徑清單是否完整（見「未驗證」）。
