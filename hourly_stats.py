from typing import List, Dict, Any
import re
from collections import Counter


def analyze(lines: List[str]) -> Dict[str, Any]:
    """
    按小时统计访问量，找出访问高峰时段

    Args:
        lines: 日志文件的所有行

    Returns:
        {
            "stats": {小时: 访问量},
            "peak_hour": 访问量最大的小时
        }
    """
    # 匹配时间: [10/Oct/2024:13:55:36 +0800] 提取小时
    hour_pattern = re.compile(r'\[\d{2}/\w{3}/\d{4}:(\d{2}):\d{2}:\d{2}')
    hourly_counts = Counter()

    for line in lines:
        match = hour_pattern.search(line)
        if match:
            hour = int(match.group(1))
            hourly_counts[hour] += 1

    # 确保0-23小时都有记录（0填充）
    stats = {hour: hourly_counts.get(hour, 0) for hour in range(24)}

    # 找出高峰小时（访问量最大的，如果相同取先出现的）
    if stats:
        peak_hour = max(stats.items(), key=lambda x: x[1])[0]
    else:
        peak_hour = None

    return {
        "stats": stats,
        "peak_hour": peak_hour
    }
