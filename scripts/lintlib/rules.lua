local core = require("lintlib.core")

local M = {}

local SIMPLIFIED_ONLY_CHARACTERS = {
  "与", "为", "术", "体", "处", "发", "这", "来", "说", "对",
  "会", "开", "关", "实", "现", "统", "计", "习", "问", "题",
  "变", "则", "应", "当", "从", "无", "让", "经", "过", "还",
  "线", "气", "义", "单", "书", "写", "标", "类", "没", "吗",
  "门", "电", "数", "样", "别", "观", "图", "两", "产",
}

local function build_simplified_set()
  local set = {}
  for _, char in ipairs(SIMPLIFIED_ONLY_CHARACTERS) do
    set[utf8.codepoint(char)] = true
  end
  return set
end

SIMPLIFIED_CHARS = build_simplified_set()

local is_reference_heading_line
local bibliography_url_subbullet_is_pure_url

local function add_issue(issues, document, rule, line, col, message)
  local line_text = ""
  if document.lines and document.lines[line] then
    line_text = document.lines[line].text or ""
  end

  table.insert(issues, {
    path = document.path,
    lint_id = rule.id,
    line = line,
    col = core.byte_to_char_col(line_text, col or 1),
    message = message or rule.warning_message,
    severity = "warning",
  })
end

local function add_file_issue(issues, document, rule, message)
  add_issue(issues, document, rule, 1, 1, message)
end

local function prose_lines(document)
  local lines = {}
  local in_references = false

  for _, line in ipairs(document.lines) do
    if is_reference_heading_line and is_reference_heading_line(line) then
      in_references = true
    elseif line.is_heading and in_references then
      in_references = false
    end

    local is_reference_explanation = false
    if
      in_references and
      line.is_list and
      not line.is_code and
      not line.is_tag and
      not line.is_table and
      not line.is_blockquote
    then
      local subbody = line.text:match("^%s%s+%-%s+(.+)$")
      if
        subbody and
        bibliography_url_subbullet_is_pure_url and
        not bibliography_url_subbullet_is_pure_url(subbody) and
        core.contains_cjk(line.masked_text or subbody)
      then
        is_reference_explanation = true
      end
    end

    if
      is_reference_explanation or
      (
        not line.is_blank and
        not line.is_code and
        not line.is_tag and
        not line.is_heading and
        not line.is_list and
        not line.is_table and
        not line.is_blockquote
      )
    then
      table.insert(lines, line)
    end
  end
  return lines
end

local function is_markdown_image_line(line)
  local stripped = line.stripped or core.trim(line.text or "")
  return stripped:match("^!%[") ~= nil
end

local function is_top_level_code_fence(line)
  return line.is_fence and line.list_indent == 0
end

