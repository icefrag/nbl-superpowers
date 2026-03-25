#!/usr/bin/env node

/**
 * Guozhi Claude Code 同步工具
 * 同步 commands/skills/rules/agents 到用户 .claude 目录
 *
 * 使用方式:
 *   node sync.mjs              # 交互模式
 *   node sync.mjs --non-interactive  # 全量同步（非交互模式）
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { homedir } from 'node:os';
import inquirer from 'inquirer';
import chalk from 'chalk';
import fsExtra from 'fs-extra';

// 获取脚本所在目录
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// 解析命令行参数
const args = process.argv.slice(2);
const nonInteractive = args.includes('--non-interactive') || args.includes('-y');

// 配置
const targets = {
  commands: {
    source: path.join(__dirname, 'commands'),
    dest: path.join(homedir(), '.claude', 'commands'),
  },
  skills: {
    source: path.join(__dirname, 'skills'),
    dest: path.join(homedir(), '.claude', 'skills'),
  },
  rules: {
    source: path.join(__dirname, 'rules'),
    dest: path.join(homedir(), '.claude', 'rules'),
  },
  agents: {
    source: path.join(__dirname, 'agents'),
    dest: path.join(homedir(), '.claude', 'agents'),
  },
};

// 日志函数
const log = {
  info: (msg) => console.log(chalk.cyan('[信息]'), msg),
  success: (msg) => console.log(chalk.green('[完成]'), msg),
  warn: (msg) => console.log(chalk.yellow('[警告]'), msg),
  error: (msg) => console.log(chalk.red('[错误]'), msg),
  header: (msg) => console.log(chalk.white(msg)),
  divider: () => console.log(chalk.gray('─'.repeat(50))),
};

// 获取目录文件数量
function getFileCount(dirPath, recursive = true) {
  if (!fs.existsSync(dirPath)) return 0;
  let count = 0;
  const items = fs.readdirSync(dirPath, { withFileTypes: true });
  for (const item of items) {
    if (item.isFile()) {
      count++;
    } else if (item.isDirectory() && recursive) {
      count += getFileCount(path.join(dirPath, item.name), true);
    }
  }
  return count;
}

// 获取目录结构（用于菜单展示）
function getDirectoryStructure(dirPath, relativePath = '') {
  if (!fs.existsSync(dirPath)) return [];

  const items = fs.readdirSync(dirPath, { withFileTypes: true });
  const result = [];

  // 先添加目录
  const dirs = items.filter((item) => item.isDirectory()).sort((a, b) => a.name.localeCompare(b.name));
  for (const dir of dirs) {
    const fullPath = path.join(dirPath, dir.name);
    const fileCount = getFileCount(fullPath);
    result.push({
      type: 'directory',
      name: dir.name,
      path: fullPath,
      relativePath: path.join(relativePath, dir.name),
      display: `${dir.name}/ (${fileCount} 个文件)`,
    });
  }

  // 再添加文件
  const files = items.filter((item) => item.isFile()).sort((a, b) => a.name.localeCompare(b.name));
  for (const file of files) {
    result.push({
      type: 'file',
      name: file.name,
      path: path.join(dirPath, file.name),
      relativePath: path.join(relativePath, file.name),
      display: file.name,
    });
  }

  return result;
}

// 同步整个目录（覆盖模式）
async function syncFullDirectory(source, dest, name) {
  if (!fs.existsSync(source)) {
    log.error(`源目录不存在: ${source}`);
    return 0;
  }

  // 确保目标目录存在
  if (!fs.existsSync(dest)) {
    fs.mkdirSync(dest, { recursive: true });
    log.info(`已创建目录: ${dest}`);
  }

  let copied = 0;

  // 递归复制所有文件
  const copyRecursive = (src, dst) => {
    const entries = fs.readdirSync(src, { withFileTypes: true });
    for (const entry of entries) {
      const srcPath = path.join(src, entry.name);
      const dstPath = path.join(dst, entry.name);

      if (entry.isDirectory()) {
        if (!fs.existsSync(dstPath)) {
          fs.mkdirSync(dstPath, { recursive: true });
        }
        copyRecursive(srcPath, dstPath);
      } else {
        const destDir = path.dirname(dstPath);
        if (!fs.existsSync(destDir)) {
          fs.mkdirSync(destDir, { recursive: true });
        }
        fs.copyFileSync(srcPath, dstPath);
        copied++;
      }
    }
  };

  copyRecursive(source, dest);
  log.success(`${name}: 已复制 ${copied} 个文件（覆盖模式）`);
  return copied;
}

// 同步单个文件
async function syncSingleFile(srcPath, destDir, relativePath) {
  const destFile = path.join(destDir, relativePath);
  const destFileDir = path.dirname(destFile);

  if (!fs.existsSync(destFileDir)) {
    fs.mkdirSync(destFileDir, { recursive: true });
  }

  fs.copyFileSync(srcPath, destFile);
  log.success(`已复制: ${relativePath}`);
  return 1;
}

// 浏览并选择文件/目录同步
async function browseAndSync(source, dest, currentPath = source, depth = 0) {
  const structure = getDirectoryStructure(currentPath);

  if (structure.length === 0) {
    log.warn('目录为空');
    return 0;
  }

  // 显示文件菜单
  console.log();
  log.header(currentPath);
  log.divider();

  // 如果不是根目录，添加返回选项
  const choices = [];
  if (depth > 0) {
    choices.push({ name: '.. (返回上级)', value: 'parent', type: 'directory' });
  }

  for (const item of structure) {
    const emoji = item.type === 'directory' ? '📁' : '📄';
    const color = item.type === 'directory' ? chalk.cyan : chalk.green;
    choices.push({
      name: `${emoji} ${item.display}`,
      value: item.path,
      type: item.type,
      relativePath: item.relativePath,
    });
  }

  choices.push({ name: '返回主菜单', value: 'back', type: 'cancel' });

  const { selection } = await inquirer.prompt([
    {
      type: 'list',
      name: 'selection',
      message: '请选择:',
      choices: choices,
    },
  ]);

  if (selection === 'back' || selection === 'parent') {
    if (selection === 'parent' && depth > 0) {
      return await browseAndSync(source, dest, path.dirname(currentPath), depth - 1);
    }
    return 0;
  }

  const selectedItem = choices.find((c) => c.value === selection);

  if (selectedItem.type === 'directory') {
    // 目录操作菜单
    console.log();
    log.header(`📁 ${selectedItem.value}`);
    log.divider();

    const { action } = await inquirer.prompt([
      {
        type: 'list',
        name: 'action',
        message: '选择操作:',
        choices: [
          { name: '1. 同步整个文件夹（覆盖）', value: 'sync' },
          { name: '2. 浏览文件夹内容', value: 'browse' },
          { name: '0. 返回', value: 'back' },
        ],
      },
    ]);

    if (action === 'sync') {
      const relativePath = path.relative(source, selectedItem.value);
      const targetDir = path.join(dest, relativePath);
      return await syncFullDirectory(selectedItem.value, targetDir, path.basename(selectedItem.value));
    } else if (action === 'browse') {
      return await browseAndSync(source, dest, selectedItem.value, depth + 1);
    }
    return 0;
  } else {
    // 文件操作
    const relativePath = path.relative(source, selectedItem.value);
    return await syncSingleFile(selectedItem.value, dest, relativePath);
  }
}

// 主菜单
async function showMainMenu() {
  const destDir = path.join(homedir(), '.claude');

  // 计算各目录文件数量
  const counts = {};
  let total = 0;
  for (const [key, config] of Object.entries(targets)) {
    counts[key] = fs.existsSync(config.source) ? getFileCount(config.source) : 0;
    total += counts[key];
  }

  console.log();
  log.header('═══ Guozhi Claude Code 同步工具 ═══');
  console.log(chalk.gray('目标目录:'), destDir);
  log.divider();

  const choices = [
    {
      name: chalk.cyan(`1. 全量同步 (${total} 个文件)`),
      value: 'full',
    },
    new inquirer.Separator(),
    {
      name: chalk.yellow(`2. commands (${counts.commands} 个文件)`),
      value: 'commands',
    },
    {
      name: chalk.yellow(`3. skills (${counts.skills} 个文件)`),
      value: 'skills',
    },
    {
      name: chalk.yellow(`4. rules (${counts.rules} 个文件)`),
      value: 'rules',
    },
    {
      name: chalk.yellow(`5. agents (${counts.agents} 个文件)`),
      value: 'agents',
    },
    new inquirer.Separator(),
    {
      name: chalk.gray('0. 退出'),
      value: 'exit',
    },
  ];

  const { option } = await inquirer.prompt([
    {
      type: 'list',
      name: 'option',
      message: '请选择:',
      choices: choices,
    },
  ]);

  return option;
}

// 全量同步
async function syncAll() {
  log.info('开始全量同步...');
  let total = 0;

  for (const [key, config] of Object.entries(targets)) {
    const count = await syncFullDirectory(config.source, config.dest, key);
    total += count;
  }

  console.log();
  log.success(`全量同步完成: 共 ${total} 个文件`);
}

// 单项同步
async function syncSingle(targetKey) {
  const config = targets[targetKey];

  if (!fs.existsSync(config.source)) {
    log.error(`源目录不存在: ${config.source}`);
    return;
  }

  console.log();
  log.header(`选择同步方式 - ${targetKey}`);
  log.divider();

  const { mode } = await inquirer.prompt([
    {
      type: 'list',
      name: 'mode',
      message: '请选择:',
      choices: [
        { name: '1. 同步整个目录（覆盖）', value: 'full' },
        { name: '2. 选择具体文件/文件夹', value: 'browse' },
        { name: '0. 返回', value: 'back' },
      ],
    },
  ]);

  if (mode === 'full') {
    await syncFullDirectory(config.source, config.dest, targetKey);
  } else if (mode === 'browse') {
    const count = await browseAndSync(config.source, config.dest);
    console.log();
    log.success(`已同步: ${count} 个文件`);
  }
}

// 主函数
async function main() {
  try {
    // 确保 .claude 目录存在
    const claudeDir = path.join(homedir(), '.claude');
    if (!fs.existsSync(claudeDir)) {
      fs.mkdirSync(claudeDir, { recursive: true });
      log.info(`已创建目录: ${claudeDir}`);
    }

    // 非交互模式 - 直接全量同步
    if (nonInteractive) {
      log.info('非交互模式 - 开始全量同步');
      await syncAll();
      process.exit(0);
    }

    // 交互模式
    while (true) {
      const option = await showMainMenu();

      if (option === 'exit') {
        console.log();
        log.info('再见!');
        break;
      }

      if (option === 'full') {
        await syncAll();
      } else {
        await syncSingle(option);
      }

      console.log();
    }
  } catch (error) {
    log.error(`发生错误: ${error.message}`);
    process.exit(1);
  }
}

main();
