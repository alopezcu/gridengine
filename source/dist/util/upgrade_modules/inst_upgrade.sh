#!/bin/sh
#
# SGE configuration script (Upgrade/Downgrade)
# Scriptname: inst_upgrade.sh
# Module: common upgrade functions
#
#___INFO__MARK_BEGIN__
##########################################################################
#
#  The Contents of this file are made available subject to the terms of
#  the Sun Industry Standards Source License Version 1.2
#
#  Sun Microsystems Inc., March, 2001
#
#
#  Sun Industry Standards Source License Version 1.2
#  =================================================
#  The contents of this file are subject to the Sun Industry Standards
#  Source License Version 1.2 (the "License"); You may not use this file
#  except in compliance with the License. You may obtain a copy of the
#  License at http://gridengine.sunsource.net/Gridengine_SISSL_license.html
#
#  Software provided under this License is provided on an "AS IS" basis,
#  WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING,
#  WITHOUT LIMITATION, WARRANTIES THAT THE SOFTWARE IS FREE OF DEFECTS,
#  MERCHANTABLE, FIT FOR A PARTICULAR PURPOSE, OR NON-INFRINGING.
#  See the License for the specific provisions governing your rights and
#  obligations concerning the Software.
#
#  The Initial Developer of the Original Code is: Sun Microsystems, Inc.
#
#  Copyright: 2001 by Sun Microsystems, Inc.
#
#  All Rights Reserved.
#
##########################################################################
#___INFO__MARK_END__


#--------------------------------------------------------------------------
# WelcomeTheUserUpgrade - upgrade welcome message
#
WelcomeTheUserUpgrade()
{
   $INFOTEXT -u "\nWelcome to the Grid Engine Upgrade Procedure"
   $INFOTEXT "\nBefore you continue with the upgrade, read these hints:\n\n" \
             "   - Your terminal window should have a size of at least\n" \
             "     80x24 characters\n\n" \
             "   - At any time during the upgrade process, use your standard \n" \
             "     interrupt key to abort the upgrade. Typically, the interrupt \n" \
             "     key combination is Ctrl-C.\n\n" \
             "The upgrade procedure will take approximately 1-2 minutes.\n"
   $INFOTEXT -wait -auto $AUTO -n "Hit <RETURN> to continue >> "
   $CLEAR
}

#-------------------------------------------------------------------------------
# GetBackupedAdminUser: Get admin user form the cluster configuration backup
# TODO: Cleanup duplicit with inst_common.sh GetAdminUser()
GetBackupedAdminUser()
{
   ADMIN_USER=`BootstrapGetValue "$UPGRADE_BACKUP_DIR/cell" admin_user`
   euid=`$SGE_UTILBIN/uidgid -euid`

   TMP_USER=`echo "$ADMINUSER" |tr "[A-Z]" "[a-z]"`
   if [ \( -z "$TMP_USER" -o "$TMP_USER" = "none" \) -a $euid = 0 ]; then
      ADMINUSER=default
   fi

   if [ "$SGE_ARCH" = "win32-x86" ]; then
      HOSTNAME=`hostname | tr "[a-z]" "[A-Z]"`
      ADMINUSER="$HOSTNAME+$ADMINUSER"
   fi
}

