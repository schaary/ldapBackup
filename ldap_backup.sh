#!/bin/bash

DUMPFILE=dump-`date +%F-%H-%M-%S`
EMAILADDRESS=''


function fehler() 
{
  local rc=$1
  /usr/bin/logger -is -p ldap.err -t ldap_backup $*
  schift 1
  (
    echo "Fehler bei LDAP-Backup: $*"
  ) | /usr/bin/mail -s "Fehler bei LDAP-Backup!!!" ${EMAILADDRESS} 2>/dev/null

  exit $rc
} 

ME=`ps -o user= -p $$ | awk '{print $1}'`

if [ 'root' != ${ME} ]; then
  fehler 255 "bitte als root starten"
fi

if [ '' == ${EMAILADDRESS} ]; then
  fehler 255 "es wurde noch keine Emailadresse in EMAILADDRESS hinterlegt"
fi

if [ ! -d '/archive' ]; then
  echo "Das Verzeichnis /archive existiert nicht - ich lege es an!"
  /bin/mkdir /archive
fi

if [ ! -d '/archive/backup' ]; then
  echo "Das Verzeichnis /archive/backup existiert nicht - ich lege es an!"
  /bin/mkdir /archive/backup
fi

/usr/bin/logger -is -p local0.info -t ldap_backup LDAP-Backup gestartet

cd /archive/backup
if test $? -ne 0 
then
  fehler 1 "kann nicht nach /archive/backup wechseln"
fi 

#/etc/init.d/ldap stop 
/usr/sbin/service slapd stop
if test $? -ne 0 
then
  fehler 2 "kann den LDAP-Server nicht stoppen"
fi 

/usr/sbin/slapcat -l ${DUMPFILE} 
if test $? -ne 0 
then
  fehler 3 "kann den Dump nicht ${DUMPFILE} schreiben"
fi 

#/etc/init.d/ldap start
/usr/sbin/service slapd start
if test $? -ne 0 
then
  fehler 4 "kann den LDAP-Server nicht wieder starten"
fi 

/bin/bzip2 ${DUMPFILE}
if test $? -ne 0 
then
  fehler 5 "kann den Dump nicht packen"
fi 

/bin/chmod 600 /archive/backup/*
if test $? -ne 0 
then
  fehler 6 "kann die Zugriffsrechte in /data/backup nicht auf 600 setzen"
fi 

echo Alles bestens | /usr/bin/mail -s "LDAP-Backup erfolgreich!" ${EMAILADDRESS} 2>/dev/null
/usr/bin/logger -is -p local0.info -t ldap_backup LDAP-Backup erfolgreich beendet
