# 2026-04-28 Spring Boot 与 Flowable 升级记录

## 背景

本次改动前先创建了 Git tag，用于保留升级前基线：

```bash
git checkout before-springboot-upgrade-20260428
```

## 改动内容

- Spring Boot 从 `2.7.0` 升级到 `2.7.18`。
- Flowable 从 `6.3.0` 升级到 `6.8.1`。
- MySQL 驱动从 `mysql:mysql-connector-java:5.1.45` 调整为 `com.mysql:mysql-connector-j`。
- `application.yml` 去掉真实数据库地址和密码，改用 `MYSQL_URL`、`MYSQL_USERNAME`、`MYSQL_PASSWORD` 环境变量。
- 新增 `.env.example`，提供本地环境变量示例。
- `.gitignore` 增加本地配置、日志、macOS 文件和 Maven 临时文件忽略规则。
- 新增 `src/test/resources/application.yml`，测试环境使用 H2 内存数据库，避免测试依赖真实 MySQL。
- README 增加升级前 tag 说明，并同步升级后的依赖和配置示例。

## 后续约定

后续每次有功能、依赖、配置或行为改动，都在 `docs/history/` 下新增一份历史记录文档。

文件命名建议：

```text
YYYY-MM-DD-change-summary.md
```

每份记录至少包含：

- 改动背景
- 改动内容
- 验证结果
- 兼容性或风险说明

## 验证

已执行：

```bash
mvn test
```

验证结果：通过。

升级过程中处理过两个兼容点：

- Flowable `6.8.1` 的 `ProcessDiagramGenerator.generateDiagram` 方法签名增加了 `boolean` 参数，已在流程图生成代码中补充。
- H2 `2.1.x` 默认不兼容 Flowable H2 建表脚本里的 `identity` 类型，测试环境已使用 `MODE=LEGACY`。
