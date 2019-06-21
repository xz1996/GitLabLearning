
## 安装GitLab Runner

本教程的安装环境为Ubuntu18.04。

1. 运行以下命令增加GitLab官方仓库：

  ```bash
  curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash
  ```

2. 安装最新版本的GitLab Runner，或者选择特定的版本：

    - 安装最新版本

    ```bash
    sudo apt-get install gitlab-runner
    ```
    - 选择特定的版本

    ```bash
    sudo apt-get install gitlab-runner=10.0.0
    ```

---

## 注册GitLab Runner

此处是将你的GitLab Runner注册到GitLab page上，让GitLab page可以和你的Runner通信。

### 先决条件

在注册Runner之前，你首先需要：
- 安装好Runner的Linux主机
- 从GitLab page上获得token

### 注册

1. 运行如下命令：

  ```bash
  sudo gitlab-runner register
  ```

2. 输入GitLab URL：

  ```bash
  Please enter the gitlab-ci coordinator URL (e.g. https://gitlab.com )
  https://code.siemens.com/
  ```
  *注意：你可以通过```GitLab page -> Settings -> CI/CD -> Runners```来获得URL，当然前提条件是你有权限进入这些页面。*
  ![RegisterRunner.PNG](https://upload-images.jianshu.io/upload_images/15645146-2d71eb9ea70207a3.PNG?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

3. 输入你的注册token：

  ```bash
  Please enter the gitlab-ci token for this runner  
  xxx
  ```
  *在步骤2中你也可以同时看到 token信息*

4. 输入对这个Runner的表述（同时也是这个Runner的名字），当然，你也可以稍后在GitLab page上修改它：

  ```bash
  Please enter the gitlab-ci description for this runner  
  [hostame] my-runner
  ```

5. 输入Runner的[tag](https://docs.gitlab.com/ee/ci/runners/#using-tags)，稍后你同样可以在GitLab page上修改它：

  ```bash
  Please enter the gitlab-ci tags for this runner (comma separated):
  my-tag,another-tag
  ```
  *注意 tag可以有多个，各 tag之间用逗号隔开。如果你使用了多个 tag，那么当你想用这个 Runner时，在```.gitlab-ci.yml```的 tag字段里也必须明确指明这些 tags。*

6. 输入Runner的[executor](https://docs.gitlab.com/runner/executors/README.html)：

  ```bash
  Please enter the executor: ssh, docker+machine, docker-ssh+machine, kubernetes, docker, parallels, virtualbox, docker-ssh, shell:
  docker
  ```
  如果你选择Docker作为Runner的executor，你还要选择默认的docker image来运行job（当然，你也可以在```.gitlab-ci.yml```里指明你需要用的image）：

  ```bash
  Please enter the Docker image (eg. ruby:2.1):
  alpine:latest
  ```

*注册完成后你可以在```/etc/gitlab-runner```里发现 [```config.toml```](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-global-section)文件，该文件是Runner的配置文件*

---

## 使用GitLab Runner

- 直接运行Runner

  ```bash
  sudo gitlab-runner run
  ```
- 将Runner作为一个服务

  1. 将GitLab Runner安装为[系统服务](https://docs.gitlab.com/runner/configuration/init.html)：

    ```bash
    sudo gitlab-runner install -n "<service-name>" -u <user-name>
    ```
  2. 启动服务：

    ```bash
    sudo gitlab-runner start -n "<service-name>"
    ```
    *注意：这些[服务相关的命令](https://docs.gitlab.com/runner/commands/README.html#service-related-commands)是不推荐的并且将会在接下来的版本中删除。*

想要了解更多GitLab Runner相关的命令，请访问[GitLab Runner Commands](https://docs.gitlab.com/runner/commands/README.html).

---

### 重要的话题 —— Executor

### Shell Executor

以宿主机（此处为Ubuntu18.04系统）作为Runner的所有jobs的执行器。

Runner将会从远程仓库pull你的工程，工程的目录为：```<working-directory>/builds/<short-token>/<concurrent-id>/<namespace>/<project-name>```。

如果你使用了cache，那么cache将会存在```<working-directory>/cache/<namespace>/<project-name>```。

想了解更多关于Shell executor的内容，请访问[Shell Executor](https://docs.gitlab.com/runner/executors/shell.html)。

### Docker Executor

所有jobs的执行环境为指定的docker image所生成的container，每个job都会生成一个container并且在job结束后立即销毁。

- [build和cache的存储](https://docs.gitlab.com/runner/executors/docker.html#the-builds-and-cache-storage)

  Docker executor默认将所有的builds存储在```/builds/<namespace>/<project-name>```（这里的路径是container里的路径，Runner配置文件```config.toml```里的```build_dir```字段可以重新指明build的目录，默认对应于宿主机的目录是在宿主机的docker volume下：```/var/lib/docker/volumes/<volume-id>/_data/<project-name>```），默认将所有的caches存储在container里的```/cache```目录（```config.toml```里的```cache_dir```字段可以重新指明cache的目录），注意```build_dir```和```cache_dir```指向的均是container里的目录，要想将container里的数据持久化，需要用到```volumes```字段，这个字段的使用和docker volume的使用是类似的，只需在```config.toml```的```[runner.docker]```部分添加```volumes = ["/cache", "<host_dir:container_dir>:rw"]```即可实现container里```/cache```目录数据的永久保存以及将host目录挂载到相应的container目录并具有读写的功能。

- [Pull policies](https://docs.gitlab.com/runner/executors/docker.html#how-pull-policies-work)

  当你使用```docker``` 或 ```docker+machine``` executors时，你可以通过设置```pull_policy```来决定Runner如何pull docker image。```pull_policy```有三种值：
  ```always``` —— Runner始终从远程pull docker image。
  ```if-not-present``` —— Runner会首先检查本地是否有该image，如果有则用本地的，如果没有则从远程拉取。
  ```never``` —— Runner始终使用本地的image。

- [Helper image](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#helper-image)

  当你使用```docker```, ```docker+machine``` 或 ```kubernetes```作为executor时，GitLab Runner将会使用特定的container来处理Git、artifacts 和cache 操作。通过在宿主机中键入以下命令：
  ```bash
  sudo docker images
  ```
  你会发现一些特殊的images，如：
  ```bash
  REPOSITORY                          TAG
  gitlab/gitlab-runner-helper     x86_64-3afdaba6
  gitlab/gitlab-runner-helper     x86_64-cf91d5e1
  ```
  当然，你也可以通过配置```config.toml```里的```helper_image```字段来让Runner使用你自己定制化的helper image。

想要了解更多关于docker executor的信息，请访问[docker executor](https://docs.gitlab.com/runner/executors/docker.html#workflow)。

---

## 常见问题

### 当在Ubuntu18.04上使用docker executor runner时，出现Runner无法连接网络的问题

这个是Ubuntu18.04与Docker的问题，是关于宿主机与Container的DNS的映射问题，详情可以访问https://github.com/docker/libnetwork/issues/2187。
你的pipeline可能出现如下情况：
```bash
fatal: unable to access 'https://gitlab-ci-token:xxxxxxxxxxxxxxxxxxxx@code.siemens.com/zhen.xie/iavgitlabrunnertest.git/': Could not resolve host: code.siemens.com
```
该问题的解决办法是在Runner的配置文件```config.toml```里增加```dns = ["***.***.***.***"]```，dns的值你可以通过在宿主机上运行```nmcli dev show```来获得。

### Pipeline出现"```JAVA_HOME``` is not set and no java command could be found in your PATH"

这个错误通常出现在你使用Shell executor时，你可以在GitLab page上设置这个环境变量，具体路径是```GitLab page -> Settings -> CI/CD -> Variables```。

### 如何配置GitLab Runner

请参考<https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-global-section>。

### Runner间隔多久去GitLab上检查是否有job

```config.toml```文件的```check_interval```字段会决定这个时间间隔，它的默认值是3秒（注意当你把它设为0时依然采用的是默认值3秒，而不是0秒）。要解释它的意义，首先我们先来定义**worker**，在```config.toml```文件中定义了很多runner，它们可能executor类型不同，可能注册地址不同，但都是由GitLab Runner这个服务来管理的，为了与GitLab Runner区分开，我们将```config.toml```文件中定义的runner称为**worker**。对于不同的worker，worker之间（如worker A ---> worker B）的间隔为**check_interval / worker_nums**，但是对于worker A本身来说它下次去检查是否有job的时间间隔仍为```check_interval```。我们再举个简单例子：```config.toml```定义了3个**worker**—— worker A, worker B 和 worker C，```check_interval```采用默认值为3秒，第0秒时worker A会去检查是否有属于自己的job，第1秒时worker B会去检查，第2秒时worker C去检查，第3秒时worker A再检查……这个过程中worker A到worker B的间隔为3 / 3 = 1秒，而对于worker A下次检查job时的时间间隔为```check_interval```，即3秒。

  官方文档对```check_interval```的解释：<https://docs.gitlab.com/runner/configuration/advanced-configuration.html#how-check_interval-works>。

### ```config.toml```里的```concurrent```字段的意义

```concurrent```限制了**整个GitLab Runner**能并发处理job的数量。特别注意```concurrent```与**worker**数量无任何关系，所有**worker**的工作是受GitLab Runner控制的，如果```concurrent```值为1并且有一个worker已经在工作了，那么即使其他worker达到了可以工作的条件也只能“pending”。

### cache存储在哪里

请参考<https://docs.gitlab.com/ee/ci/caching/#where-the-caches-are-stored>

### 怎样清除cache

注意cache是没有过期时间的，而且每一次新的push触发的pipeline，都会重新生成cache，重新生成的cache的名字为“<cache-key>-<num>”，其中num是随着push数量递增的。如果不去清除cache，cache会永久保留在Runner上，日积月累会填满存储空间的，因此最好隔一段时间进行一次清除，清除方法请参考<https://docs.gitlab.com/ee/ci/caching/#clearing-the-cache>，或者使用[clear_volumes.sh](https://github.com/xz1996/GitLabLearning/blob/master/util/clear_volumes.sh) 这个简单脚本来处理它。

### GitLab Runner 变量的优先级

请参考<https://docs.gitlab.com/ee/ci/variables/#priority-of-environment-variables>

### GitLab Runner有哪些预定义的变量

请参考<https://docs.gitlab.com/ee/ci/variables/#predefined-variables-environment-variables>

### 当我的Runner采用docker作为executor时，无法build docker image

这是个“dind(docker in docker)” 问题，一般pipeline会报如下错误：

```bash
Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
time="2018-12-17T11:12:33Z" level=error msg="failed to dial gRPC: cannot connect to the Docker daemon. Is 'docker daemon' running on this host?: dial unix
```
你可以将本地的docker socket绑定到container里来解决这个问题，具体方法是将```volumes = ["/var/run/docker.sock:/var/run/docker.sock"]```配置到```config.toml```文件里。

想要了解更多关于“dind”的信息，请参考<https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#use-docker-in-docker-executor>。

### 如何在job所对应的container里使用```git clone```命令
如果你想在job运行期间clone某些代码（如shell或python的脚本），首先要确保你的宿主机有权限clone代码，然后你就可以将你的secret挂载到container里，例如，你是通过ssh的方式克隆代码，并且你的ssh目录为```home/<user>/.ssh```，你就可以在```config.toml```文件里添加如下配置：
```toml
volumes = ["/home/x1twbm/.ssh:/root/.ssh:ro"]
```
然后，这个job所对应的container就可以拉取指定代码了。

