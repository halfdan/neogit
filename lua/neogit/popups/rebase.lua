local cli = require("neogit.lib.git.cli")
local git = require("neogit.lib.git")
local popup = require("neogit.lib.popup")
local CommitSelectViewBuffer = require("neogit.buffers.commit_select_view")
local rebase = require("neogit.lib.git.rebase")

local M = {}
local a = require("plenary.async")

function M.create()
  local status = require("neogit.status")
  local p = popup
    .builder()
    :name("NeogitRebasePopup")
    :action_if(status and status.repo.rebase.head, "r", "Continue rebase", function()
      rebase.continue()
      a.util.scheduler()
      status.refresh(true)
    end)
    :action_if(status and status.repo.rebase.head, "s", "Skip rebase", function()
      rebase.skip()
      a.util.scheduler()
      status.refresh(true)
    end)
    :action_if(status and status.repo.rebase.head, "a", "Abort rebase", function()
      cli.rebase.abort.call_sync()
      a.util.scheduler()
      status.refresh(true)
    end)
    :action("p", "Rebase onto master", function()
      cli.rebase.args("master").call_sync()
    end)
    :action("e", "Rebase onto elsewhere", function()
      local branch = git.branch.prompt_for_branch(git.branch.get_all_branches())
      cli.rebase.args(branch).call_sync()
      a.util.scheduler()
      status.refresh(true)
    end)
    :action("i", "Interactive", function()
      local commits = rebase.commits()
      CommitSelectViewBuffer.new(commits, function(_view, selected)
        rebase.run_interactive(selected.oid)
        a.util.scheduler()
        _view:close()
        status.refresh(true)
      end):open()
    end)
    :build()

  p:show()

  return p
end

return M
