#!/usr/bin/env lua

local function usage()
  io.write([[
Usage:
  scripts/lint.lua [OPTIONS] <FILE> [<FILE> ...]

Options:
  --format <text|json|markdown>
                         Output format. Default: text
  --rules <IDS>          Comma-separated lint ids to run (inclusion)
  --exclude <IDS>        Comma-separated lint ids to skip (applies to base set)
  --profile <NAME>       Predefined exclusion set: spec|glossary|meta|final|default
  --list-rules           Show implemented rules and exit
  --fail-on-warning      Exit with status 1 if any warning is emitted
  --help                 Show this help

Profiles:
  spec      skip L017, L027, L002, L130 (spec / meta prose)
  glossary  skip L044, L045, L046, L022 (English-Chinese glossary tables)
  meta      skip L017, L018, L130 (preflight / dialogue artefacts allowed)
  final     default set (no extra exclusions)
  default   alias of final

Examples:
  scripts/lint.lua working/foo/output.md
  scripts/lint.lua --format json working/foo/output.md
  scripts/lint.lua --format markdown working/foo/output.md
  scripts/lint.lua --rules L001,L002,L015 scripts/README.md
  scripts/lint.lua --profile spec references/output_grammar.md references/output_style.md
  scripts/lint.lua --exclude L017,L027 scripts/README.md
  scripts/lint.lua --list-rules
]])
end

local PROFILES = {
  spec = { "L017", "L027", "L002", "L130" },
  glossary = { "L044", "L045", "L046", "L022" },
  meta = { "L017", "L018", "L130" },
  final = {},
  default = {},
}

local script_path = arg[0] or "scripts/lint.lua"
local script_dir = script_path:match("^(.*)/[^/]+$") or "."
local repo_root = script_dir .. "/.."
package.path = table.concat({
  script_dir .. "/?.lua",
  script_dir .. "/?/init.lua",
  package.path,
}, ";")

local core = require("lintlib.core")
local rules = require("lintlib.rules")

local function die(message)
  io.stderr:write("error: " .. message .. "\n")
  os.exit(1)
end

local function parse_args(argv)
  local options = {
    format = "text",
    fail_on_warning = false,
    list_rules = false,
    selected_rules = nil,
    excluded_rules = nil,
    profile = nil,
    paths = {},
  }

  local index = 1
  while index <= #argv do
    local value = argv[index]
    if value == "--help" then
      usage()
      os.exit(0)
    elseif value == "--format" then
      index = index + 1
      local format = argv[index]
      if format ~= "text" and format ~= "json" and format ~= "markdown" then
        die("unsupported format: " .. tostring(format))
      end
      options.format = format
    elseif value == "--rules" then
      index = index + 1
      local raw = argv[index]
      if not raw or raw == "" then
        die("--rules requires a comma-separated value")
      end
      options.selected_rules = core.make_set(core.split_csv(raw))
    elseif value == "--exclude" then
      index = index + 1
      local raw = argv[index]
      if not raw or raw == "" then
        die("--exclude requires a comma-separated value")
      end
      options.excluded_rules = core.make_set(core.split_csv(raw))
    elseif value == "--profile" then
      index = index + 1
      local name = argv[index]
      if not name or name == "" then
        die("--profile requires a name")
      end
      if not PROFILES[name] then
        die("unknown profile: " .. name .. " (available: spec, glossary, meta, final, default)")
      end
      options.profile = name
    elseif value == "--list-rules" then
      options.list_rules = true
    elseif value == "--fail-on-warning" then
      options.fail_on_warning = true
    elseif value:sub(1, 2) == "--" then
      die("unknown option: " .. value)
    else
      table.insert(options.paths, value)
    end
    index = index + 1
  end

  return options
end

