from typing import List, Dict
import re
from collections import Counter


def analyze(lines: List[str]) -> Dict[int, int]:
    """
    统计HTTP状态码的分布

    Args:
        lines: 日志文件的所有行

    Returns:
        {状态码: 次数} 按状态码升序排列
    """
    # 匹配末尾的状态码: "... 200 1234"
    status_pattern = re.compile(r' (\d{3}) \d+$')
    status_counts = Counter()

    for line in lines:
        match = status_pattern.search(line)
        if match:
            status_code = int(match.group(1))
            status_counts[status_code] += 1

    # 按键排序返回字典
    return dict(sorted(status_counts.items()))