#TODO: Use it in inst_sge
#-------------------------------------------------------------------------------
# FileGetValue: Get values from a file for appropriate key
#  $1 - PATH to the file
#  $2 - key: e.g: qmaster_spool_dir | ignore_fqdn | default_domain, etc.
FileGetValue()
{
   if [ $# -ne 2 ]; then
      $INFOTEXT "Expecting 2 arguments for FileGetValue. Got %s." $#
      exit 1
   fi
   if [ ! -f "$1" ]; then
      $INFOTEXT "No file %s found" $1
      exit 1
   fi
   echo `cat $1 | grep "$2" | awk '{ print $2}' 2>/dev/null`
}

#Helper to get bootstrap file values
#See FileGetValue
BootstrapGetValue()
{
   FileGetValue "$1/bootstrap" $2
}

#-------------------------------------------------------------------------------
# CheckUpgradeUser: Check if valid user performs the upgrade
#
CheckUpgradeUser()
{
   if [ $euid -ne 0 -a `whoami` != "$ADMINUSER" ]; then
      $INFOTEXT "\nUpgrade procedure must be started as a root or admin user.\nCurrent user is `whoami`."
      exit 1
   elif [ "$OLD_ADMIN_USER" != "$ADMIN_USER" ]; then
      $INFOTEXT "\nCannot use this backup for the upgrade.\n" \
                "   current admin user: '$OLD_ADMIN_USER'\n" \
	        "   admin user in the backup: '$ADMIN_USER'\n" \
	        "Seems like this is not a backup of this cluster. If you want really continue \n" \
	        "with this backup manually edit bootstrap file in the backup to have the same \n" \
	        "admin user as your cluster currently has."
      exit 1
   fi
}

#-------------------------------------------------------------------------------
# GetBackupDirectory: Ask for backup directory. Udes during the upgrade.
#
GetBackupDirectory()
{
   done=false
   while [ $done = false ]; do
      $CLEAR
      $INFOTEXT -u "\nType the complete path to the Grid Engine configuration backup directory."
      $INFOTEXT -n " Backup directory  >> "
      eval UPGRADE_BACKUP_DIR=`Enter $UPGRADE_BACKUP_DIR`
      version=`cat "${UPGRADE_BACKUP_DIR}/version" 2>/dev/null`
      backup_date=`cat "${UPGRADE_BACKUP_DIR}/backup_date" 2>/dev/null`
      if [ -n "$version" -a -n "$backup_date" -a -d "${UPGRADE_BACKUP_DIR}/cell" ]; then
         #Ask if correct
	      $INFOTEXT -n "\nFound backup from $version version created on $backup_date"
	      $INFOTEXT -auto $AUTO -ask "y" "n" -def "y" -n "\nContinue with this backup directory (y/n) [y] >> "
         if [ $? -eq 0 ]; then
            done=true
	         return 0
         fi
      else
         $INFOTEXT -n "\nInvalid backup directory \"${UPGRADE_BACKUP_DIR}\"!"
         UPGRADE_BACKUP_DIR=""
	      $INFOTEXT -auto $AUTO -ask "y" "n" -def "y" -n "\nEnter a new backup directory or exit ('n') (y/n) [y] >> "
	      if [ $? -ne 0 ]; then
	         exit 0
	      fi
      fi
   done
}

#-------------------------------------------------------------------------------
# RestoreCell: Restore backup cell directory
#   $1 - BACKUPED_CELL_DIRECTORY
RestoreCell()
{
   old_cell=$1
   if [ ! -d  "$SGE_ROOT/$SGE_CELL/common" ]; then
      Makedir "$SGE_ROOT/$SGE_CELL/common"
   fi
   
   FILE_LIST="bootstrap
host_aliases
qtask
sge_aliases
sge_ar_request
sge_request
sge_qquota
sge_qstat
shadow_masters
accounting
dbwriter.conf"

   for f in $FILE_LIST; do
      if [ -f "${old_cell}/$f" ]; then
         ExecuteAsAdmin cp -f "${old_cell}/$f" "$SGE_ROOT/$SGE_CELL/common"
      fi
   done
   
   #Modify bootstrap file
   ExecuteAsAdmin $CHMOD 666 "$SGE_ROOT/$SGE_CELL/common/bootstrap"
   #Version string
   ReplaceLineWithMatch "$SGE_ROOT/$SGE_CELL/common/bootstrap" 666 'Version.*' "Version: $SGE_VERSION"
   #ADMIN_USER
   if [ $ADMINUSER != default ]; then
      admin_user_value="admin_user              $ADMINUSER"
   else
      admin_user_value="admin_user              none"
   fi
   ReplaceLineWithMatch "$SGE_ROOT/$SGE_CELL/common/bootstrap" 666 'admin_user.*' "$admin_user_value"
   #TODO: default_domain, ignore_fqdn?
   #BINARY PATH
   ReplaceLineWithMatch "$SGE_ROOT/$SGE_CELL/common/bootstrap" 666 'binary_path.*' "binary_path             $SGE_ROOT/bin"
   #QMASTER SPOOL DIR
   ReplaceLineWithMatch "$SGE_ROOT/$SGE_CELL/common/bootstrap" 666 'qmaster_spool_dir.*' "qmaster_spool_dir       $QMDIR"
   #PRODUCT MODE
   ReplaceLineWithMatch "$SGE_ROOT/$SGE_CELL/common/bootstrap" 666 'security_mode.*' "security_mode           $PRODUCT_MODE"
   
   #Remove gdi_threads if present
   RemoveLineWithMatch "$SGE_ROOT/$SGE_CELL/common/bootstrap" 666 'gdi_threads.*'
   
   #Add threads info if missing
   cat $SGE_ROOT/$SGE_CELL/common/bootstrap | grep "threads" >/dev/null 2>&1
   do_bootstrap_upgrade=$?
   if [ $do_bootstrap_upgrade -eq 1 ]; then
      $ECHO "listener_threads        2" >> $SGE_ROOT/$SGE_CELL/common/bootstrap
      $ECHO "worker_threads          2" >> $SGE_ROOT/$SGE_CELL/common/bootstrap
      $ECHO "scheduler_threads       1" >> $SGE_ROOT/$SGE_CELL/common/bootstrap
   fi
   
   if [ "$SGE_ENABLE_JMX" = "true" ]; then
      ReplaceOrAddLine "$SGE_ROOT/$SGE_CELL/common/bootstrap" 666 'jvm_threads.*' "jvm_threads             1"
   else
      ReplaceOrAddLine "$SGE_ROOT/$SGE_CELL/common/bootstrap" 666 'jvm_threads.*' "jvm_threads             0"
   fi
   ExecuteAsAdmin $CHMOD 644 "$SGE_ROOT/$SGE_CELL/common/bootstrap"
}

#-------------------------------------------------------------------------------
# RestoreJMX: Ask if JMX setting from the backup should be used
#   $1 - BACKUPED_JMX_DIRECTORY
RestoreJMX()
{
   old_jmx=$1
   if [ "$SGE_ENABLE_JMX" = "true" -a -d "${old_jmx}" ]; then
      $CLEAR
      $INFOTEXT -n "\nFound JMX settings in the backup"
      $INFOTEXT -auto $AUTO -ask "y" "n" -def "y" -n "\nUse the JMX settings from the backup ('y') or reconfigure ('n') (y/n) [y] >> "
      if [ $? -eq 0 ]; then
	      #Use backup
	      ExecuteAsAdmin cp -r "${old_jmx}" "$SGE_ROOT/$SGE_CELL/common"
	      SGE_ENABLE_JMX=false
      fi
   fi
}

#-------------------------------------------------------------------------------
# NewIJS: Ask if JMX setting from the backup should be used
#   $1 - BACKUPED_JMX_DIRECTORY
SavedOrNewIJS()
{
   newIJS=false
   if [ "$USE_OLD_IJS" = true ]; then
      return
   fi
   $CLEAR
   $INFOTEXT -u "Interactive Job Support (IJS) Selection"   
   $INFOTEXT -auto $AUTO -ask "y" "n" -def "y" -n "\nThe backup configuration includes information for running \n" \
                                                  "interactive jobs. Do you want to use the IJS information from \n" \
                                                  "the backup ('y') or use new default values ('n') (y/n) [y] >> "
   if [ $? -ne 0 ]; then
      $INFOTEXT -n "\nUsing new interactive job support default setting for a new installation."
      newIJS=true
   fi
   $INFOTEXT -wait -auto $AUTO -n "\nHit <RETURN> to continue >> "
   $CLEAR
}

#-------------------------------------------------------------------------------
# AskForNewSequenceNumber: Ask for the next sequence number
#   $1 - file with the seq_number
#   $2 - "job" | "AR"
AskForNewSequenceNumber()
{
   NEXT_SEQ_NUMBER=""
   if [ ! -f "$1" ]; then #set to 0 is no file in backup and don't ask
      NEXT_SEQ_NUMBER=0
      return
   fi
   DEFAULT_SEQ_NUMBER=`cat "${1}" 2>/dev/null`
   if [ -z "$DEFAULT_SEQ_NUMBER" -o "$DEFAULT_SEQ_NUMBER" -lt 1 ]; then
      DEFAULT_SEQ_NUMBER=1
   fi
   #Add 1000 and round up
   TMP_SEQ_NUMBER=`expr $DEFAULT_SEQ_NUMBER / 1000 + 2`
   TMP_SEQ_NUMBER=`expr $TMP_SEQ_NUMBER \* 1000`

   if [ "$2" != "job" -a "$2" != "AR" ]; then
      $INFOTEXT "Invalid value '"$2"' provided to AskForNewSequenceNumber"
      exit 1
   fi
   done=false
   while [ "$done" != true ]; do
      $CLEAR
      $INFOTEXT -u "Provide a value to use for the next %s ID." "$2"
      $INFOTEXT -n "\nBackup contains last %s ID %s. As a suggested value, we added 1000 \n" \
                   "to that number and rounded it up to the nearest 1000.\n" \
                   "Increase the value, if appropriate.\n" \
		             "Choose the new next %s ID [%s] >> " "$2" "$DEFAULT_SEQ_NUMBER" "$2" "$TMP_SEQ_NUMBER"
      eval NEXT_SEQ_NUMBER=`Enter $TMP_SEQ_NUMBER`
      if [ "$NEXT_SEQ_NUMBER" -lt 1 -o "$NEXT_SEQ_NUMBER" -gt 9999999 ]; then
         $INFOTEXT -n "\nInvalid sequence number %s!\n" \
                      "Number must be between 1 .. 9999999" "$NEXT_SEQ_NUMBER"
      else
         NEXT_SEQ_NUMBER=`expr $NEXT_SEQ_NUMBER - 1`
         done=true
      fi
      $INFOTEXT -wait -auto $AUTO -n "\nHit <RETURN> to continue >> "
   done
   $CLEAR
}

#-------------------------------------------------------------------------------
# RestoreSequenceNumberFiles: Ask for the next sequence number
#   $1 - qmaster_spool_dir
RestoreSequenceNumberFiles()
{
   QMASTER_SPOOL_DIR=$1
   AskForNewSequenceNumber "${UPGRADE_BACKUP_DIR}/jobseqnum" "job"
   SafelyCreateFile "$QMASTER_SPOOL_DIR/jobseqnum" 644 $NEXT_SEQ_NUMBER
   AskForNewSequenceNumber "${UPGRADE_BACKUP_DIR}/arseqnum" "AR"
   SafelyCreateFile "$QMASTER_SPOOL_DIR/arseqnum" 644 $NEXT_SEQ_NUMBER
}


#Select spooling method
# $1 - backued spooling method
SelectNewSpooling() 
{
   backup_spooling_method=$1
   if [ "$backup_spooling_method" != "berkeleydb" -a "$backup_spooling_method" != "classic" ]; then
      $INFOTEXT "Invalid arg $1 to SelectNewSpooling"
      exit 1
   fi
	
   keep=false
	
   $CLEAR
   $INFOTEXT -auto $AUTO -ask "y" "n" -def "y" -n "\nUse previous %s spooling method ('y') or use new spooling method ('n') (y/n) [y] >> " \
             $backup_spooling_method
   if [ $? -eq 0 ]; then
      keep=true
      SPOOLING_METHOD=`BootstrapGetValue $SGE_ROOT/$SGE_CELL/common "spooling_method"`
      SPOOLING_LIB=`BootstrapGetValue $SGE_ROOT/$SGE_CELL/common "spooling_lib"`
      SPOOLING_ARGS=`BootstrapGetValue $SGE_ROOT/$SGE_CELL/common "spooling_params"`
      if [ "$SPOOLING_METHOD" = "berkeleydb" ]; then
         db_server_host=`echo "$SPOOLING_ARGS" | awk -F: '{print $1}'`
         db_server_spool_dir=`echo "$SPOOLING_ARGS" | awk -F: '{print $2}'`
         if [ -z "$db_server_spool_dir" ]; then #local bdb spooling
            if [ -d "$SPOOLING_ARGS" ]; then
               ExecuteAsAdmin rm -rf "$SPOOLING_ARGS"/*
            else #Create spooling dir if not present
               Makedir "$SPOOLING_ARGS"
            fi
         else # BDB server
            DoRemoteAction "$db_server_host" "$ADMINUSER" "/bin/sh -c if [ -d $db_server_spool_dir ]; then rm -rf $db_server_spool_dir/*; fi"
         fi
      else #Classic
         tmp_spool=`echo $SPOOLING_ARGS | awk -F";" '{print $1}' | awk '{print $2}'`
         list="configuration
local_conf
sched_configuration"
         for f in $list; do
            ExecuteAsAdmin rm -rf "${tmp_spool}/${f}"
         done
      fi
   else
      if [ "$backup_spooling_method" = "classic" ]; then
          suggested_spooling_method=berkeley
      else
          suggested_spooling_method=classic
      fi
      #Selecting new spooling method
      suggested_spoooling_params=`BootstrapGetValue ${UPGRADE_BACKUP_DIR}/$SGE_CELL/common "spooling_params"`
      SetSpoolingOptions "$suggested_spooling_method" "$suggested_spooling_params"
   fi
	
   if [ "$keep" = false ]; then
      ReplaceLineWithMatch "$SGE_ROOT/$SGE_CELL/common/bootstrap" 644 'spooling_method.*' "spooling_method         $SPOOLING_METHOD"
      ReplaceLineWithMatch "$SGE_ROOT/$SGE_CELL/common/bootstrap" 644 'spooling_lib.*'    "spooling_lib            $SPOOLING_LIB"
      ReplaceLineWithMatch "$SGE_ROOT/$SGE_CELL/common/bootstrap" 644 'spooling_params.*' "spooling_params         $SPOOLING_ARGS"
   fi
}

#AddDummyConfiguration - add a dummy configuration so we can start qmaster
#
AddDummyConfiguration() 
{
   CFG_EXE_SPOOL=$QMDIR/execd
   MAILER=mailx
   XTERM=xterm
   CFG_MAIL_ADDR=none
   CFG_GID_RANGE=20000-21000
   QLOGIN_COMMAND=builtin
   QLOGIN_DAEMON=builtin
   RLOGIN_COMMAND=builtin
   RLOGIN_DAEMON=builtin
   RSH_COMMAND=builtin
   RSH_DAEMON=builtin
   TMPC=/tmp/configuration_`date '+%Y-%m-%d_%H:%M:%S'`
   rm -f $TMPC
   SafelyCreateFile $TMPC 666 ""
   PrintConf >> $TMPC
   ExecuteAsAdmin $SPOOLDEFAULTS configuration $TMPC
   ExecuteAsAdmin rm -f $TMPC
}

#For copy upgrade type
PrepareConfiguration()
{
   $CLEAR
   tmp_range=`FileGetValue "$UPGRADE_BACKUP_DIR/configurations/global" "gid_range"`
   echo "$tmp_range" | grep -- "-" >/dev/null 2>&1
   if [ $? -ne 0 ]; then #single value
      GID_RANGE=`expr $tmp_range + 100`
   else                  #range
      tmp_start=`echo $tmp_range | awk -F"-" ' { print $1 }'`
      tmp_end=`echo $tmp_range | awk -F"-" ' { print $2 }'`
      tmp_range=`expr $tmp_end - $tmp_start`
      tmp_end=`expr $tmp_end + 100`
      GID_RANGE="${tmp_end}-`expr $tmp_end + $tmp_range`"
   fi
   GetConfiguration "$SGE_ROOT/$SGE_CELL/spool" `FileGetValue "$UPGRADE_BACKUP_DIR/configurations/global" "administrator_mail"`
}

ReplaceLineWithMatch()
{
   repFile="${1:?Need the file name to operate}"
   filePerms="${2:?Need file final permissions}"
   repExpr="${3:?Need an expression, where to replace}" 
   replace="${4:?Need the replacement text}" 

   #Return if no match
   grep "${repExpr}" $repFile >/dev/null 2>&1
   if [ $? -ne 0 ]; then
      return
   fi
   #We need to change the file
   ExecuteAsAdmin touch ${repFile}.tmp
   ExecuteAsAdmin chmod 666 ${repFile}.tmp
  
   SEP="|"
   echo "$repExpr $replace" | grep "|" >/dev/null 2>&1
   if [ $? -eq 0 ]; then
      echo "$repExpr $replace" | grep "%" >/dev/null 2>&1
      if [ $? -ne 0 ]; then
         SEP="%"
      else
         echo "$repExpr $replace" | grep "?" >/dev/null 2>&1
         if [ $? -ne 0 ]; then
            SEP="?"
         else
            $INFOTEXT "repExpr $replace contains |,% and ? characters: cannot use sed"
            exit 1
         fi
      fi
   fi
   #We need to change the file
   sed -e "s${SEP}${repExpr}${SEP}${replace}${SEP}g" "$repFile" >> "${repFile}.tmp"
   ExecuteAsAdmin mv -f "${repFile}.tmp"  "${repFile}"
   ExecuteAsAdmin chmod "${filePerms}" "${repFile}"
}

ReplaceOrAddLine()
{
   repFile="${1:?Need the file name to operate}"
   filePerms="${2:?Need file final permissions}"
   repExpr="${3:?Need an expression, where to replace}" 
   replace="${4:?Need the replacement text}" 
   
   #Does the pattern exists
   grep "${repExpr}" "${repFile}" > /dev/null 2>&1
   if [ $? -eq 0 ]; then #match
      ReplaceLineWithMatch "$repFile" "$filePerms" "$repExpr" "$replace"
   else                  #line does not exist
      echo "$replace" >> "$repFile"
   fi
}

#Remove line with maching expression
RemoveLineWithMatch()
{
   remFile="${1:?Need the file name to operate}"
   filePerms="${2:?Need file final permissions}"
   remExpr="${3:?Need an expression, where to remove lines}"
   
   #Return if no match
   grep "${remExpr}" $remFile >/dev/null 2>&1
   if [ $? -ne 0 ]; then
      return
   fi

   #We need to change the file
   ExecuteAsAdmin touch ${remFile}.tmp
   ExecuteAsAdmin chmod 666 ${remFile}.tmp
   sed -e "/${remExpr}/d" "$remFile" > "${remFile}.tmp"
   ExecuteAsAdmin mv -f "${remFile}.tmp"  "${remFile}"
   ExecuteAsAdmin chmod "${filePerms}" "${remFile}"
}
