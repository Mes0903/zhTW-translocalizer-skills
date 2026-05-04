#!/usr/bin/env lua

local function die(message)
  io.stderr:write("error: " .. message .. "\n")
  os.exit(1)
end

local function shell_quote(value)
  return "'" .. tostring(value):gsub("'", [['"'"']]) .. "'"
end

local function read_file(path)
  local handle, err = io.open(path, "rb")
  if not handle then
    die("failed to open " .. path .. ": " .. tostring(err))
  end
  local text = handle:read("*a")
  handle:close()
  return text
end

local function dirname(path)
  local dir = tostring(path):match("^(.*)/[^/]+$")
  if dir == nil or dir == "" then
    return "."
  end
  return dir
end

local function ensure_dir(path)
  local ok, _, code = os.execute("mkdir -p " .. shell_quote(path))
  if not (ok == true or ok == 0 or code == 0) then
    die("failed to create directory: " .. path)
  end
end

local function write_temp(text, preferred_path)
  local path = preferred_path or os.tmpname()
  if preferred_path then
    ensure_dir(dirname(path))
  end
  local handle, err = io.open(path, "wb")
  if not handle then
    die("failed to create temp file: " .. tostring(err))
  end
  handle:write(text)
  handle:close()
  return path
end

local function run_command(command)
  local output_path = os.tmpname()
  local ok, _, code = os.execute(command .. " > " .. shell_quote(output_path) .. " 2>&1")
  local output = read_file(output_path)
  os.remove(output_path)
  local success = ok == true or ok == 0 or code == 0
  return success, output
end

local function assert_contains(output, needle, label)
  if not output:find(needle, 1, true) then
    die(label .. ": expected output to contain " .. needle .. "\n" .. output)
  end
end

local function assert_not_contains(output, needle, label)
  if output:find(needle, 1, true) then
    die(label .. ": expected output not to contain " .. needle .. "\n" .. output)
  end
end

local function trim(value)
  return (tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local script_path = arg[0] or "scripts/lint_smoke.lua"
local repo_root = script_path:match("^(.*)/scripts/[^/]+$") or "."
local lint_script = repo_root .. "/scripts/lint.lua"
local smoke_project_root = repo_root .. "/working/_lint_smoke_project"
local smoke_glossary_path = smoke_project_root .. "/glossary.md"
local smoke_glossary = [[| 英文 | 臺灣用語 |
| --- | --- |
| semaphore / Semaphore | semaphore |
| scheduler | 排程器 |
]]

local cases = {
  {
    name = "default_disables_l005",
    text = "<style>body{color:red;}</style>\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "default_disables_l005")
      assert_not_contains(output, "[L005]", "default_disables_l005")
    end,
  },
  {
    name = "manual_enable_l005",
    text = "<style>body{color:red;}</style>\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L005 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L005]", "manual_enable_l005")
      assert_contains(output, "1 warning(s)", "manual_enable_l005")
    end,
  },
  {
    name = "markdown_grouped_output_merges_locations",
    text = "前言：\n```cpp\nint main() {}\n```\n結語。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --format markdown --rules L036 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "# Lint Report", "markdown_grouped_output_merges_locations")
      assert_contains(output, "| Files scanned | 1 |", "markdown_grouped_output_merges_locations")
      assert_contains(output, "| Total warnings | 2 |", "markdown_grouped_output_merges_locations")
      assert_contains(
        output,
        "| `warning` | `L036` | 2 | L2:C1, L4:C1 | 一般 code block 前後應保留空行；若位於 list item 內可依上下文省略 |",
        "markdown_grouped_output_merges_locations"
      )
    end,
  },
  {
    name = "markdown_output_reports_zero_warnings",
    text = "正文。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --format markdown --rules L003 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "| Files scanned | 1 |", "markdown_output_reports_zero_warnings")
      assert_contains(output, "| Total warnings | 0 |", "markdown_output_reports_zero_warnings")
      assert_contains(output, "No warnings.", "markdown_output_reports_zero_warnings")
    end,
  },
  {
    name = "json_columns_use_utf8_character_offsets",
    text = "甲乙的配置會影響結果。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --format json --rules L108 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "\"lint_id\":\"L108\"", "json_columns_use_utf8_character_offsets")
      assert_contains(output, "\"col\":3", "json_columns_use_utf8_character_offsets")
      assert_not_contains(output, "\"col\":7", "json_columns_use_utf8_character_offsets")
    end,
  },
  {
    name = "detect_colon_list",
    text = "前言：\n- 項目一\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L003 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L003]", "detect_colon_list")
    end,
  },
  {
    name = "short_list_blank_line_warns",
    text = "- 項目一\n\n- 項目二\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L004 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L004]", "short_list_blank_line_warns")
    end,
  },
  {
    name = "long_bibliography_items_allow_spacing",
    text = "- [A01] 這是一條很長很長的 bibliographic list item，後面還跟著一整句補充說明，長度足夠像正式參考書目。\n\n- [B02] 這是另一條同樣很長的 bibliographic list item，也帶有完整說明，用來模擬 reference section 的排版。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L004 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "long_bibliography_items_allow_spacing")
      assert_not_contains(output, "[L004]", "long_bibliography_items_allow_spacing")
    end,
  },
  {
    name = "bibliography_reference_entry_structure_warns",
    text = "## References\n\n- [I09] \"Intel 64 and IA-32 Architectures Software Developer's Manuals\" by Intel, 2009. http://example.com/manuals 特別注意 Volume 3A\n  - 網址：http://example.com/manuals 和補充說明\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L055 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L055]", "bibliography_reference_entry_structure_warns")
    end,
  },
  {
    name = "bibliography_reference_url_corpse_warns",
    text = "## References\n\n- <a id=\"8\">[I09]</a> \"Intel 64 and IA-32 Architectures Software Developer's Manuals\" by Intel, 2009.\n  - http://www.intel.com/products/processor/manuals特別注意Volume3A\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L055 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L055]", "bibliography_reference_url_corpse_warns")
    end,
  },
  {
    name = "bibliography_initials_spacing_warns",
    text = "## References\n\n- [KE+62] \"One-level Storage System\" by T.Kilburn, D.B.G. Edwards, M.J. Lanigan, F.H. Sumner. IRE Trans. EC-11, 2, 1962.\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L056 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L056]", "bibliography_initials_spacing_warns")
    end,
  },
  {
    name = "bibliography_abbreviation_number_spacing_warns",
    text = "## References\n\n- [LL82] \"Virtual Memory Management in the VAX/VMS Operating System\" by Hank Levy, P. Lipman. IEEE Computer, Vol.15, No.3, pp.45-52, March 1982.\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L057 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L057]", "bibliography_abbreviation_number_spacing_warns")
    end,
  },
  {
    name = "bibliography_year_shorthand_spacing_warns",
    text = "## References\n\n- [G+95] \"Idleness is not sloth\" by Richard Golding, Peter Bosch, Carl Staelin, Tim Sullivan, John Wilkes. USENIX ATC'95, New Orleans, Louisiana.\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L058 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L058]", "bibliography_year_shorthand_spacing_warns")
    end,
  },
  {
    name = "bibliography_possessive_spacing_warns",
    text = "## References\n\n- [I09] \"Intel 64 and IA-32 Architectures Software Developer 's Manuals\" by Intel, 2009.\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L059 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L059]", "bibliography_possessive_spacing_warns")
    end,
  },
  {
    name = "bibliography_curly_quotes_warns",
    text = "## References\n\n- [I09] “Intel 64 and IA-32 Architectures Software Developer’s Manuals” by Intel, 2009.\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L060 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L060]", "bibliography_curly_quotes_warns")
    end,
  },
  {
    name = "bibliography_reference_style_ok",
    text = "## References\n\n- <a id=\"8\">[I09]</a> \"Intel 64 and IA-32 Architectures Software Developer's Manuals\" by Intel, 2009.\n  - http://www.intel.com/products/processor/manuals\n  - 特別注意其中的「Volume 3A: System Programming Guide Part 1」和「Volume 3B: System Programming Guide Part 2」\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L055,L056,L057,L058,L059,L060 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "bibliography_reference_style_ok")
      assert_not_contains(output, "[L055]", "bibliography_reference_style_ok")
      assert_not_contains(output, "[L056]", "bibliography_reference_style_ok")
      assert_not_contains(output, "[L057]", "bibliography_reference_style_ok")
      assert_not_contains(output, "[L058]", "bibliography_reference_style_ok")
      assert_not_contains(output, "[L059]", "bibliography_reference_style_ok")
      assert_not_contains(output, "[L060]", "bibliography_reference_style_ok")
    end,
  },
  {
    name = "bibliography_explanation_halfwidth_comma_warns",
    text = "## References\n\n- <a id=\"9\">[M15]</a> \"OSSpinLock Is Unsafe\" by J. McCall.\n  - https://mjtsai.com/blog/2015/12/16/osspinlock-is-unsafe\n  - 指出在 macOS 上使用不同優先權的執行緒時, OSSpinLock 可能導致無限忙等，提醒 Mac 使用者謹慎\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L061 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L061]", "bibliography_explanation_halfwidth_comma_warns")
    end,
  },
  {
    name = "bibliography_explanation_terminal_period_warns",
    text = "## References\n\n- <a id=\"11\">[P81]</a> \"Myths About the Mutual Exclusion Problem\" by G. L. Peterson. Information Processing Letters, 12(3), pages 115-116, 1981.\n  - 此文首次介紹了 Peterson 的演算法.\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L061 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L061]", "bibliography_explanation_terminal_period_warns")
    end,
  },
  {
    name = "bibliography_explanation_chinese_punctuation_ok",
    text = "## References\n\n- <a id=\"9\">[M15]</a> \"OSSpinLock Is Unsafe\" by J. McCall.\n  - https://mjtsai.com/blog/2015/12/16/osspinlock-is-unsafe\n  - 指出在 macOS 上使用不同優先權的執行緒時，OSSpinLock 可能導致無限忙等，提醒 Mac 使用者謹慎\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L061 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "bibliography_explanation_chinese_punctuation_ok")
      assert_not_contains(output, "[L061]", "bibliography_explanation_chinese_punctuation_ok")
    end,
  },
  {
    name = "bibliography_explanation_uses_general_prose_rules",
    text = "## References\n\n- <a id=\"3\">[D68]</a> \"Cooperating sequential processes\" by Edsger W. Dijkstra. 1968.\n  - http://www.cs.utexas.edu/users/EWD/ewd01xx/EWD123.PDF\n  - 這篇經典論文提出 \"原始並行問題\" 與 Dekker 的解法\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L023 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L023]", "bibliography_explanation_uses_general_prose_rules")
    end,
  },
  {
    name = "formal_citation_key_style_ok",
    text = "正文提到 Solaris 與 Linux 的實作細節 <sup>[[L09]](#7), [[S09]](#14)</sup>。\n\n## References\n\n- <a id=\"7\">[L09]</a> \"glibc 2.9 (include Linux pthreads implementation)\" by Many authors.\n- <a id=\"14\">[S09]</a> \"OpenSolaris Thread Library\" by Sun.\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L015,L016 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "formal_citation_key_style_ok")
      assert_not_contains(output, "[L015]", "formal_citation_key_style_ok")
      assert_not_contains(output, "[L016]", "formal_citation_key_style_ok")
    end,
  },
  {
    name = "formal_citation_key_style_missing_reference_section_warns",
    text = "正文提到 Solaris 與 Linux 的實作細節 <sup>[[L09]](#7), [[S09]](#14)</sup>。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L015 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L015]", "formal_citation_key_style_missing_reference_section_warns")
    end,
  },
  {
    name = "formal_citation_key_style_broken_mapping_warns",
    text = "正文提到 Solaris 與 Linux 的實作細節 <sup>[[L09]](#7), [[S09]](#14)</sup>。\n\n## References\n\n- <a id=\"7\">[L09]</a> \"glibc 2.9 (include Linux pthreads implementation)\" by Many authors.\n- <a id=\"14\">[L81]</a> \"Observations on the Development of an Operating System\" by Hugh Lauer.\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L016 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L016]", "formal_citation_key_style_broken_mapping_warns")
    end,
  },
  {
    name = "formal_citation_uncited_reference_allowed",
    text = "正文提到 Linux 的實作細節 <sup>[[L09]](#7)</sup>。\n\n## References\n\n- <a id=\"7\">[L09]</a> \"glibc 2.9 (include Linux pthreads implementation)\" by Many authors.\n- <a id=\"14\">[S09]</a> \"OpenSolaris Thread Library\" by Sun.\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L015,L016 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "formal_citation_uncited_reference_allowed")
      assert_not_contains(output, "[L015]", "formal_citation_uncited_reference_allowed")
      assert_not_contains(output, "[L016]", "formal_citation_uncited_reference_allowed")
    end,
  },
  {
    name = "frontmatter_ignored_for_l002",
    text = "---\ntitle: 測試\ntag:\n- one\n---\n\n正文。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L002 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "frontmatter_ignored_for_l002")
      assert_not_contains(output, "[L002]", "frontmatter_ignored_for_l002")
    end,
  },
  {
    name = "component_tag_ignored_for_quote_rules",
    text = "<center-panel title=\"執行緒 A（你）\">\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L023,L026 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "component_tag_ignored_for_quote_rules")
      assert_not_contains(output, "[L023]", "component_tag_ignored_for_quote_rules")
      assert_not_contains(output, "[L026]", "component_tag_ignored_for_quote_rules")
    end,
  },
  {
    name = "image_caption_ignored_for_l026",
    text = "![（Figure 8.1: Layers of the file system.）](image/fslayer.png)\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L026 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "image_caption_ignored_for_l026")
      assert_not_contains(output, "[L026]", "image_caption_ignored_for_l026")
    end,
  },
  {
    name = "fullwidth_parentheses_allows_english_prose_gloss",
    text = "最低一個 bit（lowest-order bit of the first byte）用來判斷版本。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L026 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "fullwidth_parentheses_allows_english_prose_gloss")
      assert_not_contains(output, "[L026]", "fullwidth_parentheses_allows_english_prose_gloss")
    end,
  },
  {
    name = "fullwidth_parentheses_warns_on_code_like_ascii",
    text = "Operator（++）needs handling.\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L026 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L026]", "fullwidth_parentheses_warns_on_code_like_ascii")
    end,
  },
  {
    name = "directive_block_ignored_for_l002",
    text = "::: info\n思考題：這是一段內容。\n:::\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L002 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "directive_block_ignored_for_l002")
      assert_not_contains(output, "[L002]", "directive_block_ignored_for_l002")
    end,
  },
  {
    name = "display_math_ignored_for_l002",
    text = "$$\na < b\n$$\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L002 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "display_math_ignored_for_l002")
      assert_not_contains(output, "[L002]", "display_math_ignored_for_l002")
    end,
  },
  {
    name = "top_level_code_fence_requires_surrounding_blank_lines",
    text = "想像一下如果 `>>` 的 bool conversion 不是 explicit 會發生什麼事：\n```cpp\nint main() {}\n```\n那麼這件事會自動發生：\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L036 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L036]", "top_level_code_fence_requires_surrounding_blank_lines")
      assert_contains(output, "2 warning(s)", "top_level_code_fence_requires_surrounding_blank_lines")
    end,
  },
  {
    name = "top_level_code_fence_with_blank_lines_allowed",
    text = "想像一下如果 `>>` 的 bool conversion 不是 explicit 會發生什麼事：\n\n```cpp\nint main() {}\n```\n\n那麼這件事會自動發生：\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L036 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "top_level_code_fence_with_blank_lines_allowed")
      assert_not_contains(output, "[L036]", "top_level_code_fence_with_blank_lines_allowed")
    end,
  },
  {
    name = "indented_list_code_fence_spacing_allowed",
    text = "- 範例：\n  ```cpp\n  int main() {}\n  ```\n  接著說明。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L036 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "indented_list_code_fence_spacing_allowed")
      assert_not_contains(output, "[L036]", "indented_list_code_fence_spacing_allowed")
    end,
  },
  {
    name = "code_fence_adjacent_to_custom_container_boundary_allowed",
    text = ":::tip\n```text\nexample\n```\n:::\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L036 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "code_fence_adjacent_to_custom_container_boundary_allowed")
      assert_not_contains(output, "[L036]", "code_fence_adjacent_to_custom_container_boundary_allowed")
    end,
  },
  {
    name = "sentence_punctuation_spacing_warns",
    text = "第一句。第二句？第三句；第四句\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L037 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L037]", "sentence_punctuation_spacing_warns")
      assert_contains(output, "3 warning(s)", "sentence_punctuation_spacing_warns")
    end,
  },
  {
    name = "sentence_punctuation_spacing_allows_spaces",
    text = "第一句。 第二句？ 第三句； 第四句\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L037 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "sentence_punctuation_spacing_allows_spaces")
      assert_not_contains(output, "[L037]", "sentence_punctuation_spacing_allows_spaces")
    end,
  },
  {
    name = "sentence_punctuation_spacing_allows_attached_chinese_closing_quote",
    text = "他說：「完成。」接著回到主流程\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L037 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "sentence_punctuation_spacing_allows_attached_chinese_closing_quote")
      assert_not_contains(output, "[L037]", "sentence_punctuation_spacing_allows_attached_chinese_closing_quote")
    end,
  },
  {
    name = "sentence_punctuation_spacing_allows_closing_quote_at_eol",
    text = "他說：「完成。」\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L037 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "sentence_punctuation_spacing_allows_closing_quote_at_eol")
      assert_not_contains(output, "[L037]", "sentence_punctuation_spacing_allows_closing_quote_at_eol")
    end,
  },
  {
    name = "sentence_punctuation_spacing_allows_following_fullwidth_comma",
    text = "他問「是否安全？」，這需要另外判斷\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L037 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "sentence_punctuation_spacing_allows_following_fullwidth_comma")
      assert_not_contains(output, "[L037]", "sentence_punctuation_spacing_allows_following_fullwidth_comma")
    end,
  },
  {
    name = "sentence_punctuation_spacing_checks_list_items",
    text = "- 第一項。第二句\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L037 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L037]", "sentence_punctuation_spacing_checks_list_items")
      assert_contains(output, "1 warning(s)", "sentence_punctuation_spacing_checks_list_items")
    end,
  },
  {
    name = "sentence_punctuation_spacing_ignores_inline_code",
    text = "這裡的 `foo。bar` 不檢查； 這裡有空格\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L037 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "sentence_punctuation_spacing_ignores_inline_code")
      assert_not_contains(output, "[L037]", "sentence_punctuation_spacing_ignores_inline_code")
    end,
  },
  {
    name = "sentence_punctuation_spacing_ignores_markdown_image",
    text = "![圖說。Source](image/example.png)\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L037 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "sentence_punctuation_spacing_ignores_markdown_image")
      assert_not_contains(output, "[L037]", "sentence_punctuation_spacing_ignores_markdown_image")
    end,
  },
  {
    name = "cjk_latin_spacing_warns",
    text = "這個API呼叫需要修正\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L038 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L038]", "cjk_latin_spacing_warns")
      assert_contains(output, "2 warning(s)", "cjk_latin_spacing_warns")
    end,
  },
  {
    name = "cjk_latin_spacing_allows_spaces",
    text = "這個 API 呼叫需要修正\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L038 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "cjk_latin_spacing_allows_spaces")
      assert_not_contains(output, "[L038]", "cjk_latin_spacing_allows_spaces")
    end,
  },
  {
    name = "cjk_latin_spacing_checks_list_items",
    text = "- 這個API 需要修正\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L038 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L038]", "cjk_latin_spacing_checks_list_items")
      assert_contains(output, "1 warning(s)", "cjk_latin_spacing_checks_list_items")
    end,
  },
  {
    name = "cjk_latin_spacing_ignores_inline_code",
    text = "呼叫`API`函式不由這條規則檢查\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L038 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "cjk_latin_spacing_ignores_inline_code")
      assert_not_contains(output, "[L038]", "cjk_latin_spacing_ignores_inline_code")
    end,
  },
  {
    name = "cjk_latin_spacing_ignores_codeish_tokens",
    text = "foo_bar變數和 https://example.com文件先不由這條規則檢查\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L038 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "cjk_latin_spacing_ignores_codeish_tokens")
      assert_not_contains(output, "[L038]", "cjk_latin_spacing_ignores_codeish_tokens")
    end,
  },
  {
    name = "cjk_latin_spacing_warns_numeric_closed_forms",
    text = "第10篇\n3個項目\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L038 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L038]", "cjk_latin_spacing_warns_numeric_closed_forms")
      assert_contains(output, "3 warning(s)", "cjk_latin_spacing_warns_numeric_closed_forms")
    end,
  },
  {
    name = "cjk_latin_spacing_allows_numeric_spaces",
    text = "第 10 篇\n3 個項目\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L038 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "cjk_latin_spacing_allows_numeric_spaces")
      assert_not_contains(output, "[L038]", "cjk_latin_spacing_allows_numeric_spaces")
    end,
  },
  {
    name = "markdown_link_spacing_warns_on_chinese_label_followed_by_space",
    text = "雖有[論文](http://example.com) 在進行中\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L040 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L040]", "markdown_link_spacing_warns_on_chinese_label_followed_by_space")
      assert_contains(output, "1 warning(s)", "markdown_link_spacing_warns_on_chinese_label_followed_by_space")
    end,
  },
  {
    name = "halfwidth_parentheses_ignores_markdown_link_url",
    text = "雖有[論文](http://example.com)在進行中\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L025 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "halfwidth_parentheses_ignores_markdown_link_url")
      assert_not_contains(output, "[L025]", "halfwidth_parentheses_ignores_markdown_link_url")
    end,
  },
  {
    name = "markdown_link_spacing_allows_mixed_label_before_chinese",
    text = "目前可以在[最新的 draft](https://example.com) 看見該片段\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L040 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "markdown_link_spacing_allows_mixed_label_before_chinese")
      assert_not_contains(output, "[L040]", "markdown_link_spacing_allows_mixed_label_before_chinese")
    end,
  },
  {
    name = "markdown_link_spacing_warns_on_english_label_without_spaces",
    text = "可以看[draft](https://example.com)版本\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L040 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L040]", "markdown_link_spacing_warns_on_english_label_without_spaces")
      assert_contains(output, "2 warning(s)", "markdown_link_spacing_warns_on_english_label_without_spaces")
    end,
  },
  {
    name = "fullwidth_comma_spacing_warns",
    text = "第一句 ，第二句， 第三句\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L041 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L041]", "fullwidth_comma_spacing_warns")
      assert_contains(output, "2 warning(s)", "fullwidth_comma_spacing_warns")
    end,
  },
  {
    name = "fullwidth_comma_spacing_allows_no_spaces",
    text = "第一句，第二句，第三句\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L041 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "fullwidth_comma_spacing_allows_no_spaces")
      assert_not_contains(output, "[L041]", "fullwidth_comma_spacing_allows_no_spaces")
    end,
  },
  {
    name = "markdown_link_tracking_params_warn",
    text = "相關內容詳見 [offsetof](https://en.cppreference.com/w/cpp/types/offsetof?fbclid=abc&utm_source=chatgpt.com#:~:text=offsetof)\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L042 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L042]", "markdown_link_tracking_params_warn")
      assert_contains(output, "1 warning(s)", "markdown_link_tracking_params_warn")
    end,
  },
  {
    name = "markdown_link_tracking_params_warns_nested_label",
    text = "延伸閱讀：[[重新理解 C++] Array 和 Pointer 的差異](https://example.com/post?fbclid=abc)\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L042 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L042]", "markdown_link_tracking_params_warns_nested_label")
      assert_contains(output, "1 warning(s)", "markdown_link_tracking_params_warns_nested_label")
    end,
  },
  {
    name = "markdown_link_tracking_params_allows_original_query",
    text = "請看 [search](https://example.com/search?q=offsetof&page=1#result)\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L042 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "markdown_link_tracking_params_allows_original_query")
      assert_not_contains(output, "[L042]", "markdown_link_tracking_params_allows_original_query")
    end,
  },
  {
    name = "terminal_continuation_punctuation_warns",
    text = "bit-field 不是我們的重點，所以就不展開敘述了，\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L043 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L043]", "terminal_continuation_punctuation_warns")
      assert_contains(output, "1 warning(s)", "terminal_continuation_punctuation_warns")
    end,
  },
  {
    name = "terminal_continuation_punctuation_checks_wrapped_quote",
    text = "他說：「這段還沒結束，」\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L043 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L043]", "terminal_continuation_punctuation_checks_wrapped_quote")
      assert_contains(output, "1 warning(s)", "terminal_continuation_punctuation_checks_wrapped_quote")
    end,
  },
  {
    name = "terminal_continuation_punctuation_allows_question_and_bracket",
    text = "這樣可以嗎？\n這句以括號結尾（補充）\n請看 [bit-field](https://example.com/bit_field)\n舉例：`1 + 1`、`i * 2`、`i / 3`\n舉例：\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L043 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "terminal_continuation_punctuation_allows_question_and_bracket")
      assert_not_contains(output, "[L043]", "terminal_continuation_punctuation_allows_question_and_bracket")
    end,
  },
  {
    name = "halfwidth_parentheses_english_prose_gloss_warns",
    text = "最低一個 bit(lowest-order bit of the first byte) 用來判斷版本。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L044 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L044]", "halfwidth_parentheses_english_prose_gloss_warns")
      assert_contains(output, "1 warning(s)", "halfwidth_parentheses_english_prose_gloss_warns")
    end,
  },
  {
    name = "halfwidth_parentheses_version_in_cjk_context_warns",
    text = "在我的環境上 (mingw-gcc 11.2.0) 也是 15。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L044 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L044]", "halfwidth_parentheses_version_in_cjk_context_warns")
      assert_contains(output, "1 warning(s)", "halfwidth_parentheses_version_in_cjk_context_warns")
    end,
  },
  {
    name = "halfwidth_parentheses_allows_function_call_shape",
    text = "這裡呼叫 foo(a, b) 只是示意。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L044 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "halfwidth_parentheses_allows_function_call_shape")
      assert_not_contains(output, "[L044]", "halfwidth_parentheses_allows_function_call_shape")
    end,
  },
  {
    name = "halfwidth_parentheses_allows_inline_math",
    text = "實際容量為 $(N \\\\cdot B)/2$。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L044 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "halfwidth_parentheses_allows_inline_math")
      assert_not_contains(output, "[L044]", "halfwidth_parentheses_allows_inline_math")
    end,
  },
  {
    name = "halfwidth_parentheses_markdown_link_warns",
    text = "Pablo Halpern 在 PMR 的提案 ([N3916](https://example.com/n3916.pdf)) 中提到：\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L044 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L044]", "halfwidth_parentheses_markdown_link_warns")
      assert_contains(output, "1 warning(s)", "halfwidth_parentheses_markdown_link_warns")
    end,
  },
  {
    name = "halfwidth_parentheses_allows_standalone_url",
    text = "詳見 (https://example.com/n3916.pdf) 的說明。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L044 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "halfwidth_parentheses_allows_standalone_url")
      assert_not_contains(output, "[L044]", "halfwidth_parentheses_allows_standalone_url")
    end,
  },
  {
    name = "halfwidth_parentheses_checks_whole_cjk_paragraph",
    text = "This term (mutex) appears here.\n下一行是中文說明。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L044 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L044]", "halfwidth_parentheses_checks_whole_cjk_paragraph")
      assert_contains(output, "1 warning(s)", "halfwidth_parentheses_checks_whole_cjk_paragraph")
    end,
  },
  {
    name = "halfwidth_parentheses_allows_all_english_paragraph",
    text = "This term (mutex) appears here.\nAnother English sentence follows.\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L044 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "halfwidth_parentheses_allows_all_english_paragraph")
      assert_not_contains(output, "[L044]", "halfwidth_parentheses_allows_all_english_paragraph")
    end,
  },
  {
    name = "fullwidth_parentheses_spacing_warns",
    text = "在我的環境上 （mingw-gcc 11.2.0） 也是 15。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L045 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L045]", "fullwidth_parentheses_spacing_warns")
      assert_contains(output, "1 warning(s)", "fullwidth_parentheses_spacing_warns")
    end,
  },
  {
    name = "fullwidth_parentheses_spacing_allows_attached",
    text = "在我的環境上（mingw-gcc 11.2.0）也是 15。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L045 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "fullwidth_parentheses_spacing_allows_attached")
      assert_not_contains(output, "[L045]", "fullwidth_parentheses_spacing_allows_attached")
    end,
  },
  {
    name = "fullwidth_parentheses_spacing_allows_sentence_boundary",
    text = "前句。 （補充說明。） 後句\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L045 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "fullwidth_parentheses_spacing_allows_sentence_boundary")
      assert_not_contains(output, "[L045]", "fullwidth_parentheses_spacing_allows_sentence_boundary")
    end,
  },
  {
    name = "fullwidth_parentheses_spacing_checks_heading",
    text = "### 建構子（Constructor） 與解構子（Destructor）\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L045 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L045]", "fullwidth_parentheses_spacing_checks_heading")
      assert_contains(output, "1 warning(s)", "fullwidth_parentheses_spacing_checks_heading")
    end,
  },
  {
    name = "bilingual_term_order_warns_on_english_first",
    text = "mutex（互斥鎖）可以避免競爭。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L046 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L046]", "bilingual_term_order_warns_on_english_first")
      assert_contains(output, "1 warning(s)", "bilingual_term_order_warns_on_english_first")
    end,
  },
  {
    name = "bilingual_term_order_allows_chinese_first",
    text = "互斥鎖（mutex）可以避免競爭。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L046 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "bilingual_term_order_allows_chinese_first")
      assert_not_contains(output, "[L046]", "bilingual_term_order_allows_chinese_first")
    end,
  },
  {
    name = "bilingual_term_order_allows_descriptive_parenthetical",
    text = "把內容寫回 counter（位址 `0x8049a1c`）。\nmkfs（讀作 make fs）會建立檔案系統。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L046 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "bilingual_term_order_allows_descriptive_parenthetical")
      assert_not_contains(output, "[L046]", "bilingual_term_order_allows_descriptive_parenthetical")
    end,
  },
  {
    name = "cjk_internal_space_warns",
    text = "雖然有些 開機載入器會這樣做。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L047 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L047]", "cjk_internal_space_warns")
      assert_contains(output, "1 warning(s)", "cjk_internal_space_warns")
    end,
  },
  {
    name = "cjk_internal_space_allows_sentence_spacing",
    text = "第一句。 第二句繼續。\n中文 `code sample` 中文不由這條規則檢查。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L047 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "cjk_internal_space_allows_sentence_spacing")
      assert_not_contains(output, "[L047]", "cjk_internal_space_allows_sentence_spacing")
    end,
  },
  {
    name = "cjk_internal_space_checks_custom_container_body",
    text = ":::info\n熟悉並善用你的工具 你應該持續學習。\n:::\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L047 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L047]", "cjk_internal_space_checks_custom_container_body")
      assert_contains(output, "1 warning(s)", "cjk_internal_space_checks_custom_container_body")
    end,
  },
  {
    name = "title_mark_spacing_warns",
    text = "請讀 《作業系統》 這本書。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L048 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L048]", "title_mark_spacing_warns")
      assert_contains(output, "1 warning(s)", "title_mark_spacing_warns")
    end,
  },
  {
    name = "title_mark_spacing_allows_attached_marks",
    text = "請讀《作業系統》與〈第一章〉。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L048 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "title_mark_spacing_allows_attached_marks")
      assert_not_contains(output, "[L048]", "title_mark_spacing_allows_attached_marks")
    end,
  },
  {
    name = "title_mark_spacing_checks_markdown_link_label_edges",
    text = "請讀[《作業系統》](https://example.com) 這本書。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L048 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L048]", "title_mark_spacing_checks_markdown_link_label_edges")
      assert_contains(output, "1 warning(s)", "title_mark_spacing_checks_markdown_link_label_edges")
    end,
  },
  {
    name = "halfwidth_exclamation_in_cjk_prose_warns",
    text = "這真的太棒了!下一題來看看。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L049 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L049]", "halfwidth_exclamation_in_cjk_prose_warns")
      assert_contains(output, "1 warning(s)", "halfwidth_exclamation_in_cjk_prose_warns")
    end,
  },
  {
    name = "halfwidth_question_in_cjk_prose_warns",
    text = "真的嗎?我不太確定。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L049 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L049]", "halfwidth_question_in_cjk_prose_warns")
      assert_contains(output, "1 warning(s)", "halfwidth_question_in_cjk_prose_warns")
    end,
  },
  {
    name = "halfwidth_exclamation_terminal_after_cjk_warns",
    text = "太棒了!\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L049 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L049]", "halfwidth_exclamation_terminal_after_cjk_warns")
      assert_contains(output, "1 warning(s)", "halfwidth_exclamation_terminal_after_cjk_warns")
    end,
  },
  {
    name = "halfwidth_exclamation_in_english_prose_ignored",
    text = "That is great!\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L049 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "halfwidth_exclamation_in_english_prose_ignored")
      assert_not_contains(output, "[L049]", "halfwidth_exclamation_in_english_prose_ignored")
    end,
  },
  {
    name = "halfwidth_exclamation_inside_inline_code_ignored",
    text = "在 shell 裡用 `echo !` 就可以。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L049 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "halfwidth_exclamation_inside_inline_code_ignored")
      assert_not_contains(output, "[L049]", "halfwidth_exclamation_inside_inline_code_ignored")
    end,
  },
  {
    name = "fullwidth_exclamation_question_in_cjk_prose_ignored",
    text = "這真的太棒了！下一題來看看。真的嗎？我不太確定。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L049 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "fullwidth_exclamation_question_in_cjk_prose_ignored")
      assert_not_contains(output, "[L049]", "fullwidth_exclamation_question_in_cjk_prose_ignored")
    end,
  },
  {
    name = "curly_double_quote_in_cjk_prose_warns",
    text = "作者把它叫做\u{201C}輕量執行緒\u{201D}，很直觀。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L050 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L050]", "curly_double_quote_in_cjk_prose_warns")
      assert_contains(output, "1 warning(s)", "curly_double_quote_in_cjk_prose_warns")
    end,
  },
  {
    name = "curly_double_quote_around_english_ignored",
    text = "Paper \u{201C}Thread Scheduling\u{201D} talks about this.\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L050 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "curly_double_quote_around_english_ignored")
      assert_not_contains(output, "[L050]", "curly_double_quote_around_english_ignored")
    end,
  },
  {
    name = "corner_bracket_in_cjk_prose_ignored",
    text = "作者把它叫做「輕量執行緒」，很直觀。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L050 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "corner_bracket_in_cjk_prose_ignored")
      assert_not_contains(output, "[L050]", "corner_bracket_in_cjk_prose_ignored")
    end,
  },
  {
    name = "fullwidth_quote_spacing_warns",
    text = "或許我們不該關注「誰最先提出？」 這個問題\n計算 「平均」搜尋距離\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L051 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L051]", "fullwidth_quote_spacing_warns")
      assert_contains(output, "2 warning(s)", "fullwidth_quote_spacing_warns")
    end,
  },
  {
    name = "fullwidth_quote_spacing_allows_attached",
    text = "或許我們不該關注「誰最先提出？」這個問題\n計算「平均」搜尋距離\n- 「列點開頭」可保留 marker 後的空格\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L051 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "fullwidth_quote_spacing_allows_attached")
      assert_not_contains(output, "[L051]", "fullwidth_quote_spacing_allows_attached")
    end,
  },
  {
    name = "internal_consecutive_space_warns",
    text = "而  `poll()` 系統呼叫的行為非常相似\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L052 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L052]", "internal_consecutive_space_warns")
      assert_contains(output, "1 warning(s)", "internal_consecutive_space_warns")
    end,
  },
  {
    name = "internal_consecutive_space_allows_latex_and_leading_indent",
    text = "- 項目：\n  body 可以換行放在下一行\n\n$$\na  b\n=\nc  d\n$$\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L052 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "internal_consecutive_space_allows_latex_and_leading_indent")
      assert_not_contains(output, "[L052]", "internal_consecutive_space_allows_latex_and_leading_indent")
    end,
  },
  {
    name = "preferred_taiwan_terms_warns",
    text = "當前 process 的程序會訪問物理地址的 virtual memory，通過 syscall 打開 USB 設備。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L053 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L053]", "preferred_taiwan_terms_warns")
      assert_contains(output, "「物理地址」建議改為「實體位址」", "preferred_taiwan_terms_warns")
      assert_contains(output, "「程序」建議改為「行程」", "preferred_taiwan_terms_warns")
      assert_contains(output, "「設備」建議改為「裝置」", "preferred_taiwan_terms_warns")
    end,
  },
  {
    name = "preferred_taiwan_terms_warns_exception_programming",
    text = "這個 try-catch 區塊會把異常重新拋出。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L053 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L053]", "preferred_taiwan_terms_warns_exception_programming")
      assert_contains(output, "「異常」建議改為「例外」", "preferred_taiwan_terms_warns_exception_programming")
    end,
  },
  {
    name = "preferred_taiwan_terms_warns_memory_address",
    text = "這個地址會映射到頁表。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L053 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L053]", "preferred_taiwan_terms_warns_memory_address")
      assert_contains(output, "「地址」建議改為「位址」", "preferred_taiwan_terms_warns_memory_address")
    end,
  },
  {
    name = "preferred_taiwan_terms_allows_nonit_shebei",
    text = "工地大型設備需要定期保養。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L053 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "preferred_taiwan_terms_allows_nonit_shebei")
      assert_not_contains(output, "[L053]", "preferred_taiwan_terms_allows_nonit_shebei")
    end,
  },
  {
    name = "preferred_taiwan_terms_allows_nonit_chengxu",
    text = "法律程序必須依既定程序進行。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L053 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "preferred_taiwan_terms_allows_nonit_chengxu")
      assert_not_contains(output, "[L053]", "preferred_taiwan_terms_allows_nonit_chengxu")
    end,
  },
  {
    name = "preferred_taiwan_terms_allows_nonit_yichang",
    text = "這個病人的血壓明顯異常。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L053 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "preferred_taiwan_terms_allows_nonit_yichang")
      assert_not_contains(output, "[L053]", "preferred_taiwan_terms_allows_nonit_yichang")
    end,
  },
  {
    name = "preferred_taiwan_terms_allows_nonit_dizhi",
    text = "請把收件地址填在表格裡。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L053 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "preferred_taiwan_terms_allows_nonit_dizhi")
      assert_not_contains(output, "[L053]", "preferred_taiwan_terms_allows_nonit_dizhi")
    end,
  },
  {
    name = "preferred_taiwan_terms_allows_contextual_good_usage",
    text = "我們會分配工作，也通過測試。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L053 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "preferred_taiwan_terms_allows_contextual_good_usage")
      assert_not_contains(output, "[L053]", "preferred_taiwan_terms_allows_contextual_good_usage")
    end,
  },
  {
    name = "preferred_taiwan_terms_checks_memory_allocation_and_processor_core",
    text = "記憶體分配器會分配空間，使用 4 個核心。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L053 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L053]", "preferred_taiwan_terms_checks_memory_allocation_and_processor_core")
      assert_contains(output, "3 warning(s)", "preferred_taiwan_terms_checks_memory_allocation_and_processor_core")
      assert_contains(output, "「個核心」建議改為「個處理器核」", "preferred_taiwan_terms_checks_memory_allocation_and_processor_core")
    end,
  },
  {
    name = "preferred_taiwan_terms_ignores_inline_code",
    text = "請輸入 `當前程序會訪問地址`。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L053 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "preferred_taiwan_terms_ignores_inline_code")
      assert_not_contains(output, "[L053]", "preferred_taiwan_terms_ignores_inline_code")
    end,
  },
  {
    name = "preferred_taiwan_terms_allows_fixed_terms_with_embedded_needles",
    text = "只有當前置成分真的建立範圍時才前置。\nHandle 譯為控制代碼。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L053 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "preferred_taiwan_terms_allows_fixed_terms_with_embedded_needles")
      assert_not_contains(output, "[L053]", "preferred_taiwan_terms_allows_fixed_terms_with_embedded_needles")
    end,
  },
  {
    name = "custom_container_fence_warns_on_attached_content",
    text = "前文\n::: info更\n\n：內容:::\n後文\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L039 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L039]", "custom_container_fence_warns_on_attached_content")
      assert_contains(output, "4 warning(s)", "custom_container_fence_warns_on_attached_content")
    end,
  },
  {
    name = "custom_container_fence_allows_arbitrary_label",
    text = "前文\n\n:::callout_beta\n更：內容\n\n另外一段\n:::\n\n後文\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L039 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "custom_container_fence_allows_arbitrary_label")
      assert_not_contains(output, "[L039]", "custom_container_fence_allows_arbitrary_label")
    end,
  },
  {
    name = "custom_container_fence_warns_on_attached_title_without_space",
    text = ":::warning另外\n內容\n:::\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L039 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L039]", "custom_container_fence_warns_on_attached_title_without_space")
      assert_contains(output, "1 warning(s)", "custom_container_fence_warns_on_attached_title_without_space")
    end,
  },
  {
    name = "custom_container_fence_warns_on_lowercase_label_uppercase_title",
    text = ":::infoCRUX\n內容\n:::\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L039 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L039]", "custom_container_fence_warns_on_lowercase_label_uppercase_title")
      assert_contains(output, "1 warning(s)", "custom_container_fence_warns_on_lowercase_label_uppercase_title")
    end,
  },
  {
    name = "custom_container_fence_ignores_code_fence",
    text = "```text\n::: info更\n：內容:::\n```\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L039 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "custom_container_fence_ignores_code_fence")
      assert_not_contains(output, "[L039]", "custom_container_fence_ignores_code_fence")
    end,
  },
  {
    name = "dash_rule_warns_in_prose",
    text = "這是一段說明 — 後面接補充。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L028 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L028]", "dash_rule_warns_in_prose")
    end,
  },
  {
    name = "dash_rule_ignores_blockquote_and_table",
    text = "> source — quote\n\n| a | b |\n| - | - |\n| – | 0 |\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L028 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "dash_rule_ignores_blockquote_and_table")
      assert_not_contains(output, "[L028]", "dash_rule_ignores_blockquote_and_table")
    end,
  },
  {
    name = "extraction_artifact_rule_ignores_markdown_image",
    text = "![](image/figure-01.png)\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L006 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "extraction_artifact_rule_ignores_markdown_image")
      assert_not_contains(output, "[L006]", "extraction_artifact_rule_ignores_markdown_image")
    end,
  },
  {
    name = "references_heading_without_citation_apparatus",
    text = "## References\n\n- 一條參考項目\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L015 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "references_heading_without_citation_apparatus")
      assert_not_contains(output, "[L015]", "references_heading_without_citation_apparatus")
    end,
  },
  {
    name = "missing_eof_newline_warns",
    text = "這個檔案沒有文末換行",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L014 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L014]", "missing_eof_newline_warns")
    end,
  },
  {
    name = "eof_newline_present_allowed",
    text = "這個檔案有文末換行\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L014 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "eof_newline_present_allowed")
      assert_not_contains(output, "[L014]", "eof_newline_present_allowed")
    end,
  },
  {
    name = "paragraph_density_accepts_medium_paragraph",
    text = "這是一段中長技術說明。它會連續講三件事情，但整體還算好讀。最後再補一個例子，讓讀者知道前面的抽象說明要怎麼落回具體情境。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L020 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "paragraph_density_accepts_medium_paragraph")
      assert_not_contains(output, "[L020]", "paragraph_density_accepts_medium_paragraph")
    end,
  },
  {
    name = "paragraph_density_warns_dense_paragraph",
    text = "這是一段非常長的技術說明；它一口氣塞進背景、限制、例外與權衡；同時又把平台差異、同步保證與錯誤處理全部壓進同一段；接著還補上另一組平台條件、例外流程、測試假設與回退策略；然後再加入更多實作細節、案例比較、邊界行為與成本分析；最後又把抽象規則、局部例外、效能取捨、可移植性限制與維護負擔全部一起收束，讓讀者必須在單一段落裡處理過量資訊，整體密度已經高到非常適合拆段與重排。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L020 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L020]", "paragraph_density_warns_dense_paragraph")
    end,
  },
  {
    name = "single_low_value_semicolon_warns",
    text = "先做 preflight；未過關前不可開始起草。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L021 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L021]", "single_low_value_semicolon_warns")
    end,
  },
  {
    name = "single_low_value_semicolon_in_list_warns",
    text = "- 先做 preflight；未過關前不可開始起草。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L021 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L021]", "single_low_value_semicolon_in_list_warns")
    end,
  },
  {
    name = "single_semicolon_in_long_sentence_allowed",
    text = "這段先交代背景脈絡、限制條件、例外情況與相依關係，讓讀者知道前提在哪裡；接著再補一整段較長的後續說明，描述這些前提如何影響後面的設計與推論，避免把單一分號一律當成壞句子。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L021 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "single_semicolon_in_long_sentence_allowed")
      assert_not_contains(output, "[L021]", "single_semicolon_in_long_sentence_allowed")
    end,
  },
  {
    name = "parallel_semicolon_enumeration_warns_for_review",
    text = "名字這麼多看起來也許有點意外，但其實是有原因的。`increment` 和 `decrement` 這對名稱描述的是操作本身，也就是把值加一或減一；`signal` 和 `wait` 描述的是它們「常被拿來做什麼」；而 `V` 與 `P` 則是 Dijkstra 當年提出的原始名稱。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L021 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L021]", "parallel_semicolon_enumeration_warns_for_review")
    end,
  },
  {
    name = "multiple_non_parallel_semicolons_warns",
    text = "先做 preflight；未過關前不可開始起草；寫入前還要重新驗證。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L021 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L021]", "multiple_non_parallel_semicolons_warns")
    end,
  },
  {
    name = "inline_enumeration_without_final_conjunction_warns",
    text = "這裡會放每個主題的來源材料、正式輸出、圖片、補充資料、context memory。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L029 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L029]", "inline_enumeration_without_final_conjunction_warns")
    end,
  },
  {
    name = "inline_enumeration_with_final_yu_allowed",
    text = "這裡會放每個主題的來源材料、正式輸出、圖片、補充資料、project-local glossary 與 context memory。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L029 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "inline_enumeration_with_final_yu_allowed")
      assert_not_contains(output, "[L029]", "inline_enumeration_with_final_yu_allowed")
    end,
  },
  {
    name = "inline_enumeration_with_final_huo_allowed",
    text = "正式輸出不應混入開工前檢查、自檢筆記、對話痕跡、原文區塊、source-side CSS 或純呈現用 HTML wrapper。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L029 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "inline_enumeration_with_final_huo_allowed")
      assert_not_contains(output, "[L029]", "inline_enumeration_with_final_huo_allowed")
    end,
  },
  {
    name = "json_summary",
    text = "這是 \"中文引號\"\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L023 --format json " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "\"warning_count\":1", "json_summary")
      assert_contains(output, "\"lint_id\":\"L023\"", "json_summary")
    end,
  },
  {
    name = "source_text_block_leftover",
    text = "## 原文\n這是一段原文\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L019 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L019]", "source_text_block_leftover")
    end,
  },
  {
    name = "term_form_drift_after_first_bilingual",
    text = "快取（cache）\n緩存（cache）\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L031 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L031]", "term_form_drift_after_first_bilingual")
    end,
  },
  {
    name = "term_form_drift_ignores_clause_like_pair",
    text = "### 作業系統（OS）\n\nBIOS 最終會將作業系統（OS）給啟動。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L031 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "term_form_drift_ignores_clause_like_pair")
      assert_not_contains(output, "[L031]", "term_form_drift_ignores_clause_like_pair")
    end,
  },
  {
    name = "term_form_drift_ignores_list_separator_prefix",
    text = "提取（Fetch）、解碼（Decode）和執行（Execute）\n- 解碼（Decode）：解析指令。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L031 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "term_form_drift_ignores_list_separator_prefix")
      assert_not_contains(output, "[L031]", "term_form_drift_ignores_list_separator_prefix")
    end,
  },
  {
    name = "bare_english_drift_after_bilingual_anchor",
    text = "排程器（scheduler）會處理佇列。\n後面這裡直接寫 scheduler。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L054 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L054]", "bare_english_drift_after_bilingual_anchor")
    end,
  },
  {
    name = "bare_english_drift_multiword_after_bilingual_anchor",
    text = "直接證明（Direct Proof）在這裡先定義。\n後面這裡直接寫 Direct Proof。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L054 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L054]", "bare_english_drift_multiword_after_bilingual_anchor")
    end,
  },
  {
    name = "bare_english_drift_digit_term_after_bilingual_anchor",
    text = "第一層快取（L1 cache）會先命中。\n後面這裡直接寫 L1 cache。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L054 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L054]", "bare_english_drift_digit_term_after_bilingual_anchor")
    end,
  },
  {
    name = "bare_english_drift_ignores_reintroduced_bilingual_pair",
    text = "排程器（scheduler）會處理佇列。\n後面仍寫排程器（scheduler）。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L054 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "bare_english_drift_ignores_reintroduced_bilingual_pair")
      assert_not_contains(output, "[L054]", "bare_english_drift_ignores_reintroduced_bilingual_pair")
    end,
  },
  {
    name = "bare_english_drift_ignores_inline_code",
    text = "排程器（scheduler）會處理佇列。\n後面只在 `scheduler` 這段 code 提到。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L054 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "bare_english_drift_ignores_inline_code")
      assert_not_contains(output, "[L054]", "bare_english_drift_ignores_inline_code")
    end,
  },
  {
    name = "bare_english_drift_ignores_acronym_heavy_anchor",
    text = "單指令多資料（SIMD）會做平行運算。\n後面這裡直接寫 SIMD。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L054 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "bare_english_drift_ignores_acronym_heavy_anchor")
      assert_not_contains(output, "[L054]", "bare_english_drift_ignores_acronym_heavy_anchor")
    end,
  },
  {
    name = "repeated_bilingual_term_pair_warns",
    text = "快取（cache）\n快取（cache）\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L030 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L030]", "repeated_bilingual_term_pair_warns")
    end,
  },
  {
    name = "repeated_explanatory_parentheses_ignored",
    text = "fundamental type（除了 void）\nfundamental type（除了 void）\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L030 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "repeated_explanatory_parentheses_ignored")
      assert_not_contains(output, "[L030]", "repeated_explanatory_parentheses_ignored")
    end,
  },
  {
    name = "bilingual_term_chinese_first_warns",
    text = "### Direct Proof（直接證明）\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L046 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L046]", "bilingual_term_chinese_first_warns")
      assert_contains(output, "1 warning(s)", "bilingual_term_chinese_first_warns")
    end,
  },
  {
    name = "bilingual_term_chinese_first_allows_correct_order",
    text = "### 直接證明（Direct Proof）\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L046 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "bilingual_term_chinese_first_allows_correct_order")
      assert_not_contains(output, "[L046]", "bilingual_term_chinese_first_allows_correct_order")
    end,
  },
  {
    name = "unexpanded_workspace_jargon",
    text = "這裡主要處理術語邊界。\n下一段才開始說別的事。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L033 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L033]", "unexpanded_workspace_jargon")
    end,
  },
  {
    name = "unexpanded_workspace_jargon_baseline",
    text = "這裡主要處理 baseline。\n下一段才開始說別的事。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L033 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L033]", "unexpanded_workspace_jargon_baseline")
    end,
  },
  {
    name = "glossary_preferred_form_match",
    text = "快取（cache）\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L032 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "glossary_preferred_form_match")
      assert_not_contains(output, "[L032]", "glossary_preferred_form_match")
    end,
  },
  {
    name = "glossary_preferred_form_match_thread",
    text = "執行緒（thread）\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L032 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "glossary_preferred_form_match_thread")
      assert_not_contains(output, "[L032]", "glossary_preferred_form_match_thread")
    end,
  },
  {
    name = "glossary_preferred_form_mismatch",
    text = "緩存（cache）\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L032 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L032]", "glossary_preferred_form_mismatch")
    end,
  },
  {
    name = "project_local_glossary_override",
    path = smoke_project_root .. "/_lint_smoke_local_glossary.md",
    text = "信號量（semaphore）\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L032 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L032]", "project_local_glossary_override")
    end,
  },
  {
    name = "project_local_glossary_override_relative_path",
    path = smoke_project_root .. "/_lint_smoke_local_glossary_relative.md",
    text = "信號量（semaphore）\n",
    command = function()
      return "cd " .. shell_quote(repo_root) ..
        " && lua5.4 scripts/lint.lua --rules L032 working/_lint_smoke_project/_lint_smoke_local_glossary_relative.md"
    end,
    check = function(output)
      assert_contains(output, "[L032]", "project_local_glossary_override_relative_path")
    end,
  },
  {
    name = "glossary_term_after_copula_prefix",
    path = smoke_project_root .. "/_lint_smoke_scheduler.md",
    text = "做這個決定的是排程器（scheduler）。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L032 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "glossary_term_after_copula_prefix")
      assert_not_contains(output, "[L032]", "glossary_term_after_copula_prefix")
    end,
  },
  {
    name = "glossary_term_after_modal_prefix",
    text = "這個 SBI 呼叫會阻塞（block）。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L032 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "glossary_term_after_modal_prefix")
      assert_not_contains(output, "[L032]", "glossary_term_after_modal_prefix")
    end,
  },
  {
    name = "term_form_drift_not_triggered_by_explanatory_prefix",
    text = "## 非決定性（Non-determinism）\n\n並行程式通常具有非決定性（non-determinism）。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L031 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "term_form_drift_not_triggered_by_explanatory_prefix")
      assert_not_contains(output, "[L031]", "term_form_drift_not_triggered_by_explanatory_prefix")
    end,
  },
  {
    name = "taxonomy_only_summary",
    text = "這段主要整理規則優先序、術語邊界與工作模式，也只是抽象分類、原則與條件的摘要。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L034 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L034]", "taxonomy_only_summary")
    end,
  },
  {
    name = "taxonomy_only_summary_baseline",
    text = "這段主要整理 baseline、分類與條件，整體還停在抽象摘要。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L034 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L034]", "taxonomy_only_summary_baseline")
    end,
  },
  {
    name = "taxonomy_summary_with_anchor",
    text = "這段主要整理規則優先序與術語邊界，會更新 references/output_guide.md 的相關段落，並補一個具體例子。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L034 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "taxonomy_summary_with_anchor")
      assert_not_contains(output, "[L034]", "taxonomy_summary_with_anchor")
    end,
  },
  {
    name = "internal_control_label_leaked_into_formal_prose",
    text = "這一輪要先做受影響範圍重驗證，再處理 output contract。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L130 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L130]", "internal_control_label_leaked_into_formal_prose")
    end,
  },
  {
    name = "internal_control_label_rewritten_as_plain_sentence",
    text = "若這一輪會修改既有段落，寫入前先重新檢查這次改動波及的段落，並先確認這次最後要交付的是完整譯文還是 review 報告。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L130 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "internal_control_label_rewritten_as_plain_sentence")
      assert_not_contains(output, "[L130]", "internal_control_label_rewritten_as_plain_sentence")
    end,
  },
  {
    name = "huixie_misuse_before_writeout",
    text = "回寫前記得做自檢。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L035 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L035]", "huixie_misuse_before_writeout")
    end,
  },
  {
    name = "huixie_misuse_to_glossary",
    text = "穩定的術語決策應回寫到 project-local glossary。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L035 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L035]", "huixie_misuse_to_glossary")
    end,
  },
  {
    name = "huixie_write_back_term_allowed",
    text = "這個控制器採用回寫快取（write-back caching）。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L035 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "huixie_write_back_term_allowed")
      assert_not_contains(output, "[L035]", "huixie_write_back_term_allowed")
    end,
  },
  {
    name = "long_de_chain_dense_window",
    text = "這個流程的設定的建立的順序很重要。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L008 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L008]", "long_de_chain_dense_window")
    end,
  },
  {
    name = "long_de_chain_not_total_line_count",
    text = "同步的涵義更廣了一些，它描述的是事件之間的關係。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L008 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "long_de_chain_not_total_line_count")
      assert_not_contains(output, "[L008]", "long_de_chain_not_total_line_count")
    end,
  },
  {
    name = "paired_conjunction_incomplete",
    text = "雖然這裡列出了風險，後面沒有補對比骨架。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L125 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L125]", "paired_conjunction_incomplete")
    end,
  },
  {
    name = "paired_conjunction_complete",
    text = "雖然這裡列出了風險，但後面也補了對比骨架。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L125 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "paired_conjunction_complete")
      assert_not_contains(output, "[L125]", "paired_conjunction_complete")
    end,
  },
  {
    name = "paired_conjunction_causal_clause_allowed",
    text = "由於負載過高，系統回應變慢。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L125 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "paired_conjunction_causal_clause_allowed")
      assert_not_contains(output, "[L125]", "paired_conjunction_causal_clause_allowed")
    end,
  },
  {
    name = "paired_conjunction_causal_clause_with_suoyi_allowed",
    text = "由於負載過高，所以系統回應變慢。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L125 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "paired_conjunction_causal_clause_with_suoyi_allowed")
      assert_not_contains(output, "[L125]", "paired_conjunction_causal_clause_with_suoyi_allowed")
    end,
  },
  {
    name = "paired_conjunction_conditional_clause_allowed",
    text = "如果資料量過大，流程會阻塞。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L125 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "paired_conjunction_conditional_clause_allowed")
      assert_not_contains(output, "[L125]", "paired_conjunction_conditional_clause_allowed")
    end,
  },
  {
    name = "paired_conjunction_conditional_clause_with_jiu_allowed",
    text = "如果資料量過大，流程就會阻塞。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L125 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "paired_conjunction_conditional_clause_with_jiu_allowed")
      assert_not_contains(output, "[L125]", "paired_conjunction_conditional_clause_with_jiu_allowed")
    end,
  },
  {
    name = "imminent_event_without_sentence_final_le",
    text = "展示快要開始。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L127 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L127]", "imminent_event_without_sentence_final_le")
    end,
  },
  {
    name = "imminent_event_with_sentence_final_le",
    text = "展示快要開始了。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L127 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "imminent_event_with_sentence_final_le")
      assert_not_contains(output, "[L127]", "imminent_event_with_sentence_final_le")
    end,
  },
  {
    name = "imminent_subordinate_clause",
    text = "展示快要開始時，請先就座。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L127 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "imminent_subordinate_clause")
      assert_not_contains(output, "[L127]", "imminent_subordinate_clause")
    end,
  },
  {
    name = "completed_event_negated_with_bu",
    text = "系統不初始化了這個 buffer。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L128 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L128]", "completed_event_negated_with_bu")
    end,
  },
  {
    name = "completed_event_negated_with_mei",
    text = "系統沒有初始化這個 buffer。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L128 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "completed_event_negated_with_mei")
      assert_not_contains(output, "[L128]", "completed_event_negated_with_mei")
    end,
  },
  {
    name = "plain_bu_change_of_plan",
    text = "系統不更新了。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L128 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "plain_bu_change_of_plan")
      assert_not_contains(output, "[L128]", "plain_bu_change_of_plan")
    end,
  },
  {
    name = "you_plus_verb_generic_aspect",
    text = "系統有完成初始化。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L120 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L120]", "you_plus_verb_generic_aspect")
    end,
  },
  {
    name = "you_plus_verb_support",
    text = "這個模組有支援快取寫回。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L120 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L120]", "you_plus_verb_support")
    end,
  },
  {
    name = "you_plus_verb_inside_suoyou",
    text = "把所有更新都視為非原子的。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L120 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "you_plus_verb_inside_suoyou")
      assert_not_contains(output, "[L120]", "you_plus_verb_inside_suoyou")
    end,
  },
  {
    name = "you_possessive_sentence",
    text = "這個 queue 有 retry buffer。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L120 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "you_possessive_sentence")
      assert_not_contains(output, "[L120]", "you_possessive_sentence")
    end,
  },
  {
    name = "repeated_subject_chain",
    text = "系統會先載入設定，系統再初始化模組。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L009 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L009]", "repeated_subject_chain")
    end,
  },
  {
    name = "repeated_subject_across_sentences",
    text = "程式設計師無法控制排程。程式設計師也無法預測順序。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L009 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "repeated_subject_across_sentences")
      assert_not_contains(output, "[L009]", "repeated_subject_across_sentences")
    end,
  },
  {
    name = "passive_overuse",
    text = "模組被系統載入後，又被流程重新初始化。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L010 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L010]", "passive_overuse")
    end,
  },
  {
    name = "passive_across_sentences",
    text = "這些操作可能被中斷。這種指令不會被打斷。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L010 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "passive_across_sentences")
      assert_not_contains(output, "[L010]", "passive_across_sentences")
    end,
  },
  {
    name = "ba_without_result_state",
    text = "請把設定改。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L011 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L011]", "ba_without_result_state")
    end,
  },
  {
    name = "de_di_de_confusion",
    text = "這個流程跑的很快。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L012 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L012]", "de_di_de_confusion")
    end,
  },
  {
    name = "de_di_de_allows_zhendehen",
    text = "這個手冊真的很難讀。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L012 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "de_di_de_allows_zhendehen")
      assert_not_contains(output, "[L012]", "de_di_de_allows_zhendehen")
    end,
  },
  {
    name = "de_di_de_allows_adverbial_di_test",
    text = "這也顯示要可靠地測試 race condition 是很困難的。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L012 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "de_di_de_allows_adverbial_di_test")
      assert_not_contains(output, "[L012]", "de_di_de_allows_adverbial_di_test")
    end,
  },
  {
    name = "aspect_le_mismatch",
    text = "這個服務每天啟動了都會先載入設定。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L013 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L013]", "aspect_le_mismatch")
    end,
  },
  {
    name = "aspect_le_lexical_weile",
    text = "為了方便表達，這種簡化是可以接受的。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L013 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "aspect_le_lexical_weile")
      assert_not_contains(output, "[L013]", "aspect_le_lexical_weile")
    end,
  },
  {
    name = "aspect_le_prefix_too_far",
    text = "程式設計師通常需要關心同步約束，這個約束提出了一系列要求。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L013 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "aspect_le_prefix_too_far")
      assert_not_contains(output, "[L013]", "aspect_le_prefix_too_far")
    end,
  },
  {
    name = "nonspecific_np_fronted_as_topic",
    text = "三個 worker，會在這一輪被建立。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L101 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L101]", "nonspecific_np_fronted_as_topic")
    end,
  },
  {
    name = "temporal_count_phrase_not_topic",
    text = "幾年前，學生提出了更精簡的寫法。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L101 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "temporal_count_phrase_not_topic")
      assert_not_contains(output, "[L101]", "temporal_count_phrase_not_topic")
    end,
  },
  {
    name = "self_ziji_ambiguity",
    text = "他告訴她自己已經準備好了。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L102 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L102]", "self_ziji_ambiguity")
    end,
  },
  {
    name = "shi_you_confusion",
    text = "這個問題是有一個穩定解法。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L103 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L103]", "shi_you_confusion")
    end,
  },
  {
    name = "hai_shi_you_not_shi_you_confusion",
    text = "但還是有一些變數會被共享。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L103 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "hai_shi_you_not_shi_you_confusion")
      assert_not_contains(output, "[L103]", "hai_shi_you_not_shi_you_confusion")
    end,
  },
  {
    name = "de_nominalization_overuse",
    text = "這個流程的設定的建立需要更多時間。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L105 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L105]", "de_nominalization_overuse")
    end,
  },
  {
    name = "de_nominalization_plain_processing_way",
    text = "這樣的處理方式比較溫和。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L105 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "de_nominalization_plain_processing_way")
      assert_not_contains(output, "[L105]", "de_nominalization_plain_processing_way")
    end,
  },
  {
    name = "ba_object_lacks_clear_reference",
    text = "把一個暫存檔寫回磁碟。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L106 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L106]", "ba_object_lacks_clear_reference")
    end,
  },
  {
    name = "ba_object_indefinite_only_later_in_clause",
    text = "最後把新值寫回去的操作展示了一個案例。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L106 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "ba_object_indefinite_only_later_in_clause")
      assert_not_contains(output, "[L106]", "ba_object_indefinite_only_later_in_clause")
    end,
  },
  {
    name = "ba_clause_without_bounded_endpoint",
    text = "把設定改，避免後續錯誤。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L107 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L107]", "ba_clause_without_bounded_endpoint")
    end,
  },
  {
    name = "np_de_vp_overcompression",
    text = "資源配置的決定會影響後續排程。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L108 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L108]", "np_de_vp_overcompression")
    end,
  },
  {
    name = "np_de_vp_not_on_processing_way",
    text = "目錄的實作方式和一般檔案非常類似。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L108 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "np_de_vp_not_on_processing_way")
      assert_not_contains(output, "[L108]", "np_de_vp_not_on_processing_way")
    end,
  },
  {
    name = "shou_with_bare_event",
    text = "這個模組受到初始化流程影響。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L111 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L111]", "shou_with_bare_event")
    end,
  },
  {
    name = "you_sentence_with_definite_np",
    text = "有這個模組需要額外處理。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L112 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L112]", "you_sentence_with_definite_np")
    end,
  },
  {
    name = "descriptive_v_de_with_overt_object",
    text = "整理得資料很清楚。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L114 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L114]", "descriptive_v_de_with_overt_object")
    end,
  },
  {
    name = "overloaded_postverbal_stack",
    text = "系統整理資料三次完整輸出結果。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L115 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L115]", "overloaded_postverbal_stack")
    end,
  },
  {
    name = "local_pronoun_used_for_reflexive_meaning",
    text = "他修改他的設定檔。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L116 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L116]", "local_pronoun_used_for_reflexive_meaning")
    end,
  },
  {
    name = "ziji_in_bei_clause_dual_antecedent_ambiguity",
    text = "主程式被外掛覆寫了自己的設定檔。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L118 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L118]", "ziji_in_bei_clause_dual_antecedent_ambiguity")
    end,
  },
  {
    name = "nonagentive_subject_with_control_modal",
    text = "系統願意重新載入設定。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L121 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L121]", "nonagentive_subject_with_control_modal")
    end,
  },
  {
    name = "missing_associative_de_after_modifier",
    text = "這是一套複雜控制流程。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L122 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L122]", "missing_associative_de_after_modifier")
    end,
  },
  {
    name = "missing_adverbial_di_after_modifier",
    text = "請清楚說明這個步驟。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L123 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L123]", "missing_adverbial_di_after_modifier")
    end,
  },
  {
    name = "missing_complement_de_after_verb",
    text = "這樣比較看出來差異。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L124 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L124]", "missing_complement_de_after_verb")
    end,
  },
  {
    name = "lexical_kanchulai_allowed",
    text = "這個錯誤很容易看出來。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L124 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "lexical_kanchulai_allowed")
      assert_not_contains(output, "[L124]", "lexical_kanchulai_allowed")
    end,
  },
  {
    name = "count_phrase_after_sentence_final_le",
    text = "服務重試三次請求了。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L129 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L129]", "count_phrase_after_sentence_final_le")
    end,
  },
  {
    name = "count_phrase_before_last_clause_boundary",
    text = "如果是在同一個處理器內部，我們就無法判斷先後順序了。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L129 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "count_phrase_before_last_clause_boundary")
      assert_not_contains(output, "[L129]", "count_phrase_before_last_clause_boundary")
    end,
  },
  {
    name = "ordinal_phrase_before_sentence_final_le",
    text = "第一個問題很簡單，第二個就不簡單了。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L129 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "ordinal_phrase_before_sentence_final_le")
      assert_not_contains(output, "[L129]", "ordinal_phrase_before_sentence_final_le")
    end,
  },
  {
    name = "aspect_le_preserved_by_state_change_zhongyu",
    text = "這個服務每天終於啟動了都會先載入設定。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L013 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "aspect_le_preserved_by_state_change_zhongyu")
      assert_not_contains(output, "[L013]", "aspect_le_preserved_by_state_change_zhongyu")
    end,
  },
  {
    name = "aspect_le_preserved_by_state_change_kaishi",
    text = "程式通常開始重試了幾次之後會放棄。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L013 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "aspect_le_preserved_by_state_change_kaishi")
      assert_not_contains(output, "[L013]", "aspect_le_preserved_by_state_change_kaishi")
    end,
  },
  {
    name = "aspect_le_preserved_by_state_change_biande",
    text = "這個模組一般變得更敏感了一點。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L013 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "aspect_le_preserved_by_state_change_biande")
      assert_not_contains(output, "[L013]", "aspect_le_preserved_by_state_change_biande")
    end,
  },
  {
    name = "aspect_le_lexical_suanle",
    text = "通常算了就不再重試。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L013 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "aspect_le_lexical_suanle")
      assert_not_contains(output, "[L013]", "aspect_le_lexical_suanle")
    end,
  },
  {
    name = "aspect_le_preserved_by_state_change_cai",
    text = "這個服務每天才完成了初始化流程。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L013 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "aspect_le_preserved_by_state_change_cai")
      assert_not_contains(output, "[L013]", "aspect_le_preserved_by_state_change_cai")
    end,
  },
  {
    name = "aspect_le_preserved_by_state_change_geng",
    text = "這個模組通常更敏感了一些。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L013 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "aspect_le_preserved_by_state_change_geng")
      assert_not_contains(output, "[L013]", "aspect_le_preserved_by_state_change_geng")
    end,
  },
  {
    name = "aspect_le_lexical_dele",
    text = "通常得了重感冒就休息。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L013 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "aspect_le_lexical_dele")
      assert_not_contains(output, "[L013]", "aspect_le_lexical_dele")
    end,
  },
  {
    name = "citation_inline_code_example_not_flagged",
    text = "本規範的 citation 語法為 `<sup>[[2]](#2)</sup>`，放在文末。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L015 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "citation_inline_code_example_not_flagged")
      assert_not_contains(output, "[L015]", "citation_inline_code_example_not_flagged")
    end,
  },
  {
    name = "citation_code_fence_example_not_flagged",
    text = "```markdown\n<sup>[[1]](#1)</sup>\n```\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L015 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "citation_code_fence_example_not_flagged")
      assert_not_contains(output, "[L015]", "citation_code_fence_example_not_flagged")
    end,
  },
  {
    name = "citation_missing_reference_section_warns",
    text = "看這裡<sup>[[1]](#1)</sup>。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L015 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L015]", "citation_missing_reference_section_warns")
    end,
  },
  {
    name = "citation_id_display_mismatch_warns",
    text = "看這裡<sup>[[1]](#1)</sup>。\n\n## 引用文獻\n\n- <a id=\"2\">[1]</a>: ref\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L016 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L016]", "citation_id_display_mismatch_warns")
    end,
  },
  {
    name = "citation_duplicate_anchor_warns",
    text = "看這裡<sup>[[1]](#1)</sup>。\n\n## 引用文獻\n\n- <a id=\"1\">[1]</a>: first\n- <a id=\"1\">[1]</a>: duplicate\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L016 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L016]", "citation_duplicate_anchor_warns")
    end,
  },
  {
    name = "citation_well_formed_not_flagged",
    text = "看這裡<sup>[[1]](#1)</sup>。\n\n## 引用文獻\n\n- <a id=\"1\">[1]</a>: ref\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L015,L016 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "0 warning(s)", "citation_well_formed_not_flagged")
      assert_not_contains(output, "[L015]", "citation_well_formed_not_flagged")
      assert_not_contains(output, "[L016]", "citation_well_formed_not_flagged")
    end,
  },
  {
    name = "exclude_removes_rule_from_base",
    text = "## 開工前檢查\n\n測試段落。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --exclude L017 " .. shell_quote(path)
    end,
    check = function(output)
      assert_not_contains(output, "[L017]", "exclude_removes_rule_from_base")
    end,
  },
  {
    name = "profile_spec_excludes_l017",
    text = "## 開工前檢查\n\n測試段落。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --profile spec " .. shell_quote(path)
    end,
    check = function(output)
      assert_not_contains(output, "[L017]", "profile_spec_excludes_l017")
    end,
  },
  {
    name = "profile_glossary_excludes_l044",
    text = "| 英文 | 臺灣用語 |\n| --- | --- |\n| Address (n.) | 位址 |\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --profile glossary " .. shell_quote(path)
    end,
    check = function(output)
      assert_not_contains(output, "[L044]", "profile_glossary_excludes_l044")
    end,
  },
  {
    name = "unknown_profile_errors",
    text = "段落。\n",
    expect_failure = true,
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --profile bogus " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "unknown profile", "unknown_profile_errors")
    end,
  },
  {
    name = "unknown_exclude_id_errors",
    text = "段落。\n",
    expect_failure = true,
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --exclude L9999 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "unknown lint id", "unknown_exclude_id_errors")
    end,
  },
  {
    name = "l002_is_lint_hybrid",
    text = "段落。\n",
    command = function(_)
      return "lua5.4 " .. shell_quote(lint_script) .. " --list-rules"
    end,
    check = function(output)
      assert_contains(output, "L002\tlint-hybrid", "l002_is_lint_hybrid")
    end,
  },
  {
    name = "l009_ignores_single_char_pronoun",
    text = "它執行了任務，它也回報了結果。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L009 " .. shell_quote(path)
    end,
    check = function(output)
      assert_not_contains(output, "[L009]", "l009_ignores_single_char_pronoun")
    end,
  },
  {
    name = "l044_skips_table_row",
    text = "| 英文 | 臺灣用語 |\n| --- | --- |\n| Address (n.) | 位址 |\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L044 " .. shell_quote(path)
    end,
    check = function(output)
      assert_not_contains(output, "[L044]", "l044_skips_table_row")
    end,
  },
  {
    name = "l045_skips_table_row",
    text = "| 英文 | 臺灣用語 |\n| --- | --- |\n| Address （n.） | 位址 |\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L045 " .. shell_quote(path)
    end,
    check = function(output)
      assert_not_contains(output, "[L045]", "l045_skips_table_row")
    end,
  },
  {
    name = "l044_still_fires_in_prose",
    text = "這個欄位 (optional) 可以留空。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L044 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L044]", "l044_still_fires_in_prose")
    end,
  },
  {
    name = "l007_detects_bei_zuzhi_cheng",
    text = "這份文件被組織成三個章節。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L007 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L007]", "l007_detects_bei_zuzhi_cheng")
    end,
  },
  {
    name = "l007_detects_kebei_suo",
    text = "這個欄位可被上游所覆寫。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L007 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L007]", "l007_detects_kebei_suo")
    end,
  },
  {
    name = "l007_detects_wenxianzhong_beitichu",
    text = "這個想法在文獻中被提出。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L007 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L007]", "l007_detects_wenxianzhong_beitichu")
    end,
  },
  {
    name = "l022_covers_heading",
    text = "# 这是标题\n\n正文段落。\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L022 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L022]", "l022_covers_heading")
    end,
  },
  {
    name = "l022_covers_list_item",
    text = "段落。\n\n- 这个条目使用简体字\n",
    command = function(path)
      return "lua5.4 " .. shell_quote(lint_script) .. " --rules L022 " .. shell_quote(path)
    end,
    check = function(output)
      assert_contains(output, "[L022]", "l022_covers_list_item")
    end,
  },
}

