# cijtemplate
Helper files for Data Science Workshop presentation

## Build Boxes
### Build the Jenkins server first
Start with fedora-20 *medium* - you want at least 2GB of RAM to run jenkins and sonar together.
Use the build_jenkins.sh as a bootScript on the JENKINS server. 
Change the variables to your desired values.

### Build the TEST and PROD boxes second
Use fedora-20 tiny (or bigger, your choice)
Use the build_test.sh as a bootScript on the TEST server, replacing the variables with your desired values.
Get the JENKINS_KEY and JENKINS_PRIVATE_KEY from the jenkins server:
```
/var/lib/jenkins/.ssh/id_rsa.pub
/var/lib/jenkins/.ssh/id_rsa
```

Repeat to build the PROD server. Change the APP_MODE value to 'prod'.


## MANUAL STEPS
Once the 3 servers are built with their bootScripts, do this manually:

### Update IP addresses
The following files have IP addresses hard coded in them. Replace them with your IPs.  Commit, push.
```
integration/conf/base_settings.py:URL = 'http://192.169.164.240/'
integration/conf/prod_settings.py:URL = 'http://192.169.164.245/'
integration/conf/test_settings.py:URL = 'http://192.169.164.240/'
scripts/cd_deploy.PROD:fab -i ~/.ssh/id_rsa -u jenkins -H 192.169.164.245 deploy
scripts/cd_deploy.TEST:fab -i ~/.ssh/id_rsa -u jenkins -H 192.169.164.240 deploy
```
### Update git urls
The following files have git@github.com:godaddy/cijtemplate.git hard coded. Fix.  Commit, push.
```
build_test.sh:git clone git@github.com:godaddy/cijtemplate.git $NOW
fabfile.py:    run('git clone -q git@github.com:godaddy/cijtemplate.git {}'.format(code_dir))
```
### Update sonar password and projectKey
The following file has the sonar projectKey, login and password. Set to what you want, will use later. Commit, push.
```
sonar-project.properties
```
### Update scripts/sonar.py user/pass that is hard coded
```
scripts/sonar.py
```

### JENKINS 
SSH to the Jenkins server with port forwarding turned on so you can point your browser to jenkins (and sonar)

``` 
ssh -L 8080:127.0.0.1:8080 -L 9000:127.0.0.1:9000 user@host
```

Then point your browser to http://localhost:8080/jenkins

Do the global allows users to sign up, sign up, then uncheck and enable Matrix based security, add user, check all, save
 

### SONAR SETUP
Point your browser to http://localhost:9000/sonar
- login as admin/admin
- Change admin password and lock down to logged in users only
- Add a jenkins user with user/pass set in sonar-project.properties earlier
- Add a new project with projectKey set in sonar-project.properties earlier

### START NGINX
- now that services are secure, it's safe:
- service nginx restart
- chkconfig nginx on

### INSTALL JENKINS GITHUB PLUGIN AND BUILD MONITOR
- install the Github plugin: https://host/jenkins
-   Manage Jenkins -> Manage Plugins -> install Github plugin
-       and Build Monitor Plugin

### GET GITHUB PERSONAL ACCESS TOKEN
- https://github.com
- Goto settings, New personal access token, add all the repo hook perms
-   copy key somewhere safe

### CONFIGURE JENKINS GITHUB:
- https://host/jenkins
- configure system: Let Jenkins auto-manage hook URLs
-    add your user and OAUTH token
-    set Jenkins URL to go through proxy

### ADD jenkins PUBLIC KEY TO GITHUB.COM
```
cat /var/lib/jenkins/.ssh/id_rsa.pub
```
-   add key to your personal ssh keys in github.com settings

### SETUP JENKINS JOBS
- create new jenkins freestyle job
-  github project url
-  Source code: git, repo, add user with master ssh 
-    Wipe out repository and force clone
-  build when a change is published to github
-  (see about adding timestamps to console outpu)
-  Build: execute shell: ./scripts/ci_build
-  Post build: Build other projects: cijtemplate_02_deploy_test
-  Post build: Git Publisher, only if build succeeds, note: created by jenkins

- Save and Build Now...   make sure build succeeds. Resolve any issues here before proceeding.

### JENKINS DEPLOY TEST JOB
- cijtemplate_02_deploy_test
-  github project url
-  Source code: git, repo, add user with master ssh 
-    Wipe out repository and force clone
-  DO NOT: build when a change is published to github
-  Build: execute shell: ./scripts/cd_deploy.TEST
-  Post build: Build other projects: cijtemplate_03_test

### JENKINS RUN INTEGRATION TESTS
- cijtemplate_03_test
-  github project url
-  Source code: git, repo, add user with master ssh 
-    Wipe out repository and force clone
-  DO NOT: build when a change is published to github
-  Build: execute shell: ./scripts/ci_test
-  Post build: Build other projects: cijtemplate_04_deploy

### JENKINS DEPLOY PROD
- cijtemplate_04_deploy
-  github project url
-  Source code: git, repo, add user with master ssh 
-   git advanced name: RepoName
-    Wipe out repository and force clone
-  DO NOT: build when a change is published to github
-  Build: execute shell: ./scripts/cd_deploy.PROD
-  Post build: Build other projects: cijtemplate_05_test_prod
-  Post build: Git Publisher, Add Tag, PROD-$BUILD_ID, Create new tag, RepoName

### JENKINS RUN INTEGRATION TESTS in PROD
- cijtemplate_05_test_prod
-  github project url
-  Source code: git, repo, add user with master ssh 
-    Wipe out repository and force clone
-  DO NOT: build when a change is published to github
-  Build: execute shell: ./scripts/ci_test.PROD
-  Post build: n/a

