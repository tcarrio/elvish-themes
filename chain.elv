# DO NOT EDIT THIS FILE DIRECTLY
# This is a file generated from a literate programing source file located at
# https://github.com/zzamboni/elvish-themes/blob/master/chain.org.
# You should make any changes there and regenerate it from Emacs org-mode using C-c C-v t

prompt-segments-defaults = [ su dir git-branch git-combined arrow ]
rprompt-segments-defaults = [ ]

use re
use str

use github.com/href/elvish-gitstatus/gitstatus
use github.com/zzamboni/elvish-modules/spinners

prompt-segments = $prompt-segments-defaults
rprompt-segments = $rprompt-segments-defaults

default-glyph = [
  &git-branch=    "⎇"
  &git-dirty=     "●"
  &git-ahead=     "⬆"
  &git-behind=    "⬇"
  &git-staged=    "✔"
  &git-untracked= "+"
  &git-deleted=   "-"
  &su=            "⚡"
  &chain=         "─"
  &session=       "▪"
  &arrow=         ">"
]

default-segment-style = [
  &git-branch=    [ blue         ]
  &git-dirty=     [ yellow       ]
  &git-ahead=     [ red          ]
  &git-behind=    [ red          ]
  &git-staged=    [ green        ]
  &git-untracked= [ red          ]
  &git-deleted=   [ red          ]
  &git-combined=  [ default      ]
  &git-timestamp= [ cyan         ]
  &git-repo=      [ blue         ]
  &su=            [ yellow       ]
  &chain=         [ default      ]
  &arrow=         [ green        ]
  &dir=           [ cyan         ]
  &session=       [ session      ]
  &timestamp=     [ bright-black ]
]

glyph = [&]
segment-style = [&]

prompt-pwd-dir-length = 1

timestamp-format = "%R"

root-id = 0

bold-prompt = $false

show-last-chain = $true

space-after-arrow = $true

git-get-timestamp = { git log -1 --date=short --pretty=format:%cd }

prompt-segment-delimiters = "[]"
# prompt-segment-delimiters = [ "<<" ">>" ]

fn -session-color {
  valid-colors = [ red green yellow blue magenta cyan white bright-black bright-red bright-green bright-yellow bright-blue bright-magenta bright-cyan bright-white ]
  put $valid-colors[(% $pid (count $valid-colors))]
}

fn -colorized [what @color]{
  if (and (not-eq $color []) (eq (kind-of $color[0]) list)) {
    color = [(all $color[0])]
  }
  if (and (not-eq $color [default]) (not-eq $color [])) {
    if (eq $color [session]) {
      color = [(-session-color)]
    }
    if $bold-prompt {
      color = [ $@color bold ]
    }
    styled $what $@color
  } else {
    put $what
  }
}

fn -glyph [segment-name]{
  if (has-key $glyph $segment-name) {
    put $glyph[$segment-name]
  } else {
    put $default-glyph[$segment-name]
  }
}

fn -segment-style [segment-name]{
  if (has-key $segment-style $segment-name) {
    put $segment-style[$segment-name]
  } else {
    put $default-segment-style[$segment-name]
  }
}

fn -colorized-glyph [segment-name @extra-text]{
  -colorized (-glyph $segment-name)(joins "" $extra-text) (-segment-style $segment-name)
}

fn prompt-segment [segment-or-style @texts]{
  style = $segment-or-style
  if (or (has-key $default-segment-style $segment-or-style) (has-key $segment-style $segment-or-style)) {
    style = (-segment-style $segment-or-style)
  }
  if (or (has-key $default-glyph $segment-or-style) (has-key $glyph $segment-or-style)) {
    texts = [ (-glyph $segment-or-style) $@texts ]
  }
  text = $prompt-segment-delimiters[0](joins ' ' $texts)$prompt-segment-delimiters[1]
  -colorized $text $style
}

segment = [&]

last-status = [&]

