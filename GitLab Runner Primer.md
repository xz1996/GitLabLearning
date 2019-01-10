# GitLab Runner Primer

## Installing GitLab Runner

To install the Runner:

1. Add GitLab's official repository:

    ```bash
    # For Debian/Ubuntu/Mint
    curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash

    # For RHEL/CentOS/Fedora
    curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh | sudo bash
    ```

2. Install the latest version of GitLab Runner, or skip to the next step to install a specific version:

    - Install latest version

        ```bash
        # For Debian/Ubuntu/Mint
        sudo apt-get install gitlab-runner

        # For RHEL/CentOS/Fedora
        sudo yum install gitlab-runner
        ```

    - Install specifice version
  
        ```bash
        # for DEB based systems
        apt-cache madison gitlab-runner
        sudo apt-get install gitlab-runner=10.0.0

        # for RPM based systems
        yum list gitlab-runner --showduplicates | sort -r
        sudo yum install gitlab-runner-10.0.0-1
        ```

---

## Registering Runners

### Requirements

Before registering a Runner, you need to first:

- Install it on a server separate than where GitLab is installed on
- Obtain a token for a shared or specific Runner via GitLab’s interface

### Registering a Runner under GNU/Linux

1. Run the following command:

    ```bash
    sudo gitlab-runner register
    ```

2. Enter your GitLab instance URL:

    ```bash
    Please enter the gitlab-ci coordinator URL (e.g. https://gitlab.com )
    https://code.siemens.com/
    ```
    *Notes: You can obtain the URL by ```GitLab page -> Settings -> CI/CD -> Runners``` if you have access to it.*

    ![RegisterRunners](/resources/pictures/RegisterRunner.PNG)

3. Enter the token you obtained to register the Runner:

    ```txt
    Please enter the gitlab-ci token for this runner  
    xxx
    ```

    *notes: You can obtain the token at the same time at step 2.*

4. Enter a description (i.e. runner name) for the Runner, you can change this later in GitLab’s UI:

    ```txt
    Please enter the gitlab-ci description for this runner  
    [hostame] my-runner
    ```

