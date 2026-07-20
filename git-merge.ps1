# Godot Git Merge Manager - TUI for merging two dev branches into main
# without stepping on each other's HEAD. (Windows / PowerShell version)
#
# Run it from inside your repo folder:
#   .\git-merge-tui.ps1
#
# If Windows blocks the script from running, either:
#   Right-click the file -> Properties -> check "Unblock" -> OK
# or run once per session:
#   powershell -ExecutionPolicy Bypass -File .\git-merge-tui.ps1

# ---- CONFIG: edit these to match your actual branch names (case sensitive) ----
$MainBranch = "master"
$BranchA    = "Filip"
$BranchB    = "serdar-changes"
# --------------------------------------------------------------------------------

function Pause-Script {
    Read-Host "Press Enter to continue..." | Out-Null
}

function Show-Header {
    Clear-Host
    Write-Host "======================================================" -ForegroundColor Blue
    Write-Host "        Godot Git Merge Manager (Windows)            " -ForegroundColor Blue
    Write-Host "======================================================" -ForegroundColor Blue
    $repoName = Split-Path -Leaf (git rev-parse --show-toplevel 2>$null)
    $currentBranch = git branch --show-current 2>$null
    Write-Host "Repo: " -ForegroundColor Cyan -NoNewline
    Write-Host $repoName
    Write-Host "Current branch: " -ForegroundColor Cyan -NoNewline
    Write-Host $currentBranch
    Write-Host ""
}

function Test-Repo {
    git rev-parse --is-inside-work-tree *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Not a git repository. cd into your project first." -ForegroundColor Red
        exit 1
    }
}

function Test-BranchExists {
    param([string]$Branch)
    git show-ref --verify --quiet "refs/heads/$Branch"
    return ($LASTEXITCODE -eq 0)
}

function Confirm-BranchesExist {
    foreach ($b in @($MainBranch, $BranchA, $BranchB)) {
        if (-not (Test-BranchExists $b)) {
            Write-Host "Branch '$b' does not exist locally. Edit the CONFIG section at the top of this script, or run: git branch $b" -ForegroundColor Red
            exit 1
        }
    }
}

# Shows a colorized summary + full diff of whatever's currently uncommitted.
function Show-Changes {
    Write-Host ""
    Write-Host "Files changed:" -ForegroundColor White
    $statusLines = git status --short
    foreach ($line in $statusLines) {
        $code = $line.Substring(0, 2)
        $file = $line.Substring(3)
        if ($code -eq "??") {
            Write-Host "  [new]      $file" -ForegroundColor Cyan
        } elseif ($code -match "D") {
            Write-Host "  [deleted]  $file" -ForegroundColor Red
        } elseif ($code -match "M") {
            Write-Host "  [modified] $file" -ForegroundColor Yellow
        } elseif ($code -match "A") {
            Write-Host "  [added]    $file" -ForegroundColor Green
        } else {
            Write-Host "  [$code] $file"
        }
    }
    Write-Host ""
    $d = Read-Host "View full line-by-line diff (green=added, red=removed)? [y/N]"
    if ($d -match "^[Yy]$") {
        git -c color.ui=always diff | more
        $newFiles = git status --short | Where-Object { $_ -match "^\?\?" } | ForEach-Object { $_.Substring(3) }
        if ($newFiles) {
            $nf = Read-Host "New (untracked) files aren't shown in 'git diff'. Preview them? [y/N]"
            if ($nf -match "^[Yy]$") {
                foreach ($f in $newFiles) {
                    Write-Host "--- $f (new file) ---" -ForegroundColor Green
                    if (Test-Path $f) {
                        git -c color.ui=always diff --no-index -- NUL "$f" | more
                    }
                }
            }
        }
    }
}

function Confirm-Clean {
    $statusPorcelain = git status --porcelain
    if ($statusPorcelain) {
        Write-Host "You have uncommitted changes." -ForegroundColor Yellow
        while ($true) {
            Write-Host "1) View what changed"
            Write-Host "2) Stash changes and continue"
            Write-Host "3) Commit changes now"
            Write-Host "4) Abort"
            $c = Read-Host "Choose [1-4]"
            switch ($c) {
                "1" { Show-Changes }
                "2" {
                    $stamp = Get-Date
                    git stash push -m "auto-stash before merge $stamp"
                    Write-Host "Stashed." -ForegroundColor Green
                    return
                }
                "3" {
                    git add -A
                    $m = Read-Host "Commit message"
                    git commit -m "$m"
                    return
                }
                "4" { exit 0 }
                default { Write-Host "Invalid" }
            }
        }
    }
}

