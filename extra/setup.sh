#!/bin/sh

# ============================== Basic Config ==============================
#ssh pi@hassbian

# Raspberry Pi Only
sudo passwd root
sudo passwd --unlock root
sudo nano /etc/ssh/sshd_config #PermitRootLogin yes
sudo mkdir /root/.ssh
mkdir ~/.ssh
sudo reboot

# MacOS
#ssh root@hassbian "mkdir ~/.ssh"
#scp ~/.ssh/authorized_keys root@hassbian:~/.ssh/
#scp ~/.ssh/id_rsa root@hassbian:~/.ssh/
#scp ~/.ssh/config root@hassbian:~/.ssh/

#ssh admin@hassbian "mkdir ~/.ssh"
#scp ~/.ssh/authorized_keys admin@hassbian:~/.ssh/
#scp ~/.ssh/id_rsa admin@hassbian:~/.ssh/
#scp ~/.ssh/config admin@hassbian:~/.ssh/

#ssh root@hassbian

# # Raspberry Pi Only: Rename pi->admin
usermod -l admin pi
groupmod -n admin pi
mv /home/pi /home/admin
usermod -d /home/admin admin
passwd admin
raspi-config # Hostname, WiFi, locales(en_US.UTF-8/zh_CN.GB18030/zh_CN.UTF-8), Timezone

#
echo "admin ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Armbian
armbian-config #Hostname, wifi,timezone
#echo "Asia/Shanghai" > /etc/timezone && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# ============================== Home Assistant ==============================
apt-get update
apt-get upgrade -y
#apt-get autoclean
#apt-get clean
#apt autoremove -y

# Mosquitto
apt-get install mosquitto mosquitto-clients
#echo "allow_anonymous true" >> /etc/mosquitto/mosquitto.conf
#systemctl stop mosquitto
#sleep 2
#rm -rf /var/lib/mosquitto/mosquitto.db
#systemctl start mosquitto
#sleep 2
#mosquitto_sub -v -t '#'

# HomeKit
apt-get install libavahi-compat-libdnssd-dev

# Android
apt-get install adb

# Raspbian
##apt-get install python3 python3-pip

# Armbian
apt-get install python3-pip python3-dev libffi-dev python3-setuptools
ln -sf /usr/bin/python3 /usr/bin/python

# Speedtest
cd /usr/local/bin
wget -O speedtest https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py; chmod +x speedtest; ./speedtest

# PIP 18
##python3 -m pip install --upgrade pip # Logout after install
#curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
#python3 get-pip.py --force-reinstall

# Python 3.7+
#curl https://bc.gongxinke.cn/downloads/install-python-latest | bash

# Baidu TTS
#apt-get install libtiff5-dev libjpeg8-dev zlib1g-dev libfreetype6-dev liblcms2-dev libwebp-dev tcl8.6-dev tk8.6-dev python-tk
apt-get install libjpeg-dev zlib1g-dev

# Home Assistant
pip3 install wheel
pip3 install homeassistant

# Auto start
cat <<EOF > /etc/systemd/system/homeassistant.service
[Unit]
Description=Home Assistant
After=network-online.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/hass

[Install]
WantedBy=multi-user.target

EOF

systemctl --system daemon-reload
systemctl enable homeassistant
systemctl start homeassistant

# Alias
cat <<\EOF >> ~/.bashrc
alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -l'
alias l='ls $LS_OPTIONS -lA'
alias mqttre='systemctl stop mosquitto; sleep 2; rm -rf /var/lib/mosquitto/mosquitto.db; systemctl start mosquitto'
alias hassre='echo .>~/.homeassistant/home-assistant.log; systemctl restart homeassistant'
alias hassup='systemctl stop homeassistant; pip3 install homeassistant --upgrade; systemctl start homeassistant'
alias hasslog='tail -f ~/.homeassistant/home-assistant.log'
EOF

# Debug
hass

# ============================== Samba ==============================
# Samba
apt-get install samba
smbpasswd -a root

cat <<EOF > /etc/samba/smb.conf
[global]
workgroup = WORKGROUP
wins support = yes
dns proxy = no
log file = /var/log/samba/log.%m
max log size = 1000
syslog = 0
panic action = /usr/share/samba/panic-action %d
server role = standalone server
passdb backend = tdbsam
obey pam restrictions = yes
unix password sync = yes
passwd program = /usr/bin/passwd %u
passwd chat = *Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssuccessfully* .
pam password change = yes
map to guest = bad user
usershare allow guests = yes

