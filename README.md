# springboot-flowable

Spring Boot 整合 Flowable 的入门示例项目。项目用一个“出差报销审批”流程演示 Flowable 的基本用法：启动流程、查询待办、完成任务、驳回任务、查看当前流程图。

[GitHub](https://github.com/Rodert/springboot-flowable) | [Gitee](https://gitee.com/rodert/springboot-flowable) | [GitHub Pages](https://rodert.github.io/springboot-flowable/)

## 适合谁看

如果你刚接触 Flowable、BPMN、工作流，建议先跑通这个项目，再回头看代码。这个项目没有复杂业务系统，只保留了工作流最常见的几个动作：

- 发起一个报销流程
- 根据报销金额自动走不同审批人
- 查询某个人的待办任务
- 审批通过或驳回
- 在浏览器里查看流程当前走到哪一步

## 技术版本

| 技术 | 版本 |
| --- | --- |
| Java | 1.8 |
| Spring Boot | 2.7.18 |
| Flowable | 6.8.1 |
| MySQL 驱动 | `com.mysql:mysql-connector-j` |
| 构建工具 | Maven |

升级前代码已打 tag：

```bash
git checkout before-springboot-upgrade-20260428
```

## 项目结构

```text
springboot-flowable
├── pom.xml
├── src/main/java/com/javapub/flowable/myflowable
│   ├── SpringbootFlowableApplication.java     # 启动类
│   ├── conf/FlowableConfig.java               # 流程图中文字体配置
│   ├── controller/ExpenseController.java      # 报销流程接口
│   └── task
│       ├── ManagerTaskHandler.java            # 经理审批任务分配
│       └── BossTaskHandler.java               # 老板审批任务分配
└── src/main/resources
    ├── application.yml                        # 本地运行配置
    └── processes/ExpenseProcess.bpmn20.xml    # BPMN 流程定义文件
```

## 先理解这个流程

这个示例流程叫 `Expense`，流程文件在：

```text
src/main/resources/processes/ExpenseProcess.bpmn20.xml
```

流程大致如下：

```text
开始
  |
出差报销任务，分配给发起人 userId
  |
判断报销金额 money
  |-- money <= 500 --> 经理审批
  |                     |-- 通过 --> 结束
  |                     |-- 驳回 --> 回到出差报销
  |
  |-- money > 500  --> 老板审批
                        |-- 通过 --> 结束
                        |-- 驳回 --> 回到出差报销
```

这里有一个新手很容易误会的地方：调用 `/expense/add` 只是“发起流程”，流程启动后第一个待办是“出差报销”，它分配给你传入的 `userId`。你需要先完成这个待办，流程才会根据金额进入“经理审批”或“老板审批”。

## 环境准备

### 1. 安装 JDK 8

项目使用 Java 8。确认命令：

```bash
java -version
```

看到类似 `1.8.0_xxx` 即可。

### 2. 安装 Maven

确认命令：

```bash
mvn -version
```

如果命令不存在，需要先安装 Maven。

### 3. 准备 MySQL

本地启动 MySQL 后，创建数据库：

```sql
CREATE DATABASE `javapub-flowable2`
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_ci;
```

注意：第一次启动项目时，Flowable 会自动创建自己的工作流表，例如 `ACT_RU_TASK`、`ACT_RE_PROCDEF`、`ACT_HI_TASKINST` 等，不需要你手动建这些表。

## 配置数据库

配置文件在：

```text
src/main/resources/application.yml
```

默认配置如下：

```yml
spring:
  datasource:
    url: ${MYSQL_URL:jdbc:mysql://localhost:3306/javapub-flowable2?characterEncoding=UTF-8&serverTimezone=Asia/Shanghai}
    username: ${MYSQL_USERNAME:root}
    password: ${MYSQL_PASSWORD:}
    driver-class-name: com.mysql.cj.jdbc.Driver
flowable:
  async-executor-activate: false
  database-schema-update: true
server:
  port: 8081
```

如果你的 MySQL 用户名、密码不是 `root` 和空密码，有两种改法。

方式一：直接改 `application.yml`：

```yml
spring:
  datasource:
    username: root
    password: 你的密码
```

方式二：启动时通过环境变量覆盖：

```bash
MYSQL_USERNAME=root MYSQL_PASSWORD=你的密码 mvn spring-boot:run
```

`flowable.database-schema-update=true` 表示启动时自动检查并创建 Flowable 表。开发学习时这样最方便；生产环境不要随便打开，应该由数据库变更脚本管理表结构。

## 启动项目

### 方式一：本地启动

在项目根目录执行：

```bash
mvn spring-boot:run
```

启动成功后，服务地址是：

```text
http://localhost:8081
```

如果启动时报数据库连接失败，优先检查三件事：

- MySQL 是否已经启动
- `javapub-flowable2` 数据库是否已经创建
- `application.yml` 里的用户名和密码是否正确

### 方式二：Docker Compose 启动

项目已提供 `Dockerfile` 和 `docker-compose.yml`，会同时启动应用和 MySQL。你只需要本机安装并启动 Docker。

在项目根目录执行：

```bash
docker compose up --build
```

启动后服务地址仍然是：

```text
http://localhost:8081
```

`docker-compose.yml` 默认配置：

| 服务 | 端口 | 说明 |
| --- | --- | --- |
| `app` | `8081:8081` | Spring Boot 应用 |
| `mysql` | `3306:3306` | MySQL 8.0 |

Docker Compose 会自动创建数据库 `javapub-flowable2`，应用通过下面的环境变量连接容器内的 MySQL：

```yml
MYSQL_URL: jdbc:mysql://mysql:3306/javapub-flowable2?characterEncoding=UTF-8&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true&useSSL=false
MYSQL_USERNAME: root
MYSQL_PASSWORD: ""
```

常用命令：

```bash
# 后台启动
docker compose up -d --build

# 查看日志
docker compose logs -f app

# 停止服务
docker compose down

# 停止服务并删除 MySQL 数据卷
docker compose down -v
```

如果本机已经有 MySQL 占用 `3306` 端口，可以修改 `docker-compose.yml` 中 MySQL 的端口映射，例如改成：

```yml
ports:
  - "3307:3306"
```

## 接口体验

下面用浏览器或 Postman 都可以测试。为了方便复制，这里都使用 GET 请求。

### 1. 发起报销流程

```text
http://localhost:8081/expense/add?userId=123&money=2000&descption=出差打车
```

返回示例：

```text
提交成功.流程Id为：2501
```

这里的 `2501` 是流程实例 ID，后面查看流程图时要用。你的本地返回值可能不是 `2501`，以实际返回为准。

参数说明：

| 参数 | 示例 | 说明 |
| --- | --- | --- |
| `userId` | `123` | 发起人，也是第一个“出差报销”待办的处理人 |
| `money` | `2000` | 报销金额，决定走经理审批还是老板审批 |
| `descption` | `出差打车` | 描述字段，当前代码接收了这个参数，但暂时没有保存到流程变量 |

### 2. 查询发起人的待办

```text
http://localhost:8081/expense/list?userId=123
```

返回示例：

```text
[Task[id=2507, name=出差报销]]
```

这里的 `2507` 是任务 ID。后面审批通过或驳回时要传 `taskId=2507`。你的任务 ID 以本地实际返回为准。

### 3. 发起人完成“出差报销”任务

```text
http://localhost:8081/expense/apply?taskId=2507
```

返回：

```text
processed ok!
```

完成后，流程会根据金额进入下一步：

- `money <= 500`：进入“经理审批”，任务分配给 `经理`
- `money > 500`：进入“老板审批”，任务分配给 `老板`

### 4. 查询审批人的待办

如果第 1 步传的是 `money=2000`，金额大于 500，查询老板待办：

```text
http://localhost:8081/expense/list?userId=老板
```

返回示例：

```text
[Task[id=2513, name=老板审批]]
```

如果金额小于等于 500，查询经理待办：

```text
http://localhost:8081/expense/list?userId=经理
```

### 5. 审批通过

把第 4 步查到的任务 ID 传进去：

```text
http://localhost:8081/expense/apply?taskId=2513
```

返回：

```text
processed ok!
```

审批通过后流程结束，再用这个流程实例 ID 查看流程图时，接口会直接返回空内容，因为代码里写了“流程走完的不显示图”。

### 6. 审批驳回

如果审批人不同意，可以调用：

```text
http://localhost:8081/expense/reject?taskId=2513
```

返回：

```text
reject
```

驳回后，流程会回到“出差报销”任务，重新分配给发起人。比如最开始 `userId=123`，驳回后再查：

```text
http://localhost:8081/expense/list?userId=123
```

就能看到新的“出差报销”待办。

### 7. 查看流程图

流程还没有结束时，可以用流程实例 ID 查看当前节点：

```text
http://localhost:8081/expense/processDiagram?processId=2501
```

浏览器会显示一张 PNG 流程图，并高亮当前正在执行的节点。

如果图片里的中文乱码，重点检查 `FlowableConfig.java` 里的字体配置。当前项目设置为宋体：

```java
engineConfiguration.setActivityFontName("宋体");
engineConfiguration.setLabelFontName("宋体");
engineConfiguration.setAnnotationFontName("宋体");
```

Linux 或 Docker 环境里如果没有宋体，需要安装中文字体，或者改成系统中已经存在的中文字体。

## 完整测试路径

下面是一条完整的大额报销流程：

```text
1. 发起流程
GET http://localhost:8081/expense/add?userId=123&money=2000

2. 查询 123 的待办，拿到“出差报销”的 taskId
GET http://localhost:8081/expense/list?userId=123

3. 完成“出差报销”任务
GET http://localhost:8081/expense/apply?taskId=上一步查到的taskId

4. 查询老板待办，拿到“老板审批”的 taskId
GET http://localhost:8081/expense/list?userId=老板

5. 老板审批通过
GET http://localhost:8081/expense/apply?taskId=上一步查到的taskId
```

小额报销只需要把 `money=2000` 改成 `money=200`，第 4 步查询 `经理` 的待办即可：

```text
GET http://localhost:8081/expense/list?userId=经理
```

## 核心代码说明

### 启动流程

代码位置：

```text
src/main/java/com/javapub/flowable/myflowable/controller/ExpenseController.java
```

核心代码：

```java
HashMap<String, Object> map = new HashMap<>();
map.put("taskUser", userId);
map.put("money", money);
ProcessInstance processInstance = runtimeService.startProcessInstanceByKey("Expense", map);
```

含义：

- `Expense` 对应 BPMN 文件里的 `<process id="Expense">`
- `taskUser` 会被 BPMN 中的 `${taskUser}` 使用，用来指定发起人的待办
- `money` 会被 BPMN 网关条件使用，用来判断走经理还是老板

### 查询待办

```java
taskService.createTaskQuery()
    .taskAssignee(userId)
    .orderByTaskCreateTime()
    .desc()
    .list();
```

含义：查询某个办理人的当前待处理任务。

### 完成任务

```java
HashMap<String, Object> map = new HashMap<>();
map.put("outcome", "通过");
taskService.complete(taskId, map);
```

`outcome` 会被 BPMN 流程线上的条件表达式使用：

```xml
${outcome=='通过'}
${outcome=='驳回'}
```

### 自动分配审批人

经理任务创建时会执行：

```java
delegateTask.setAssignee("经理");
```

老板任务创建时会执行：

```java
delegateTask.setAssignee("老板");
```

所以查询审批人待办时，`userId` 要传中文的 `经理` 或 `老板`。

## 常见问题

### 1. 为什么 `/expense/list?userId=老板` 查不到任务？

先确认你是否完成了发起人的“出差报销”任务。刚调用 `/expense/add` 后，流程不会直接到老板审批，而是先给发起人生成一个“出差报销”待办。

大额报销的顺序是：

```text
add -> list?userId=123 -> apply 发起人的 taskId -> list?userId=老板
```

### 2. 为什么查经理还是查老板？

看 `money`：

- `money <= 500`：查 `经理`
- `money > 500`：查 `老板`

### 3. 为什么浏览器打开流程图是空白？

如果流程已经结束，`/expense/processDiagram` 会返回空内容。当前代码里有这一段：

```java
if (pi == null) {
    return;
}
```

意思是：运行中的流程实例查不到，说明流程已经结束或 ID 不对。

### 4. 启动时提示表不存在怎么办？

确认配置里有：

```yml
flowable:
  database-schema-update: true
```

并确认数据库用户有建表权限。

### 5. 启动时提示数据库连接失败怎么办？

按顺序检查：

- MySQL 是否启动
- 数据库名是否是 `javapub-flowable2`
- 用户名、密码是否正确
- MySQL 地址和端口是否是 `localhost:3306`

### 6. `descption` 是不是拼错了？

是的，英文通常写作 `description`。当前代码参数名是 `descption`，README 按代码实际参数说明，避免你调用接口时对不上。如果要改成 `description`，需要同步修改 Controller 参数和调用地址。

## 单元测试

测试环境使用 H2 内存数据库，配置在：

```text
src/test/resources/application.yml
```

执行测试：

```bash
mvn test
```

测试环境不会连接你的本地 MySQL。

## 视频教程

[点击观看视频](https://www.bilibili.com/video/BV1fa411j7Q5/) | [点击下载原文](https://mp.weixin.qq.com/s/hWwzSu-SlyTzzzHUrA7OXQ)

## BPMN 插件

如果你想在 IDE 里可视化查看或编辑 BPMN 文件，可以安装：

```text
Flowable BPMN visualizer
```

安装后打开：

```text
src/main/resources/processes/ExpenseProcess.bpmn20.xml
```

就能看到流程图。

## 开发者在线工具

[JSON 格式化工具](https://rodert.github.io/jsonformat/)

## GitHub Pages

[查看项目开发流程页面](https://rodert.github.io/springboot-flowable/)
