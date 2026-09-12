# res 资源服务使用规范（common-platform）

> 本文件所有规则均为 NON-NEGOTIABLE。

## 核心概念

- `resourceId`：前端上传文件后从 res 平台获得的资源 ID，只在绑定瞬间使用，禁止落业务库
- `refId`：绑定关系 ID，业务侧持久化的是 refId，resourceId 随时可通过 refId 反查
- `bizType` / `bizId`：绑定归属；bizType 用业务常量，bizId 用业务主键
- 通过 Feign 注入（`@RequiredArgsConstructor` + `final`）：
  - `ResourceApi`：资源详情查询，用于写入前校验
  - `RefManagementApi`：ref 的绑定 / 回显查询 / 释放

## 绑定 ref（写入路径）

三步：校验 → 全量绑定 → 落库 refId

```java
// ① 校验资源存在且有权访问（信任边界，必须做）
List<ResourceDetailResp> resources = resourceApi.getResourceDetails(resourceIds, operatorId, tenantId);
// 比对返回 id 集合与入参一致，不一致 → BizException.wrap(ClientResponseCode.BAD_REQUEST, "...")

// ② 全量绑定：每次把当前全量 resourceId 一次提交
BatchCreateRefReq req = new BatchCreateRefReq();
req.setTenantId(tenantId);
req.setBizType(BUSINESS_REF_TYPE);              // 业务常量
BatchCreateRefReq.BizRefItem refItem = new BatchCreateRefReq.BizRefItem();
refItem.setBizId(bizId);
refItem.setResourceIds(resourceIds);
req.setBizRefs(List.of(refItem));
req.setCreatedBy(operatorId);
List<BatchCreateRefResp> refs = refManagementApi.batchCreateRef(req);

// ③ 核对返回完整后，建 resourceId→refId 映射，组装业务数据落库
```

- **全量直传**：每次保存提交当前全量 resourceId，禁止自行维护「已有 ref 复用 / 新增才绑」的差量逻辑
- **返回完整性校验**：绑定返回的 resourceId 集合与入参不一致即抛错，禁止带残缺映射落库
- **旧 ref 不在 save 时释放**（可能仍被正式数据引用），由发布覆盖 / 数据删除两个时点兜底回收

## 释放 ref（删除 / 兜底路径）

```java
DeleteRefReq req = new DeleteRefReq();
req.setTenantId(tenantId);
req.setRefIds(staleRefIds);
refManagementApi.deleteRef(req);
```

- **差量释放**：数据正式覆盖或删除时，只释放「旧集合有而新集合没有」的 refIds
- **兜底场景失败不阻断**：try/catch + `log.warn`，释放失败不影响主流程；只有写路径强校验才抛错

## 回显（返回资源给前端）

```java
// 按 refIds 批量反查；调用前先做空集合守卫
if (CollUtil.isEmpty(refIds)) { return Collections.emptyMap(); }
List<RefResourceDetailResp> details = refManagementApi.listByRefs(
        BatchQueryRefDetailReq.builder().tenantId(tenantId).refIds(refIds).build());
```

- **自定义业务 Resp 全字段镜像** `RefResourceDetailResp`，禁止自行挑选字段子集
- **枚举转 name 字符串**：`previewWay` / `type` / `status` 用 `value == null ? null : value.name()`
- **previewUri 兜底派生**：平台未返回且 objectKey 非空时，置 `"/preview?previewKey=" + objectKey`
- **读路径失败降级**：listByRefs 异常时 catch + `log.warn`，仅返回业务自身字段，不阻断详情接口
- **每次全量批量查**：按当前数据持有的 refIds 整批查，禁止循环单条查（N+1）

## 通用注意

- 所有调用必传 `tenantId`；创建类操作 `createdBy` 传 `operatorId`
- 集合参数先空守卫（`CollUtil.isEmpty`）再调接口，避免无效远程调用
- **读路径降级、写路径强校验**——两类错误处理策略不可混用
