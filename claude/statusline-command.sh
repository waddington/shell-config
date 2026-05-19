#!/usr/bin/env bash
# Claude Code status line
input=$(cat)

model_name=$(echo "$input"  | jq -r '.model.display_name // ""')
ctx_size=$(echo "$input"    | jq -r '.context_window.context_window_size // 200000')
used=$(echo "$input"        | jq -r '.context_window.used_percentage // empty')
cwd=$(echo "$input"         | jq -r '.workspace.current_dir // .cwd // ""')
cost=$(echo "$input"        | jq -r '.cost.total_cost_usd // empty')
dur_ms=$(echo "$input"      | jq -r '.cost.total_duration_ms // empty')
cache_read=$(echo "$input"  | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
cache_write=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
sid=$(echo "$input"         | jq -r '.session_id // ""')
rl5_pct=$(echo "$input"     | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl5_reset=$(echo "$input"   | jq -r '.rate_limits.five_hour.resets_at // empty')
rl7_pct=$(echo "$input"     | jq -r '.rate_limits.seven_day.used_percentage // empty')
rl7_reset=$(echo "$input"   | jq -r '.rate_limits.seven_day.resets_at // empty')

PIPE="\033[2m │ \033[0m"

# Context window size label
if [ "$ctx_size" -ge 1000000 ]; then
  ctx_label="1M"
elif [ "$ctx_size" -ge 200000 ]; then
  ctx_label="200k"
else
  ctx_label="${ctx_size}"
fi

# Context bar: 10 chars wide
bar=""
if [ -n "$used" ]; then
  ctx_int=$(printf "%.0f" "$used")
  filled=$(( ctx_int * 10 / 100 ))
  empty_c=$(( 10 - filled ))
  bar_inner=""
  for i in $(seq 1 $filled);  do bar_inner="${bar_inner}█"; done
  for i in $(seq 1 $empty_c); do bar_inner="${bar_inner}░"; done
  if   [ "$ctx_int" -ge 80 ]; then bar_color="\033[31m"
  elif [ "$ctx_int" -ge 50 ]; then bar_color="\033[33m"
  else                              bar_color="\033[32m"
  fi
  bar=$(printf "${bar_color}${bar_inner} %s%%\033[0m" "$ctx_int")
fi

# Git branch — red on main/master, green on feature branches
branch=""
branch_str=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" -c core.hooksPath=/dev/null symbolic-ref --short HEAD 2>/dev/null \
           || git -C "$cwd" -c core.hooksPath=/dev/null rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
      branch_str=$(printf "\033[31m⎇ %s\033[0m" "$branch")
    else
      branch_str=$(printf "\033[32m⎇ %s\033[0m" "$branch")
    fi
  fi
fi

# Dir name (basename only)
dir_name=$(basename "$cwd")

# Cost
cost_str=""
if [ -n "$cost" ] && [ "$cost" != "null" ]; then
  cost_str=$(printf "\$%.2f" "$cost")
fi

# Duration — ms to human-readable
dur_str=""
if [ -n "$dur_ms" ] && [ "$dur_ms" != "null" ]; then
  dur_sec=$(( ${dur_ms%.*} / 1000 ))
  if [ "$dur_sec" -ge 3600 ]; then
    dur_str=$(printf "%dh%02dm" $(( dur_sec / 3600 )) $(( (dur_sec % 3600) / 60 )))
  elif [ "$dur_sec" -ge 60 ]; then
    dur_str=$(printf "%dm%02ds" $(( dur_sec / 60 )) $(( dur_sec % 60 )))
  else
    dur_str=$(printf "%ds" "$dur_sec")
  fi
fi

# Cache in k
cache_read_k=$(( cache_read / 1000 ))
cache_write_k=$(( cache_write / 1000 ))
cache_str="⚡ ${cache_read_k}k↓ ${cache_write_k}k↑"

# Short session ID (first 8 chars)
sid_short="${sid:0:8}"

# Rate limit helper: unix timestamp -> time until reset
format_reset() {
  local ts="$1"
  if [ -z "$ts" ] || [ "$ts" = "null" ]; then echo ""; return; fi
  local now
  now=$(date +%s)
  local diff=$(( ts - now ))
  if [ "$diff" -le 0 ]; then echo "now"; return; fi
  local d=$(( diff / 86400 ))
  local h=$(( (diff % 86400) / 3600 ))
  local m=$(( (diff % 3600) / 60 ))
  if [ "$d" -gt 0 ]; then
    printf "%dd %dh %02dm" "$d" "$h" "$m"
  elif [ "$h" -gt 0 ]; then
    printf "%dh %02dm" "$h" "$m"
  else
    printf "%dm" "$m"
  fi
}

# --- assemble ---

# Line 1: 🤖 model [ctx_size] | context bar | ⎇ branch
line1=$(printf "🤖 \033[36m%s\033[0m \033[2m[%s]\033[0m" "$model_name" "$ctx_label")
[ -n "$bar" ]        && line1="${line1}${PIPE}${bar}"
[ -n "$branch_str" ] && line1="${line1}${PIPE}${branch_str}"

# Line 2: 📁 dir | 💰 cost | ⏱ duration | cache | 🔑 sid
line2=$(printf "📁 \033[33m%s\033[0m" "$dir_name")
[ -n "$cost_str" ] && line2="${line2}${PIPE}💰 ${cost_str}"
[ -n "$dur_str"  ] && line2="${line2}${PIPE}⏱ ${dur_str}"
line2="${line2}${PIPE}\033[2m${cache_str}\033[0m"
[ -n "$sid_short" ] && line2="${line2}${PIPE}\033[2m# ${sid_short}\033[0m"

printf "%b\n%b\n" "$line1" "$line2"

# Line 3: rate limits with reset times (only when available)
if [ -n "$rl5_pct" ] && [ "$rl5_pct" != "null" ]; then
  rl5_int=$(printf "%.0f" "$rl5_pct")
  if   [ "$rl5_int" -ge 80 ]; then rl5_color="\033[31m"
  elif [ "$rl5_int" -ge 50 ]; then rl5_color="\033[33m"
  else                              rl5_color="\033[32m"
  fi
  reset5=$(format_reset "$rl5_reset")
  rl5_str=$(printf "🔄 ${rl5_color}5h: %s%%\033[0m \033[2m(↺ %s)\033[0m" "$rl5_int" "$reset5")

  rl7_int=$(printf "%.0f" "$rl7_pct")
  if   [ "$rl7_int" -ge 80 ]; then rl7_color="\033[31m"
  elif [ "$rl7_int" -ge 50 ]; then rl7_color="\033[33m"
  else                              rl7_color="\033[32m"
  fi
  reset7=$(format_reset "$rl7_reset")
  rl7_str=$(printf "${rl7_color}7d: %s%%\033[0m \033[2m(↺ %s)\033[0m" "$rl7_int" "$reset7")

  printf "%b%b%b\n" "$rl5_str" "$PIPE" "$rl7_str"
fi
