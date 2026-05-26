#!/usr/bin/env python3
import os
import re
from datetime import datetime

def parse_duration(s):
    hours = 0
    minutes = 0
    h_match = re.search(r'(\d+)\s*hour', s)
    m_match = re.search(r'(\d+)\s*minute', s)
    if h_match:
        hours = int(h_match.group(1))
    if m_match:
        minutes = int(m_match.group(1))
    return hours * 60 + minutes

def get_minutes_since_midnight(time_str):
    try:
        dt = datetime.strptime(time_str, "%I:%M %p")
        return dt.hour * 60 + dt.minute
    except:
        return 0

def main():
    log_file = os.path.expanduser("~/.config/hypr/.cache/.uptime")
    today = datetime.now()
    today_str = today.strftime("%d/%m/%Y")
    
    # Run the existing update script to log current uptime
    os.system("bash ~/.config/hypr/scripts/uptime.sh > /dev/null 2>&1")
    
    if not os.path.exists(log_file):
        print("No usage data found. Run 'uptime.sh' to start tracking.")
        return

    total_today = 0
    sessions = {} # {session_id: max_uptime}
    current_session_id = 0
    last_uptime = -1
    
    with open(log_file, 'r') as f:
        for line in f:
            try:
                # Format: 26/05/2026, 05:31 PM -> 8 hours, 18 minutes
                if "->" not in line: continue
                date_part = line.split(",")[0].strip()
                duration_part = line.split("->")[1].strip()
                uptime_min = parse_duration(duration_part)
                
                if uptime_min < last_uptime:
                    current_session_id += 1
                
                last_uptime = uptime_min
                
                if date_part == today_str:
                    sessions[current_session_id] = max(sessions.get(current_session_id, 0), uptime_min)
            except Exception:
                continue
    
    total_today = sum(sessions.values())
    
    if total_today == 0:
        # Fallback if log was empty or today hasn't been logged yet
        print("No usage recorded for today yet.")
        return

    h = total_today // 60
    m = total_today % 60
    
    output = f"Today's Overall Usage: "
    if h > 0:
        output += f"{h}h "
    output += f"{m}m"
    
    print(output)
    
    # Send a notification with the total as well
    os.system(f'notify-send -i "$HOME/.config/hypr/icons/pc.png" "Screen Time" "{output}"')

if __name__ == "__main__":
    main()