local function parse_custom_container_marker(text)
  local indent, marker, rest = text:match("^(%s*)(:::+)(.*)$")
  if not marker then
    return nil
  end

  local trimmed_rest = core.trim(rest)
  local label = nil
  local label_tail = ""
  if trimmed_rest ~= "" then
    label = trimmed_rest:match("^([%w_%-]+)")
    if label then
      label_tail = trimmed_rest:sub(#label + 1)
      local lowercase_label, attached_title = label:match("^([a-z][a-z0-9_%-]*)([A-Z].*)$")
      if lowercase_label and attached_title then
        label = lowercase_label
        label_tail = attached_title .. label_tail
      end
    else
      label_tail = trimmed_rest
    end
  end

  return {
    indent = indent,
    marker = marker,
    marker_len = #marker,
    rest = rest,
    trimmed_rest = trimmed_rest,
    label = label,
    label_tail = label_tail,
    has_space_after_marker = rest:match("^%s+%S") ~= nil,
    is_closing = trimmed_rest == "",
  }
end

local function is_top_level_custom_container_marker(info)
  return info and #info.indent == 0
end

local function is_custom_container_opening_line(line)
  if not line then
    return false
  end
  local info = parse_custom_container_marker(line.text)
  return info ~= nil and not info.is_closing
end

local function is_custom_container_closing_line(line)
  if not line then
    return false
  end
  local info = parse_custom_container_marker(line.text)
  return info ~= nil and info.is_closing
end

local SENTENCE_SPACING_PUNCTUATION = {
  ["。"] = true,
  ["？"] = true,
  ["；"] = true,
}

local SENTENCE_SPACING_CLOSERS = {
  ["」"] = true,
  ["』"] = true,
  ["）"] = true,
  [")"] = true,
  ["】"] = true,
  ["]"] = true,
  ["》"] = true,
  ["〉"] = true,
  ['"'] = true,
  ["'"] = true,
}

local SENTENCE_SPACING_FOLLOWING_PUNCTUATION = {
  ["，"] = true,
  ["、"] = true,
  ["。"] = true,
  ["；"] = true,
  ["："] = true,
  ["！"] = true,
  ["？"] = true,
}

local TITLE_MARK_OPENERS = {
  ["《"] = true,
  ["〈"] = true,
}

local TITLE_MARK_CLOSERS = {
  ["》"] = true,
  ["〉"] = true,
}

local FULLWIDTH_QUOTE_OPENERS = {
  ["「"] = true,
  ["『"] = true,
}

local FULLWIDTH_QUOTE_CLOSERS = {
  ["」"] = true,
  ["』"] = true,
}

local TERMINAL_CONTINUATION_PUNCTUATION = {
  ["，"] = true,
  ["、"] = true,
  ["；"] = true,
  [","] = true,
  [";"] = true,
}

local TERMINAL_PUNCTUATION_CLOSERS = {
  ["」"] = true,
  ["』"] = true,
  ["”"] = true,
  ["’"] = true,
  ["）"] = true,
  [")"] = true,
  ["】"] = true,
  ["]"] = true,
  ["》"] = true,
  ["〉"] = true,
}

local function punctuation_spacing_lines(document)
  local lines = {}
  for _, line in ipairs(document.lines) do
    if
      not line.is_blank and
      not line.is_code and
      not line.is_tag and
      not line.is_directive and
      not line.is_heading and
      not line.is_table and
      not line.is_blockquote
    then
      table.insert(lines, line)
    end
  end
  return lines
end

local function bilingual_order_lines(document)
  local lines = {}
  for _, line in ipairs(document.lines) do
    if
      not line.is_blank and
      not line.is_code and
      not line.is_tag and
      not line.is_directive and
      not line.is_table
    then
      table.insert(lines, line)
    end
  end
  return lines
end

local function visible_text_lines(document)
  local lines = {}
  for _, line in ipairs(document.lines) do
    if
      not line.is_blank and
      not line.is_code and
      not line.is_tag and
      not line.is_directive
    then
      table.insert(lines, line)
    end
  end
  return lines
end

local function is_unmasked_char(line, item)
  return line.masked_text:sub(item.pos, item.pos + #item.char - 1) == item.char
end

local function is_original_char(line, item)
  return line.text:sub(item.pos, item.pos + #item.char - 1) == item.char
end

local function is_halfwidth_space_item(item)
  return item and (item.char == " " or item.char == "\t")
end

local function is_ascii_letter(cp)
  return (cp >= string.byte("A") and cp <= string.byte("Z")) or
    (cp >= string.byte("a") and cp <= string.byte("z"))
end

local function is_ascii_digit(cp)
  return cp >= string.byte("0") and cp <= string.byte("9")
end

local function is_ascii_alnum(cp)
  return is_ascii_letter(cp) or is_ascii_digit(cp)
end

local function is_ascii_token_char(item)
  if not item or item.cp > 0x7f then
    return false
  end
  if is_ascii_alnum(item.cp) then
    return true
  end
  return item.char == "." or
    item.char == "_" or
    item.char == "-" or
    item.char == "/" or
    item.char == "\\" or
    item.char == ":" or
    item.char == "+" or
    item.char == "#" or
    item.char == "@" or
    item.char == "%"
end

local function ascii_token_at(codepoints, index)
  local start_index = index
  local end_index = index

  while start_index > 1 and is_ascii_token_char(codepoints[start_index - 1]) do
    start_index = start_index - 1
  end

  while end_index < #codepoints and is_ascii_token_char(codepoints[end_index + 1]) do
    end_index = end_index + 1
  end

  local parts = {}
  for cursor = start_index, end_index do
    table.insert(parts, codepoints[cursor].char)
  end

  return start_index, end_index, table.concat(parts)
end

local function is_codeish_ascii_token(token)
  return token:find("://", 1, true) ~= nil or
    token:find("/", 1, true) ~= nil or
    token:find("\\", 1, true) ~= nil or
    token:find("@", 1, true) ~= nil or
    token:find("_", 1, true) ~= nil or
    token:find("::", 1, true) ~= nil
end

local function token_has_ascii_alnum(token)
  return token:find("[%w]") ~= nil
end

local function should_skip_cjk_ascii_spacing_boundary(codepoints, ascii_index, cjk_index)
  local _, _, token = ascii_token_at(codepoints, ascii_index)
  if token == "" or not token_has_ascii_alnum(token) then
    return true
  end

  if is_codeish_ascii_token(token) then
    return true
  end

  return false
end

local function markdown_link_spans(text)
  local spans = {}
  local search_from = 1
  while true do
    local open_col = text:find("%[", search_from)
    if not open_col then
      break
    end

    if open_col > 1 and text:sub(open_col - 1, open_col - 1) == "!" then
      search_from = open_col + 1
    else
      local bracket_depth = 1
      local cursor = open_col + 1
      local close_col = nil
      while cursor <= #text do
        local char = text:sub(cursor, cursor)
        if char == "[" then
          bracket_depth = bracket_depth + 1
        elseif char == "]" then
          bracket_depth = bracket_depth - 1
          if bracket_depth == 0 then
            close_col = cursor
            break
          end
        end
        cursor = cursor + 1
      end

      if not close_col then
        break
      end

      if text:sub(close_col + 1, close_col + 1) == "(" then
        local paren_depth = 1
        cursor = close_col + 2
        local end_col = nil
        while cursor <= #text do
          local char = text:sub(cursor, cursor)
          if char == "(" then
            paren_depth = paren_depth + 1
          elseif char == ")" then
            paren_depth = paren_depth - 1
            if paren_depth == 0 then
              end_col = cursor
              break
            end
          end
          cursor = cursor + 1
        end

        if not end_col then
          break
        end

        table.insert(spans, {
          start_col = open_col,
          end_col = end_col,
          hidden_start_col = close_col + 1,
          url_start_col = close_col + 2,
          url_end_col = end_col - 1,
          url = text:sub(close_col + 2, end_col - 1),
          label = text:sub(open_col + 1, close_col - 1),
        })
        search_from = end_col + 1
      else
        search_from = close_col + 1
      end
    end
  end

  return spans
end

local function col_in_markdown_link_hidden_span(spans, col)
  for _, span in ipairs(spans) do
    if span.hidden_start_col and col >= span.hidden_start_col and col <= span.end_col then
      return true
    end
  end
  return false
end

local function inline_math_spans(text)
  local spans = {}
  local cursor = 1
  while cursor <= #text do
    local start_col = text:find("$", cursor, true)
    if not start_col then
      break
    end

    if text:sub(start_col, start_col + 1) == "$$" then
      cursor = start_col + 2
    elseif start_col > 1 and text:sub(start_col - 1, start_col - 1) == "\\" then
      cursor = start_col + 1
    else
      local end_col = text:find("$", start_col + 1, true)
      while end_col and end_col > 1 and text:sub(end_col - 1, end_col - 1) == "\\" do
        end_col = text:find("$", end_col + 1, true)
      end
      if not end_col then
        break
      end

      table.insert(spans, { start_col = start_col, end_col = end_col })
      cursor = end_col + 1
    end
  end

  return spans
end

local function inline_code_spans(text)
  local spans = {}
  local cursor = 1
  while cursor <= #text do
    local start_col = text:find("`", cursor, true)
    if not start_col then
      break
    end

    local end_col = text:find("`", start_col + 1, true)
    if not end_col then
      break
    end

    table.insert(spans, { start_col = start_col, end_col = end_col })
    cursor = end_col + 1
  end

  return spans
end

local function col_in_spans(spans, col)
  for _, span in ipairs(spans) do
    if col >= span.start_col and col <= span.end_col then
      return true
    end
  end
  return false
end

local function find_matching_halfwidth_parenthesis(text, open_pos)
  local depth = 1
  local cursor = open_pos + 1
  while cursor <= #text do
    local char = text:sub(cursor, cursor)
    if char == "(" then
      depth = depth + 1
    elseif char == ")" then
      depth = depth - 1
      if depth == 0 then
        return cursor
      end
    end
    cursor = cursor + 1
  end
  return nil
end

local function ascii_word_count(text)
  local count = 0
  for _ in text:gmatch("%a[%a%-]*") do
    count = count + 1
  end
  return count
end

local function is_ascii_parenthetical_prose(text)
  local content = core.trim(text)
  if content == "" or core.contains_non_ascii(content) or not content:find("%a") then
    return false
  end

  if ascii_word_count(content) < 2 then
    return false
  end

  if content:find("[,;:%[%]{}<>=+*/\\|_]") then
    return false
  end

  if content:find("%d") or content:find("https?://") or content:find("%S+%.%S+") then
    return false
  end

  return true
end

local function is_code_like_ascii_parenthetical(text)
  local content = core.trim(text)
  if content == "" or core.contains_non_ascii(content) then
    return false
  end

  if is_ascii_parenthetical_prose(content) then
    return false
  end

  if content:find("[%s]") then
    return false
  end

  return content:find("[%d_%+%-%*%/%=<>:%[%]{}%.]") ~= nil
end

local function ascii_char_before(text, pos)
  if pos <= 1 then
    return nil
  end
  return text:sub(pos - 1, pos - 1)
end

local function is_ascii_identifier_char(char)
  return char ~= nil and char:match("[%w_]") ~= nil
end

local function is_function_call_parentheses(text, open_pos, content)
  local prev_char = ascii_char_before(text, open_pos)
  if not is_ascii_identifier_char(prev_char) then
    return false
  end

  local trimmed = core.trim(content)
  if trimmed == "" then
    return true
  end

  if trimmed:find("[,=]") then
    return true
  end

  if trimmed:find("^[_%a][_%w%.:]*$") then
    return true
  end

  return false
end

local function is_halfwidth_parenthetical_allowed_in_cjk_context(text, open_pos, content)
  local trimmed = core.trim(content)
  if trimmed == "" then
    return true
  end

  local is_standalone_url =
    (trimmed:find("^https://") or trimmed:find("^http://") or trimmed:find("^www%.")) and
    not trimmed:find("%s")
  if is_standalone_url then
    return true
  end

  return is_function_call_parentheses(text, open_pos, content)
end

local function halfwidth_parenthetical_in_cjk_context_col(line, has_cjk_context)
  if not has_cjk_context then
    return nil
  end

  local link_spans = markdown_link_spans(line.masked_text)
  local math_spans = inline_math_spans(line.masked_text)
  local search_from = 1
  while true do
    local open_pos = line.masked_text:find("(", search_from, true)
    if not open_pos then
      break
    end

    if col_in_markdown_link_hidden_span(link_spans, open_pos) or col_in_spans(math_spans, open_pos) then
      search_from = open_pos + 1
    else
      local close_pos = find_matching_halfwidth_parenthesis(line.masked_text, open_pos)
      if not close_pos then
        break
      end

      if not col_in_markdown_link_hidden_span(link_spans, close_pos) and not col_in_spans(math_spans, close_pos) then
        local content = line.masked_text:sub(open_pos + 1, close_pos - 1)
        if not is_halfwidth_parenthetical_allowed_in_cjk_context(line.masked_text, open_pos, content) then
          return open_pos
        end
      end

      search_from = close_pos + 1
    end
  end

  return nil
end

local function fullwidth_parentheses_spacing_col(line)
  if not core.contains_cjk(line.masked_text) then
    return nil
  end

  local codepoints = core.codepoints(line.masked_text)
  for index, item in ipairs(codepoints) do
    if is_unmasked_char(line, item) then
      if item.char == "（" then
        local prev_item = codepoints[index - 1]
        local prev_nonspace = core.previous_nonspace(codepoints, index)
        if
          prev_item and
          prev_item.char == " " and
          line.text:sub(prev_item.pos, prev_item.pos) == " " and
          not (prev_nonspace and SENTENCE_SPACING_PUNCTUATION[prev_nonspace.char])
        then
          return prev_item.pos
        end
      elseif item.char == "）" then
        local prev_item = codepoints[index - 1]
        local next_item = codepoints[index + 1]
        if
          next_item and
          next_item.char == " " and
          line.text:sub(next_item.pos, next_item.pos) == " " and
          not (prev_item and SENTENCE_SPACING_PUNCTUATION[prev_item.char])
        then
          return next_item.pos
        end
      end
    end
  end

  return nil
end

local function cjk_internal_space_col(line)
  local link_spans = markdown_link_spans(line.masked_text)
  local math_spans = inline_math_spans(line.masked_text)
  local codepoints = core.codepoints(line.masked_text)

  local function is_hidden_or_math(item)
    return col_in_markdown_link_hidden_span(link_spans, item.pos) or col_in_spans(math_spans, item.pos)
  end

  for index = 1, #codepoints - 2 do
    local left = codepoints[index]
    if core.is_cjk(left.cp) and not is_hidden_or_math(left) then
      local cursor = index + 1
      local first_space = nil
      local valid_gap = false

      while cursor <= #codepoints and is_halfwidth_space_item(codepoints[cursor]) do
        local space = codepoints[cursor]
        if is_hidden_or_math(space) or not is_original_char(line, space) then
          valid_gap = false
          first_space = nil
          break
        end

        first_space = first_space or space
        valid_gap = true
        cursor = cursor + 1
      end

      local right = codepoints[cursor]
      if
        valid_gap and
        right and
        core.is_cjk(right.cp) and
        not is_hidden_or_math(right)
      then
        return first_space.pos
      end
    end
  end

  return nil
end

local function terminal_continuation_punctuation_col(line)
  if not core.contains_cjk(line.masked_text) then
    return nil
  end

  local link_spans = markdown_link_spans(line.masked_text)
  local codepoints = core.codepoints(line.text)
  for index = #codepoints, 1, -1 do
    local item = codepoints[index]
    if item.char:match("%s") then
      -- Skip trailing whitespace.
    elseif col_in_markdown_link_hidden_span(link_spans, item.pos) then
      -- Hidden Markdown URL syntax is not visible prose.
    elseif not is_unmasked_char(line, item) then
      -- A line that visibly ends with inline code should end at that code span.
      return nil
    elseif TERMINAL_PUNCTUATION_CLOSERS[item.char] then
      -- Closing quotes/brackets wrap the true sentence ending.
    elseif TERMINAL_CONTINUATION_PUNCTUATION[item.char] then
      return item.pos
    else
      return nil
    end
  end

  return nil
end

local TRACKING_QUERY_PARAMS = {
  fbclid = true,
  gclid = true,
  dclid = true,
  gbraid = true,
  wbraid = true,
  yclid = true,
  msclkid = true,
  mc_cid = true,
  mc_eid = true,
  igshid = true,
  spm = true,
  ops_request_misc = true,
  request_id = true,
  biz_id = true,
}

local function is_tracking_query_param(name)
  local lowered = tostring(name or ""):lower()
  return lowered:match("^utm_") ~= nil or TRACKING_QUERY_PARAMS[lowered] == true
end

local function markdown_link_url_has_tracking_param(url)
  local without_fragment = tostring(url or ""):match("^([^#]*)") or ""
  local query = without_fragment:match("%?(.+)$")
  if not query then
    return false
  end

  for raw_param in query:gmatch("[^&;]+") do
    local name = raw_param:match("^([^=]*)") or ""
    if is_tracking_query_param(name) then
      return true
    end
  end

  return false
end

local function boundary_kind(item)
  if not item then
    return nil
  end
  if core.is_cjk(item.cp) then
    return "cjk"
  end
  if is_ascii_token_char(item) and token_has_ascii_alnum(item.char) then
    return "ascii"
  end
  if item.char == "+" or item.char == "#" then
    return "ascii"
  end
  return nil
end

local function label_edge_kind(label, from_end)
  local codepoints = core.codepoints(label)
  local start_index = from_end and #codepoints or 1
  local end_index = from_end and 1 or #codepoints
  local step = from_end and -1 or 1
  for index = start_index, end_index, step do
    local kind = boundary_kind(codepoints[index])
    if kind then
      return kind
    end
  end
  return nil
end

local function previous_nonspace_item(codepoints, before_col)
  for index = #codepoints, 1, -1 do
    local item = codepoints[index]
    if item.pos < before_col and not item.char:match("%s") then
      return item
    end
  end
  return nil
end

local function next_nonspace_item(codepoints, after_col)
  for _, item in ipairs(codepoints) do
    if item.pos > after_col and not item.char:match("%s") then
      return item
    end
  end
  return nil
end

local function text_between_items(text, left_item, right_col)
  if not left_item then
    return ""
  end
  return text:sub(left_item.pos + #left_item.char, right_col - 1)
end

local function gap_has_halfwidth_space(text)
  return text:find(" ", 1, true) ~= nil
end

local function needs_cjk_ascii_space(left_kind, right_kind)
  return (left_kind == "cjk" and right_kind == "ascii") or
    (left_kind == "ascii" and right_kind == "cjk")
end

local function forbids_cjk_cjk_space(left_kind, right_kind)
  return left_kind == "cjk" and right_kind == "cjk"
end

local function title_mark_label_edge(label, from_end)
  local codepoints = core.codepoints(label)
  local start_index = from_end and #codepoints or 1
  local end_index = from_end and 1 or #codepoints
  local step = from_end and -1 or 1

  for index = start_index, end_index, step do
    local item = codepoints[index]
    if not item.char:match("%s") then
      return item.char
    end
  end

  return nil
end

local function is_markdown_prefix_before_col(text, col)
  local before = core.trim(text:sub(1, col - 1))
  return before:match("^#+$") ~= nil or
    before:match("^[-*+]$") ~= nil or
    before:match("^%d+%.$") ~= nil or
    before == ">"
end

local function fullwidth_quote_spacing_col(line)
  local link_spans = markdown_link_spans(line.masked_text)
  local math_spans = inline_math_spans(line.masked_text)
  local code_spans = inline_code_spans(line.text)
  local codepoints = core.codepoints(line.text)

  local function is_hidden_or_math_or_code(item)
    return col_in_markdown_link_hidden_span(link_spans, item.pos) or
      col_in_spans(math_spans, item.pos) or
      col_in_spans(code_spans, item.pos)
  end

  for index, item in ipairs(codepoints) do
    if (FULLWIDTH_QUOTE_OPENERS[item.char] or FULLWIDTH_QUOTE_CLOSERS[item.char]) and not is_hidden_or_math_or_code(item) then
      local prev_item = codepoints[index - 1]
      local next_item = codepoints[index + 1]

      if FULLWIDTH_QUOTE_OPENERS[item.char] then
        if
          is_halfwidth_space_item(prev_item) and
          is_original_char(line, prev_item) and
          not is_markdown_prefix_before_col(line.text, prev_item.pos)
        then
          local prev_nonspace = core.previous_nonspace(codepoints, index)
          if prev_nonspace then
            return prev_item.pos
          end
        end

        if is_halfwidth_space_item(next_item) and is_original_char(line, next_item) then
          return next_item.pos
        end
      elseif FULLWIDTH_QUOTE_CLOSERS[item.char] then
        if is_halfwidth_space_item(prev_item) and is_original_char(line, prev_item) then
          return prev_item.pos
        end

        if is_halfwidth_space_item(next_item) and is_original_char(line, next_item) then
          local next_nonspace = core.next_nonspace(codepoints, index)
          if next_nonspace then
            return next_item.pos
          end
        end
      end
    end
  end

  return nil
end

local function title_mark_direct_spacing_col(line)
  local codepoints = core.codepoints(line.masked_text)
  for index, item in ipairs(codepoints) do
    if TITLE_MARK_OPENERS[item.char] and is_unmasked_char(line, item) then
      local prev_item = codepoints[index - 1]
      local next_item = codepoints[index + 1]
      if
        is_halfwidth_space_item(prev_item) and
        is_original_char(line, prev_item) and
        not is_markdown_prefix_before_col(line.masked_text, prev_item.pos)
      then
        return prev_item.pos
      end
      if is_halfwidth_space_item(next_item) and is_original_char(line, next_item) then
        return next_item.pos
      end
    elseif TITLE_MARK_CLOSERS[item.char] and is_unmasked_char(line, item) then
      local prev_item = codepoints[index - 1]
      local next_item = codepoints[index + 1]
      if is_halfwidth_space_item(prev_item) and is_original_char(line, prev_item) then
        return prev_item.pos
      end
      if is_halfwidth_space_item(next_item) and is_original_char(line, next_item) then
        local next_nonspace = core.next_nonspace(codepoints, index)
        if next_nonspace then
          return next_item.pos
        end
      end
    end
  end

  return nil
end

local function title_mark_markdown_link_edge_spacing_col(line)
  local codepoints = core.codepoints(line.masked_text)

  for _, span in ipairs(markdown_link_spans(line.masked_text)) do
    local first_label_char = title_mark_label_edge(span.label, false)
    if TITLE_MARK_OPENERS[first_label_char] then
      local prev_item = previous_nonspace_item(codepoints, span.start_col)
      if prev_item then
        local gap = text_between_items(line.masked_text, prev_item, span.start_col)
        if gap_has_halfwidth_space(gap) and not is_markdown_prefix_before_col(line.masked_text, span.start_col) then
          return span.start_col
        end
      end
    end

    local last_label_char = title_mark_label_edge(span.label, true)
    if TITLE_MARK_CLOSERS[last_label_char] then
      local next_item = next_nonspace_item(codepoints, span.end_col)
      if next_item then
        local gap = line.masked_text:sub(span.end_col + 1, next_item.pos - 1)
        if gap_has_halfwidth_space(gap) then
          return span.end_col
        end
      end
    end
  end

  return nil
end

local function title_mark_spacing_col(line)
  return title_mark_direct_spacing_col(line) or title_mark_markdown_link_edge_spacing_col(line)
end

local function internal_consecutive_space_col(line)
  local link_spans = markdown_link_spans(line.masked_text)
  local math_spans = inline_math_spans(line.masked_text)
  local code_spans = inline_code_spans(line.text)
  local codepoints = core.codepoints(line.text)

  local function is_hidden_or_math_or_code(item)
    return col_in_markdown_link_hidden_span(link_spans, item.pos) or
      col_in_spans(math_spans, item.pos) or
      col_in_spans(code_spans, item.pos)
  end

  for index = 1, #codepoints - 1 do
    local first = codepoints[index]
    local second = codepoints[index + 1]
    if
      first.char == " " and
      second.char == " " and
      is_original_char(line, first) and
      is_original_char(line, second) and
      not is_hidden_or_math_or_code(first) and
      not is_hidden_or_math_or_code(second)
    then
      local prev_nonspace = core.previous_nonspace(codepoints, index)
      local next_nonspace = core.next_nonspace(codepoints, index + 1)
      if prev_nonspace and next_nonspace then
        return first.pos
      end
    end
  end

  return nil
end

is_reference_heading_line = function(line)
  return line and line.is_heading and (
    line.stripped:match("^##%s+引用文獻$") or
    line.stripped:match("^##%s+References$")
  )
end

local function has_reference_heading(document)
  for _, line in ipairs(document.lines) do
    if is_reference_heading_line(line) then
      return true
    end
  end
  return false
end

local BIBLIOGRAPHY_URL_LEADS = {
  "Available online at:",
  "Available online here:",
  "Available online from:",
  "Available online:",
  "Available from:",
  "Available here:",
  "Available:",
  "From:",
  "網址：",
  "網址:",
  "原網址：",
  "原網址:",
}

local function parse_reference_entry_line(text)
  local anchor_id, label, body = text:match('^%- %s*<a id="([^"]+)">%[([^%]]+)%]</a>%s*:?[ \t]*(.+)$')
  if anchor_id then
    return {
      anchor_id = anchor_id,
      label = label,
      body = body,
    }
  end

  label, body = text:match("^%- %s*%[([^%]]+)%]%s*:?[ \t]*(.+)$")
  if label then
    return {
      anchor_id = nil,
      label = label,
      body = body,
    }
  end

  return nil
end

local function bibliography_section_lines(document)
  local entries = {}
  local subbullets = {}
  local in_references = false

  for _, line in ipairs(document.lines) do
    if is_reference_heading_line(line) then
      in_references = true
    elseif line.is_heading and in_references then
      in_references = false
    elseif in_references and not line.is_code and not line.is_tag and not line.is_table and not line.is_blockquote then
      local entry = parse_reference_entry_line(line.text)
      if entry then
        entry.line = line
        table.insert(entries, entry)
      end

      local subbody = line.text:match("^%s%s+%-%s+(.+)$")
      if subbody then
        table.insert(subbullets, {
          line = line,
          body = subbody,
        })
      end
    end
  end

  return entries, subbullets
end

local function bibliography_has_url(text)
  return text:match("https?://") ~= nil or
    text:match("ftp://") ~= nil or
    text:match("www%.") ~= nil
end

bibliography_url_subbullet_is_pure_url = function(text)
  local trimmed = core.trim(text):gsub("\\~", "~")
  for _, lead in ipairs(BIBLIOGRAPHY_URL_LEADS) do
    if trimmed:sub(1, #lead) == lead then
      return false
    end
  end

  if core.contains_cjk(trimmed) then
    return false
  end

  local compact = trimmed:gsub("%s+", "")
  return compact:match("^(https?://%S+)$") ~= nil or
    compact:match("^(ftp://%S+)$") ~= nil or
    compact:match("^(www%.%S+)$") ~= nil
end

local function bibliography_explanation_subbullets(document)
  local _, subbullets = bibliography_section_lines(document)
  local explanation_lines = {}

  for _, item in ipairs(subbullets) do
    if not bibliography_url_subbullet_is_pure_url(item.body) and core.contains_cjk(item.line.masked_text or item.body) then
      table.insert(explanation_lines, item)
    end
  end

  return explanation_lines
end

local function formal_citation_links(text)
  local links = {}
  for sup_body in tostring(text or ""):gmatch("<sup>(.-)</sup>") do
    for label, target in sup_body:gmatch("%[%[([^%]]+)%]%]%(%#([^)]+)%)") do
      table.insert(links, {
        label = label,
        target = target,
      })
    end
  end
  return links
end

local WORKSPACE_JARGON = {
  "參考依據",
  "規則優先序",
  "術語邊界",
  "工作模式",
  "開工前檢查關卡",
  "baseline",
  "continuity",
  "output contract",
  "override gate",
  "task-local artifact",
  "受影響範圍重驗證",
}

local INTERNAL_CONTROL_LABELS = {
  "參考依據",
  "規則優先序",
  "術語邊界",
  "工作模式",
  "開工前檢查關卡",
  "受影響範圍重驗證",
  "內部語義欄位",
  "內部欄位",
}

local INTERNAL_CONTROL_LABELS_CASE_INSENSITIVE = {
  "baseline",
  "continuity",
  "output contract",
  "override gate",
  "task-local artifact",
  "optional override",
  "optional overrides",
}

local HUIXIE_TERM_SUFFIXES = {
  "快取",
  "策略",
  "機制",
  "模式",
  "技術",
  "caching",
  "cache",
}

local HUIXIE_TERM_PREFIXES = {
  "快取",
  "cache",
}

local ABSTRACT_TAXONOMY_TERMS = {
  "參考依據",
  "規則優先序",
  "術語邊界",
  "工作模式",
  "baseline",
  "continuity",
  "output contract",
  "override gate",
  "task-local artifact",
  "受影響範圍重驗證",
  "分類",
  "原則",
  "邊界",
  "層",
  "策略",
  "決策",
  "風險",
  "訊號",
  "條件",
  "形式",
  "功能",
  "語義",
  "對應",
}

local CLAUSE_BOUNDARIES = { "，", "。", "！", "？", "；", ",", ";", "!", "?", "\n" }

local COMPLETION_EVENT_VERBS = {
  "初始化",
  "完成",
  "更新",
  "載入",
  "儲存",
  "建立",
  "啟動",
  "安裝",
  "部署",
  "提交",
  "生成",
  "產生",
  "解析",
  "設定",
  "配置",
  "連接",
  "連線",
  "寫入",
  "刪除",
  "修正",
}

local GENERIC_YOU_VERBS = {
  "完成",
  "支援",
  "初始化",
  "更新",
  "載入",
  "處理",
  "建立",
  "啟動",
  "整理",
  "修正",
  "部署",
  "提交",
  "測試",
  "做",
  "跑",
}

local COUNT_PREFIXES = {
  "一", "二", "三", "四", "五", "六", "七", "八", "九", "十",
  "兩", "幾", "數", "多", "半",
}

local COUNT_CLASSIFIERS = {
  "個", "次", "種", "段", "項", "行", "條", "本", "份", "篇",
  "位", "張", "台", "組", "輪", "筆", "門", "層", "類", "天",
  "月", "年", "分鐘", "小時", "頁",
}

local REPEATED_SUBJECT_HEADS = {
  "系統", "模組", "服務", "程式", "流程", "這個", "該", "此", "我們",
  "文章", "欄位", "設定", "資料",
}

local BA_RESULT_MARKERS = {
  "了", "成", "到", "掉", "完", "好", "清", "住", "開", "上", "下",
  "起來", "下來", "回", "進", "出", "拆成", "寫回", "視為",
}

local BARE_BA_VERBS = {
  "改", "寫", "做", "放", "設", "打", "處理", "整理", "拆", "清",
}

local ABSTRACT_EVENT_NOUNS = {
  "取回", "決定", "建立", "處理", "比較", "分析", "配置",
  "實作", "導入", "評估", "部署", "整理",
}

local DEFINITE_MARKERS = {
  "這", "那", "該", "此", "本", "這個", "那個", "這些", "那些",
  "這份", "那份", "該欄位", "此模組",
}

local NONAGENTIVE_SUBJECTS = {
  "系統", "模組", "欄位", "流程", "錯誤", "程式", "服務", "設定",
  "文章", "專案", "資料", "快取", "buffer", "單元", "欄位", "結果",
}

local CONTROL_MODALS = { "敢", "肯", "願意" }

local HIGH_RISK_MISSING_DE_PHRASES = {
  "一種常見方法",
  "複雜控制流程",
  "跨 lane predicate 測試",
}

local HIGH_RISK_MISSING_DI_PHRASES = {
  "有系統整理",
  "清楚說明",
  "系統性比較",
}

local HIGH_RISK_MISSING_COMPLEMENT_DE = {
  "比較看出來",
  "整理很清楚",
  "寫很完整",
  "說很清楚",
  "講很明白",
}

local SHOU_BARE_EVENT_VERBS = {
  "初始化", "更新", "覆寫", "覆蓋", "刪除", "修改", "部署",
  "重寫", "拆開", "清掉",
}

local DESCRIPTION_OBJECTS = {
  "資料", "結果", "內容", "文章", "設定", "buffer", "欄位", "流程",
}

local DEGREE_MARKERS = { "很", "更", "非常", "十分", "太" }

local OVERLOADED_POSTVERBAL_VERBS = {
  "整理", "寫", "處理", "比較", "分析", "部署", "跑", "做", "說",
}

local DURATION_OR_COUNT_MARKERS = {
  "一次", "兩次", "三次", "很多次", "好幾次", "一輪", "兩輪", "三輪",
  "很久", "一段時間", "多年", "很長時間",
}

local EVENT_NOMINALIZATION_TAIL_MARKERS = {
  "會", "能", "可以", "可", "將", "應", "需", "必須",
  "影響", "造成", "導致", "帶來", "代表", "意味著", "取決於",
  "需要", "要求", "值得", "有助於", "變得",
}

local GLOSSARY_PREFIX_FALLBACK_MARKERS = {
  "也就是", "就是", "則是", "叫做", "稱作", "稱為", "是", "為",
  "會", "能", "可以", "可", "將", "應", "需", "必須",
}

local function matches_glossary_preferred_form(entry, chinese)
  if not entry or chinese == "" then
    return false
  end

  if entry.preferred_set[chinese] then
    return true
  end

  for _, marker in ipairs(GLOSSARY_PREFIX_FALLBACK_MARKERS) do
    local search_from = 1
    while true do
      local found = chinese:find(marker, search_from, true)
      if not found then
        break
      end

      local before = core.trim(chinese:sub(1, found - 1))
      local after = core.trim(chinese:sub(found + #marker))
      if
        core.visible_length(before) >= 2 and
        core.visible_length(after) >= 2 and
        entry.preferred_set[after]
      then
        return true
      end

      search_from = found + #marker
    end
  end

  return false
end

local function has_expansion_signal(text)
  local patterns = {
    "指的是",
    "也就是",
    "例如",
    "會",
    "用來",
    "控制",
    "代表",
    "實際",
    "屬於",
    "檔案",
    "路徑",
    "rule",
    "references/",
    "working/",
    "assets/",
  }
  for _, pattern in ipairs(patterns) do
    if text:find(pattern, 1, true) then
      return true
    end
  end
  return false
end

local function count_term_hits(text, terms)
  local count = 0
  for _, term in ipairs(terms) do
    if text:find(term, 1, true) then
      count = count + 1
    end
  end
  return count
end

local function has_concrete_anchor(text)
  if
    text:find("`", 1, true) or
    text:find("L%d%d%d") or
    text:find("[%w_./-]+%.md") or
    text:find("[%w_./-]+%.lua")
  then
    return true
  end

  local patterns = {
    "例如",
    "像是",
    "比如",
    "會",
    "用來",
    "改成",
    "改寫",
    "移除",
    "加入",
    "補上",
    "更新",
    "寫回",
    "實作",
    "檢查",
    "驗證",
    "對齊",
    "references/",
    "working/",
  }
  for _, pattern in ipairs(patterns) do
    if text:find(pattern, 1, true) then
      return true
    end
  end

  return false
end

local function has_any_plain(text, patterns)
  for _, pattern in ipairs(patterns) do
    if text:find(pattern, 1, true) then
      return true
    end
  end
  return false
end

local function find_internal_control_label_col(line)
  local text = line.masked_text or line.text or ""
  for _, term in ipairs(INTERNAL_CONTROL_LABELS) do
    local col = text:find(term, 1, true)
    if col then
      return col
    end
  end

  local lowered = text:lower()
  for _, term in ipairs(INTERNAL_CONTROL_LABELS_CASE_INSENSITIVE) do
    local col = lowered:find(term, 1, true)
    if col then
      return col
    end
  end

  return nil
end

local function find_any_in_lines(lines, patterns)
  for _, line in ipairs(lines) do
    for _, pattern in ipairs(patterns) do
      local col = line.masked_text:find(pattern, 1, true)
      if col then
        return line.number, col
      end
    end
  end
  return nil, nil
end

local function find_next_plain(text, patterns, start_pos)
  local earliest
  for _, pattern in ipairs(patterns) do
    local pos = text:find(pattern, start_pos, true)
    if pos and (not earliest or pos < earliest) then
      earliest = pos
    end
  end
  return earliest
end

local function is_noncode_text_line(line)
  return
    not line.is_blank and
    not line.is_code and
    not line.is_heading and
    not line.is_table and
    not line.is_blockquote
end

local function is_temporal_subordinate_clause(text)
  local patterns = {
    "的時候",
    "時候",
    "之前",
    "以後",
    "之際",
    "之時",
    "時",
  }
  return has_any_plain(text, patterns)
end

local function previous_utf8_char(text, byte_pos)
  local prev_start = utf8.offset(text, -1, byte_pos)
  if not prev_start then
    return nil
  end
  return text:sub(prev_start, byte_pos - 1)
end

local function starts_with_count_phrase(text)
  local trimmed = core.trim(text)
  local digits = trimmed:match("^(%d+)")
  if digits then
    local rest = trimmed:sub(#digits + 1)
    for _, classifier in ipairs(COUNT_CLASSIFIERS) do
      if rest:find(classifier, 1, true) == 1 then
        return true
      end
    end
  end

  for _, prefix in ipairs(COUNT_PREFIXES) do
    if trimmed:find(prefix, 1, true) == 1 then
      local rest = trimmed:sub(#prefix + 1)
      for _, classifier in ipairs(COUNT_CLASSIFIERS) do
        if rest:find(classifier, 1, true) == 1 then
          return true
        end
      end
    end
  end

  return false
end

local function starts_with_temporal_count_phrase(text)
  local trimmed = core.trim(text)
  local temporal_classifiers = { "年", "月", "天", "分鐘", "小時" }
  local temporal_suffixes = { "前", "後", "內", "來" }
  local function has_temporal_suffix(text_after_classifier)
    for _, suffix in ipairs(temporal_suffixes) do
      if text_after_classifier:find(suffix, 1, true) == 1 then
        return true
      end
    end
    return false
  end

  local digits = trimmed:match("^(%d+)")
  if digits then
    local rest = trimmed:sub(#digits + 1)
    for _, classifier in ipairs(temporal_classifiers) do
      if rest:find(classifier, 1, true) == 1 then
        local after = rest:sub(#classifier + 1)
        if has_temporal_suffix(after) then
          return true
        end
      end
    end
  end

  for _, prefix in ipairs(COUNT_PREFIXES) do
    if trimmed:find(prefix, 1, true) == 1 then
      local rest = trimmed:sub(#prefix + 1)
      for _, classifier in ipairs(temporal_classifiers) do
        if rest:find(classifier, 1, true) == 1 then
          local after = rest:sub(#classifier + 1)
          if has_temporal_suffix(after) then
            return true
          end
        end
      end
    end
  end

  return false
end

local function has_count_phrase(text)
  for _, classifier in ipairs(COUNT_CLASSIFIERS) do
    if text:find("%d+" .. classifier) then
      return true
    end
    for _, prefix in ipairs(COUNT_PREFIXES) do
      if text:find(prefix .. classifier, 1, true) then
        return true
      end
    end
  end
  return false
end

local function clause_window(text, start_pos)
  local boundary = find_next_plain(text, CLAUSE_BOUNDARIES, start_pos)
  return boundary and text:sub(start_pos, boundary - 1) or text:sub(start_pos)
end

local function has_result_marker(text)
  return has_any_plain(text, BA_RESULT_MARKERS)
end

local function count_plain_occurrences(text, needles)
  local count = 0
  for _, needle in ipairs(needles) do
    count = count + core.count_substring(text, needle)
  end
  return count
end

local split_strong_sentences

local function count_strong_sentences(text)
  local count = 0
  for _, segment in ipairs(split_strong_sentences(text)) do
    if core.visible_length(core.trim(segment.text)) >= 12 then
      count = count + 1
    end
  end
  return count
end

local function has_nearby_plain(text, needle, byte_pos, max_window)
  local start_pos = math.max(1, byte_pos - max_window)
  return text:sub(start_pos, byte_pos - 1):find(needle, 1, true) ~= nil
end

local function trimmed_tail(text, byte_pos)
  return core.trim(text:sub(byte_pos))
end

local function strip_terminal_fullwidth_punctuation(text)
  local trimmed = core.trim(text)
  for _, marker in ipairs({ "。", "；", "：" }) do
    if trimmed:sub(-#marker) == marker then
      return core.trim(trimmed:sub(1, #trimmed - #marker))
    end
  end
  return trimmed
end

local function text_after_last_plain(text, marker)
  local last_pos = nil
  local search_from = 1
  while true do
    local pos = text:find(marker, search_from, true)
    if not pos then
      break
    end
    last_pos = pos
    search_from = pos + #marker
  end

  if not last_pos then
    return nil
  end
  return text:sub(last_pos + #marker)
end

local function has_inline_final_conjunction(text)
  local trimmed = core.trim(text)
  if trimmed == "" then
    return false
  end

  for _, marker in ipairs({ "與", "及", "或" }) do
    local search_from = 1
    while true do
      local pos = trimmed:find(marker, search_from, true)
      if not pos then
        break
      end

      local before = core.trim(trimmed:sub(1, pos - 1))
      local after = core.trim(trimmed:sub(pos + #marker))
      if before ~= "" and after ~= "" then
        return true
      end

      search_from = pos + #marker
    end
  end

  return false
end

local function find_bare_english_drift_col(line, english_lower)
  local text = line.masked_text
  local text_lower = text:lower()
  local codepoints_cache = nil

  local search_from = 1
  while true do
    local match_start, match_end = text_lower:find(english_lower, search_from, true)
    if not match_start then
      return nil
    end

    local left_char = match_start > 1 and text:sub(match_start - 1, match_start - 1) or ""
    local right_char = text:sub(match_end + 1, match_end + 1)
    local word_bounded = not left_char:match("[%w_]") and not right_char:match("[%w_]")

    local in_bilingual = false
    if word_bounded then
      if match_start >= 4 and text:sub(match_start - 3, match_start - 1) == "（" then
        in_bilingual = true
      elseif text:sub(match_end + 1, match_end + 3) == "）" then
        in_bilingual = true
      end
    end

    if word_bounded and not in_bilingual then
      codepoints_cache = codepoints_cache or core.codepoints(text)

      local start_idx = nil
      for i, item in ipairs(codepoints_cache) do
        if item.pos == match_start then
          start_idx = i
          break
        elseif item.pos > match_start then
          break
        end
      end

      if start_idx then
        local end_idx = start_idx
        while
          end_idx <= #codepoints_cache and
          codepoints_cache[end_idx].pos <= match_end
        do
          end_idx = end_idx + 1
        end
        end_idx = end_idx - 1

        local left_neighbor = core.previous_nonspace(codepoints_cache, start_idx)
        local right_neighbor = core.next_nonspace(codepoints_cache, end_idx)
        local has_cjk_neighbor =
          (left_neighbor and core.is_cjk(left_neighbor.cp)) or
          (right_neighbor and core.is_cjk(right_neighbor.cp))

        if has_cjk_neighbor then
          return match_start
        end
      end
    end

    search_from = match_end + 1
  end
end

local function should_track_bare_english_drift_anchor(raw_english, english_key)
  local trimmed = core.trim(tostring(raw_english or ""))
  if english_key == "" or #english_key < 3 then
    return false
  end

  if not trimmed:find("%a") then
    return false
  end

  if
    trimmed:find("://", 1, true) or
    trimmed:find("/", 1, true) or
    trimmed:find("\\", 1, true) or
    trimmed:find("@", 1, true) or
    trimmed:find("::", 1, true) or
    trimmed:find("_", 1, true)
  then
    return false
  end

  -- Acronym-heavy terms are often intentionally kept in bare English downstream.
  if trimmed:match("^[A-Z][A-Z0-9%-]*$") then
    return false
  end

  return true
end

local function is_term_like_chinese(text)
  local normalized = core.normalize_chinese_term(text)
  if normalized == "" then
    return false
  end

  if core.visible_length(normalized) > 10 then
    return false
  end

  local blockers = {
    "的",
    "最終",
    "重點",
    "正常情況",
    "這個",
    "那個",
    "前面",
    "後面",
    "如果",
    "除了",
    "因此",
    "所以",
    "但是",
    "不過",
  }

  return not has_any_plain(normalized, blockers)
end

split_strong_sentences = function(text)
  local segments = {}
  local start_pos = 1
  local byte_pos = 1

  while byte_pos <= #text do
    local codepoint = utf8.codepoint(text, byte_pos)
    local char = utf8.char(codepoint)
    if char == "。" or char == "！" or char == "？" or char == "；" then
      table.insert(segments, { text = text:sub(start_pos, byte_pos - 1), start_pos = start_pos })
      start_pos = byte_pos + #char
    end
    byte_pos = byte_pos + #char
  end

  if start_pos <= #text then
    table.insert(segments, { text = text:sub(start_pos), start_pos = start_pos })
  end

  return segments
end

local function next_utf8_char(text, byte_pos)
  local next_start = utf8.offset(text, 2, byte_pos)
  if not next_start then
    return nil
  end

  local current_len = #text:sub(byte_pos, next_start - 1)
  local char_start = byte_pos + current_len
  if char_start > #text then
    return nil
  end

  local after_start = utf8.offset(text, 2, char_start)
  if after_start then
    return text:sub(char_start, after_start - 1)
  end
  return text:sub(char_start)
end

local function starts_with_any(text, patterns)
  for _, pattern in ipairs(patterns) do
    if text:find(pattern, 1, true) == 1 then
      return true
    end
  end
  return false
end

local function ends_with_any(text, patterns)
  for _, pattern in ipairs(patterns) do
    if #text >= #pattern and text:sub(-#pattern) == pattern then
      return true
    end
  end
  return false
end

local MEMORY_ALLOCATION_CONTEXT = {
  "記憶體", "虛擬記憶", "主記憶", "位址空間", "位元組", "頁框", "頁面",
  "堆積", "heap", "malloc", "alloc", "allocation", "allocator",
  "分配器", "空間", "buffer", "緩衝區", "區塊",
}

local TONGGUO_PASS_OBJECTS = {
  "測試", "了測試", "所有測試", "全部測試", "這個測試", "該測試",
  "考試", "了考試", "檢查", "了檢查", "驗證", "了驗證",
  "審查", "審核", "門檻", "條件", "要求", "關卡", "法案", "決議",
  "review", "Review",
}

local IT_CONTEXT_TERMS = {
  "系統", "程式", "程式碼", "軟體", "硬體", "資料", "資料庫",
  "記憶體", "位址", "檔案", "目錄", "網路", "封包", "函式",
  "方法", "類別", "物件", "執行", "流程", "架構", "介面",
  "模組", "用戶端", "伺服器", "作業系統", "行程", "執行緒",
  "api", "cpu", "gpu",
}

local PROCESSOR_CORE_COUNT_PREFIXES = {
  "一", "二", "三", "四", "五", "六", "七", "八", "九", "十",
  "兩", "幾", "數", "多", "每", "各",
}

local HARDWARE_DEVICE_CONTEXT = {
  "驅動", "driver", "中斷", "interrupt", "匯流排", "bus",
  "PCI", "USB", "GPIO", "DMA", "MMIO", "IRQ",
  "控制器", "controller", "firmware", "韌體",
  "周邊", "外接", "介面卡", "網卡", "網路卡", "顯示卡",
  "硬碟", "SSD", "NVMe",
  "暫存器", "register",
}

local PROCESS_PROGRAMMING_CONTEXT = {
  "process", "thread", "scheduler", "scheduling",
  "fork", "exec", "waitpid", "signal", "syscall", "daemon",
  "kernel", "userspace", "user-space",
  "執行緒", "排程", "作業系統", "行程", "核心態", "使用者態",
  "context switch", "PID", "TID",
}

local EXCEPTION_PROGRAMMING_CONTEXT = {
  "exception", "throw", "catch", "raise", "rethrow",
  "try", "finally", "handler", "unhandled",
  "stack trace", "stacktrace", "backtrace",
  "例外", "拋出", "捕捉", "錯誤處理", "錯誤碼",
  "try-catch", "try/catch",
}

local MEMORY_ADDRESS_CONTEXT = {
  "memory", "pointer", "offset", "virtual", "physical",
  "MMU", "TLB", "page table", "segment",
  "記憶體", "指標", "偏移", "虛擬", "實體",
  "映射", "位址空間", "頁表", "分頁", "段頁式",
  "address space",
}

local function has_case_insensitive_plain(text, patterns)
  local lowered = tostring(text or ""):lower()
  for _, pattern in ipairs(patterns) do
    if lowered:find(tostring(pattern):lower(), 1, true) then
      return true
    end
  end
  return false
end

local function has_memory_allocation_context(text)
  return has_case_insensitive_plain(text, MEMORY_ALLOCATION_CONTEXT)
end

local function is_tongguo_pass_usage(text, col)
  local after = core.trim(text:sub(col + #"通過"))
  return starts_with_any(after, TONGGUO_PASS_OBJECTS)
end

local function has_it_context(text)
  return has_case_insensitive_plain(text, IT_CONTEXT_TERMS)
end

local function has_hardware_device_context(text)
  return has_case_insensitive_plain(text, HARDWARE_DEVICE_CONTEXT)
end

local function has_process_programming_context(text)
  return has_case_insensitive_plain(text, PROCESS_PROGRAMMING_CONTEXT)
end

local function has_exception_programming_context(text)
  return has_case_insensitive_plain(text, EXCEPTION_PROGRAMMING_CONTEXT)
end

local function has_memory_address_context(text)
  return has_case_insensitive_plain(text, MEMORY_ADDRESS_CONTEXT)
end

local function is_processor_core_count_usage(text, col)
  local before = text:sub(1, col - 1)
  if before:match("%d+%s*$") then
    return true
  end

  local trimmed_before = core.trim(before)
  for _, prefix in ipairs(PROCESSOR_CORE_COUNT_PREFIXES) do
    if #trimmed_before >= #prefix and trimmed_before:sub(-#prefix) == prefix then
      return true
    end
  end

  return false
end

local function should_warn_preferred_term(entry, text, col)
  if entry.term == "當前" and text:sub(col + #"當前", col + #"當前" + #"置" - 1) == "置" then
    return false
  end
  if entry.term == "代碼" and text:sub(math.max(1, col - #"控制"), col - 1) == "控制" then
    return false
  end
  if entry.context == "memory_allocation" then
    return has_memory_allocation_context(text)
  end
  if entry.context == "tongguo_via" then
    return not is_tongguo_pass_usage(text, col)
  end
  if entry.context == "processor_core_count" then
    return is_processor_core_count_usage(text, col)
  end
  if entry.context == "it" then
    return has_it_context(text)
  end
  if entry.context == "hardware_device" then
    return has_hardware_device_context(text)
  end
  if entry.context == "process_programming" then
    return has_process_programming_context(text)
  end
  if entry.context == "exception_programming" then
    return has_exception_programming_context(text)
  end
  if entry.context == "memory_address" then
    return has_memory_address_context(text)
  end
  return true
end

local PREFERRED_TAIWAN_TERMS = {
  {
    term = "參數列表",
    preferred = "參數列",
    note = "parameter 譯為「參數」；argument 譯為「引數」，兩者不可混用",
  },
  {
    term = "引數列表",
    preferred = "引數列",
    note = "argument 譯為「引數」；parameter 譯為「參數」，兩者不可混用",
  },
  { term = "物理位址", preferred = "實體位址" },
  { term = "物理地址", preferred = "實體位址" },
  { term = "命令行", preferred = "命令列" },
  { term = "並行度", preferred = "平行度", note = "parallelism 應譯為「平行」；concurrency 才譯為「並行」" },
  { term = "多核心", preferred = "多核", note = "multicore / multi-core 譯為「多核」，以和 multi-kernel 的「多核心」區分" },
  { term = "個核心", preferred = "個處理器核", context = "processor_core_count", note = "量詞 + 核心在 CPU 語境指 processor core" },
  { term = "原始碼", preferred = "原始程式碼" },
  { term = "自定義", preferred = "自訂" },
  { term = "客戶端", preferred = "用戶端" },
  { term = "空閒", preferred = "閒置" },
  { term = "當前", preferred = "目前" },
  { term = "分配", preferred = "配置", context = "memory_allocation", note = "僅限記憶體配置語境；「分配工作」是正確用法" },
  { term = "設備", preferred = "裝置", context = "hardware_device", note = "硬體語境建議用「裝置」；大型設施仍可用「設備」" },
  { term = "程序", preferred = "行程", context = "process_programming", note = "若原文是 process，應譯為「行程」；program 應譯為「程式」" },
  { term = "異常", preferred = "例外", context = "exception_programming", note = "若原文是 exception，應譯為「例外」" },
  { term = "實現", preferred = "實作" },
  { term = "運行", preferred = "執行" },
  { term = "地址", preferred = "位址", context = "memory_address", note = "限計算機 address 語境；一般住址可保留「地址」" },
  { term = "拷貝", preferred = "複製" },
  { term = "條指令", preferred = "道指令", note = "instruction 的量詞用「道」" },
  { term = "佈局", preferred = "版面配置", note = "若原文是 layout，建議譯為「版面配置」" },
  { term = "計劃", preferred = "計畫" },
  { term = "型別", preferred = "型態" },
  { term = "通過", preferred = "透過 / 藉由 / 經由", context = "tongguo_via", note = "「通過」保留給 pass，如通過測試" },
  { term = "發送", preferred = "傳送" },
  { term = "轉發", preferred = "轉寄" },
  { term = "偽碼", preferred = "虛擬碼" },
  { term = "僞碼", preferred = "虛擬碼" },
  { term = "構建", preferred = "建構" },
  { term = "意味著", preferred = "代表 / 表示" },
  { term = "隊列", preferred = "佇列" },
  { term = "優化", preferred = "最佳化" },
  { term = "閥值", preferred = "臨界值" },
  { term = "遍歷", preferred = "走訪" },
  { term = "訪問", preferred = "存取" },
  { term = "內核", preferred = "核心" },
  { term = "場景", preferred = "情境", context = "it", note = "限 IT 語境；電影 / 戲劇 scene 可譯為「場景」" },
  { term = "導入", preferred = "引入" },
  { term = "打開", preferred = "開啟" },
  { term = "代碼", preferred = "程式碼" },
  { term = "網卡", preferred = "網路卡" },
}

local function preferred_term_message(entry)
  local message = "「" .. entry.term .. "」建議改為「" .. entry.preferred .. "」"
  if entry.note then
    message = message .. "；" .. entry.note
  end
  return message
end

local function span_overlaps(spans, start_col, end_col)
  for _, span in ipairs(spans) do
    if start_col <= span.end_col and end_col >= span.start_col then
      return true
    end
  end
  return false
end

local DESCRIPTIVE_PARENTHETICAL_PREFIXES = {
  "位址",
  "讀作",
  "例如",
  "因為",
  "如果",
  "是否",
  "即",
  "甚至",
  "包含",
  "針對",
  "免費",
  "用來",
  "參見",
  "見",
  "也就是",
  "也稱為",
  "稱作",
  "圖中",
  "十六進位",
  "查詢",
  "從",
  "寫入",
  "讀取",
  "將",
  "讓",
  "確保",
  "記錄",
  "釋放",
  "呼叫",
  "喚醒",
  "設置",
  "跳過",
  "回傳",
}

local function parenthetical_content_at(text, open_pos)
  local close_pos = text:find("）", open_pos + #"（", true)
  if not close_pos then
    return nil
  end
  return text:sub(open_pos + #"（", close_pos - 1)
end

local function is_descriptive_chinese_parenthetical(text)
  local trimmed = core.trim(text or "")
  if trimmed == "" then
    return false
  end

  if trimmed:find("`", 1, true) or trimmed:find("：", 1, true) then
    return true
  end

  if trimmed:find("%d") or core.contains_ascii_letter(trimmed) then
    return true
  end

  return starts_with_any(trimmed, DESCRIPTIVE_PARENTHETICAL_PREFIXES)
end

local function is_write_back_term_usage(text, col)
  local lowered = text:lower()
  if
    lowered:find("write-back", 1, true) or
    lowered:find("write back", 1, true) or
    lowered:find("write-through", 1, true)
  then
    return true
  end

  local after = core.trim(text:sub(col + #"回寫"))
  if starts_with_any(after, HUIXIE_TERM_SUFFIXES) then
    return true
  end

  local before = core.trim(text:sub(1, col - 1)):lower()
  if ends_with_any(before, HUIXIE_TERM_PREFIXES) then
    return true
  end

  return false
end

local function is_lexical_le(text, col)
  local prev_char = previous_utf8_char(text, col)
  local lexical_prev_chars = {
    ["為"] = true, ["除"] = true,
    ["罷"] = true, ["算"] = true, ["對"] = true, ["好"] = true, ["忘"] = true,
    ["得"] = true,
  }
  if lexical_prev_chars[prev_char] then
    return true
  end

  local tail = text:sub(col)
  return starts_with_any(tail, {
    "了解",
    "瞭解",
    "了結",
    "了然",
    "了當",
    "了不起",
  })
end

local function find_dense_de_chain_col(text)
  for _, segment in ipairs(split_strong_sentences(text)) do
    local positions = {}
    local search_from = 1
    while true do
      local relative_col = segment.text:find("的", search_from, true)
      if not relative_col then
        break
      end

      local absolute_col = segment.start_pos + relative_col - 1
      if next_utf8_char(text, absolute_col) ~= "是" then
        table.insert(positions, relative_col)
      end
      search_from = relative_col + #"的"
    end

    for index = 1, #positions - 2 do
      local first = positions[index]
      local third = positions[index + 2]
      local window = segment.text:sub(first, third + #"的" - 1)
      if core.visible_length(window) <= 15 then
        return segment.start_pos + first - 1
      end
    end
  end

  return nil
end

local function find_nearby_prefix_before(text, byte_pos, prefixes, max_distance)
  local last_boundary = 0
  for _, boundary in ipairs(CLAUSE_BOUNDARIES) do
    local search_from = 1
    while true do
      local found = text:find(boundary, search_from, true)
      if not found or found >= byte_pos then
        break
      end
      if found > last_boundary then
        last_boundary = found
      end
      search_from = found + #boundary
    end
  end

  local clause_start = last_boundary + 1
  for _, prefix in ipairs(prefixes) do
    local search_from = clause_start
    while true do
      local found = text:find(prefix, search_from, true)
      if not found or found >= byte_pos then
        break
      end

      local span = text:sub(found, byte_pos + #"了" - 1)
      if core.visible_length(span) <= max_distance then
        return found
      end
      search_from = found + #prefix
    end
  end

  return nil
end

local function find_final_clause(text)
  local last_boundary = 0
  for _, boundary in ipairs(CLAUSE_BOUNDARIES) do
    local search_from = 1
    while true do
      local found = text:find(boundary, search_from, true)
      if not found then
        break
      end
      if found + #boundary - 1 < #text and found > last_boundary then
        last_boundary = found
      end
      search_from = found + #boundary
    end
  end

  local clause_start = last_boundary + 1
  return text:sub(clause_start), clause_start
end

local function contains_definite_marker(text)
  return has_any_plain(text, DEFINITE_MARKERS)
end

local function is_clause_start_before(text, byte_pos)
  local prev_char = previous_utf8_char(text, byte_pos)
  if not prev_char then
    return true
  end
  return
    prev_char:match("%s") ~= nil or
    has_any_plain(prev_char, { "，", "。", "；", "：", ",", ";", "!", "?", "（", "(" })
end

local RULES

RULES = {
  {
    id = "L001",
    status = "lint-ready",
    summary = "sentence-per-line artifact",
    warning_message = "可能殘留 sentence-per-line / extraction artifact，建議改回正常段落",
    run = function(document, issues, rule)
      for _, paragraph in ipairs(document.paragraphs) do
        if paragraph.line_count >= 3 then
          local short_line_count = 0
          local sentence_like_count = 0
          for _, line in ipairs(paragraph.lines) do
            local length = core.visible_length(line.text)
            if length >= 8 and length <= 60 then
              short_line_count = short_line_count + 1
            end
            if core.is_sentence_like(line.text) then
              sentence_like_count = sentence_like_count + 1
            end
          end
          if short_line_count == paragraph.line_count and sentence_like_count >= 2 then
            add_issue(issues, document, rule, paragraph.start_line, 1)
          end
        end
      end
    end,
  },
  {
    id = "L002",
    status = "lint-hybrid",
    summary = "prose hard wrap without blank line",
    warning_message = "一般 prose 不應只換行不分段，請合併成單段或補空行",
    run = function(document, issues, rule)
      for _, paragraph in ipairs(document.paragraphs) do
        if paragraph.line_count >= 2 then
          add_issue(issues, document, rule, paragraph.start_line, 1)
        end
      end
    end,
  },
  {
    id = "L003",
    status = "lint-ready",
    summary = "colon followed by list without blank line",
    warning_message = "一般段落以全形冒號引出清單時，冒號後應保留空行",
    run = function(document, issues, rule)
      for index = 1, #document.lines - 1 do
        local line = document.lines[index]
        local next_line = document.lines[index + 1]
        if
          not line.is_code and
          not line.is_list and
          line.stripped:find("：$") and
          next_line.is_list and
          next_line.list_indent == 0
        then
          add_issue(issues, document, rule, line.number, #line.text)
        end
      end
    end,
  },
  {
    id = "L004",
    status = "lint-ready",
    summary = "extra blank lines between list items",
    warning_message = "相鄰 list item 或巢狀清單前不應有多餘空行",
    run = function(document, issues, rule)
      for index, line in ipairs(document.lines) do
        if line.is_blank then
          local prev_line = document.lines[index - 1]
          local next_line = document.lines[index + 1]
          if prev_line and next_line and prev_line.is_list and next_line.is_list then
            local allow_spacious_long_items =
              prev_line.list_indent == 0 and
              next_line.list_indent == 0 and
              (core.visible_length(prev_line.text) >= 60 or core.visible_length(next_line.text) >= 60)
            if not allow_spacious_long_items then
              add_issue(issues, document, rule, line.number, 1)
            end
          end
        end
      end
    end,
  },
  {
    id = "L005",
    status = "lint-ready",
    enabled_by_default = false,
    summary = "raw html presentational wrapper",
    warning_message = "偵測到純呈現層 HTML / CSS，應改為 Markdown 或移除",
    run = function(document, issues, rule)
      local patterns = {
        "<style",
        "style=",
        "<div",
        "</div>",
        "<span",
        "</span>",
        "<font",
        "</font>",
        "<center",
        "</center>",
        "class=",
      }
      for _, line in ipairs(document.lines) do
        if not line.is_code then
          local lowered = line.masked_text:lower()
          for _, pattern in ipairs(patterns) do
            local col = lowered:find(pattern, 1, true)
            if col then
              add_issue(issues, document, rule, line.number, col)
              break
            end
          end
        end
      end
    end,
  },
  {
    id = "L006",
    status = "lint-ready",
    summary = "source extraction artifact leftover",
    warning_message = "偵測到來源抽取中介痕跡，正式輸出不應保留",
    run = function(document, issues, rule)
      local patterns = {
        "_page_%d+",
        "page_%d+%.png",
        "^Page%s+%d+$",
        "^第?%d+頁$",
      }
      for _, line in ipairs(document.lines) do
        if not line.is_code and not is_markdown_image_line(line) then
          for _, pattern in ipairs(patterns) do
            local col = line.masked_text:find(pattern)
            if col then
              add_issue(issues, document, rule, line.number, col)
              break
            end
          end
        end
      end
    end,
  },
  {
    id = "L007",
    status = "lint-ready",
    summary = "anti-pattern stock phrase",
    warning_message = "偵測到 stock anti-pattern 句型，建議改為直接陳述",
    run = function(document, issues, rule)
      local reported = {}
      local function report(line_number, col)
        local key = line_number .. ":" .. col
        if reported[key] then
          return
        end
        reported[key] = true
        add_issue(issues, document, rule, line_number, col)
      end

      local opener_bare_patterns = {
        "不是",
        "所謂",
        "這也意味著",
      }
      local first = document.first_paragraph
      if first then
        local opener = core.mask_inline_code(first.text)
        for _, pattern in ipairs(opener_bare_patterns) do
          local col = opener:find(pattern, 1, true)
          if col and col <= 12 then
            report(first.start_line, col)
            break
          end
        end
      end

      local pair_patterns = {
        { first = "不是", second = "而是" },
        { first = "所謂", second = "就是" },
        { first = "可被", second = "所" },
      }
      local standalone_patterns = {
        "這也意味著",
        "被組織成",
        "為目標來",
        "一種常見方法",
        "指令取回後",
        "文獻中被提出",
      }

      for _, paragraph in ipairs(document.paragraphs) do
        local masked_lines = {}
        for _, line in ipairs(paragraph.lines) do
          table.insert(masked_lines, core.mask_inline_code(line.text))
        end

        for _, pair in ipairs(pair_patterns) do
          for i, masked in ipairs(masked_lines) do
            local search_from = 1
            while true do
              local first_col = masked:find(pair.first, search_from, true)
              if not first_col then
                break
              end
              local found_second = false
              local rest = masked:sub(first_col + #pair.first)
              if rest:find(pair.second, 1, true) then
                found_second = true
              else
                for j = i + 1, #masked_lines do
                  if masked_lines[j]:find(pair.second, 1, true) then
                    found_second = true
                    break
                  end
                end
              end
              if found_second then
                report(paragraph.lines[i].number, first_col)
              end
              search_from = first_col + #pair.first
            end
          end
        end

        for _, pattern in ipairs(standalone_patterns) do
          for i, masked in ipairs(masked_lines) do
            local search_from = 1
            while true do
              local col = masked:find(pattern, search_from, true)
              if not col then
                break
              end
              report(paragraph.lines[i].number, col)
              search_from = col + #pattern
            end
          end
        end
      end
    end,
  },
  {
    id = "L008",
    status = "lint-ready",
    summary = "long de chain",
    warning_message = "可能存在過長的「的」鏈，建議改寫成子句、拆句或後置說明",
    run = function(document, issues, rule)
      for _, line in ipairs(prose_lines(document)) do
        local col = find_dense_de_chain_col(line.masked_text)
        if col then
          add_issue(issues, document, rule, line.number, col)
        end
      end
    end,
  },
  {
    id = "L015",
    status = "lint-ready",
    summary = "academic citation missing reference section",
    warning_message = "academic citation apparatus 似乎不完整，請檢查正文標記與 reference section 是否成套出現",
    run = function(document, issues, rule)
      local citations = formal_citation_links(document.prose_text or document.text)
      local has_heading = has_reference_heading(document)
      local entries = bibliography_section_lines(document)
      local has_anchor = false

      for _, entry in ipairs(entries) do
        if entry.anchor_id then
          has_anchor = true
          break
        end
      end

      if (#citations > 0 and not has_heading) or (#citations > 0 and not has_anchor) then
        add_file_issue(issues, document, rule)
      end
    end,
  },
  {
    id = "L016",
    status = "lint-ready",
    summary = "academic citation broken mapping",
    warning_message = "citation 編號與 reference list 可能沒有一一對上，請檢查缺漏、重複項或 id 與顯示編號不一致",
    run = function(document, issues, rule)
      local citations = formal_citation_links(document.prose_text or document.text)
      local entries = bibliography_section_lines(document)
      local anchor_to_label = {}
      local label_to_anchor = {}

      for _, entry in ipairs(entries) do
        if entry.anchor_id then
          if anchor_to_label[entry.anchor_id] then
            add_file_issue(issues, document, rule)
            return
          end
          if label_to_anchor[entry.label] and label_to_anchor[entry.label] ~= entry.anchor_id then
            add_file_issue(issues, document, rule)
            return
          end

          anchor_to_label[entry.anchor_id] = entry.label
          label_to_anchor[entry.label] = entry.anchor_id
        end
      end

      for _, citation in ipairs(citations) do
        local entry_label = anchor_to_label[citation.target]
        if not entry_label or entry_label ~= citation.label then
          add_file_issue(issues, document, rule)
          return
        end
      end
    end,
  },
  {
    id = "L017",
    status = "lint-ready",
    summary = "preflight or selfcheck leftover",
    warning_message = "正式輸出不應保留 preflight / 自檢 / TODO 類中介區塊",
    run = function(document, issues, rule)
      local patterns = {
        "開工前檢查",
        "preflight",
        "自檢",
        "驗證關卡",
        "TODO",
      }
      for _, line in ipairs(document.lines) do
        if not line.is_code then
          for _, pattern in ipairs(patterns) do
            local col = line.masked_text:find(pattern, 1, true)
            if col and (line.is_heading or line.masked_text:match("^%s*[-*]") or line.masked_text:match("^%s*%d+%.")) then
              add_issue(issues, document, rule, line.number, col)
              break
            end
          end
        end
      end
    end,
  },
  {
    id = "L018",
    status = "lint-ready",
    summary = "dialogue trace leftover",
    warning_message = "正式輸出不應保留對話痕跡或角色標籤",
    run = function(document, issues, rule)
      local pattern = "^%s*(使用者：|assistant:|user:|system:)"
      for _, line in ipairs(document.lines) do
        if not line.is_code and line.masked_text:match(pattern) then
          add_issue(issues, document, rule, line.number, core.first_nonspace_col(line.text))
        end
      end
    end,
  },
  {
    id = "L020",
    status = "lint-ready",
    summary = "paragraph too dense",
    warning_message = "這段可能過密，請檢查是否應拆段或重排資訊",
    run = function(document, issues, rule)
      for _, paragraph in ipairs(document.paragraphs) do
        local sentence_count = count_strong_sentences(paragraph.text)
        local semicolon_count = core.count_substring(paragraph.text, "；") + core.count_substring(paragraph.text, ";")
        if
          paragraph.line_count > 7 or
          paragraph.visible_length >= 520 or
          (paragraph.visible_length >= 280 and sentence_count >= 4) or
          (paragraph.visible_length >= 180 and semicolon_count >= 2)
        then
          add_issue(issues, document, rule, paragraph.start_line, 1)
        end
      end
    end,
  },
  {
    id = "L021",
    status = "lint-ready",
    summary = "semicolon overuse",
    warning_message = "這裡的分號可能沒有必要，若不是平行列舉同一目的下的不同對象，請拆句、改逗號或重寫",
    run = function(document, issues, rule)
      for _, line in ipairs(document.lines) do
        if
          not line.is_blank and
          not line.is_code and
          not line.is_tag and
          not line.is_heading and
          not line.is_table and
          not line.is_blockquote
        then
        local stripped = core.trim(line.masked_text)
        if stripped:match("^<") == nil then
          local count = core.count_substring(line.masked_text, "；") + core.count_substring(line.masked_text, ";")
          if count >= 2 then
            local pos = line.masked_text:find("；", 1, true) or line.masked_text:find(";", 1, true) or 1
            add_issue(issues, document, rule, line.number, pos)
          elseif count == 1 and core.visible_length(stripped) <= 70 then
            local pos, token
            if line.masked_text:find("；", 1, true) then
              pos = line.masked_text:find("；", 1, true)
              token = "；"
            elseif line.masked_text:find(";", 1, true) then
              pos = line.masked_text:find(";", 1, true)
              token = ";"
            end

            if pos and token then
              local before = core.trim(line.masked_text:sub(1, pos - 1):gsub("^[-*+]%s+", ""))
              local after = core.trim(line.masked_text:sub(pos + #token))
              if core.visible_length(before) >= 6 and core.visible_length(after) >= 6 then
                add_issue(issues, document, rule, line.number, pos)
              end
            end
          end
        end
        end
      end
    end,
  },
  {
    id = "L022",
    status = "lint-ready",
    summary = "simplified Chinese present",
    warning_message = "偵測到疑似簡體中文寫法，請改回繁體臺灣用語",
    run = function(document, issues, rule)
      for _, line in ipairs(document.lines) do
        if
          not line.is_blank and
          not line.is_code and
          not line.is_tag and
          not line.is_directive
        then
          for _, item in ipairs(core.codepoints(line.masked_text)) do
            if SIMPLIFIED_CHARS[item.cp] then
              add_issue(issues, document, rule, line.number, item.pos)
              break
            end
          end
        end
      end
    end,
  },
  {
    id = "L023",
    status = "lint-ready",
    summary = "ASCII quote in CJK prose",
    warning_message = "中文 prose 的引號建議使用「」或『』，不要直接沿用 ASCII 雙引號",
    run = function(document, issues, rule)
      for _, line in ipairs(prose_lines(document)) do
        local search_from = 1
        while true do
          local open_pos = line.masked_text:find('"', search_from, true)
          if not open_pos then
            break
          end
          local close_pos = line.masked_text:find('"', open_pos + 1, true)
          if not close_pos then
            break
          end
          local content = line.masked_text:sub(open_pos + 1, close_pos - 1)
          if core.contains_cjk(content) then
            add_issue(issues, document, rule, line.number, open_pos)
            break
          end
          search_from = close_pos + 1
        end
      end
    end,
  },
  {
    id = "L024",
    status = "lint-ready",
    summary = "halfwidth punctuation in CJK prose",
    warning_message = "中文 prose 可能誤用了半形標點，請檢查是否應改成全形中文標點",
    run = function(document, issues, rule)
      local targets = {
        [string.byte(",")] = true,
        [string.byte(";")] = true,
        [string.byte(":")] = true,
      }

      for _, line in ipairs(prose_lines(document)) do
        local codepoints = core.codepoints(line.masked_text)
        for index, item in ipairs(codepoints) do
          if targets[item.cp] then
            local prev_item = core.previous_nonspace(codepoints, index)
            local next_item = core.next_nonspace(codepoints, index)
            local surrounded_by_cjk = prev_item and next_item and core.is_cjk(prev_item.cp) and core.is_cjk(next_item.cp)
            local colon_after_cjk = item.cp == string.byte(":") and prev_item and core.is_cjk(prev_item.cp) and not next_item
            if surrounded_by_cjk or colon_after_cjk then
              add_issue(issues, document, rule, line.number, item.pos)
              break
            end
          end
        end
      end
    end,
  },
  {
    id = "L025",
    status = "lint-ready",
    enabled_by_default = false,
    summary = "halfwidth parentheses without spacing",
    warning_message = "半形括號若出現在中文 prose 中，括號與周圍中文之間應保留半形空格。 注意：本 workspace 的標準修法是改成全形括號（見 L044），本條僅在選擇保留半形括號時使用",
    run = function(document, issues, rule)
      for _, line in ipairs(prose_lines(document)) do
        local codepoints = core.codepoints(line.masked_text)
        local link_spans = markdown_link_spans(line.masked_text)
        for index, item in ipairs(codepoints) do
          if col_in_markdown_link_hidden_span(link_spans, item.pos) then
            -- URL parentheses are Markdown syntax, not visible prose punctuation.
          elseif item.cp == string.byte("(") then
            local prev_item = codepoints[index - 1]
            if prev_item and core.is_cjk(prev_item.cp) then
              add_issue(issues, document, rule, line.number, item.pos)
              break
            end
          elseif item.cp == string.byte(")") then
            local next_item = codepoints[index + 1]
            if next_item and core.is_cjk(next_item.cp) then
              add_issue(issues, document, rule, line.number, item.pos)
              break
            end
          end
        end
      end
    end,
  },
  {
    id = "L026",
    status = "lint-ready",
    summary = "fullwidth parentheses around code-like latin",
    warning_message = "code-like 純英文、數字或符號內容建議改用半形括號",
    run = function(document, issues, rule)
      for _, line in ipairs(prose_lines(document)) do
        if not is_markdown_image_line(line) and not core.contains_cjk(line.masked_text) then
          local bilingual_cols = {}
          for _, pair in ipairs(core.extract_bilingual_pairs(line.masked_text)) do
            bilingual_cols[pair.col] = true
          end
          local search_from = 1
          while true do
            local open_pos = line.masked_text:find("（", search_from, true)
            if not open_pos then
              break
            end
            local close_pos = line.masked_text:find("）", open_pos + 3, true)
            if not close_pos then
              break
            end
            local content = line.masked_text:sub(open_pos + 3, close_pos - 1)
            if is_code_like_ascii_parenthetical(content) and not bilingual_cols[open_pos] then
              add_issue(issues, document, rule, line.number, open_pos)
              break
            end
            search_from = close_pos + 3
          end
        end
      end
    end,
  },
  {
    id = "L027",
    status = "lint-hybrid",
    summary = "terminal fullwidth period in markdown prose",
    warning_message = "本 workspace 的 Markdown 技術 prose 通常省略段末句號，請檢查這裡是否需要保留",
    run = function(document, issues, rule)
      for _, line in ipairs(prose_lines(document)) do
        if line.masked_text:find("。%s*$") then
          add_issue(issues, document, rule, line.number, #line.text)
        end
      end
    end,
  },
  {
    id = "L028",
    status = "lint-ready",
    summary = "dash as punctuation",
    warning_message = "偵測到破折號，請檢查是否該改用逗號、冒號、括號、分句或重寫處理",
    run = function(document, issues, rule)
      local dash_patterns = { "─", "—", "–" }
      for _, line in ipairs(document.lines) do
        if not line.is_code and not line.is_blockquote and not line.is_table then
          for _, pattern in ipairs(dash_patterns) do
            local search_from = 1
            while true do
              local col = line.masked_text:find(pattern, search_from, true)
              if not col then
                break
              end
              add_issue(issues, document, rule, line.number, col)
              search_from = col + #pattern
            end
          end
        end
      end
    end,
  },
  {
    id = "L029",
    status = "lint-hybrid",
    summary = "inline enumeration without final conjunction",
    warning_message = "中文 prose 的行內列舉最後一項前通常建議補「與 / 及 / 或」，請檢查這裡是否需要",
    run = function(document, issues, rule)
      for _, line in ipairs(prose_lines(document)) do
        if core.count_substring(line.masked_text, "、") >= 2 then
          local masked_text = strip_terminal_fullwidth_punctuation(line.masked_text)
          local original_text = strip_terminal_fullwidth_punctuation(line.text)
          local suffix = text_after_last_plain(masked_text, "、")
          local original_suffix = text_after_last_plain(original_text, "、")
          local has_final_conjunction =
            has_inline_final_conjunction(suffix or "") or has_inline_final_conjunction(original_suffix or "")
          if suffix and not has_final_conjunction then
            local col = line.masked_text:find("、", 1, true) or 1
            add_issue(issues, document, rule, line.number, col)
          end
        end
      end
    end,
  },
  {
    id = "L030",
    status = "lint-ready",
    summary = "repeated bilingual term pair",
    warning_message = "這個雙語術語已經介紹過，後文通常應固定單一形式，不必重複整組雙語對",
    run = function(document, issues, rule)
      local seen = {}
      for _, line in ipairs(document.lines) do
        if not line.is_code then
          for _, pair in ipairs(core.extract_bilingual_pairs(line.masked_text)) do
            if is_term_like_chinese(pair.chinese) then
              local english = core.normalize_english_term(pair.english)
              local chinese = core.normalize_chinese_term(pair.chinese)
              local key = english .. "||" .. chinese
              if seen[key] then
                add_issue(issues, document, rule, line.number, pair.col)
              else
                seen[key] = true
              end
            end
          end
        end
      end
    end,
  },
  {
    id = "L113",
    status = "lint-ready",
    summary = "focus shi inside predicate",
    warning_message = "這裡的「是」可能插進了不自然的謂語內部位置，請檢查是否應改回普通句",
    run = function(document, issues, rule)
      local patterns = {
        "把[^。；，\n]-是",
        "被[^。；，\n]-是",
      }
      for _, line in ipairs(prose_lines(document)) do
        for _, pattern in ipairs(patterns) do
          local col = line.masked_text:find(pattern)
          if col then
            add_issue(issues, document, rule, line.number, col)
            break
          end
        end
      end
    end,
  },
  {
    id = "L126",
    status = "lint-ready",
    summary = "stacked discourse marker chain",
    warning_message = "這裡可能把連接詞堆成一串，請保留最小必要的一個就好",
    run = function(document, issues, rule)
      local patterns = {
        "因此所以",
        "因此，但",
        "然而但是",
        "但是然而",
        "此外同時",
        "同時此外",
      }
      for _, line in ipairs(prose_lines(document)) do
        for _, pattern in ipairs(patterns) do
          local col = line.masked_text:find(pattern, 1, true)
          if col then
            add_issue(issues, document, rule, line.number, col)
            break
          end
        end
      end
    end,
  },
  {
    id = "L019",
    status = "lint-hybrid",
    summary = "source text block leftover",
    warning_message = "正式輸出可能殘留原文或對照區塊，請確認這不是中介草稿內容",
    run = function(document, issues, rule)
      local patterns = {
        "^#+%s*原文%s*$",
        "^#+%s*source text%s*$",
        "^#+%s*譯文對照%s*$",
        "^%s*原文：",
        "^%s*譯文：",
        "^%s*source：",
        "^%s*translation：",
      }
      for _, line in ipairs(document.lines) do
        if not line.is_code then
          local lowered = line.masked_text:lower()
          for _, pattern in ipairs(patterns) do
            if lowered:match(pattern) then
              add_issue(issues, document, rule, line.number, core.first_nonspace_col(line.text))
              break
            end
          end
        end
      end
    end,
  },
  {
    id = "L031",
    status = "lint-hybrid",
    summary = "term form drift after first bilingual",
    warning_message = "這個術語在首次介紹後可能出現形式漂移，請固定 downstream form",
    run = function(document, issues, rule)
      local seen = {}
      for _, line in ipairs(document.lines) do
        if not line.is_code and not line.is_table then
          for _, pair in ipairs(core.extract_bilingual_pairs(line.masked_text)) do
            if is_term_like_chinese(pair.chinese) then
              local english = core.normalize_english_term(pair.english)
              local chinese = core.normalize_chinese_term(pair.chinese)
              local previous = seen[english]
              if previous and previous ~= chinese then
                add_issue(issues, document, rule, line.number, pair.col)
              else
                seen[english] = chinese
              end
            end
          end
        end
      end
    end,
  },
  {
    id = "L033",
    status = "lint-hybrid",
    summary = "unexpanded workspace jargon",
    warning_message = "這個內部術語首次出現時可能沒有展開，請補一句白話說明或具體例子",
    run = function(document, issues, rule)
      local seen = {}
      local lines = prose_lines(document)
      for index, line in ipairs(lines) do
        local next_line = lines[index + 1]
        local combined = line.text .. " " .. (next_line and next_line.text or "")
        for _, jargon in ipairs(WORKSPACE_JARGON) do
          local col = line.masked_text:find(jargon, 1, true)
          if col and not seen[jargon] then
            seen[jargon] = true
            if not has_expansion_signal(combined) then
              add_issue(issues, document, rule, line.number, col)
            end
          end
        end
      end
    end,
  },
  {
    id = "L032",
    status = "lint-ready",
    summary = "glossary preferred form mismatch",
    warning_message = "這個雙語術語的中文形式和 glossary 偏好譯法不一致，請確認是否要改回既定術語",
    run = function(document, issues, rule)
      local glossary = document.glossary or {}
      if next(glossary) == nil then
        return
      end

      for _, line in ipairs(document.lines) do
        if not line.is_code and not line.is_table then
          for _, pair in ipairs(core.extract_bilingual_pairs(line.masked_text)) do
            if is_term_like_chinese(pair.chinese) then
              local english = core.normalize_english_term(pair.english)
              local chinese = core.normalize_chinese_term(pair.chinese)
              local entry = glossary[english]
              if entry and chinese ~= "" and not matches_glossary_preferred_form(entry, chinese) then
                add_issue(issues, document, rule, line.number, pair.col)
              end
            end
          end
        end
      end
    end,
  },
  {
    id = "L034",
    status = "lint-hybrid",
    summary = "taxonomy only summary",
    warning_message = "這段可能退化成純 taxonomy 摘要，請補一個具體檔案、規則、決策或例子",
    run = function(document, issues, rule)
      for _, paragraph in ipairs(document.paragraphs) do
        local text = paragraph.text
        if paragraph.visible_length >= 24 then
          local abstract_hits = count_term_hits(text, ABSTRACT_TAXONOMY_TERMS)
          if abstract_hits >= 3 and not has_concrete_anchor(text) and not has_expansion_signal(text) then
            add_issue(issues, document, rule, paragraph.start_line, 1)
          end
        end
      end
    end,
  },
  {
    id = "L130",
    status = "lint-hybrid",
    summary = "internal control label leaked into formal prose",
    warning_message = "這裡可能把內部 workflow 控制詞直接寫進正式中文，建議改成完整句子，說明誰在什麼情況下做什麼",
    run = function(document, issues, rule)
      for _, line in ipairs(visible_text_lines(document)) do
        local col = find_internal_control_label_col(line)
        if col then
          add_issue(issues, document, rule, line.number, col)
        end
      end
    end,
  },
  {
    id = "L035",
    status = "lint-ready",
    summary = "huixie lexical misuse outside write-back term",
    warning_message = "「回寫」通常保留給 write-back 類技術術語。若這裡只是一般寫入、寫回或更新動作，建議改成更精確的詞",
    run = function(document, issues, rule)
      for _, line in ipairs(document.lines) do
        if is_noncode_text_line(line) then
          local search_from = 1
          while true do
            local col = line.masked_text:find("回寫", search_from, true)
            if not col then
              break
            end

            if not is_write_back_term_usage(line.masked_text, col) then
              add_issue(issues, document, rule, line.number, col)
              break
            end

            search_from = col + #"回寫"
          end
        end
      end
    end,
  },
  {
    id = "L125",
    status = "lint-hybrid",
    summary = "paired conjunction incomplete",
    warning_message = "這裡的成對連接詞可能沒有補完整，請檢查中文的對比 / 因果骨架是否清楚",
    run = function(document, issues, rule)
      local groups = {
        { openers = { "雖然" }, closers = { "但", "但是", "不過", "仍然", "仍", "卻" } },
        { openers = { "不但", "不僅", "不只" }, closers = { "而且", "還", "也" } },
      }

      for _, paragraph in ipairs(document.paragraphs) do
        local text = paragraph.text
        if not text:find("：%s*$") then
          for _, group in ipairs(groups) do
            local line_number, col = find_any_in_lines(paragraph.lines, group.openers)
            if line_number and not has_any_plain(text, group.closers) then
              add_issue(issues, document, rule, line_number, col)
              break
            end
          end
        end
      end
    end,
  },
  {
    id = "L127",
    status = "lint-hybrid",
    summary = "imminent event without sentence final le",
    warning_message = "這個將至事件句可能少了句尾「了」，請檢查是否應寫成「快要……了 / 就要……了」",
    run = function(document, issues, rule)
      local openers = { "快要", "就要" }

      for _, line in ipairs(document.lines) do
        if is_noncode_text_line(line) then
          for _, opener in ipairs(openers) do
            local search_from = 1
            while true do
              local col = line.masked_text:find(opener, search_from, true)
              if not col then
                break
              end

              local boundary = find_next_plain(line.masked_text, CLAUSE_BOUNDARIES, col + #opener)
              local clause = boundary and line.masked_text:sub(col, boundary - 1) or line.masked_text:sub(col)
              if
                not clause:find("了", 1, true) and
                not is_temporal_subordinate_clause(clause) and
                not has_any_plain(clause, { "就要主動", "就要直接", "就要先", "就要再", "就要立即", "就要立刻" })
              then
                add_issue(issues, document, rule, line.number, col)
                break
              end

              search_from = col + #opener
            end
          end
        end
      end
    end,
  },
  {
    id = "L128",
    status = "lint-hybrid",
    summary = "completed event negated with bu",
    warning_message = "這裡若是否定已完成事件，通常應優先用「沒 / 沒有」而不是「不」",
    run = function(document, issues, rule)
      for _, line in ipairs(document.lines) do
        if is_noncode_text_line(line) then
          for _, verb in ipairs(COMPLETION_EVENT_VERBS) do
            local pattern = "不" .. verb .. "了"
            local search_from = 1
            while true do
              local col = line.masked_text:find(pattern, search_from, true)
              if not col then
                break
              end

              local end_pos = col + #pattern - 1
              local boundary = find_next_plain(line.masked_text, CLAUSE_BOUNDARIES, end_pos + 1)
              local clause = boundary and line.masked_text:sub(col, boundary - 1) or line.masked_text:sub(col)
              local tail = core.trim(clause:sub(#pattern + 1))
              if core.visible_length(tail) >= 2 then
                add_issue(issues, document, rule, line.number, col)
                break
              end

              search_from = col + #pattern
            end
          end
        end
      end
    end,
  },
  {
    id = "L120",
    status = "lint-hybrid",
    summary = "you plus verb as generic aspect marker",
    warning_message = "這裡的「有 + V」可能只是口氣填充或泛用完成標記，請檢查是否應改成普通句、已、曾或句尾「了」",
    run = function(document, issues, rule)
      for _, line in ipairs(document.lines) do
        if is_noncode_text_line(line) then
          for _, verb in ipairs(GENERIC_YOU_VERBS) do
            local pattern = "有" .. verb
            local search_from = 1
            while true do
              local col = line.masked_text:find(pattern, search_from, true)
              if not col then
                break
              end

              local prev_char = previous_utf8_char(line.masked_text, col)
              if prev_char ~= "沒" and prev_char ~= "没" and prev_char ~= "所" then
                add_issue(issues, document, rule, line.number, col)
                break
              end

              search_from = col + #pattern
            end
          end
        end
      end
    end,
  },
  {
    id = "L009",
    status = "lint-hybrid",
    summary = "repeated subject chain",
    warning_message = "相鄰子句可能重複主語，請檢查是否可改為 topic chain",
    run = function(document, issues, rule)
      for _, line in ipairs(prose_lines(document)) do
        for _, segment in ipairs(split_strong_sentences(line.masked_text)) do
          for _, head in ipairs(REPEATED_SUBJECT_HEADS) do
            local escaped = core.escape_pattern(head)
            local pattern = escaped .. ".-[，；]" .. escaped
            local col = segment.text:find(pattern)
            if col then
              add_issue(issues, document, rule, line.number, segment.start_pos + col - 1)
              break
            end
          end
        end
      end
    end,
  },
  {
    id = "L010",
    status = "lint-hybrid",
    summary = "passive overuse",
    warning_message = "這裡可能機械沿用了被動句，請檢查是否應改為主動、無主句或框架先行",
    run = function(document, issues, rule)
      for _, line in ipairs(prose_lines(document)) do
        for _, segment in ipairs(split_strong_sentences(line.masked_text)) do
          if core.count_substring(segment.text, "被") >= 2 then
            local col = segment.text:find("被", 1, true) or 1
            add_issue(issues, document, rule, line.number, segment.start_pos + col - 1)
            break
          end
        end
      end
    end,
  },
  {
    id = "L011",
    status = "lint-hybrid",
    summary = "ba without result state",
    warning_message = "這個「把」字句可能沒有清楚的處置 / 結果語義，請再確認",
    run = function(document, issues, rule)
      for _, line in ipairs(prose_lines(document)) do
        local col = line.masked_text:find("把", 1, true)
        if col then
          local clause = clause_window(line.masked_text, col)
          if
            core.visible_length(clause) <= 22 and
            has_any_plain(clause, BARE_BA_VERBS) and
            not has_any_plain(clause, { "把字句", "把字", "語義", "結構", "補語" }) and
            not has_result_marker(clause)
          then
            add_issue(issues, document, rule, line.number, col)
          end
        end
      end
    end,
  },
  {
    id = "L012",
    status = "lint-hybrid",
    summary = "de di de confusion",
    warning_message = "這裡可能有「的 / 地 / 得」使用問題",
    run = function(document, issues, rule)
      local patterns = {
        "的很",
        "地流程",
        "地方法",
        "地測試",
        "得流程",
        "得方法",
        "得測試",
      }
      local function should_ignore(pattern, text, col)
        if pattern == "的很" then
          local prev = text:sub(col - #"真", col - 1)
          return prev == "真"
        end
        if pattern == "地測試" then
          local prev = text:sub(col - #"可靠", col - 1)
          return prev == "可靠"
        end
        return false
      end

      for _, line in ipairs(prose_lines(document)) do
        local reported = false
        for _, pattern in ipairs(patterns) do
          local search_from = 1
          while not reported do
            local col = line.masked_text:find(pattern, search_from, true)
            if not col then
              break
            end
            if not should_ignore(pattern, line.masked_text, col) then
              add_issue(issues, document, rule, line.number, col)
              reported = true
              break
            end
            search_from = col + #pattern
          end
          if reported then
            break
          end
        end
      end
    end,
  },
  {
    id = "L013",
    status = "lint-hybrid",
    summary = "aspect le mismatch",
    warning_message = "這裡的「了」可能是誤用的完成體；若是句尾狀態變化標記（如 終於…了 / 愈來愈…了 / 現在…了 / 變得…了），應保留，只有在誤接於習慣／定義／靜態 predicate 後才移除",
    run = function(document, issues, rule)
      local suspicious_prefixes = {
        "每天", "通常", "一般", "常常", "慣常", "定義上",
        "代表", "屬於", "負責", "用來",
      }

      local state_change_signals = {
        "快要", "就要", "已經", "曾", "剛", "沒有", "沒",
        "終於", "總算", "才", "現在", "如今", "從此", "最近",
        "愈來愈", "越來越", "變得", "變成", "開始", "更",
      }

      for _, line in ipairs(prose_lines(document)) do
        if not has_any_plain(line.masked_text, state_change_signals) then
          local search_from = 1
          while true do
            local col = line.masked_text:find("了", search_from, true)
            if not col then
              break
            end

            if not is_lexical_le(line.masked_text, col) then
              local prefix_col = find_nearby_prefix_before(line.masked_text, col, suspicious_prefixes, 12)
              if prefix_col then
                add_issue(issues, document, rule, line.number, col)
                break
              end
            end

            search_from = col + #"了"
          end
        end
      end
    end,
  },
  {
    id = "L101",
    status = "lint-hybrid",
    summary = "nonspecific np fronted as topic",
    warning_message = "這個前置名詞可能是無定短語，請檢查是否真的適合當話題",
    run = function(document, issues, rule)
      for _, line in ipairs(prose_lines(document)) do
        local trimmed = core.trim(line.masked_text)
        local comma = trimmed:find("，", 1, true) or trimmed:find(",", 1, true)
        if comma and comma <= 24 and starts_with_count_phrase(trimmed) and not starts_with_temporal_count_phrase(trimmed) then
          add_issue(issues, document, rule, line.number, core.first_nonspace_col(line.text))
        end
      end
    end,
  },
  {
    id = "L102",
    status = "lint-hybrid",
    summary = "self ziji ambiguity",
    warning_message = "「自己」可能有多重先行詞歧義，請檢查照應是否清楚",
    run = function(document, issues, rule)
      local pronouns = { "他們", "她們", "它們", "他", "她", "它" }
      for _, line in ipairs(prose_lines(document)) do
        local self_pos = line.masked_text:find("自己", 1, true)
        if self_pos then
          local prefix = line.masked_text:sub(1, self_pos - 1)
          local count = count_plain_occurrences(prefix, pronouns)
          if count >= 2 or (count >= 1 and prefix:find("被", 1, true)) then
            add_issue(issues, document, rule, line.number, self_pos)
          end
        end
      end
    end,
  },
  {
    id = "L103",
    status = "lint-hybrid",
    summary = "shi you confusion",
    warning_message = "這裡可能混用了「是」與「有」的功能，請檢查是判斷、存在還是焦點句",
    run = function(document, issues, rule)
      for _, line in ipairs(prose_lines(document)) do
        for _, pattern in ipairs({ "是有", "有是" }) do
          local col = line.masked_text:find(pattern, 1, true)
          local prev_char = col and previous_utf8_char(line.masked_text, col) or nil
          if col and not (pattern == "是有" and prev_char == "還") then
            add_issue(issues, document, rule, line.number, col)
            break
          end
        end
      end
    end,
  },
  {
    id = "L105",
    status = "lint-hybrid",
    summary = "de nominalization overuse",
    warning_message = "這裡可能有過重的「的」字結構或名物化，請檢查是否應改回事件子句",
    run = function(document, issues, rule)
      for _, line in ipairs(prose_lines(document)) do
        if core.count_substring(line.masked_text, "的") >= 2 then
          for _, noun in ipairs(ABSTRACT_EVENT_NOUNS) do
            local pattern = "的" .. noun
            local col = line.masked_text:find(pattern, 1, true)
            if col then
              local tail = trimmed_tail(line.masked_text, col + #pattern)
              if has_nearby_plain(line.masked_text, "的", col, 18) and starts_with_any(tail, EVENT_NOMINALIZATION_TAIL_MARKERS) then
                add_issue(issues, document, rule, line.number, col)
                break
              end
            end
          end
        end
      end
    end,
  },
  {
    id = "L106",
    status = "lint-hybrid",
    summary = "ba object lacks clear reference",
    warning_message = "這個「把」字句後面的名詞可能不是定指或殊指，請檢查是否自然",
    run = function(document, issues, rule)
      local indefinite_markers = { "一個", "一些", "某個", "某種", "很多", "不少", "幾個", "數個", "任何" }
      for _, line in ipairs(prose_lines(document)) do
        local col = line.masked_text:find("把", 1, true)
        if col then
          local rest = core.trim(line.masked_text:sub(col + #"把"))
          if starts_with_count_phrase(rest) or starts_with_any(rest, indefinite_markers) then
            add_issue(issues, document, rule, line.number, col)
          end
        end
      end
    end,
  },
  {
    id = "L107",
    status = "lint-hybrid",
    summary = "ba clause without bounded endpoint",
    warning_message = "這個「把」字句可能缺少有界事件或結果狀態，請檢查是否應改回一般動詞句",
    run = function(document, issues, rule)
      for _, line in ipairs(prose_lines(document)) do
        local col = line.masked_text:find("把", 1, true)
        if col then
          local clause = clause_window(line.masked_text, col)
          if has_any_plain(clause, BARE_BA_VERBS) and not has_result_marker(clause) then
            add_issue(issues, document, rule, line.number, col)
          end
        end
      end
    end,
  },
  {
    id = "L108",
    status = "lint-hybrid",
    summary = "np de vp overcompression",
    warning_message = "這裡可能把事件過度壓成「名詞組 + 的 + 動詞組」書面結構，請檢查是否應還原成事件子句",
    run = function(document, issues, rule)
      for _, line in ipairs(prose_lines(document)) do
        for _, noun in ipairs(ABSTRACT_EVENT_NOUNS) do
          local pattern = "的" .. noun
          local col = line.masked_text:find(pattern, 1, true)
          if col then
            local tail = trimmed_tail(line.masked_text, col + #pattern)
            if starts_with_any(tail, EVENT_NOMINALIZATION_TAIL_MARKERS) then
              add_issue(issues, document, rule, line.number, col)
              break
            end
          end
        end
      end
    end,
  },
  {
    id = "L111",
    status = "lint-hybrid",
    summary = "shou with bare event or resultative complement",
    warning_message = "這個「受 / 受到」後面可能接了不自然的動詞事件或結果結構，請檢查是否應改回主動或「被」句",
    run = function(document, issues, rule)
      for _, line in ipairs(prose_lines(document)) do
        for _, opener in ipairs({ "受", "受到" }) do
          local col = line.masked_text:find(opener, 1, true)
          if col then
            local clause = clause_window(line.masked_text, col + #opener)
            if has_any_plain(clause, SHOU_BARE_EVENT_VERBS) then
              add_issue(issues, document, rule, line.number, col)
              break
            end
          end
        end
      end
    end,
  },
  {
    id = "L112",
    status = "lint-hybrid",
    summary = "you sentence with definite np",
    warning_message = "這個存在句後面的名詞可能是定指成分，請檢查是否其實不適合用「有」引入",
    run = function(document, issues, rule)
      for _, line in ipairs(prose_lines(document)) do
        local search_from = 1
        while true do
          local col = line.masked_text:find("有", search_from, true)
          if not col then
            break
          end

          local prev_char = previous_utf8_char(line.masked_text, col)
          local clause = clause_window(line.masked_text, col + #"有")
          if
            (not prev_char or (prev_char ~= "沒" and prev_char ~= "没" and prev_char ~= "擁")) and
            is_clause_start_before(line.masked_text, col) and
            contains_definite_marker(clause)
          then
            add_issue(issues, document, rule, line.number, col)
            break
          end

          search_from = col + #"有"
        end
      end
    end,
  },
  {
    id = "L114",
    status = "lint-hybrid",
    summary = "descriptive v de with overt object",
    warning_message = "這個「V得...」結構後面可能保留了不自然的顯性賓語，請檢查它是否其實不是結果補語",
    run = function(document, issues, rule)
      for _, line in ipairs(prose_lines(document)) do
        for _, object in ipairs(DESCRIPTION_OBJECTS) do
          for _, degree in ipairs(DEGREE_MARKERS) do
            local pattern = "得" .. object .. degree
            local col = line.masked_text:find(pattern, 1, true)
            if col then
              add_issue(issues, document, rule, line.number, col)
              break
            end
          end
        end
      end
    end,
  },
  {
    id = "L115",
    status = "lint-hybrid",
    summary = "overloaded postverbal stack",
    warning_message = "這裡的動詞後成分可能過度擁擠，請檢查是否應重排語序或拆句",
    run = function(document, issues, rule)
      local complements = { "清楚", "完整", "明白", "完成", "完", "好" }
      for _, line in ipairs(prose_lines(document)) do
        if not line.masked_text:find("得", 1, true) then
          for _, verb in ipairs(OVERLOADED_POSTVERBAL_VERBS) do
            local col = line.masked_text:find(verb, 1, true)
            if col and has_any_plain(line.masked_text, DURATION_OR_COUNT_MARKERS) and has_any_plain(line.masked_text, complements) then
              add_issue(issues, document, rule, line.number, col)
              break
            end
          end
        end
      end
    end,
  },
  {
    id = "L116",
    status = "lint-hybrid",
    summary = "local pronoun used for reflexive meaning",
    warning_message = "這個代詞可能在承擔局部反身指涉，請檢查是否應改成「自己」或明示名詞",
    run = function(document, issues, rule)
      local patterns = {
        "他的",
        "她的",
        "它的",
      }
      for _, line in ipairs(prose_lines(document)) do
        for _, pronoun in ipairs({ "他", "她", "它" }) do
          local clause = line.masked_text
          if clause:find(pronoun, 1, true) and clause:find(pronoun .. "的", 1, true) then
            local first = clause:find(pronoun, 1, true)
            local second = clause:find(pronoun .. "的", first + #pronoun, true)
            if second then
              add_issue(issues, document, rule, line.number, first)
              break
            end
          end
        end
      end
    end,
  },
  {
    id = "L118",
    status = "lint-hybrid",
    summary = "ziji in bei clause dual antecedent ambiguity",
    warning_message = "這個「自己」在被字句中可能同時有兩個候選先行語，請檢查是否需要主動消歧",
    run = function(document, issues, rule)
      for _, line in ipairs(prose_lines(document)) do
        local bei_col = line.masked_text:find("被", 1, true)
        local self_col = line.masked_text:find("自己", 1, true)
        if bei_col and self_col and self_col > bei_col then
          local before = core.trim(line.masked_text:sub(1, bei_col - 1))
          local middle = core.trim(line.masked_text:sub(bei_col + #"被", self_col - 1))
          if core.visible_length(before) >= 1 and core.visible_length(middle) >= 1 then
            add_issue(issues, document, rule, line.number, self_col)
          end
        end
      end
    end,
  },
  {
    id = "L121",
    status = "lint-hybrid",
    summary = "nonagentive subject with control modal",
    warning_message = "這個主語看起來不像能承擔意志或主動選擇，請檢查是否應改成「會 / 可能 / 可以 / 應該」",
    run = function(document, issues, rule)
      for _, line in ipairs(prose_lines(document)) do
        for _, subject in ipairs(NONAGENTIVE_SUBJECTS) do
          local subject_col = line.masked_text:find(subject, 1, true)
          if subject_col then
            local clause = clause_window(line.masked_text, subject_col)
            for _, modal in ipairs(CONTROL_MODALS) do
              local modal_col = clause:find(modal, 1, true)
              if modal_col and modal_col <= 18 then
                add_issue(issues, document, rule, line.number, subject_col)
                break
              end
            end
          end
        end
      end
    end,
  },
  {
    id = "L122",
    status = "lint-hybrid",
    summary = "missing associative de after modifier",
    warning_message = "這裡可能少了結構助詞「的」，請檢查修飾邊界是否清楚",
    run = function(document, issues, rule)
      for _, line in ipairs(prose_lines(document)) do
        for _, phrase in ipairs(HIGH_RISK_MISSING_DE_PHRASES) do
          local col = line.masked_text:find(phrase, 1, true)
          if col then
            add_issue(issues, document, rule, line.number, col)
            break
          end
        end
      end
    end,
  },
  {
    id = "L123",
    status = "lint-hybrid",
    summary = "missing adverbial di after modifier",
    warning_message = "這裡可能少了結構助詞「地」，請檢查修飾關係是否足夠清楚",
    run = function(document, issues, rule)
      for _, line in ipairs(prose_lines(document)) do
        for _, phrase in ipairs(HIGH_RISK_MISSING_DI_PHRASES) do
          local col = line.masked_text:find(phrase, 1, true)
          if col then
            add_issue(issues, document, rule, line.number, col)
            break
          end
        end
      end
    end,
  },
  {
    id = "L124",
    status = "lint-hybrid",
    summary = "missing complement de after verb",
    warning_message = "這裡可能少了結構助詞「得」，請檢查是否需要明確標出補語關係",
    run = function(document, issues, rule)
      for _, line in ipairs(prose_lines(document)) do
        for _, phrase in ipairs(HIGH_RISK_MISSING_COMPLEMENT_DE) do
          local col = line.masked_text:find(phrase, 1, true)
          if col then
            add_issue(issues, document, rule, line.number, col)
            break
          end
        end
      end
    end,
  },
  {
    id = "L129",
    status = "lint-hybrid",
    summary = "count phrase after sentence final le",
    warning_message = "這裡的「了」可能落在句尾位置。若你想表完成體，請檢查是否應改成「V了 + 數量短語」",
    run = function(document, issues, rule)
      local event_count_classifiers = {
        "次", "遍", "回", "輪", "天", "月", "年", "分鐘", "小時",
      }

      for _, line in ipairs(prose_lines(document)) do
        local trimmed = core.trim(line.masked_text)
        if
          trimmed:sub(-#"了") == "了" or
          trimmed:sub(-#"了。") == "了。" or
          trimmed:sub(-#"了！") == "了！" or
          trimmed:sub(-#"了？") == "了？"
        then
          local clause, clause_start = find_final_clause(line.masked_text)
          for _, classifier in ipairs(event_count_classifiers) do
            local digit_col = clause:find("%d+" .. classifier)
            if digit_col and not clause:sub(1, digit_col - 1):find("了", 1, true) then
              add_issue(issues, document, rule, line.number, clause_start + digit_col - 1)
              break
            end
            for _, prefix in ipairs(COUNT_PREFIXES) do
              local phrase = prefix .. classifier
              local col = clause:find(phrase, 1, true)
              if col then
                local absolute_col = clause_start + col - 1
                local prev_char = previous_utf8_char(line.masked_text, absolute_col)
                if prev_char ~= "第" and not clause:sub(1, col - 1):find("了", 1, true) then
                  add_issue(issues, document, rule, line.number, absolute_col)
                  break
                end
              end
            end
          end
        end
      end
    end,
  },
  {
    id = "L036",
    status = "lint-ready",
    summary = "top-level code fence missing surrounding blank line",
    warning_message = "一般 code block 前後應保留空行；若位於 list item 內可依上下文省略",
    run = function(document, issues, rule)
      local in_fence = false
      for index, line in ipairs(document.lines) do
        if line.is_fence then
          if not in_fence then
            if is_top_level_code_fence(line) then
              local prev_line = document.lines[index - 1]
              if prev_line and not prev_line.is_blank and not is_custom_container_opening_line(prev_line) then
                add_issue(issues, document, rule, line.number, core.first_nonspace_col(line.text))
              end
            end
            in_fence = true
          else
            if is_top_level_code_fence(line) then
              local next_line = document.lines[index + 1]
              if next_line and not next_line.is_blank and not is_custom_container_closing_line(next_line) then
                add_issue(issues, document, rule, line.number, core.first_nonspace_col(line.text))
              end
            end
            in_fence = false
          end
        end
      end
    end,
  },
  {
    id = "L037",
    status = "lint-ready",
    summary = "missing space after sentence punctuation",
    warning_message = "同一行內的句號、問號、分號後若還有後續 prose，應保留一個半形空格",
    run = function(document, issues, rule)
      for _, line in ipairs(punctuation_spacing_lines(document)) do
        if not is_markdown_image_line(line) then
          local codepoints = core.codepoints(line.text)
          for index, item in ipairs(codepoints) do
            if SENTENCE_SPACING_PUNCTUATION[item.char] and is_unmasked_char(line, item) then
              local immediate_next = codepoints[index + 1]
              if not (immediate_next and FULLWIDTH_QUOTE_CLOSERS[immediate_next.char]) then
                local cursor = index + 1
                while codepoints[cursor] and SENTENCE_SPACING_CLOSERS[codepoints[cursor].char] do
                  cursor = cursor + 1
                end

                local next_item = codepoints[cursor]
                if
                  next_item and
                  next_item.char ~= " " and
                  not SENTENCE_SPACING_FOLLOWING_PUNCTUATION[next_item.char]
                then
                  add_issue(issues, document, rule, line.number, item.pos)
                end
              end
            end
          end
        end
      end
    end,
  },
  {
    id = "L038",
    status = "lint-ready",
    summary = "missing space between CJK and Latin or number",
    warning_message = "中文與獨立拉丁字詞或阿拉伯數字之間一般應保留一個半形空格",
    run = function(document, issues, rule)
      for _, line in ipairs(punctuation_spacing_lines(document)) do
        if not is_markdown_image_line(line) then
          local codepoints = core.codepoints(line.masked_text)
          for index = 1, #codepoints - 1 do
            local left = codepoints[index]
            local right = codepoints[index + 1]
            if core.is_cjk(left.cp) and is_ascii_alnum(right.cp) then
              if not should_skip_cjk_ascii_spacing_boundary(codepoints, index + 1, index) then
                add_issue(issues, document, rule, line.number, right.pos)
              end
            elseif is_ascii_token_char(left) and core.is_cjk(right.cp) then
              local _, token_end = ascii_token_at(codepoints, index)
              if token_end == index and not should_skip_cjk_ascii_spacing_boundary(codepoints, index, index + 1) then
                add_issue(issues, document, rule, line.number, right.pos)
              end
            end
          end
        end
      end
    end,
  },
  {
    id = "L039",
    status = "lint-ready",
    summary = "custom container fence formatting",
    warning_message = "Markdown custom container fence 應像 code fence 一樣獨立成行：opener/closer 不黏內容，區塊內側不多留空行",
    run = function(document, issues, rule)
      local in_container = false
      for index, line in ipairs(document.lines) do
        if not line.is_code then
          local info = parse_custom_container_marker(line.text)
          if info then
            if info.marker_len ~= 3 then
              add_issue(issues, document, rule, line.number, core.first_nonspace_col(line.text))
            end

            if info.is_closing then
              if in_container then
                local prev_line = document.lines[index - 1]
                if prev_line and prev_line.is_blank then
                  add_issue(issues, document, rule, line.number, core.first_nonspace_col(line.text))
                end

                if is_top_level_custom_container_marker(info) then
                  local next_line = document.lines[index + 1]
                  if next_line and not next_line.is_blank then
                    add_issue(issues, document, rule, line.number, core.first_nonspace_col(line.text))
                  end
                end

                in_container = false
              end
            else
              if info.has_space_after_marker or not info.label or core.trim(info.label_tail) ~= "" then
                add_issue(issues, document, rule, line.number, core.first_nonspace_col(line.text))
              end

              if is_top_level_custom_container_marker(info) then
                local prev_line = document.lines[index - 1]
                if prev_line and not prev_line.is_blank then
                  add_issue(issues, document, rule, line.number, core.first_nonspace_col(line.text))
                end
              end

              local next_line = document.lines[index + 1]
              if next_line and next_line.is_blank then
                add_issue(issues, document, rule, line.number, core.first_nonspace_col(line.text))
              end

              in_container = true
            end
          elseif in_container and line.text:match(":::%s*$") then
            add_issue(issues, document, rule, line.number, line.text:find(":::", 1, true) or 1)
          end
        end
      end
    end,
  },
  {
    id = "L040",
    status = "lint-ready",
    summary = "markdown link spacing follows visible label",
    warning_message = "Markdown link 前後空格應以 [] 內的可見文字判斷；中文連中文不留空格，中英相接才留空格",
    run = function(document, issues, rule)
      for _, line in ipairs(punctuation_spacing_lines(document)) do
        if not is_markdown_image_line(line) then
          local codepoints = core.codepoints(line.masked_text)
          for _, span in ipairs(markdown_link_spans(line.masked_text)) do
            local first_label_kind = label_edge_kind(span.label, false)
            local last_label_kind = label_edge_kind(span.label, true)
            local prev_item = previous_nonspace_item(codepoints, span.start_col)
            local next_item = next_nonspace_item(codepoints, span.end_col)

            if prev_item and first_label_kind then
              local prev_kind = boundary_kind(prev_item)
              local gap = text_between_items(line.masked_text, prev_item, span.start_col)
              local has_space = gap_has_halfwidth_space(gap)
              if needs_cjk_ascii_space(prev_kind, first_label_kind) and not has_space then
                add_issue(issues, document, rule, line.number, span.start_col)
              elseif forbids_cjk_cjk_space(prev_kind, first_label_kind) and has_space then
                add_issue(issues, document, rule, line.number, span.start_col)
              end
            end

            if next_item and last_label_kind then
              local next_kind = boundary_kind(next_item)
              local gap = line.masked_text:sub(span.end_col + 1, next_item.pos - 1)
              local has_space = gap_has_halfwidth_space(gap)
              if needs_cjk_ascii_space(last_label_kind, next_kind) and not has_space then
                add_issue(issues, document, rule, line.number, span.end_col)
              elseif forbids_cjk_cjk_space(last_label_kind, next_kind) and has_space then
                add_issue(issues, document, rule, line.number, span.end_col)
              end
            end
          end
        end
      end
    end,
  },
  {
    id = "L041",
    status = "lint-ready",
    summary = "halfwidth spaces around fullwidth comma",
    warning_message = "全形逗號前後不應有半形空格",
    run = function(document, issues, rule)
      for _, line in ipairs(punctuation_spacing_lines(document)) do
        if not is_markdown_image_line(line) then
          local codepoints = core.codepoints(line.text)
          for index, item in ipairs(codepoints) do
            if item.char == "，" and is_unmasked_char(line, item) then
              local prev_item = codepoints[index - 1]
              local next_item = codepoints[index + 1]
              if (prev_item and prev_item.char == " ") or (next_item and next_item.char == " ") then
                add_issue(issues, document, rule, line.number, item.pos)
              end
            end
          end
        end
      end
    end,
  },
  {
    id = "L042",
    status = "lint-ready",
    summary = "tracking query parameter in markdown link",
    warning_message = "Markdown link URL 不應保留 fbclid、utm_* 等外部來源追蹤參數，請只保留原始連結",
    run = function(document, issues, rule)
      for _, line in ipairs(punctuation_spacing_lines(document)) do
        if not is_markdown_image_line(line) then
          for _, span in ipairs(markdown_link_spans(line.masked_text)) do
            if markdown_link_url_has_tracking_param(span.url) then
              add_issue(issues, document, rule, line.number, span.url_start_col)
            end
          end
        end
      end
    end,
  },
  {
    id = "L043",
    status = "lint-ready",
    summary = "terminal continuation punctuation",
    warning_message = "Markdown prose 句末不應以逗號、頓號或分號等延續標點收尾",
    run = function(document, issues, rule)
      for _, line in ipairs(punctuation_spacing_lines(document)) do
        if not is_markdown_image_line(line) then
          local col = terminal_continuation_punctuation_col(line)
          if col then
            add_issue(issues, document, rule, line.number, col)
          end
        end
      end
    end,
  },
  {
    id = "L044",
    status = "lint-hybrid",
    summary = "halfwidth parentheses in CJK prose context",
    warning_message = "非全英文段落中的補充括號建議使用全形括號",
    run = function(document, issues, rule)
      local checked_lines = {}

      for _, paragraph in ipairs(document.paragraphs) do
        local paragraph_has_cjk = false
        for _, line in ipairs(paragraph.lines) do
          if core.contains_cjk(line.masked_text) then
            paragraph_has_cjk = true
            break
          end
        end

        if paragraph_has_cjk then
          for _, line in ipairs(paragraph.lines) do
            checked_lines[line.number] = true
            if not line.is_table and not is_markdown_image_line(line) then
              local col = halfwidth_parenthetical_in_cjk_context_col(line, true)
              if col then
                add_issue(issues, document, rule, line.number, col)
              end
            end
          end
        end
      end

      for _, line in ipairs(visible_text_lines(document)) do
        if not checked_lines[line.number] and not line.is_table and not is_markdown_image_line(line) and core.contains_cjk(line.masked_text) then
          local col = halfwidth_parenthetical_in_cjk_context_col(line, true)
          if col then
            add_issue(issues, document, rule, line.number, col)
          end
        end
      end
    end,
  },
  {
    id = "L045",
    status = "lint-ready",
    summary = "spaces around fullwidth parentheses",
    warning_message = "全形括號前後不應保留半形空格",
    run = function(document, issues, rule)
      for _, line in ipairs(document.lines) do
        if
          not line.is_blank and
          not line.is_code and
          not line.is_tag and
          not line.is_directive and
          not line.is_table and
          not is_markdown_image_line(line)
        then
          local col = fullwidth_parentheses_spacing_col(line)
          if col then
            add_issue(issues, document, rule, line.number, col)
          end
        end
      end
    end,
  },
  {
    id = "L046",
    status = "lint-ready",
    summary = "bilingual term should be Chinese first",
    warning_message = "中文上下文中的雙語術語應寫成「中文（English）」；若不是 true name / label / token，請調整順序",
    run = function(document, issues, rule)
      for _, line in ipairs(bilingual_order_lines(document)) do
        if not is_markdown_image_line(line) then
          for _, pair in ipairs(core.extract_bilingual_pairs(line.masked_text)) do
            local raw_inner = parenthetical_content_at(line.text, pair.col) or pair.inner
            if
              core.contains_ascii_letter(pair.outer) and
              not pair.outer:find("%d") and
              is_term_like_chinese(pair.inner) and
              not is_descriptive_chinese_parenthetical(raw_inner)
            then
              add_issue(issues, document, rule, line.number, pair.col)
            end
          end
        end
      end
    end,
  },
  {
    id = "L047",
    status = "lint-ready",
    summary = "halfwidth space between CJK characters",
    warning_message = "中文與中文之間不應殘留半形空格",
    run = function(document, issues, rule)
      for _, line in ipairs(visible_text_lines(document)) do
        if not is_markdown_image_line(line) then
          local col = cjk_internal_space_col(line)
          if col then
            add_issue(issues, document, rule, line.number, col)
          end
        end
      end
    end,
  },
  {
    id = "L048",
    status = "lint-ready",
    summary = "spaces around title marks",
    warning_message = "書名號《》與章名號〈〉內外側不應保留半形空格",
    run = function(document, issues, rule)
      for _, line in ipairs(visible_text_lines(document)) do
        if not line.is_table and not is_markdown_image_line(line) then
          local col = title_mark_spacing_col(line)
          if col then
            add_issue(issues, document, rule, line.number, col)
          end
        end
      end
    end,
  },
  {
    id = "L049",
    status = "lint-ready",
    summary = "halfwidth exclamation or question mark in CJK prose",
    warning_message = "中文 prose 的 `!` 與 `?` 建議使用全形「！」「？」",
    run = function(document, issues, rule)
      local targets = {
        [string.byte("!")] = true,
        [string.byte("?")] = true,
      }
      for _, line in ipairs(prose_lines(document)) do
        local codepoints = core.codepoints(line.masked_text)
        for index, item in ipairs(codepoints) do
          if targets[item.cp] then
            local prev_item = core.previous_nonspace(codepoints, index)
            local next_item = core.next_nonspace(codepoints, index)
            local prev_is_cjk = prev_item and core.is_cjk(prev_item.cp)
            local next_is_cjk = next_item and core.is_cjk(next_item.cp)
            local surrounded_by_cjk = prev_is_cjk and next_is_cjk
            local terminal_after_cjk = prev_is_cjk and not next_item
            if surrounded_by_cjk or terminal_after_cjk then
              add_issue(issues, document, rule, line.number, item.pos)
              break
            end
          end
        end
      end
    end,
  },
  {
    id = "L050",
    status = "lint-ready",
    summary = "curly double quote in CJK prose",
    warning_message = "中文 prose 的引號建議使用「」或『』，不要使用全形彎引號「\u{201C}\u{201D}」",
    run = function(document, issues, rule)
      local open_quote = "\u{201C}"
      local close_quote = "\u{201D}"
      for _, line in ipairs(prose_lines(document)) do
        local search_from = 1
        while true do
          local open_pos = line.masked_text:find(open_quote, search_from, true)
          if not open_pos then
            break
          end
          local close_pos = line.masked_text:find(close_quote, open_pos + #open_quote, true)
          if not close_pos then
            break
          end
          local content = line.masked_text:sub(open_pos + #open_quote, close_pos - 1)
          if core.contains_cjk(content) then
            add_issue(issues, document, rule, line.number, open_pos)
            break
          end
          search_from = close_pos + #close_quote
        end
      end
    end,
  },
  {
    id = "L051",
    status = "lint-ready",
    summary = "spaces around fullwidth quotes",
    warning_message = "中文引號「」與『』內外側不應保留半形空格",
    run = function(document, issues, rule)
      for _, line in ipairs(visible_text_lines(document)) do
        if not is_markdown_image_line(line) then
          local col = fullwidth_quote_spacing_col(line)
          if col then
            add_issue(issues, document, rule, line.number, col)
          end
        end
      end
    end,
  },
  {
    id = "L052",
    status = "lint-ready",
    summary = "internal consecutive halfwidth spaces",
    warning_message = "一般 prose 行內不應出現連續兩個半形空白",
    run = function(document, issues, rule)
      for _, line in ipairs(visible_text_lines(document)) do
        if not line.is_table and not line.is_blockquote and not is_markdown_image_line(line) then
          local col = internal_consecutive_space_col(line)
          if col then
            add_issue(issues, document, rule, line.number, col)
          end
        end
      end
    end,
  },
  {
    id = "L053",
    status = "lint-ready",
    summary = "preferred Taiwan technical terms",
    warning_message = "這個詞可能偏離 workspace glossary 的臺灣技術用詞偏好",
    run = function(document, issues, rule)
      for _, line in ipairs(visible_text_lines(document)) do
        if not is_markdown_image_line(line) then
          local reported_spans = {}
          for _, entry in ipairs(PREFERRED_TAIWAN_TERMS) do
            local search_from = 1
            while true do
              local col = line.masked_text:find(entry.term, search_from, true)
              if not col then
                break
              end

              local end_col = col + #entry.term - 1
              if
                not span_overlaps(reported_spans, col, end_col) and
                should_warn_preferred_term(entry, line.masked_text, col)
              then
                add_issue(issues, document, rule, line.number, col, preferred_term_message(entry))
                table.insert(reported_spans, { start_col = col, end_col = end_col })
              end

              search_from = col + #entry.term
            end
          end
        end
      end
    end,
  },
  {
    id = "L054",
    status = "lint-hybrid",
    summary = "bare English drift after bilingual anchor",
    warning_message = "這個英文詞在首次雙語介紹後又在中文語境中出現成 bare English，請確認下游是否固定用中文單一形式",
    run = function(document, issues, rule)
      local anchors = {}
      for _, line in ipairs(document.lines) do
        if not line.is_code and not line.is_table then
          for _, pair in ipairs(core.extract_bilingual_pairs(line.masked_text)) do
            local raw_inner = parenthetical_content_at(line.text, pair.col) or pair.inner
            if
              pair.outer == pair.chinese and
              is_term_like_chinese(pair.chinese) and
              not raw_inner:find("`", 1, true)
            then
              local raw_english = core.trim(pair.english)
              local english_key = core.normalize_english_term(raw_english)
              if
                should_track_bare_english_drift_anchor(raw_english, english_key) and
                not anchors[english_key]
              then
                anchors[english_key] = {
                  line = line.number,
                  col = pair.col,
                }
              end
            end
          end
        end
      end

      if next(anchors) == nil then
        return
      end

      for _, line in ipairs(document.lines) do
        if
          not line.is_blank and
          not line.is_code and
          not line.is_tag and
          not line.is_directive and
          not line.is_table and
          not line.is_heading
        then
          for english_key, anchor in pairs(anchors) do
            if line.number > anchor.line then
              local col = find_bare_english_drift_col(line, english_key)
              if col then
                add_issue(issues, document, rule, line.number, col)
                break
              end
            end
          end
        end
      end
    end,
  },
  {
    id = "L055",
    status = "lint-ready",
    summary = "bibliography entry structure",
    warning_message = "formal reference entry 的 bibliographic 主行、URL 子列點與中文說明應分開，不要把它們擠在同一行或同一個子列點",
    run = function(document, issues, rule)
      local entries, subbullets = bibliography_section_lines(document)

      for _, item in ipairs(entries) do
        if
          core.contains_cjk(item.body) or
          bibliography_has_url(item.body) or
          item.body:match("%[[^%]]+%]%([^%)]+%)")
        then
          add_issue(issues, document, rule, item.line.number, 1)
        end
      end

      for _, item in ipairs(subbullets) do
        if bibliography_has_url(item.body) and not bibliography_url_subbullet_is_pure_url(item.body) then
          add_issue(issues, document, rule, item.line.number, 1)
        end
      end
    end,
  },
  {
    id = "L056",
    status = "lint-ready",
    summary = "bibliography initials spacing",
    warning_message = "bibliography 主行的人名縮寫建議寫成「A. B. C. Surname」，不要把 initials 黏在一起",
    run = function(document, issues, rule)
      local entries = bibliography_section_lines(document)
      for _, item in ipairs(entries) do
        local col = item.line.text:find("%u%.%u") or item.line.text:find("%u%.%u%l")
        if col then
          add_issue(issues, document, rule, item.line.number, col)
        end
      end
    end,
  },
  {
    id = "L057",
    status = "lint-ready",
    summary = "bibliography abbreviation number spacing",
    warning_message = "bibliography 主行中的 `Vol.` / `No.` / `p.` / `pp.` 若後面接數字，縮寫後應保留半形空格",
    run = function(document, issues, rule)
      local entries = bibliography_section_lines(document)
      local patterns = {
        "%f[%a]Vol%.%d",
        "%f[%a]No%.%d",
        "%f[%a]p%.%d",
        "%f[%a]pp%.%d",
      }

      for _, item in ipairs(entries) do
        for _, pattern in ipairs(patterns) do
          local col = item.line.text:find(pattern)
          if col then
            add_issue(issues, document, rule, item.line.number, col)
            break
          end
        end
      end
    end,
  },
  {
    id = "L058",
    status = "lint-ready",
    summary = "bibliography year shorthand spacing",
    warning_message = "年份簡寫如 `'95` 前通常要有半形空格，例如 `USENIX ATC '95`",
    run = function(document, issues, rule)
      local entries = bibliography_section_lines(document)
      for _, item in ipairs(entries) do
        local col = item.line.text:find("[%w%)]'%d%d")
        if col then
          add_issue(issues, document, rule, item.line.number, col)
        end
      end
    end,
  },
  {
    id = "L059",
    status = "lint-ready",
    summary = "bibliography possessive apostrophe spacing",
    warning_message = "英文所有格 `'s` 應直接接在前一個字後面，例如 `Developer's Manuals`",
    run = function(document, issues, rule)
      local entries = bibliography_section_lines(document)
      for _, item in ipairs(entries) do
        local col = item.line.text:find("[%a%d]%s+'s%f[%A]")
        if col then
          add_issue(issues, document, rule, item.line.number, col)
        end
      end
    end,
  },
  {
    id = "L060",
    status = "lint-ready",
    summary = "bibliography curly quotes or apostrophes",
    warning_message = "bibliography 主行保留英文引號時，請使用 ASCII `\"` 與 `'`，不要使用彎引號或彎 apostrophe",
    run = function(document, issues, rule)
      local entries = bibliography_section_lines(document)
      for _, item in ipairs(entries) do
        local col = item.line.text:find("[“”‘’]")
        if col then
          add_issue(issues, document, rule, item.line.number, col)
        end
      end
    end,
  },
  {
    id = "L061",
    status = "lint-ready",
    summary = "bibliography explanation uses Chinese punctuation",
    warning_message = "References 的中文說明子列點應使用中文標點，避免半形 `,` / `:` / `;`，且一般不以半形 `.` 收尾",
    run = function(document, issues, rule)
      local explanation_lines = bibliography_explanation_subbullets(document)
      local targets = {
        [string.byte(",")] = true,
        [string.byte(":")] = true,
        [string.byte(";")] = true,
      }

      for _, item in ipairs(explanation_lines) do
        local line = item.line
        local codepoints = core.codepoints(line.masked_text)

        for index, point in ipairs(codepoints) do
          if targets[point.cp] and is_unmasked_char(line, point) then
            local prev_item = core.previous_nonspace(codepoints, index)
            local next_item = core.next_nonspace(codepoints, index)
            local touches_cjk =
              (prev_item and core.is_cjk(prev_item.cp)) or
              (next_item and core.is_cjk(next_item.cp))

            if touches_cjk then
              add_issue(issues, document, rule, line.number, point.pos)
              goto continue
            end
          end
        end

        local last_item = core.last_nonspace_codepoint(codepoints)
        if last_item and last_item.char == "." and is_unmasked_char(line, last_item) then
          add_issue(issues, document, rule, line.number, last_item.pos)
        end

        ::continue::
      end
    end,
  },
  {
    id = "L014",
    status = "lint-ready",
    summary = "missing EOF newline",
    warning_message = "檔案結尾應保留 EOF newline，請在文末補上一個換行",
    run = function(document, issues, rule)
      if document.text ~= "" and document.text:sub(-1) ~= "\n" then
        local last_line = document.lines[#document.lines]
        local line_number = last_line and last_line.number or 1
        local col = last_line and (#last_line.text + 1) or 1
        add_issue(issues, document, rule, line_number, col)
      end
    end,
  },
}

function M.all()
  return RULES
end

return M
