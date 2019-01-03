# Home Assistant Extras for Yonsm

这是我个人的 Home Assistant 配置和扩展插件库，请酌情参考。

# 一、[www/dash.html](www/dash.html)

dash.html 是为 Home Assistant 开发 Dashboard 操作面板，使用 HA WebSocket API 作为数据通道，基于非常简单的 HTML+JS+CSS 渲染而成的高效、快速的操控面板。使用方法也非常简单，只要放入 www 目录，然后使用 http://xxx.xxx.xxx/local/dash.html 访问即可。

# 1. 参数

待续

# 2. 个性化配置

待续

# 3. 个性化配置

待续

# 二、custom_components 插件

# 1. [climate/modbus.py](custom_components/climate/modbus.py)

通用 ModBus 空调插件，详情请参考 [https://yonsm.github.io/modbus](https://yonsm.github.io/modbus)

# 2. [climate/saswell.py](custom_components/climate/saswell.py)

SasWell 温控面板插件（地暖），详情请参考 [https://yonsm.github.io/saswell](https://yonsm.github.io/saswell)

# 3. [cover/broadlink.py](custom_components/cover/broadlink.py)

基于 broadlink 万能遥控器的窗帘插件（支持 RF），详情请参考 [https://bbs.hassbian.com/thread-1924-1-1.html](https://bbs.hassbian.com/thread-1924-1-1.html)

`这个并非我原创，我只是使用者`，我的修改点：

-   依赖库升级到 `broadlink==0.9.0`，解决 N1 armbian HA 0.8x 下面 segment fault 的问题；
-   `self._travel == 0` 改成 `self._travel <= 0` 避免相关 BUG。

# 4. [sensor/caiyun.py](custom_components/sensor/caiyun.py)

彩云天气插件，详情请参考[https://yonsm.github.io/caiyun](https://yonsm.github.io/caiyun)

# 5. [sensor/phicomm.py](custom_components/sensor/phicomm.py)

基于斐讯在线云数据实现的斐讯悟空空间检测仪 M1 插件，详情请参考 [https://yonsm.github.io/phicomm](https://yonsm.github.io/phicomm)

# 6. [sensor/aircat.py](custom_components/sensor/aircat.py)

基于 DNS 拦截实现的斐讯悟空空间检测仪 M1 插件，详情请参考网友发的帖子 [https://bbs.hassbian.com/thread-4601-1-1.html](https://bbs.hassbian.com/thread-4601-1-1.html)

# 6. [swicth/mqtt2.py](custom_components/swicth/mqtt2.py)

基于 mqtt swicth 扩展的 MQTT 开关，支持以下功能：

-   支持 icon_template 配置，可以使用 Jinja 脚本运算出不通的图标（参考我的 configuration.yaml 中的 mqtt2 Speaker）；
-    支持 original_state attribute。

# 7. [swicth/broadlink2.py](custom_components/swicth/broadlink2.py)

解决 broadlink SP3 Mini 在 Python 3.5.3 环境中 int 类型判断的问题（否则一堆错误日志）。目前暂未使用，待优化（建议升级到 Python 3.6/3.7 或可以避免相关问题）。

# 7. [aligenie.py](custom_components/aligenie.py)

几乎零配置，一键接入 Home Assistant 的大部分设备到天猫精灵，可以语音控制相关设备开关。详情请参考 [https://bbs.hassbian.com/thread-2700-1-1.html](https://bbs.hassbian.com/thread-2700-1-1.html)

但上述文章是老的实现方式，不适用于此插件。此插件使用姿势更妙，无需第三方服务器，直接使用 Home Assistant 作为服务器和 OAuth，链路更高效。具体可参考网友的帖子 [https://bbs.hassbian.com/thread-4758-1-1.html](https://bbs.hassbian.com/thread-4758-1-1.html)

# 8.[miai.py](custom_components/miai.py)

类似 aligenie.py，一键接入 Home Assistant 的大部分设备到小爱同学。但小爱同学的智能设备使用控制方式没有天猫精灵好，需要唤醒词语。

详情请参考 [https://bbs.hassbian.com/thread-4680-1-1.html](https://bbs.hassbian.com/thread-4680-1-1.html)

# 8. [hello_miai.py](custom_components/hello_miai.py)

小爱同学 TTS 播报插件，可以参考 automation.yaml 中大量使用到相关功能；还可以 [在HomeAssistant中输入文本，让小爱音TTS箱朗读出来](https://bbs.hassbian.com/thread-4184-1-1.html)；我并非原创者，源自 [https://bbs.hassbian.com/thread-3669-1-1.html](https://bbs.hassbian.com/thread-3669-1-1.html)

# 三、个人配置

## 1. [configuration.yaml](configuration.yaml)

这是我的 Home Assistant 配置文件。

## 2. [automation.yaml](automation.yaml)

这是我的 Home Assistant 自动化文件，其中有些脚本可以参考，如只用 Motion Sensor 解决洗手间自动开关灯的难题。

## 3. [group.yaml](group.yaml)

这是我的 Home Assistant 分组文件。

## 4. [customize.yaml](customize.yaml)

这是我的 Home Assistant 个性化配置文件，主要是中文名称和部分插件的个性化扩展配置。

## 5. [scripts.yaml](scripts.yaml)

这是我的 Home Assistant 脚本文件，主要是开关投影仪的批量处理脚本。

# 四、extra

# 1. [extra/setup.sh](extra/setup.sh)

树莓派和斐讯 N1 armbian 下安装 Home Assistant 的脚本，仅供参考，请按需逐步执行，不要整个脚本直接运行。

# 2. [其它](extra)

主要是一些过期的或者不用的文件，仅供备忘参考。