5. Enter the [tags associated with the Runner](https://docs.gitlab.com/ee/ci/runners/#using-tags), you can change this later in GitLab’s UI:

    ```bash
    Please enter the gitlab-ci tags for this runner (comma separated):
    my-tag,another-tag
    ```

6. Enter the [Runner executor](https://docs.gitlab.com/runner/executors/README.html):

    ```bash
    Please enter the executor: ssh, docker+machine, docker-ssh+machine, kubernetes, docker, parallels, virtualbox, docker-ssh, shell:
    docker
    ```

    If you chose Docker as your executor, you’ll be asked for the default image to be used for projects that do not define one in ```.gitlab-ci.yml```:

    ```bash
    Please enter the Docker image (eg. ruby:2.1):
    alpine:latest
    ```

---

## Using GitLab Runner

- Run the GitLab Runner directly:

    ```bash
    sudo gitlab-runner run
    ```

- Run the GitLab Runner as a service:

    1. Install GitLab Runner as a [system service](https://docs.gitlab.com/runner/configuration/init.html):

        ```bash
        sudo gitlab-runner install -n "<service name>" -u <user-name>
        ```
    2. Start the GitLab Runner service:

        ```bash
        sudo gitlab-runner start -n "<service name>"
        ```
    *Notes: These [service-related commands](https://docs.gitlab.com/runner/commands/README.html#service-related-commands) are deprecated and will be removed in one of the upcoming releases.*

For more GitLab Runner commands, you can visit [here](https://docs.gitlab.com/runner/commands/README.html).

---

## Important topics — Executor

### Shell Executor

The source project is checked out to: ```<working-directory>/builds/<short-token>/<concurrent-id>/<namespace>/<project-name>```.

The caches for project are stored in ```<working-directory>/cache/<namespace>/<project-name>```.

For more shell executor information, please visit [here](https://docs.gitlab.com/runner/executors/shell.html).

### Docker Executor

- [The builds and cache storage](https://docs.gitlab.com/runner/executors/docker.html#the-builds-and-cache-storage)

    The Docker executor by default stores all builds in ```/builds/<namespace>/<project-name>``` (the ```build_dir``` can determine the build directories, the default directory is under docker volumes: ```/var/lib/docker/volumes/<volume-id>/_data/<project-name>```) and all caches in ```/cache``` (inside the container, the ```cache_dir``` can determine the cache directories).

    *Notes: If you want to persist the data, you'd better define proper ```volumes = ["/**/"]``` under the ```[runner.docker]``` section in ```config.toml```*.

- [Pull policies](https://docs.gitlab.com/runner/executors/docker.html#how-pull-policies-work)

    When using the ```docker``` or ```docker+machine``` executors, you can set the ```pull_policy``` parameter  which defines how the Runner will work when pulling Docker images (for both image and services keywords). The pull_policy has 3 modes: ```always``` (default value), ```if-not-present``` and ```never```.

    ```always``` — Runner will always pull the image from remote.  
    ```if-not-present``` — Runner will check if the image is present locally at first. If it is, then the local version of image will be used. Otherwise, the Runner will try to pull the image.  
    ```never``` — Runner will always use local images and never pull from remote.

- [Helper image](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#helper-image)

    When one of ```docker```, ```docker+machine``` or ```kubernetes``` executors is used, GitLab Runner uses a specific container to handle Git, artifacts and cache operations. You can find the images by
    ```bash
    sudo docker images
    ```
    and the result may be:
    ```bash
    REPOSITORY                          TAG
    gitlab/gitlab-runner-helper     x86_64-3afdaba6
    gitlab/gitlab-runner-helper     x86_64-cf91d5e1
    ```
    You can also customize the helper image and override it in Runner's ```config.toml```.

For more docker executor information, please visit [here](https://docs.gitlab.com/runner/executors/docker.html#workflow).

---

## FAQ

### When using docker executor runner in ubuntu 18.04, the runner can't access to the Internet

There is a DNS issue when using ubuntu 18.04 with Docker, you can refer to [here](https://github.com/docker/libnetwork/issues/2187) for more detail information.

The following error may occur in the pipeline:

    fatal: unable to access 'https://gitlab-ci-token:xxxxxxxxxxxxxxxxxxxx@code.siemens.com/zhen.xie/iavgitlabrunnertest.git/': Could not resolve host: code.siemens.com

You can resolve this problem by adding ```dns = ["***.***.***.***"]``` in the runner's config file (it usually can be found in ```/etc/gitlab-runner/config.toml```) to change the docker container dns.

*Tips: You can obtain the detail network information by command ```nmcli dev show```, and then add the effective dns address to the relevant runner config  section in ```config.toml```*

### "```JAVA_HOME``` is not set and no java command could be foune in your PATH" when running the pipeline

This error usually occur when runner uses shell executor, you can set the ```JAVA_HOME```  in the ```GitLab page -> Settings -> CI/CD -> Variables```.

### How should I configure my GitLab Runner

Refer to <https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-global-section>

### How often does the Runner check the new jobs from GitLab instance

The ```check_interval``` attribute in [config.toml](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-global-section) will determine the interval, its default value is 3 seconds, but it just for one worker (there are many runners defined in ```config.toml```, we call them workers). If there are many workers, each worker (worker A ---> worker B) interval is **check_interval / worker_nums**, but it still takes the ```check_interval``` time for one worker to request next job (worker A ---> worker A). You can see [here](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#how-check_interval-works) for more information.

### What is the ```concurrent``` in ```config.toml```

```concurrent``` limits how many jobs globally can be run concurrently. There are some examples (trigger 2 jobs concurrently) for understanding it easily.

- concurrent = 1, one shell runner and the other is docker runner

    2 jobs were tagged by different runners (one is shell runner, the other is docker runner), only one runner will take the jobs, the other is pending.

- concurrent = 2, one shell runner and the other is docker runner

    2 jobs were tagged by different runners (one is shell runner, the other is docker runner),
    each runner can take each job concurrently.

- concurrent = 2, only one docker runner

    2 jobs were tagged by docker runner, this two jobs can concurrently be taken by the runner, and you can see the information "Running on runner-runnner-xxx-project-xxx-concurrent-0" and "Running on runner-runnner-xxx-project-xxx-concurrent-1" in pipeline console at first.

### Where the caches are stored

Refer to <https://docs.gitlab.com/ee/ci/caching/#where-the-caches-are-stored>

### How to clear the cache

The caches will never expire, and only take effect on one pipeline. If you push a new commit and the new pipeline will use a new cache, whose name is "(cache_key)-(increased_num)", and the "increased-num" will plus 1 on the next push. To avoid the Runner being filled with caches, we need to clear them  periodically. You can refer to <https://docs.gitlab.com/ee/ci/caching/#clearing-the-cache> for the clear cache methods, or use the [clear_volumes.sh](https://github.com/xz1996/GitLabLearning/blob/master/util/clear_volumes.sh) script to handle it.

### What is the priority of variables in GitLab Runner

Refer to <https://docs.gitlab.com/ee/ci/variables/#priority-of-variables>

### What are the predefined variables in GitLab Runner

Refer to <https://docs.gitlab.com/ee/ci/variables/#predefined-variables-environment-variables>

### I can't build docker when my runner is docker executor

This is "dind (Docker in Docker)" problem, The following error may occur in the pipeline:

    Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
    time="2018-12-17T11:12:33Z" level=error msg="failed to dial gRPC: cannot connect to the Docker daemon. Is 'docker daemon' running on this host?: dial unix  

You can resolve this problem by using docker socket binding, for example, you can add ```volumes = ["/var/run/docker.sock:/var/run/docker.sock", "/cache"]``` in ```config.toml```, more detail information, please refer to <https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#use-docker-in-docker-executor>.