local function filter_rules(selected_ids, excluded_ids, profile_name)
  local effective_excluded = {}
  if profile_name and PROFILES[profile_name] then
    for _, id in ipairs(PROFILES[profile_name]) do
      effective_excluded[id] = true
    end
  end
  if excluded_ids then
    for id in pairs(excluded_ids) do
      effective_excluded[id] = true
    end
  end

  local selected = {}
  local implemented = {}

  for _, rule in ipairs(rules.all()) do
    implemented[rule.id] = true
    local enabled_by_default = rule.enabled_by_default ~= false
    local in_base =
      (selected_ids and selected_ids[rule.id]) or
      (not selected_ids and enabled_by_default)
    if in_base and not effective_excluded[rule.id] then
      table.insert(selected, rule)
    end
  end

  if selected_ids then
    for lint_id in pairs(selected_ids) do
      if not implemented[lint_id] then
        die("unknown lint id: " .. lint_id)
      end
    end
  end
  if excluded_ids then
    for lint_id in pairs(excluded_ids) do
      if not implemented[lint_id] then
        die("unknown lint id: " .. lint_id)
      end
    end
  end

  return selected
end

local function list_rules()
  for _, rule in ipairs(rules.all()) do
    local mode = rule.enabled_by_default == false and "disabled-by-default" or "enabled"
    io.write(string.format("%s\t%s\t%s\t%s\n", rule.id, rule.status, mode, rule.summary))
  end
end

local function lint_path(path, selected_rules, options)
  local text = core.read_file(path)
  local document = core.build_document(path, text)
  document.repo_root = repo_root
  document.glossary = core.load_glossary_context(path, repo_root)
  local issues = {}

  for _, rule in ipairs(selected_rules) do
    rule.run(document, issues, rule)
  end

  table.sort(issues, function(left, right)
    if left.path ~= right.path then
      return left.path < right.path
    end
    if left.line ~= right.line then
      return left.line < right.line
    end
    if left.col ~= right.col then
      return left.col < right.col
    end
    return left.lint_id < right.lint_id
  end)

  return issues
end

local function print_text(all_issues)
  local total = 0
  for _, issues in ipairs(all_issues) do
    total = total + #issues
    for _, issue in ipairs(issues) do
      io.write(string.format(
        "%s:%d:%d [%s] %s\n",
        issue.path,
        issue.line,
        issue.col,
        issue.lint_id,
        issue.message
      ))
    end
  end

  io.write(string.format("\n%d warning(s)\n", total))
end

local function flatten_issues(all_issues)
  local flat = {}
  for _, issues in ipairs(all_issues) do
    for _, issue in ipairs(issues) do
      table.insert(flat, issue)
    end
  end
  return flat
end

local function markdown_escape(text)
  local escaped = tostring(text or "")
  escaped = escaped:gsub("\\", "\\\\")
  escaped = escaped:gsub("|", "\\|")
  escaped = escaped:gsub("\n", "<br>")
  return escaped
end

local function format_location(issue)
  return string.format("L%d:C%d", issue.line, issue.col)
end

local function group_issues(issues)
  local grouped = {}
  local ordered = {}

  for _, issue in ipairs(issues) do
    local key = table.concat({
      issue.severity or "warning",
      issue.lint_id or "",
      issue.message or "",
    }, "\0")

    local group = grouped[key]
    if not group then
      group = {
        severity = issue.severity or "warning",
        lint_id = issue.lint_id,
        message = issue.message,
        count = 0,
        locations = {},
        first_line = issue.line,
        first_col = issue.col,
      }
      grouped[key] = group
      table.insert(ordered, group)
    end

    group.count = group.count + 1
    table.insert(group.locations, format_location(issue))
  end

  table.sort(ordered, function(left, right)
    if left.first_line ~= right.first_line then
      return left.first_line < right.first_line
    end
    if left.first_col ~= right.first_col then
      return left.first_col < right.first_col
    end
    if left.lint_id ~= right.lint_id then
      return left.lint_id < right.lint_id
    end
    return left.message < right.message
  end)

  return ordered
end

