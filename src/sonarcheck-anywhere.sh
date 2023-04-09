#!/bin/sh
echo "此脚本作用：在当前目录下创建一个临时目录（执行完成后会删除），拉取指定git仓库的主分支代码到本地，通过maven的sonar插件命令检查代码(项目必须是基于maven构建的)，并将结果上传到sonarQube服务器。"
echo "执行此脚本的前提：1.本地安装git并配置全局环境变量；2.本地安装maven并配置全局环境变量；3.项目基于maven构建。"
echo "此脚本接收两个参数："
echo "第一个参数，待检查项目的git远程仓库的地址（必须）；"
echo "第二个参数，git的远程（origin）分支名(可选)，默认为master；"
echo ""
if [ "$1" = "" ] || ( [[ "$1" != http* ]] && [[ "$1" != ssh* ]]  && [[ "$1" != git* ]] );
then
	echo "[error]缺少参数或参数非法，参数为：待检查项目的git远程仓库的地址"
	exit 1
fi
SONARURL=$(head -1 config)
SONARURL_ERROR=$(echo $?) #检查上一步命令执行的结果：值为0表示成功，其他值表示失败
if [ "$SONARURL_ERROR" != "0" ] || [ "$SONARURL" = "" ];then
	echo "[error]获取sonarQube服务器地址失败，请确认脚本的同级目录下存在config文件且文件中的第一行为sonarQube服务器地址!"
	exit 1
fi
SONARLOGIN=$(sed -n '2p' config)
SONARLOGIN_ERROR=$(echo $?) #检查上一步命令执行的结果：值为0表示成功，其他值表示失败
if [ "$SONARLOGIN_ERROR" != "0" ] || [ "$SONARLOGIN" = "" ];then
	echo "[error]获取sonarQube服务器的用户令牌失败，请确认脚本的同级目录下存在config文件且文件中的第二行为sonarQube服务器的用户令牌!"
	exit 1
fi
TEMP_DIRECTORY="temp-"$(date +%s) #获取时间戳
echo "创建临时目录$TEMP_DIRECTORY..."
mkdir $TEMP_DIRECTORY
MKDIR_ERROR=$(echo $?) #检查上一步命令执行的结果：值为0表示成功，其他值表示失败
if [ "$MKDIR_ERROR" != "0" ];then
	echo "[error]创建目录$TEMP_DIRECTORY失败，请检查目录是否已存在或当前用户是否有在当前目录下操作的权限!"
	exit 1
fi
echo "进入到临时目录$TEMP_DIRECTORY..."
cd $TEMP_DIRECTORY
echo "拉取远程分支代码(git clone $1)..."
git clone $1
CLONE_ERROR=$(echo $?)
if [ "$CLONE_ERROR" != "0" ];then
	echo "[error]拉取远程分支代码失败，请检查是否有项目的权限；请确认本地安装了git，并设置了全局的环境变量！"
	cd ..
	rm -rf $TEMP_DIRECTORY
	exit 1
fi
GIT_DIRECTORY=$(ls 2> /dev/null)
echo "git项目名称为：$GIT_DIRECTORY"
if [ "$GIT_DIRECTORY" = "" ];then
	echo "[error]未获取到git项目，请检查git项目是否正确！"
	cd ..
	rm -rf $TEMP_DIRECTORY
	exit 1
fi
echo "进入git项目根目录：$GIT_DIRECTORY"
cd $GIT_DIRECTORY
GIT_DIRECTORY_ERROR=$(echo $?)
if [ "$GIT_DIRECTORY_ERROR" != "0" ];then
	echo "[error]进入git项目根目录失败，请检查git项目是否正确!"
	cd ..
	rm -rf $TEMP_DIRECTORY
	exit 1
fi
PROJECT=$(mvn org.apache.maven.plugins:maven-help-plugin:3.2.0:evaluate -Dexpression=project.artifactId -q -DforceStdout)
MAVEN_ERROR=$(echo $?)
echo "maven的artifactId为：$PROJECT"
if [ "$MAVEN_ERROR" != "0" ] || [ "$PROJECT" = "" ];then
	echo "[error]执行maven命令失败。请确保此目录 $GIT_DIRECTORY 的项目为maven项目，并且在项目的根目录下；请确认本地安装了maven，并设置了全局的环境变量！"
	cd ../../
	rm -rf $TEMP_DIRECTORY
	exit 1
fi
if [ "$2" != "" ];then
	echo "切换到指定的远程（origin）git分支下，分支名：$2"
	git checkout -b $2 origin/$2
fi
BRANCH=$(git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
echo "git的当前分支为：$BRANCH"
if [ "$BRANCH" = "" ];then
	echo "[error]执行git命令失败。请确保此目录 $GIT_DIRECTORY 的项目为git项目，并且在项目的根目录下；请确认本地安装了git，并设置了全局的环境变量！"
	cd ../../
	rm -rf $TEMP_DIRECTORY
	exit 1
fi

PROJECTNAME=$PROJECT"-"$BRANCH
PROJECTKEY=$PROJECT":"$BRANCH


echo "开始执行sonar分析的maven命令..."
mvn clean package sonar:sonar \
	-Dsonar.projectName=$PROJECTNAME \
	-Dsonar.projectKey=$PROJECTKEY \
	-Dsonar.java.binaries=target/classes \
	-Dsonar.host.url=$SONARURL \
	-Dsonar.login=$SONARLOGIN
MAVEN_SONAR_ERROR=$(echo $?)
if [ "$MAVEN_SONAR_ERROR" != "0" ];then
	echo "[error]执行mvn package命令失败，请检查代码是否正确，maven私服连接是否正确，项目相关的jar包依赖是否存在"
	echo "[error]执行sonar分析的maven命令失败，请检查config文件的配置信息是否正确，文件中第一行为sonarQube服务器地址，第二行为sonarQube服务器的用户令牌!"
	cd ../../
	rm -rf $TEMP_DIRECTORY
	exit 1
fi
echo "执行sonar分析完成，上传到sonarQube服务器地址为：$SONARURL"
echo "执行sonar分析完成，生成的sonar项目名称为：$PROJECTNAME"
echo "开始删除临时目录..."
cd ../../
rm -rf $TEMP_DIRECTORY
echo "删除临时目录完成。"
echo "执行结束！"
