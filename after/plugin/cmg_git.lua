local ok, cmp_git = pcall(require, "cmp_git")
if not ok then
  require("user.utils").info("skipped cmp-git")
  return
end

local function format_timestamp(ts)
  return os.date("%Y.%m.%d %H:%M:%S", ts)
end

local git_commit_format = {
  label = function(trigger_char, commit)
    local commit_time = format_timestamp(commit.commit_timestamp)
    return string.format('%s "%s"', commit_time, commit.title)
  end,

  filterText = function(trigger_char, commit)
    -- If the trigger char is not part of the label, no items will show up
    return string.format("%s %s %s", trigger_char, commit.sha, commit.title)
  end,

  insertText = function(trigger_char, commit)
    -- return commit.sha
    return commit.title
  end,

  documentation = function(trigger_char, commit)
    return {
      kind = "markdown",
      value = string.format(
        "# %s\n%s\n%s\nCommited by __%s__ (*%s*) on `%s`",
        commit.title,
        commit.sha,
        commit.description or "-",
        commit.author_name,
        commit.author_mail,
        os.date("%c", commit.commit_timestamp)
      ),
    }
  end,
}

local function git_commit_sort(commit)
  return format_timestamp(commit.commit_timestamp)
end

cmp_git.setup({
  git = {
    commits = {
      sort_by = git_commit_sort,
      format = git_commit_format,
    }
  },
})