fn -parse-git [&with-timestamp=$false]{
  last-status = (gitstatus:query $pwd)
  if $with-timestamp {
    last-status[timestamp] = ($git-get-timestamp)
  }
}

segment[git-branch] = {
  branch = $last-status[local-branch]
  if (not-eq $branch $nil) {
    if (eq $branch '') {
      branch = $last-status[commit][0..7]
    }
    prompt-segment git-branch $branch
  }
}

segment[git-timestamp] = {
  ts = $nil
  if (has-key $last-status timestamp) {
    ts = $last-status[timestamp]
  } else {
    ts = ($git-get-timestamp)
  }
  prompt-segment git-timestamp $ts
}

fn -show-git-indicator [segment]{
  status-name = [
    &git-dirty=  unstaged        &git-staged=    staged
    &git-ahead=  commits-ahead   &git-untracked= untracked
    &git-behind= commits-behind  &git-deleted=   unstaged
  ]
  value = $last-status[$status-name[$segment]]
  # The indicator must show if the element is >0 or a non-empty list
  if (eq (kind-of $value) list) {
    not-eq $value []
  } else {
    and (not-eq $value $nil) (> $value 0)
  }
}

fn -git-prompt-segment [segment]{
  if (-show-git-indicator $segment) {
    prompt-segment $segment
  }
}

#-git-indicator-segments = [untracked deleted dirty staged ahead behind]
-git-indicator-segments = [untracked dirty staged ahead behind]

each [ind]{
  segment[git-$ind] = { -git-prompt-segment git-$ind }
} $-git-indicator-segments

segment[git-combined] = {
  indicators = [(each [ind]{
        if (-show-git-indicator git-$ind) { -colorized-glyph git-$ind }
  } $-git-indicator-segments)]
  if (> (count $indicators) 0) {
    color = (-segment-style git-combined)
    put (-colorized $prompt-segment-delimiters[0] $color) $@indicators (-colorized $prompt-segment-delimiters[1] $color)
  }
}

fn -prompt-pwd {
  tmp = (tilde-abbr $pwd)
  if (== $prompt-pwd-dir-length 0) {
    put $tmp
  } else {
    re:replace '(\.?[^/]{'$prompt-pwd-dir-length'})[^/]*/' '$1/' $tmp
  }
}

segment[dir] = {
  prompt-segment dir (-prompt-pwd)
}

segment[su] = {
  uid = (id -u)
  if (eq $uid $root-id) {
    prompt-segment su
  }
}

segment[timestamp] = {
  prompt-segment timestamp (date +$timestamp-format)
}

segment[session] = {
  prompt-segment session
}

segment[arrow] = {
  end-text = ''
  if $space-after-arrow { end-text = ' ' }
  -colorized-glyph arrow $end-text
}

fn -interpret-segment [seg]{
  k = (kind-of $seg)
  if (eq $k 'fn') {
    # If it's a lambda, run it
    $seg
  } elif (eq $k 'string') {
    if (has-key $segment $seg) {
      # If it's the name of a built-in segment, run its function
      $segment[$seg]
    } else {
      # If it's any other string, return it as-is
      put $seg
    }
  } elif (or (eq $k 'styled') (eq $k 'styled-text')) {
    # If it's a styled object, return it as-is
    put $seg
  } else {
    fail "Invalid segment of type "(kind-of $seg)": "(to-string $seg)". Must be fn, string or styled."
  }
}

fn -build-chain [segments]{
  if (eq $segments []) {
    return
  }
  for seg $segments {
    if (str:has-prefix (to-string $seg) "git-") {
      -parse-git
      break
    }
  }
  first = $true
  output = ""
  for seg $segments {
    output = [(-interpret-segment $seg)]
    if (> (count $output) 0) {
      if (not $first) {
        if (or $show-last-chain (not-eq $seg $segments[-1])) {
          -colorized-glyph chain
        }
      }
      put $@output
      first = $false
    }
  }
}