local function summarize_rules(flat_issues)
  local grouped = {}
  local ordered = {}

  for _, issue in ipairs(flat_issues) do
    local key = table.concat({
      issue.severity or "warning",
      issue.lint_id or "",
    }, "\0")
    local entry = grouped[key]
    if not entry then
      entry = {
        severity = issue.severity or "warning",
        lint_id = issue.lint_id,
        count = 0,
      }
      grouped[key] = entry
      table.insert(ordered, entry)
    end
    entry.count = entry.count + 1
  end

  table.sort(ordered, function(left, right)
    if left.count ~= right.count then
      return left.count > right.count
    end
    if left.severity ~= right.severity then
      return left.severity < right.severity
    end
    return left.lint_id < right.lint_id
  end)

  return ordered
end

local function summarize_files(all_issues)
  local ordered = {}
  for _, issues in ipairs(all_issues) do
    if #issues > 0 then
      table.insert(ordered, {
        path = issues[1].path,
        count = #issues,
      })
    end
  end

  table.sort(ordered, function(left, right)
    if left.count ~= right.count then
      return left.count > right.count
    end
    return left.path < right.path
  end)

  return ordered
end

local function print_markdown(all_issues)
  local flat_issues = flatten_issues(all_issues)
  local file_summary = summarize_files(all_issues)
  local rule_summary = summarize_rules(flat_issues)

  io.write("# Lint Report\n\n")
  io.write("| Metric | Count |\n")
  io.write("| --- | ---: |\n")
  io.write(string.format("| Files scanned | %d |\n", #all_issues))
  io.write(string.format("| Files with warnings | %d |\n", #file_summary))
  io.write(string.format("| Total warnings | %d |\n", #flat_issues))

  if #flat_issues == 0 then
    io.write("\n## Detailed Warnings\n\n")
    io.write("No warnings.\n")
    return
  end

  io.write("\n## Summary by Rule\n\n")
  io.write("| Severity | Rule | Count |\n")
  io.write("| --- | --- | ---: |\n")
  for _, entry in ipairs(rule_summary) do
    io.write(string.format(
      "| `%s` | `%s` | %d |\n",
      markdown_escape(entry.severity),
      markdown_escape(entry.lint_id),
      entry.count
    ))
  end

  io.write("\n## Summary by File\n\n")
  io.write("| File | Warnings |\n")
  io.write("| --- | ---: |\n")
  for _, entry in ipairs(file_summary) do
    io.write(string.format(
      "| `%s` | %d |\n",
      markdown_escape(entry.path),
      entry.count
    ))
  end

  io.write("\n## Detailed Warnings\n\n")
  for _, issues in ipairs(all_issues) do
    if #issues > 0 then
      local path = issues[1].path
      local grouped = group_issues(issues)

      io.write(string.format("### %s (%d)\n\n", path, #issues))
      io.write("| Severity | Rule | Count | Locations | Message |\n")
      io.write("| --- | --- | ---: | --- | --- |\n")
      for _, group in ipairs(grouped) do
        io.write(string.format(
          "| `%s` | `%s` | %d | %s | %s |\n",
          markdown_escape(group.severity),
          markdown_escape(group.lint_id),
          group.count,
          markdown_escape(table.concat(group.locations, ", ")),
          markdown_escape(group.message)
        ))
      end
      io.write("\n")
    end
  end
end

local function main(argv)
  local options = parse_args(argv)

  if options.list_rules then
    list_rules()
    return
  end

  if #options.paths == 0 then
    usage()
    os.exit(1)
  end

  local selected_rules = filter_rules(options.selected_rules, options.excluded_rules, options.profile)
  local all_issues = {}

  for _, path in ipairs(options.paths) do
    table.insert(all_issues, lint_path(path, selected_rules, options))
  end

  if options.format == "json" then
    local payload = {
      warnings = flatten_issues(all_issues),
      summary = {
        warning_count = #flatten_issues(all_issues),
        files = options.paths,
      },
    }
    io.write(core.json_encode(payload) .. "\n")
  elseif options.format == "markdown" then
    print_markdown(all_issues)
  else
    print_text(all_issues)
  end

  if options.fail_on_warning and #flatten_issues(all_issues) > 0 then
    os.exit(1)
  end
end

main(arg)
