手把手实现springboot整合flowable、附源码-视频教程

[toc]

## 视频教程

<>

## 插件安装

BPMN绘图可视化工具

> Flowable BPMN visualizer

## 导入依赖

```xml

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <!--flowable工作流依赖-->
        <dependency>
            <groupId>org.flowable</groupId>
            <artifactId>flowable-spring-boot-starter</artifactId>
            <version>6.3.0</version>
        </dependency>
        <!--mysql依赖-->
        <dependency>
            <groupId>mysql</groupId>
            <artifactId>mysql-connector-java</artifactId>
            <version>5.1.45</version>
        </dependency>
```

## 新建数据库

database

> javapub-flowable2

## 修改配置

```yml
spring:
  datasource:
    url: jdbc:mysql://bj-cdb-mw08tjgs.sql.tencentcdb.com:60042/javapub-flowable2?characterEncoding=UTF-8
    username: root
    password: password
    driver-class-name: com.mysql.jdbc.Driver
flowable:
  #关闭定时任务JOB
  async-executor-activate: false
  database-schema-update: true
server:
  port: 8081
```

**配置说明：**


> database-schema-update: true

数据库更新策略，其取值有四个：

```xml
flase：       默认值。activiti在启动时，会对比数据库表中保存的版本，如果没有表或者版本不匹配，将抛出异常。（生产环境常用）
true：        activiti会对数据库中所有表进行更新操作。如果表不存在，则自动创建。（开发时常用）
create_drop： 在activiti启动时创建表，在关闭时删除表（必须手动关闭引擎，才能删除表）。（单元测试常用）
drop-create： 在activiti启动时删除原来的旧表，然后在创建新表（不需要手动关闭引擎）。
```


## 定义流程文件

这里还是用一个开源的流程文件

