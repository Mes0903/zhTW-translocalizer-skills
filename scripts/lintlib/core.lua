local M = {}

local LEFT_PAREN = "（"
local RIGHT_PAREN = "）"
local TERM_BOUNDARY_CHARS = {
  [","] = true,
  ["."] = true,
  [";"] = true,
  [":"] = true,
  ["!"] = true,
  ["?"] = true,
  ["，"] = true,
  ["。"] = true,
  ["；"] = true,
  ["："] = true,
  ["！"] = true,
  ["？"] = true,
  ["「"] = true,
  ["」"] = true,
  ["『"] = true,
  ["』"] = true,
  ["（"] = true,
  ["）"] = true,
  ["("] = true,
  [")"] = true,
  ["["] = true,
  ["]"] = true,
  ["{"] = true,
  ["}"] = true,
  ["<"] = true,
  [">"] = true,
  ['"'] = true,
  ["'"] = true,
}

function M.read_file(path)
  local handle, err = io.open(path, "rb")
  if not handle then
    error("failed to open " .. path .. ": " .. tostring(err))
  end

  local text = handle:read("*a")
  handle:close()
  return text
end

function M.file_exists(path)
  local handle = io.open(path, "rb")
  if not handle then
    return false
  end
  handle:close()
  return true
end

function M.trim(text)
  return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

function M.split_csv(text)
  local values = {}
  for chunk in tostring(text):gmatch("([^,]+)") do
    local trimmed = M.trim(chunk)
    if trimmed ~= "" then
      table.insert(values, trimmed)
    end
  end
  return values
end

function M.make_set(values)
  local set = {}
  for _, value in ipairs(values) do
    set[value] = true
  end
  return set
end

function M.count_substring(text, needle)
  local count = 0
  local start = 1
  while true do
    local first = text:find(needle, start, true)
    if not first then
      break
    end
    count = count + 1
    start = first + #needle
  end
  return count
end

function M.contains_ascii_letter(text)
  return text:find("%a") ~= nil
end

function M.contains_non_ascii(text)
  return text:find("[\128-\255]") ~= nil
end

function M.is_cjk(cp)
  return
    (cp >= 0x3400 and cp <= 0x4DBF) or
    (cp >= 0x4E00 and cp <= 0x9FFF) or
    (cp >= 0xF900 and cp <= 0xFAFF)
end

function M.codepoints(text)
  local values = {}
  for pos, cp in utf8.codes(text) do
    table.insert(values, {
      pos = pos,
      cp = cp,
      char = utf8.char(cp),
    })
  end
  return values
end

function M.contains_cjk(text)
  for _, item in ipairs(M.codepoints(text)) do
    if M.is_cjk(item.cp) then
      return true
    end
  end
  return false
end

function M.visible_length(text)
  local count = 0
  for _, item in ipairs(M.codepoints(text)) do
    local char = item.char
    if not char:match("%s") then
      count = count + 1
    end
  end
  return count
end

