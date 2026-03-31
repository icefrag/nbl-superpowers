import sys
from typing import List, Dict, Any

import ip_stats
import status_code_stats
import hourly_stats
import url_stats


def print_results(
    ip_result: List,
    status_result: Dict[int, int],
    hourly_result: Dict[str, Any],
    url_result: List
) -> None:
    """格式化打印所有结果"""

    print("\n" + "=" * 50)
    print("=== IP统计 Top 10 ===")
    print("=" * 50)
    for i, (ip, count) in enumerate(ip_result, 1):
        print(f"{i:2d}. {ip:<15} {count:>4} 次")

    print("\n" + "=" * 50)
    print("=== 状态码分布 ===")
    print("=" * 50)
    for code, count in status_result.items():
        print(f"{code}: {count} 次")

    print("\n" + "=" * 50)
    print("=== 访问时段统计 ===")
    print("=" * 50)
    stats = hourly_result["stats"]
    peak_hour = hourly_result["peak_hour"]
    # 两行打印，每12小时一行
    first_line = " ".join(f"{h:02d}:{stats[h]:<4}" for h in range(12))
    second_line = " ".join(f"{h:02d}:{stats[h]:<4}" for h in range(12, 24))
    print(first_line)
    print(second_line)
    if peak_hour is not None:
        print(f"\n高峰时段: {peak_hour:02d}点 ({stats[peak_hour]}次访问)")

    print("\n" + "=" * 50)
    print("=== URL统计 Top 10 ===")
    print("=" * 50)
    for i, (url, count) in enumerate(url_result, 1):
        print(f"{i:2d}. {url:<30} {count:>4} 次")
    print()


def main():
    if len(sys.argv) != 2:
        print("Usage: python main.py <log_file>")
        print("Example: python main.py sample.log")
        sys.exit(1)

    log_file = sys.argv[1]

    try:
        with open(log_file, 'r', encoding='utf-8') as f:
            lines = [line.rstrip('\n') for line in f if line.strip()]
    except FileNotFoundError:
        print(f"Error: File not found: {log_file}")
        sys.exit(1)
    except Exception as e:
        print(f"Error reading file: {e}")
        sys.exit(1)

    # 调用各模块分析
    ip_result = ip_stats.analyze(lines)
    status_result = status_code_stats.analyze(lines)
    hourly_result = hourly_stats.analyze(lines)
    url_result = url_stats.analyze(lines)

    # 打印结果
    print_results(ip_result, status_result, hourly_result, url_result)


if __name__ == "__main__":
    main()