[homes]
comment = Home Directories
browseable = no
create mask = 0700
directory mask = 0700
valid users = %S

[hass]
path = /root/.homeassistant
valid users = root
browseable = yes
writable = yes

EOF
/etc/init.d/samba restart

# Merlin?
mkdir /media/sda1
cat <<\EOF > /etc/fstab
/dev/sda1 /media/sda1 hfsplus ro,sync,noexec,nodev,noatime,nodiratime 0 0
EOF

# ============================== Deprecated Config ==============================
# Global Customization file
#homeassistant:
  #customize_glob: !include customize_glob.yaml
  # auth_providers:
  #   - type: homeassistant
  #   - type: trusted_networks
  #   - type: legacy_api_password

#http:
  #api_password: !secret http_password
  # trusted_networks:
  # - 127.0.0.1
  # - 192.168.1.0/24
  # - 192.168.2.0/24

# Enables the frontend
#frontend:
  #javascript_version: latest
  #extra_html_url:
  #  - /local/custom_ui/state-card-button.html
  # - /local/custom_ui/state-card-custom-ui.html
  #extra_html_url_es5:
  #  - /local/custom_ui/state-card-button.html
  # - /local/custom_ui/state-card-custom-ui-es5.html

# Customizer
# customizer:
#   custom_ui: local
  # customize.yaml
  # config:
  #   extra_badge:
  #     - entity_id: switch.speaker
  #       attribute: original_state
  #   entities:
  #     - entity: switch.speaker
  #       icon: mdi:video-input-component
  #       service: mqtt.publish
  #       data:
  #         topic: NodeMCU3/relay/0/set
  #         payload: toggle
  # custom_ui_state_card: state-card-button
  #dashboard_static_text_attribute: original_state

#recorder:
#  purge_keep_days: 2
#  db_url: sqlite:////tmp/home-assistant.db

#logger:
  # default: warning
  #logs:
  #homeassistant.components.homekit: debug

# Text to speech
#tts:
#  - platform: google
#    language: zh-cn
#   - platform: baidu
#     app_id: !secret baidu_app_id
#     api_key: !secret baidu_api_key
#     secret_key: !secret baidu_secret_key

#shell_command:
  #genie_power: 'adb connect Genie; adb -s Genie shell input keyevent 26'
  #genie_dashboard: 'adb connect Genie; adb -s Genie shell am start -n de.rhuber.homedash/org.wallpanelproject.android.WelcomeActivity'


