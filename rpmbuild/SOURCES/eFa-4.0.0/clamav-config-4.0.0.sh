#!/bin/sh
#-----------------------------------------------------------------------------#
# eFa 4.0.0 initial clamav-configuration script
#-----------------------------------------------------------------------------#
# Copyright (C) 2013~2018 https://efa-project.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Source the settings file
#-----------------------------------------------------------------------------#
source /usr/src/eFa/eFa-settings.inc
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Start configuration of clamav
#-----------------------------------------------------------------------------#
echo "Configuring clamav..."
clamav_version=$(rpm -q --queryformat=%{VERSION} clamav-server)

useradd -d /var/lib/clamav -c "Clam Anti Virus Checker" -G virusgroup,clamupdate,mtagroup -s /sbin/nologin -M clam

sed -i '/^Example/ c\#Example' /etc/freshclam.conf
sed -i '/REMOVE ME/d' /etc/sysconfig/freshclam
cp /usr/share/doc/clamav-server-$clamav_version/clamd.conf /etc/clamd.d/clamd.conf
sed -i '/^Example/ c\#Example' /etc/clamd.d/clamd.conf
sed -i '/^User <USER>/ c\User clam' /etc/clamd.d/clamd.conf
sed -i '/#LocalSocket \/var\/run\/clamd.<SERVICE>\/clamd.sock/ c\LocalSocket /var/run/clamd.scan/clamd.sock' /etc/clamd.d/clamd.conf
sed -i '/#LogFile \/var\/log\/clamd.<SERVICE>/ c\LogFile /var/log/clamd.scan/scan.log' /etc/clamd.d/clamd.conf
cat > /usr/lib/systemd/system/clam.freshclam.service << 'EOF'
# Run the freshclam as daemon
[Unit]
Description = freshclam scanner
After = network.target

[Service]
Type = forking
ExecStart = /usr/bin/freshclam -d -c 4
Restart = on-failure
PrivateTmp = true

[Install]
WantedBy=multi-user.target

EOF
cat > /usr/lib/systemd/system/clam.scan.service << 'EOF'
[Unit]
Description = clamd scanner daemon
After = syslog.target nss-lookup.target network.target

[Service]
Type = forking
ExecStart = /usr/sbin/clamd -c /etc/clamd.d/clamd.conf
Restart = on-failure
PrivateTmp = true

[Install]
WantedBy=multi-user.target
EOF

cp /usr/share/doc/clamav-server-$clamav_version/clamd.logrotate /etc/logrotate.d/
cat > /etc/sysconfig/clamd << 'EOF'
CLAMD_CONFIGFILE=/etc/clamd.d/clamd.conf
CLAMD_SOCKET=/var/run/clamd.scan/clamd.sock
#CLAMD_OPTIONS=
EOF
chown -R clam:clam /etc/clamd.d
mkdir -p /var/log/clamd.scan
chown -R clam:clam /var/log/clamd.scan
chcon -u system_u -r object_r -t antivirus_log_t /var/log/clamd.scan
semanage fcontext -a -t antivirus_log_t /var/log/clamd.scan
mkdir -p /var/run/clamd.scan
chown -R clam:mtagroup /var/run/clamd.scan
chcon -u system_u -r object_r -t antivirus_var_run_t /var/run/clamd.scan
semanage fcontext -a -t antivirus_var_run_t /var/run/clamd.scan
echo "d /var/run/clamd.scan 0750 clam mtagroup -" > /etc/tmpfiles.d/clamd.conf

echo "Configuring clamav...done"

