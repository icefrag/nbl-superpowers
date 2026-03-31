from typing import List, Tuple
import re
from collections import Counter


def analyze(lines: List[str]) -> List[Tuple[str, int]]:
    """
    统计访问最多的Top 10 URL路径

    Args:
        lines: 日志文件的所有行

    Returns:
        [(URL路径, 次数), ...] 按次数降序排列，返回Top 10
    """
    # 匹配请求行: "GET /index.html HTTP/1.1" 提取URL路径
    url_pattern = re.compile(r'"(?:GET|POST|PUT|DELETE|HEAD|OPTIONS|PATCH) (\S+)')
    url_counts = Counter()

    for line in lines:
        match = url_pattern.search(line)
        if match:
            url = match.group(1)
            url_counts[url] += 1

    # 返回Top 10
    return url_counts.most_common(10)