fn prompt {
  if (not-eq $prompt-segments []) {
    -build-chain $prompt-segments
  }
}

fn rprompt {
  if (not-eq $rprompt-segments []) {
    -build-chain $rprompt-segments
  }
}

fn init {
  edit:prompt = $prompt~
  edit:rprompt = $rprompt~
}

init

find-all-user-repos = {
  fd -H -I -t d '^.git$' ~ | each $path-dir~
}

summary-repos-file = ~/.elvish/package-data/elvish-themes/chain-summary-repos.json

summary-repos = []

fn -write-summary-repos {
  mkdir -p (path-dir $summary-repos-file)
  to-json [$summary-repos] > $summary-repos-file
}

fn -read-summary-repos {
  try {
    summary-repos = (from-json < $summary-repos-file)
  } except {
    summary-repos = []
  }
}

fn summary-data [repos]{
  each [r]{
    try {
      cd $r
      -parse-git &with-timestamp
      status = [($segment[git-combined])]
      put [
        &repo= (tilde-abbr $r)
        &status= $status
        &ts= $last-status[timestamp]
        &timestamp= ($segment[git-timestamp])
        &branch= ($segment[git-branch])
      ]
    } except e {
      put [
        &repo= (tilde-abbr $r)
        &status= [(styled '['(to-string $e)']' red)]
        &ts= ""
        &timestamp= ""
        &branch= ""
      ]
    }
  } $repos
}

fn summary-status [@repos &all=$false &only-dirty=$false]{
  prev = $pwd

  # Determine how to sort the output. This only happens in newer
  # versions of Elvish (where the order function exists)
  use builtin
  order-cmd~ = $all~
  if (has-key $builtin: order~) {
    order-cmd~ = { order &less-than=[a b]{ <s $a[ts] $b[ts] } &reverse }
  }

  # Read repo list from disk, cache in $chain:summary-repos
  -read-summary-repos

  # Determine the list of repos to display:
  # 1) If the &all option is given, find them
  if $all {
    spinners:run &title="Finding all git repos" &style=blue {
      repos = [($find-all-user-repos)]
    }
  }
  # 2) If repos is not given nor defined through &all, use $chain:summary-repos
  if (eq $repos []) {
    repos = $summary-repos
  }
  # 3) If repos is specified, just use it

  # Produce the output
  spinners:run &title="Gathering repo data" &style=blue { summary-data $repos } | order-cmd | each [r]{
    status-display = $r[status]
    if (or (not $only-dirty) (not-eq $status-display [])) {
      if (eq $status-display []) {
        status-display = [(-colorized "[" session) (styled OK green) (-colorized "]" session)]
      }
      @status = $r[timestamp] ' ' (all $status-display) ' ' $r[branch]
      echo &sep="" $@status ' ' (-colorized $r[repo] (-segment-style git-repo))
    }
  }
  cd $prev
}

fn add-summary-repo [@dirs]{
  if (eq $dirs []) {
    dirs = [ $pwd ]
  }
  -read-summary-repos
  each [d]{
    if (has-value $summary-repos $d) {
      echo (styled "Repo "$d" is already in the list" yellow)
    } else {
      summary-repos = [ $@summary-repos $d ]
      echo (styled "Repo "$d" added to the list" green)
    }
  } $dirs
  -write-summary-repos
}

fn remove-summary-repo [@dirs]{
  if (eq $dirs []) {
    dirs = [ $pwd ]
  }
  -read-summary-repos
  @new-repos = (each [d]{
      if (not (has-value $dirs $d)) { put $d }
  } $summary-repos)
  each [d]{
    if (has-value $summary-repos $d) {
      echo (styled "Repo "$d" removed from the list." green)
    } else {
      echo (styled "Repo "$d" was not on the list" yellow)
    }
  } $dirs

  summary-repos = $new-repos
  -write-summary-repos
}