function Invoke-FetchAll {
    Write-Host "Fetching from origin..." -ForegroundColor Cyan
    git fetch --all --prune
}

# Returns $true if fully resolved, $false if aborted
function Resolve-Conflicts {
    param([string]$IncomingBranch)
    while ($true) {
        $files = git diff --name-only --diff-filter=U
        if (-not $files) {
            Write-Host "No more conflicts." -ForegroundColor Green
            return $true
        }
        Write-Host "Merge conflicts:" -ForegroundColor Red
        foreach ($f in $files) { Write-Host "  - $f" }
        Write-Host ""
        Write-Host "1) Open conflicted files in your editor (resolve manually)"
        Write-Host "2) Take $MainBranch's version for ALL conflicts (ours)"
        Write-Host "3) Take $IncomingBranch's version for ALL conflicts (theirs)"
        Write-Host "4) Decide per file (with colorized diff preview)"
        Write-Host "5) Abort merge"
        $choice = Read-Host "Choose [1-5]"
        switch ($choice) {
            "1" {
                $editor = $env:EDITOR
                if (-not $editor) { $editor = "notepad" }
                foreach ($f in $files) { & $editor $f }
            }
            "2" {
                foreach ($f in $files) { git checkout --ours -- "$f"; git add "$f" }
            }
            "3" {
                foreach ($f in $files) { git checkout --theirs -- "$f"; git add "$f" }
            }
            "4" {
                foreach ($f in $files) {
                    Write-Host "File: $f" -ForegroundColor Yellow
                    Write-Host "   d) show conflict diff   o) ours ($MainBranch)   t) theirs ($IncomingBranch)   e) edit manually   s) skip"
                    $fc = Read-Host "   Choice"
                    if ($fc -eq "d") {
                        git -c color.ui=always diff -- "$f" | more
                        Write-Host "   o) ours   t) theirs   e) edit manually   s) skip"
                        $fc2 = Read-Host "   Choice"
                        switch ($fc2) {
                            "o" { git checkout --ours -- "$f"; git add "$f" }
                            "t" { git checkout --theirs -- "$f"; git add "$f" }
                            "e" {
                                $editor = $env:EDITOR
                                if (-not $editor) { $editor = "notepad" }
                                & $editor $f
                            }
                            default { }
                        }
                    }
                    elseif ($fc -eq "o") { git checkout --ours -- "$f"; git add "$f" }
                    elseif ($fc -eq "t") { git checkout --theirs -- "$f"; git add "$f" }
                    elseif ($fc -eq "e") {
                        $editor = $env:EDITOR
                        if (-not $editor) { $editor = "notepad" }
                        & $editor $f
                    }
                }
            }
            "5" {
                git merge --abort
                Write-Host "Merge aborted." -ForegroundColor Yellow
                return $false
            }
            default { Write-Host "Invalid choice" }
        }
        $remaining = git diff --name-only --diff-filter=U
        if (-not $remaining) { return $true }
    }
}

# Fetches origin/<branch>, merges it in (with conflict handling) if origin has
# moved ahead, THEN pushes. Prevents the "rejected, fetch first" error.
# Assumes you are already checked out on <branch>.
function Invoke-SafePush {
    param([string]$Branch)
    Write-Host "Checking origin/$Branch before pushing..." -ForegroundColor Cyan
    git fetch origin $Branch *> $null

    git show-ref --verify --quiet "refs/remotes/origin/$Branch"
    if ($LASTEXITCODE -ne 0) {
        # branch doesn't exist on origin yet, just push it
        git push -u origin $Branch
        return
    }

    $localHash = git rev-parse $Branch
    $remoteHash = git rev-parse "origin/$Branch"

    if ($localHash -eq $remoteHash) {
        Write-Host "Already up to date with origin/$Branch." -ForegroundColor Green
        return
    }

    $base = git merge-base $Branch "origin/$Branch"
    if ($base -eq $remoteHash) {
        # origin has nothing local doesn't already have -> safe to push directly
        git push origin $Branch
        return
    }

    Write-Host "origin/$Branch has commits you don't have locally (someone else pushed). Merging them in first..." -ForegroundColor Yellow
    git merge "origin/$Branch" -m "Merge origin/$Branch into $Branch"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Merged origin/$Branch cleanly." -ForegroundColor Green
    } else {
        $resolved = Resolve-Conflicts "origin/$Branch"
        if ($resolved) {
            git commit --no-edit
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Commit failed after resolving -- check 'git status' manually." -ForegroundColor Red
                return
            }
        } else {
            Write-Host "Merge aborted -- not pushing. Resolve manually and push when ready." -ForegroundColor Yellow
            return
        }
    }

    git push origin $Branch
}

