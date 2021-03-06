include:
  - modules.haproxy.rsyslog

haproxy-dep-install:
  pkg.installed:
    - pkgs:
      - make
      - gcc
      - gcc-c++
      - bzip2-devel
      - pcre-devel
      - openssl-devel
      - systemd-devel
 
haproxy:
  user.present:
    - system: true
    - shell: /sbin/nologin
    - createhome: false

unzip-haproxy:
  archive.extracted:
    - name: /usr/src
    - source: salt://modules/haproxy/files/haproxy-{{ pillar['haproxy_version'] }}.tar.gz
    - if_missing: /usr/src/haproxy-{{ pillar['haproxy_version'] }}

haproxy-install:
  cmd.script:
    - name: salt://modules/haproxy/files/install.sh.j2
    - template: jinja
    - require:
      - archive: unzip-haproxy
    - unless: test -d {{ pillar['haproxy_installdir'] }}

/usr/sbin/haproxy:
  file.symlink:
   - target: {{ pillar['haproxy_installdir'] }}/sbin/haproxy

/etc/sysctl.conf:
  file.append:
    - text:
      - net.ipv4.ip_nonlocal_bind = 1
      - net.ipv4.ip_forward = 1
  cmd.run:
    - name: sysctl -p

{{ pillar['haproxy_installdir'] }}/conf:
  file.directory:
    - user: root
    - group: root
    - mode: '0755'
    - makedirs: true
    - require:
      - cmd: haproxy-install

config-file:
  file.managed:
    - names:
      - {{ pillar['haproxy_installdir'] }}/conf/haproxy.cfg:
        - source: salt://modules/haproxy/files/haproxy.cfg.j2
        - template: jinja
      - /usr/lib/systemd/system/haproxy.service:
        - source: salt://modules/haproxy/files/haproxy.service.j2
        - template: jinja

haproxy.service:
  service.running:
    - enable: true
    - reload: true
    - watch:
      - file: {{ pillar['haproxy_installdir'] }}/conf/haproxy.cfg