write_temp(smoke_glossary, smoke_glossary_path)

for _, case in ipairs(cases) do
  local temp_path = write_temp(case.text, case.path)
  local ok, output = run_command(case.command(temp_path))
  os.remove(temp_path)
  if case.expect_failure then
    if ok then
      die(case.name .. ": expected command to fail but it succeeded\n" .. output)
    end
  elseif not ok then
    die(case.name .. ": command failed\n" .. output)
  end
  case.check(output)
end

os.remove(smoke_glossary_path)
os.execute("rmdir " .. shell_quote(smoke_project_root) .. " >/dev/null 2>&1")

local function split_markdown_row(row)
  local inner = trim(row)
  if inner:sub(1, 1) == "|" then
    inner = inner:sub(2)
  end
  if inner:sub(-1) == "|" then
    inner = inner:sub(1, -2)
  end

  local cells = {}
  for cell in (inner .. "|"):gmatch("(.-)|") do
    cells[#cells + 1] = trim(cell)
  end
  return cells
end

local function is_separator_row(cells)
  if #cells == 0 then
    return false
  end
  for _, cell in ipairs(cells) do
    if not cell:match("^:?-+:?$") then
      return false
    end
  end
  return true
end

local function collect_preferred_taiwan_terms(path)
  local text = read_file(path)
  local terms = {}
  local seen = {}

  for line in text:gmatch("[^\n]+") do
    local stripped = trim(line)
    if stripped:match("^|") then
      local cells = split_markdown_row(stripped)
      local is_header = #cells >= 2 and cells[1] == "避免用語" and cells[2] == "建議用語"
      local owned_by_l053 = #cells >= 4 and cells[4]:find("L053", 1, true) ~= nil
      if not is_header and not is_separator_row(cells) and owned_by_l053 and #cells >= 1 then
        for term in cells[1]:gmatch("`([^`]+)`") do
          if not seen[term] then
            seen[term] = true
            terms[#terms + 1] = term
          end
        end
      end
    end
  end
  return terms
end

local function collect_preferred_terms(path)
  local text = read_file(path)
  local terms = {}
  local block_start = text:find("PREFERRED_TAIWAN_TERMS", 1, true)
  if block_start then
    local block = text:sub(block_start)
    local block_end = block:find("\n}", 1, true)
    if block_end then
      block = block:sub(1, block_end)
    end
    for term in block:gmatch('term%s*=%s*"([^"]+)"') do
      terms[term] = true
    end
  end
  return terms
end

local preferred_terms_path = repo_root .. "/references/preferred_taiwan_terms.md"
local rules_path = repo_root .. "/scripts/lintlib/rules.lua"
local glossary_terms = collect_preferred_taiwan_terms(preferred_terms_path)
local preferred_terms = collect_preferred_terms(rules_path)

local missing = {}
for _, term in ipairs(glossary_terms) do
  if not preferred_terms[term] then
    table.insert(missing, term)
  end
end

if #missing > 0 then
  io.stderr:write(
    "preferred_taiwan_terms_drift: preferred_taiwan_terms.md 中由 L053 檢查的「避免用語」條目在 PREFERRED_TAIWAN_TERMS 缺項：" ..
    table.concat(missing, ", ") ..
    "\n"
  )
  os.exit(1)
end

io.write("lint smoke tests passed\n")
