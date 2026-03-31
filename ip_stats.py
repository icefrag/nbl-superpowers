from typing import List, Tuple
import re
from collections import Counter


def analyze(lines: List[str]) -> List[Tuple[str, int]]:
    """
    统计日志中每个IP出现的次数，返回Top 10

    Args:
        lines: 日志文件的所有行

    Returns:
        [(ip地址, 次数), ...] 按次数降序排列，返回Top 10
    """
    ip_pattern = re.compile(r'^(\S+)')
    ip_counts = Counter()

    for line in lines:
        match = ip_pattern.match(line)
        if match:
            ip = match.group(1)
            ip_counts[ip] += 1

    # 返回Top 10
    return ip_counts.most_common(10)
