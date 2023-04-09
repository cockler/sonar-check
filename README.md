# sonar-check

#### 介绍
本项目是一个代码质量检查的工具。通过运行shell脚本，可以很便捷的进行代码静态检查，并将结果上传到sonarQube服务器。

#### 软件架构
使用maven的sonar插件检查代码库，并将结果上传到sonarQube服务器。

#### 使用说明

1.  进入到src目录下
2.  修改名为config的文件中的信息  
第一行：sonarQube服务器的地址；  
第二行：sonarQube服务器的用户令牌；
3.  在当前目录下，打开支持shell命令的工具
4.  输入执行命令（a和b二选一）   
a.从远程git仓库检查：   
./sonarcheck-anywhere.sh 需要检查的远程git项目的仓库地址 远程分支名   
说明：接收两个参数，参数之间空格隔开。第一个参数，待检查项目的git远程仓库的地址（必须）；第二个参数，git的远程（origin）分支名(可选)，默认为master；   
b.从本地git项目检查：   
./sonarcheck-project.sh 需要检查的本地git项目的根目录全路径 是否拉取远程仓库最新代码 分支名   
说明：接收三个参数，参数之间空格隔开。第一个参数，本地git项目的根目录全路径(必需)，指定待检查的本地git项目的根目录全路径；第二个参数，是否拉取远程git仓库的最新代码(必需)，y-是，其他-否；第三个参数，git的分支名(可选)，指定待检查的git的本地分支（会切换到该分支下），默认为当前分支。

#### 注意事项

1.	本地安装git并配置全局环境变量
2.	本地安装maven并配置全局环境变量
3.	项目是基于maven构建的

#### 参与贡献

1.  Fork 本仓库
2.  新建 Feat_xxx 分支
3.  提交代码
4.  新建 Pull Request