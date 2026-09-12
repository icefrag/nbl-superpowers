---
name: dev-standards
description: >
  guozhi 项目开发规范唯一入口（架构原则/开发规范/命名规范，按场景动态加载）。
  触发条件：在 guozhi 项目中编写、修改、重构或 review 任何 Java/SQL/Mapper XML 代码之前；
  撰写技术设计文档、技术方案之前；设计新服务、新模块、新接口、新表之前。
  必须先调起本 skill 并按路由表读取对应规范文件后再动手。
---

# Dev Standards（guozhi 开发规范）

规范的唯一事实来源是本目录下五个文件，本 SKILL.md 只做路由，不复制任何规则内容。

## 路由表

按当前任务场景读取对应文件（场景叠加时全部读取）：

| 场景 | 必读文件 |
|------|---------|
| 技术设计文档/技术方案、新服务或新模块定位、架构分层、包结构设计 | `architecture.md` |
| 编写/修改 Java 代码、SQL 建表/DML、Mapper XML | `coding-conventions.md` |
| 新建类/接口/枚举/Req/Resp/Entity 或其字段命名 | `naming.md` |
| 涉及文件/附件上传、资源绑定、资源回显或释放（ResourceApi / RefManagementApi） | `res-service.md` |

实现一个新功能通常 = architecture + coding-conventions + naming 三份全读。

## 完成自检

声称任务完成之前，重读本次改动涉及的规范文件，逐条核对改动是否违规，有违规先修复再交付。