# fan:
#   - platform: template
#     fans:
#       wall_fan:
#         friendly_name: "Wall Fan"
#         value_template: "{{ states('input_boolean.wall_fan_state') }}"
#         speed_template: "{{ states('input_select.wall_fan_speed') }}"
#         direction_template: "{% if is_state('input_boolean.wall_fan_direction', 'on') %}forward{% else %}reverse{% endif %}"
#         oscillating_template: "{% if is_state('input_boolean.wall_fan_osc', 'on') %}True{% else %}False{% endif %}"
#         turn_on:
#         - condition: template
#           value_template: "{{ is_state('input_boolean.wall_fan_state', 'off') }}"
#         - service: broadlink.send
#           data:
#             host: Remote2
#             packet: 'JgDCACkOKg4OKCoOKQ4OKQ4pDioOKQ4pDikp6SkOKg0OKSoOKQ4OKQ4pDikOKQ8pDSop6CoOKQ4OKSkOKg4OKQ4pDikOKQ4pDikq6CoOKQ4OKSkOKQ4PKQ4pDikOKQ4pDikq6ykOKg0OKSoNKg4OKQ4pDikOKQ4qDSop7CoNKg4OKSkOKQ4OKQ4qDSoOKQ4pDikq6ykOKg4OKSkOKg0PKQ0qDikOKQ4pDikq6ykOKg4OKSkOKQ4PKQ4pDikOKQ4pDikqAA0FAAAAAAAA'
#         - service: input_boolean.turn_on
#           data:
#             entity_id: input_boolean.wall_fan_state
#         turn_off:
#         - condition: template
#           value_template: "{{ is_state('input_boolean.wall_fan_state', 'on') }}"
#         - service: broadlink.send
#           data:
#             host: Remote2
#             packet: 'JgDCACkOKg4OKCoOKQ4OKQ4pDioOKQ4pDikp6SkOKg0OKSoOKQ4OKQ4pDikOKQ8pDSop6CoOKQ4OKSkOKg4OKQ4pDikOKQ4pDikq6CoOKQ4OKSkOKQ4PKQ4pDikOKQ4pDikq6ykOKg0OKSoNKg4OKQ4pDikOKQ4qDSop7CoNKg4OKSkOKQ4OKQ4qDSoOKQ4pDikq6ykOKg4OKSkOKg0PKQ0qDikOKQ4pDikq6ykOKg4OKSkOKQ4PKQ4pDikOKQ4pDikqAA0FAAAAAAAA'
#         - service: input_boolean.turn_off
#           data:
#             entity_id: input_boolean.wall_fan_state
#         set_speed:
#         - condition: template
#           value_template: "{{ not is_state('input_select.wall_fan_speed', speed) }}"
#         - service: broadlink.send
#           data:
#             host: Remote2
#             packet: 'JgDCACkOKg4OKSoNKg4qDg4pDikOKQ4qKQ4q6SoOKQ4OKSoOKg4pDg4pDioOKQ4pKg4q6SoOKQ4OKSoOKg0qDg4pDioOKQ4pKg4q6SoOKQ4OKSoOKg0qDg4pDioOKQ4pKg4q6yoOKQ4OKSoOKg0qDg4pDioNKg4pKg4p7CkOKg0PKSkOKg4pDg4pDioOKQ4pKg4p6yoNKg4OKSkOKg4pDg4pDioOKQ4pKQ4q6yoNKg4OKSkOKg4pDg4pDikOKg4pKQ4qAA0FAAAAAAAA'
#         - service: input_select.select_next
#           data:
#             entity_id: input_select.wall_fan_speed
#         set_oscillating:
#         - service: broadlink.send
#           data:
#             host: Remote2
#             packet: 'JgDqACkOKg0PKSkOKQ4OKQ4qKQ4OKQ4pDikPAAEDKg4pDg4pKQ4qDg4pDikpDg8pDikOKQ4AAQQpDioODikpDikODykOKSkODikOKQ4qDgABBCkOKQ4OKSoNKg4OKQ4pKg4OKQ4pDikOAAEHKg0qDg4pKQ4pDg4pDykpDg4pDikOKQ4AAQgqDSoODikpDioODikOKSkODikPKQ4pDgABByoNKg4OKSkOKg4OKQ4pKg0OKQ4qDikOAAEHKQ4qDQ8oKg4pDg4pDykpDg4pDikOKQ4AAQcqDikODikpDioODikOKSkODykOKQ4pDgANBQAAAAAAAAAAAAAAAAAA'
#         - service: input_boolean.toggle
#           data:
#             entity_id: input_boolean.wall_fan_osc
#         set_direction:
#         - service: broadlink.send
#           data_template:
#             host: Remote2
#             packet: "{% if direction == 'forward' %}'JgDyACwLLAwQJywLLAwsCxApDigQJw8oLAwr5ywMLAsQJywMLAssDBAnECcQKA8oKQ4s5ywMKwwQJyoOLAssDBAnDykQJw8oLAwr6CsMLAwQJywLLAwsCxEnECcPKA8pKwws6SwMLAsRJysMLAwrDBAoECcQJxAnLAws6SwLLAwQJywMKwwsDBAnECcQJxAoKQ4s6SsMLAsRJysMLAwrDBAnECcRJxAnKQ4s6SsMLAsQJywMKwwsDBAnDygQJxAoKwwr6isMLAsQKCsMKwwsDBAnECcQJxAnLAwr6iwLLAwQKCoMLAwrDBAnECcQKA4pKQ4sAA0FAAAAAAAA'{% else %}'JgDqACkOKQ8NKikPKQ4qDg0qDSoOKigPKQ8NAAEGKA8pDw0qKQ8oDykPDSoNKw0qKQ8oDw0AAQcoDykPDSoqDigPKQ8NKg8pECcrDSgPDQABBisNKQ8NKikOKQ8pDw8oECcQKCsMKw0PAAEFLAwqDQ8pKwwrDSoNDykQJxAnKw0qDQ8AAQYrDCsNECcrDCsNKg0PKRAnECcsDCoNDwABBSwMKA8NKiwMKA8pDw0qECcQJywMKA8NAAEIKg0pDg4qKg0pDygPDSoQJxAoKwwpDg8AAQYsDCoNDygsDCoNKg0PKRAnECcrDCsNDwANBQAAAAAAAAAAAAAAAAAA'{% endif %}"
#         - service: input_boolean.toggle
#           data:
#             entity_id: input_boolean.wall_fan_direction


# input_boolean:
#   wall_fan_state:
#   wall_fan_osc:
#   wall_fan_direction:

# input_select:
#   wall_fan_speed:
#     options: [low, medium, high]
