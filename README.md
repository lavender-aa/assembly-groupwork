# Overview
All our group projects are organized here, in their own folders.

# Common Commands Reference
Below is a list of common commands and their descriptions. If you don't know how to use git or the workflow we're using, ask Lavender to show you.

Items in [brackets] are to be replaced (ex. "[branch name]" -> "main").

Most common:
- `git add .` or `git add [file/dirname]` -- stage everything (dot) or a specific file or directory
- `git commit -m "[commit message]"` -- commit staged changes with a message
- `git status` -- see the status of current changes
- `git pull` -- pull changes from remote into the current branch
- `git push` -- push changes to the current upstream branch
- `git branch` -- list all local branches
- `git checkout [branch name]` -- switch to a different branch

Less common, but still often:
- `git fetch origin -p` -- download changes from remote (including deleted remote branches)
- `git push -u origin [branch name]` -- if there is no upstream branch, publish the current one
- `git branch -r` -- list all remote branches
- `git branch [branch name]` -- create a new branch from the current branch
- `git checkout -b origin/[remote branch] [local name]` -- create a branch that tracks a remote one
- `git branch -d [branch name]` -- delete a branch
- `git merge [branch to merge]` -- merge a branch into current branch 