function Invoke-Merge {
    param([string]$Branch)
    Write-Host "Merging $Branch into $MainBranch..." -ForegroundColor Cyan
    git checkout $MainBranch
    if ($LASTEXITCODE -ne 0) { return $false }
    git pull origin $MainBranch --ff-only *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "(no fast-forward pull available, continuing with local $MainBranch)" -ForegroundColor Yellow
    }

    git merge --no-ff $Branch -m "Merge $Branch into $MainBranch"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Merged $Branch cleanly, no conflicts." -ForegroundColor Green
    } else {
        $resolved = Resolve-Conflicts $Branch
        if ($resolved) {
            git commit --no-edit
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Conflicts resolved, merge committed." -ForegroundColor Green
            } else {
                Write-Host "Commit failed -- check 'git status'." -ForegroundColor Red
                return $false
            }
        } else {
            return $false
        }
    }

    $p = Read-Host "Push $MainBranch to origin now? [y/N]"
    if ($p -match "^[Yy]$") { Invoke-SafePush $MainBranch }
    return $true
}

function Sync-BranchFromMain {
    param([string]$Branch)
    $r = Read-Host "Update $Branch with the latest $MainBranch now (recommended, keeps it conflict-free next time)? [y/N]"
    if ($r -match "^[Yy]$") {
        git checkout $Branch
        git merge $MainBranch -m "Sync $MainBranch into $Branch"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$Branch synced." -ForegroundColor Green
        } else {
            $resolved = Resolve-Conflicts $MainBranch
            if ($resolved) { git commit --no-edit }
        }
        $p2 = Read-Host "Push $Branch to origin? [y/N]"
        if ($p2 -match "^[Yy]$") { Invoke-SafePush $Branch }
        git checkout $MainBranch
    }
}

function Invoke-FullSync {
    $ok = Invoke-Merge $BranchA
    if ($ok) { Sync-BranchFromMain $BranchB }
    $ok2 = Invoke-Merge $BranchB
    if ($ok2) { Sync-BranchFromMain $BranchA }
}

function Show-Status {
    Show-Header
    Write-Host "Branch status vs origin:" -ForegroundColor White
    foreach ($b in @($MainBranch, $BranchA, $BranchB)) {
        $ahead = git rev-list --count "origin/$b..$b" 2>$null
        if (-not $ahead) { $ahead = "?" }
        $behind = git rev-list --count "$b..origin/$b" 2>$null
        if (-not $behind) { $behind = "?" }
        Write-Host "  $b`: ahead $ahead / behind $behind"
    }
    Write-Host ""
    Write-Host "Recent history (all branches):" -ForegroundColor White
    git log --oneline --graph --decorate -n 12 --all
    Write-Host ""
    Pause-Script
}

function Show-MainMenu {
    while ($true) {
        Show-Header
        Write-Host "1) Merge $BranchA -> $MainBranch"
        Write-Host "2) Merge $BranchB -> $MainBranch"
        Write-Host "3) Full sync ($BranchA then $BranchB into $MainBranch, then sync branches back)"
        Write-Host "4) Show branch status / log"
        Write-Host "5) Fetch from origin"
        Write-Host "6) View uncommitted changes"
        Write-Host "7) Exit"
        Write-Host ""
        $opt = Read-Host "Choose an option [1-7]"
        switch ($opt) {
            "1" { Confirm-Clean; Invoke-Merge $BranchA | Out-Null; Pause-Script }
            "2" { Confirm-Clean; Invoke-Merge $BranchB | Out-Null; Pause-Script }
            "3" { Confirm-Clean; Invoke-FullSync; Pause-Script }
            "4" { Show-Status }
            "5" { Invoke-FetchAll; Pause-Script }
            "6" { Show-Header; Show-Changes; Pause-Script }
            "7" { Write-Host "Bye!"; exit 0 }
            default { Write-Host "Invalid option"; Pause-Script }
        }
    }
}

Test-Repo
Confirm-BranchesExist
Show-MainMenu