function M.mask_inline_code(text)
  return (text:gsub("`[^`\n]-`", function(segment)
    return string.rep(" ", #segment)
  end))
end

function M.escape_pattern(text)
  return (text:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1"))
end

function M.normalize_english_term(text)
  local normalized = M.trim(tostring(text or "")):lower()
  normalized = normalized:gsub("（[^）]-）", "")
  normalized = normalized:gsub("%b()", "")
  normalized = normalized:gsub("%s+", " ")
  return M.trim(normalized)
end

function M.normalize_chinese_term(text)
  local normalized = M.trim(tostring(text or ""))
  normalized = normalized:gsub("%s+", "")
  normalized = normalized:gsub("^[、，；：]+", "")
  normalized = normalized:gsub("^和", "")
  normalized = normalized:gsub("^與", "")
  normalized = normalized:gsub("^及", "")
  return normalized
end

function M.first_nonspace_col(text)
  local first = text:find("%S")
  return first or 1
end

function M.byte_to_char_col(text, byte_col)
  local source = tostring(text or "")
  local target = math.floor(tonumber(byte_col) or 1)

  if target <= 1 then
    return 1
  end

  local after_end = #source + 1
  if target > after_end then
    target = after_end
  end

  local char_col = 1
  for pos, _ in utf8.codes(source) do
    if pos >= target then
      return char_col
    end
    char_col = char_col + 1
  end

  return char_col
end

function M.is_sentence_like(text)
  local trimmed = M.trim(text)
  if trimmed == "" then
    return false
  end

  if trimmed:find("[。！？；：%.%!%?]$") then
    return true
  end

  return trimmed:find("：$") ~= nil
end

function M.last_nonspace_codepoint(codepoints)
  for index = #codepoints, 1, -1 do
    if not codepoints[index].char:match("%s") then
      return codepoints[index]
    end
  end
  return nil
end

function M.previous_nonspace(codepoints, index)
  for cursor = index - 1, 1, -1 do
    if not codepoints[cursor].char:match("%s") then
      return codepoints[cursor]
    end
  end
  return nil
end

function M.next_nonspace(codepoints, index)
  for cursor = index + 1, #codepoints do
    if not codepoints[cursor].char:match("%s") then
      return codepoints[cursor]
    end
  end
  return nil
end

local function is_code_fence_start(stripped)
  return stripped:match("^([`~][`~][`~]+)")
end

local function is_code_fence_end(stripped, fence_char, fence_len)
  local run = stripped:match("^(" .. fence_char .. "+)")
  return run and #run >= fence_len
end

local function count_pipes(text)
  local _, count = text:gsub("|", "")
  return count
end

local function is_html_like_tag(stripped)
  return stripped:match("^</?[%a][%w%-]*[^>]*>$") ~= nil
end

local function is_directive_marker(stripped)
  return stripped:match("^:::+") ~= nil
end

local function classify_lines(text)
  local lines = {}
  local byte_offset = 1
  local in_code_fence = false
  local fence_char = nil
  local fence_len = 0
  local in_frontmatter = false
  local frontmatter_pending = false
  local in_math_block = false

  for raw_line in (text .. "\n"):gmatch("(.-)\n") do
    local stripped = M.trim(raw_line)
    local leading_ws = raw_line:match("^(%s*)") or ""
    if #lines == 0 and stripped == "---" then
      frontmatter_pending = true
    end
    local line = {
      number = #lines + 1,
      text = raw_line,
      masked_text = M.mask_inline_code(raw_line),
      stripped = stripped,
      start_byte = byte_offset,
      end_byte = byte_offset + #raw_line - 1,
      is_blank = stripped == "",
      is_code = false,
      is_fence = false,
      is_heading = false,
      is_list = false,
      list_indent = #leading_ws,
      is_table = false,
      is_blockquote = false,
      is_tag = false,
      is_frontmatter = false,
      is_directive = false,
      is_math = false,
    }

    if frontmatter_pending or in_frontmatter then
      line.is_frontmatter = true
      line.is_code = true
      if frontmatter_pending then
        in_frontmatter = true
        frontmatter_pending = false
      elseif stripped == "---" then
        in_frontmatter = false
      end
    elseif not in_code_fence then
      local opener = is_code_fence_start(stripped)
      if opener then
        line.is_code = true
        line.is_fence = true
        in_code_fence = true
        fence_char = opener:sub(1, 1)
        fence_len = #opener
      elseif in_math_block then
        line.is_math = true
        line.is_code = true
        if stripped == "$$" then
          in_math_block = false
        end
      elseif stripped == "$$" then
        line.is_math = true
        line.is_code = true
        in_math_block = true
      elseif is_directive_marker(stripped) then
        line.is_directive = true
      elseif is_html_like_tag(stripped) then
        line.is_tag = true
      else
        line.is_heading = stripped:match("^#+%s+") ~= nil
        line.is_blockquote = stripped:match("^>%s*") ~= nil
        line.is_list = stripped:match("^[-*+]%s+") ~= nil or stripped:match("^%d+%.%s+") ~= nil
        line.is_table =
          count_pipes(raw_line) >= 2 or
          stripped:match("^|?%s*:?-+:?%s*(|%s*:?-+:?%s*)+|?$") ~= nil
      end
    else
      line.is_code = true
      if is_code_fence_end(stripped, fence_char, fence_len) then
        line.is_fence = true
        in_code_fence = false
        fence_char = nil
        fence_len = 0
      end
    end

    table.insert(lines, line)
    byte_offset = byte_offset + #raw_line + 1
  end

  return lines
end

local function build_paragraphs(lines)
  local paragraphs = {}
  local current = {}

  local function flush()
    if #current == 0 then
      return
    end

    local texts = {}
    for _, line in ipairs(current) do
      table.insert(texts, line.text)
    end

    local text = table.concat(texts, "\n")
    table.insert(paragraphs, {
      start_line = current[1].number,
      end_line = current[#current].number,
      lines = current,
      line_count = #current,
      text = text,
      visible_length = M.visible_length(text),
    })

    current = {}
  end

  for _, line in ipairs(lines) do
    if
      line.is_blank or
      line.is_code or
      line.is_tag or
      line.is_directive or
      line.is_list or
      line.is_heading or
      line.is_table or
      line.is_blockquote
    then
      flush()
    else
      table.insert(current, line)
    end
  end

  flush()
  return paragraphs
end

local function build_prose_text(lines)
  local fragments = {}
  for _, line in ipairs(lines) do
    if not line.is_code then
      table.insert(fragments, line.masked_text)
    else
      table.insert(fragments, "")
    end
  end
  return table.concat(fragments, "\n")
end

function M.build_document(path, text)
  local lines = classify_lines(text)
  local paragraphs = build_paragraphs(lines)
  return {
    path = path,
    text = text,
    prose_text = build_prose_text(lines),
    lines = lines,
    paragraphs = paragraphs,
    first_paragraph = paragraphs[1],
  }
end

local function split_markdown_row(text)
  local row = M.trim(text)
  if row:sub(1, 1) == "|" then
    row = row:sub(2)
  end
  if row:sub(-1) == "|" then
    row = row:sub(1, -2)
  end

  local cells = {}
  for cell in (row .. "|"):gmatch("(.-)|") do
    table.insert(cells, M.trim(cell))
  end
  return cells
end

local function is_separator_row(cells)
  if #cells == 0 then
    return false
  end

  for _, cell in ipairs(cells) do
    if cell == "" or not cell:match("^:?-+:?$") then
      return false
    end
  end

  return true
end

local function append_unique(values, seen, value)
  if value ~= "" and not seen[value] then
    seen[value] = true
    table.insert(values, value)
  end
end

local function expand_optional_parentheses(text, values, seen)
  local open_pos = text:find(LEFT_PAREN, 1, true)
  if not open_pos then
    append_unique(values, seen, text)
    return
  end

  local close_pos = text:find(RIGHT_PAREN, open_pos + #LEFT_PAREN, true)
  if not close_pos then
    append_unique(values, seen, text)
    return
  end

  local prefix = text:sub(1, open_pos - 1)
  local inner = text:sub(open_pos + #LEFT_PAREN, close_pos - 1)
  local suffix = text:sub(close_pos + #RIGHT_PAREN)

  expand_optional_parentheses(prefix .. suffix, values, seen)
  expand_optional_parentheses(prefix .. inner .. suffix, values, seen)
end

local function parse_english_variants(text)
  local cleaned = tostring(text or ""):gsub("（[^）]-）", ""):gsub("%b()", "")
  local raw_variants = {}
  if cleaned:find("%s/%s") then
    for chunk in cleaned:gmatch("([^/]+)") do
      local variant = M.normalize_english_term(chunk)
      if variant ~= "" then
        table.insert(raw_variants, variant)
      end
    end
  else
    local normalized = M.normalize_english_term(cleaned)
    if normalized ~= "" then
      table.insert(raw_variants, normalized)
    end
  end
  return raw_variants
end

local function parse_chinese_variants(text)
  local raw = M.trim(tostring(text or ""))
  if raw == "" then
    return {}
  end

  local pieces = {}
  local normalized_separators = raw:gsub("、", "|"):gsub("，", "|"):gsub(",", "|")
  if normalized_separators:find("|", 1, true) then
    for chunk in normalized_separators:gmatch("([^|]+)") do
      local variant = M.trim(chunk)
      if variant ~= "" then
        table.insert(pieces, variant)
      end
    end
  else
    table.insert(pieces, raw)
  end

  local variants = {}
  local seen = {}
  for _, piece in ipairs(pieces) do
    local expanded = {}
    expand_optional_parentheses(piece, expanded, {})
    for _, candidate in ipairs(expanded) do
      local normalized = M.normalize_chinese_term(candidate)
      append_unique(variants, seen, normalized)
    end
  end

  return variants
end

local function copy_glossary_entries(entries)
  local copied = {}
  for english, entry in pairs(entries or {}) do
    local clone = {
      preferred_terms = {},
      preferred_set = {},
    }
    for _, term in ipairs(entry.preferred_terms or {}) do
      table.insert(clone.preferred_terms, term)
      clone.preferred_set[term] = true
    end
    copied[english] = clone
  end
  return copied
end

function M.parse_glossary_file(path)
  local entries = {}
  if not M.file_exists(path) then
    return entries
  end

  local text = M.read_file(path)
  for raw_line in (text .. "\n"):gmatch("(.-)\n") do
    local stripped = M.trim(raw_line)
    if stripped:match("^|") then
      local cells = split_markdown_row(stripped)
      if #cells >= 2 and not is_separator_row(cells) then
        local is_header =
          M.normalize_chinese_term(cells[1]) == "英文" and
          M.normalize_chinese_term(cells[2]) == "臺灣用語"

        if not is_header then
          local english_terms = parse_english_variants(cells[1])
          local chinese_terms = parse_chinese_variants(cells[2])
          for _, english in ipairs(english_terms) do
            local entry = entries[english]
            if not entry then
              entry = {
                preferred_terms = {},
                preferred_set = {},
              }
              entries[english] = entry
            end
            for _, chinese in ipairs(chinese_terms) do
              if not entry.preferred_set[chinese] then
                table.insert(entry.preferred_terms, chinese)
                entry.preferred_set[chinese] = true
              end
            end
          end
        end
      end
    end
  end

  return entries
end

function M.merge_glossary_entries(base_entries, override_entries)
  local merged = copy_glossary_entries(base_entries)
  for english, entry in pairs(override_entries or {}) do
    merged[english] = copy_glossary_entries({ [english] = entry })[english]
  end
  return merged
end

local function infer_project_root(path)
  local raw_path = tostring(path or "")
  local project_root = raw_path:match("^(.-/working/[^/]+)/")
  if project_root then
    return project_root
  end
  return raw_path:match("^%.?/?(working/[^/]+)/")
end

function M.load_glossary_context(path, repo_root)
  local glossary = {}

  if repo_root then
    glossary = M.merge_glossary_entries(glossary, M.parse_glossary_file(repo_root .. "/references/glossary.md"))
  end

  local project_root = infer_project_root(path)
  if project_root then
    for _, filename in ipairs({ "glossary.md", "termbase.md" }) do
      glossary = M.merge_glossary_entries(glossary, M.parse_glossary_file(project_root .. "/" .. filename))
    end
  end

  return glossary
end

local function extract_outer_term(text)
  local trimmed = M.trim(text)
  local ascii = trimmed:match("([%a][%w%-%._/ ]-)$")
  if ascii and ascii ~= "" then
    return M.trim(ascii)
  end

  local trailing = {}
  local codepoints = M.codepoints(trimmed)
  for index = #codepoints, 1, -1 do
    local char = codepoints[index].char
    if char:match("%s") or TERM_BOUNDARY_CHARS[char] then
      break
    end
    table.insert(trailing, 1, char)
  end

  local candidate = M.trim(table.concat(trailing))
  local markers = {
    "也就是",
    "就是",
    "則是",
    "叫做",
    "稱作",
    "稱為",
    "具有",
    "屬於",
    "是",
    "為",
  }

  for _, marker in ipairs(markers) do
    local search_from = 1
    while true do
      local found = candidate:find(marker, search_from, true)
      if not found then
        break
      end

      local before = M.trim(candidate:sub(1, found - 1))
      local after = M.trim(candidate:sub(found + #marker))
      if M.visible_length(before) >= 2 and M.visible_length(after) >= 2 then
        candidate = after
        search_from = 1
      else
        search_from = found + #marker
      end
    end
  end

  for _, marker in ipairs({ "也就是", "就是", "則是", "是", "為" }) do
    if candidate:find(marker, 1, true) == 1 then
      local after = M.trim(candidate:sub(#marker + 1))
      if M.visible_length(after) >= 2 then
        candidate = after
      end
      break
    end
  end

  if M.visible_length(candidate) >= 3 then
    candidate = candidate:gsub("的$", "")
  end

  return M.trim(candidate)
end

local function encode_json_string(text)
  local replacements = {
    ['\\'] = '\\\\',
    ['"'] = '\\"',
    ['\b'] = '\\b',
    ['\f'] = '\\f',
    ['\n'] = '\\n',
    ['\r'] = '\\r',
    ['\t'] = '\\t',
  }

  return '"' .. text:gsub('[\\\"\b\f\n\r\t]', replacements) .. '"'
end

local function is_array(value)
  local count = 0
  for key in pairs(value) do
    if type(key) ~= "number" then
      return false
    end
    count = count + 1
  end

  for index = 1, count do
    if value[index] == nil then
      return false
    end
  end

  return true
end

function M.json_encode(value)
  local value_type = type(value)
  if value_type == "nil" then
    return "null"
  end
  if value_type == "boolean" then
    return value and "true" or "false"
  end
  if value_type == "number" then
    return tostring(value)
  end
  if value_type == "string" then
    return encode_json_string(value)
  end
  if value_type ~= "table" then
    error("unsupported json type: " .. value_type)
  end

  if is_array(value) then
    local items = {}
    for _, item in ipairs(value) do
      table.insert(items, M.json_encode(item))
    end
    return "[" .. table.concat(items, ",") .. "]"
  end

  local keys = {}
  for key in pairs(value) do
    table.insert(keys, key)
  end
  table.sort(keys)

  local fields = {}
  for _, key in ipairs(keys) do
    table.insert(fields, encode_json_string(tostring(key)) .. ":" .. M.json_encode(value[key]))
  end
  return "{" .. table.concat(fields, ",") .. "}"
end

function M.extract_bilingual_pairs(text)
  local pairs = {}
  local search_from = 1

  while true do
    local open_pos = text:find(LEFT_PAREN, search_from, true)
    if not open_pos then
      break
    end

    local close_pos = text:find(RIGHT_PAREN, open_pos + #LEFT_PAREN, true)
    if not close_pos then
      break
    end

    local inner = M.trim(text:sub(open_pos + #LEFT_PAREN, close_pos - 1))
    local left = M.trim(text:sub(1, open_pos - 1))
    local outer = extract_outer_term(left)

    if outer ~= "" and inner ~= "" then
      local outer_ascii = M.contains_ascii_letter(outer)
      local inner_ascii = M.contains_ascii_letter(inner)
      local outer_non_ascii = M.contains_non_ascii(outer)
      local inner_non_ascii = M.contains_non_ascii(inner)

      if (outer_ascii and inner_non_ascii) or (inner_ascii and outer_non_ascii) then
        local english = outer_ascii and outer or inner
        local chinese = outer_ascii and inner or outer
        table.insert(pairs, {
          key = outer .. LEFT_PAREN .. inner .. RIGHT_PAREN,
          outer = outer,
          inner = inner,
          english = english,
          chinese = chinese,
          col = open_pos,
        })
      end
    end

    search_from = close_pos + #RIGHT_PAREN
  end

  return pairs
end

return M