放在：resources/processes/ExpenseProcess.bpmn20.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:flowable="http://flowable.org/bpmn" xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"
             xmlns:omgdc="http://www.omg.org/spec/DD/20100524/DC" xmlns:omgdi="http://www.omg.org/spec/DD/20100524/DI"
             typeLanguage="http://www.w3.org/2001/XMLSchema" expressionLanguage="http://www.w3.org/1999/XPath"
             targetNamespace="http://www.flowable.org/processdef">
    <process id="Expense" name="ExpenseProcess" isExecutable="true">
        <documentation>报销流程</documentation>
        <startEvent id="start" name="开始"></startEvent>
        <userTask id="fillTask" name="出差报销" flowable:assignee="${taskUser}">
            <extensionElements>
                <modeler:initiator-can-complete xmlns:modeler="http://flowable.org/modeler">
                    <![CDATA[false]]></modeler:initiator-can-complete>
            </extensionElements>
        </userTask>
        <exclusiveGateway id="judgeTask"></exclusiveGateway>
        <userTask id="directorTak" name="经理审批">
            <extensionElements>
                <flowable:taskListener event="create"
                                       class="com.haiyang.flowable.listener.ManagerTaskHandler"></flowable:taskListener>
            </extensionElements>
        </userTask>
        <userTask id="bossTask" name="老板审批">
            <extensionElements>
                <flowable:taskListener event="create"
                                       class="com.haiyang.flowable.listener.BossTaskHandler"></flowable:taskListener>
            </extensionElements>
        </userTask>
        <endEvent id="end" name="结束"></endEvent>
        <sequenceFlow id="directorNotPassFlow" name="驳回" sourceRef="directorTak" targetRef="fillTask">
            <conditionExpression xsi:type="tFormalExpression"><![CDATA[${outcome=='驳回'}]]></conditionExpression>
        </sequenceFlow>
        <sequenceFlow id="bossNotPassFlow" name="驳回" sourceRef="bossTask" targetRef="fillTask">
            <conditionExpression xsi:type="tFormalExpression"><![CDATA[${outcome=='驳回'}]]></conditionExpression>
        </sequenceFlow>
        <sequenceFlow id="flow1" sourceRef="start" targetRef="fillTask"></sequenceFlow>
        <sequenceFlow id="flow2" sourceRef="fillTask" targetRef="judgeTask"></sequenceFlow>
        <sequenceFlow id="judgeMore" name="大于500元" sourceRef="judgeTask" targetRef="bossTask">
            <conditionExpression xsi:type="tFormalExpression"><![CDATA[${money > 500}]]></conditionExpression>
        </sequenceFlow>
        <sequenceFlow id="bossPassFlow" name="通过" sourceRef="bossTask" targetRef="end">
            <conditionExpression xsi:type="tFormalExpression"><![CDATA[${outcome=='通过'}]]></conditionExpression>
        </sequenceFlow>
        <sequenceFlow id="directorPassFlow" name="通过" sourceRef="directorTak" targetRef="end">
            <conditionExpression xsi:type="tFormalExpression"><![CDATA[${outcome=='通过'}]]></conditionExpression>
        </sequenceFlow>
        <sequenceFlow id="judgeLess" name="小于500元" sourceRef="judgeTask" targetRef="directorTak">
            <conditionExpression xsi:type="tFormalExpression"><![CDATA[${money <= 500}]]></conditionExpression>
        </sequenceFlow>
    </process>
    <bpmndi:BPMNDiagram id="BPMNDiagram_Expense">
        <bpmndi:BPMNPlane bpmnElement="Expense" id="BPMNPlane_Expense">
            <bpmndi:BPMNShape bpmnElement="start" id="BPMNShape_start">
                <omgdc:Bounds height="30.0" width="30.0" x="285.0" y="135.0"></omgdc:Bounds>
            </bpmndi:BPMNShape>
            <bpmndi:BPMNShape bpmnElement="fillTask" id="BPMNShape_fillTask">
                <omgdc:Bounds height="80.0" width="100.0" x="405.0" y="110.0"></omgdc:Bounds>
            </bpmndi:BPMNShape>
            <bpmndi:BPMNShape bpmnElement="judgeTask" id="BPMNShape_judgeTask">
                <omgdc:Bounds height="40.0" width="40.0" x="585.0" y="130.0"></omgdc:Bounds>
            </bpmndi:BPMNShape>
            <bpmndi:BPMNShape bpmnElement="directorTak" id="BPMNShape_directorTak">
                <omgdc:Bounds height="80.0" width="100.0" x="735.0" y="110.0"></omgdc:Bounds>
            </bpmndi:BPMNShape>
            <bpmndi:BPMNShape bpmnElement="bossTask" id="BPMNShape_bossTask">
                <omgdc:Bounds height="80.0" width="100.0" x="555.0" y="255.0"></omgdc:Bounds>
            </bpmndi:BPMNShape>
            <bpmndi:BPMNShape bpmnElement="end" id="BPMNShape_end">
                <omgdc:Bounds height="28.0" width="28.0" x="771.0" y="281.0"></omgdc:Bounds>
            </bpmndi:BPMNShape>
            <bpmndi:BPMNEdge bpmnElement="flow1" id="BPMNEdge_flow1">
                <omgdi:waypoint x="315.0" y="150.0"></omgdi:waypoint>
                <omgdi:waypoint x="405.0" y="150.0"></omgdi:waypoint>
            </bpmndi:BPMNEdge>
            <bpmndi:BPMNEdge bpmnElement="flow2" id="BPMNEdge_flow2">
                <omgdi:waypoint x="505.0" y="150.16611295681062"></omgdi:waypoint>
                <omgdi:waypoint x="585.4333333333333" y="150.43333333333334"></omgdi:waypoint>
            </bpmndi:BPMNEdge>
            <bpmndi:BPMNEdge bpmnElement="judgeLess" id="BPMNEdge_judgeLess">
                <omgdi:waypoint x="624.5530726256983" y="150.44692737430168"></omgdi:waypoint>
                <omgdi:waypoint x="735.0" y="150.1392757660167"></omgdi:waypoint>
            </bpmndi:BPMNEdge>
            <bpmndi:BPMNEdge bpmnElement="directorNotPassFlow" id="BPMNEdge_directorNotPassFlow">
                <omgdi:waypoint x="785.0" y="110.0"></omgdi:waypoint>
                <omgdi:waypoint x="785.0" y="37.0"></omgdi:waypoint>
                <omgdi:waypoint x="455.0" y="37.0"></omgdi:waypoint>
                <omgdi:waypoint x="455.0" y="110.0"></omgdi:waypoint>
            </bpmndi:BPMNEdge>
            <bpmndi:BPMNEdge bpmnElement="bossPassFlow" id="BPMNEdge_bossPassFlow">
                <omgdi:waypoint x="655.0" y="295.0"></omgdi:waypoint>
                <omgdi:waypoint x="771.0" y="295.0"></omgdi:waypoint>
            </bpmndi:BPMNEdge>
            <bpmndi:BPMNEdge bpmnElement="judgeMore" id="BPMNEdge_judgeMore">
                <omgdi:waypoint x="605.4340277777778" y="169.56597222222223"></omgdi:waypoint>
                <omgdi:waypoint x="605.1384083044983" y="255.0"></omgdi:waypoint>
            </bpmndi:BPMNEdge>
            <bpmndi:BPMNEdge bpmnElement="directorPassFlow" id="BPMNEdge_directorPassFlow">
                <omgdi:waypoint x="785.0" y="190.0"></omgdi:waypoint>
                <omgdi:waypoint x="785.0" y="281.0"></omgdi:waypoint>
            </bpmndi:BPMNEdge>
            <bpmndi:BPMNEdge bpmnElement="bossNotPassFlow" id="BPMNEdge_bossNotPassFlow">
                <omgdi:waypoint x="555.0" y="295.0"></omgdi:waypoint>
                <omgdi:waypoint x="455.0" y="295.0"></omgdi:waypoint>
                <omgdi:waypoint x="455.0" y="190.0"></omgdi:waypoint>
            </bpmndi:BPMNEdge>
        </bpmndi:BPMNPlane>
    </bpmndi:BPMNDiagram>
</definitions>
```

## 测试

1. 提交流程

> http://localhost:8081/expense/add?userId=123&money=2000

提交成功.流程Id为：2501

2. 待办列表查询

> http://localhost:8081/expense/list?userId=123

Task[id=2507, name=出差报销]

3. 同意

> http://localhost:8081/expense/apply?taskId=2507

processed ok!

4. 生成流程图

> http://localhost:8081/expense/processDiagram?processId=2501
>

## 源码领取

公众号：JavaPub

flowable

## 源码

源码下载：

[https://github.com/Rodert/springboot-flowable](https://github.com/Rodert/springboot-flowable) 

[https://gitee.com/rodert/springboot-flowable](https://gitee.com/rodert/springboot-flowable)

---
