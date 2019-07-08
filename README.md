# Shell-BackupScripts
Backup scripts designed to be used as Cron jobs (tested with Ubuntu). These scripts will store both local backups and upload via FTP. Includes rotational feature to cycle through and purge older backups.

Invocation must include either "h" for hourly, "d" for daily, "w" for weekly, or "m" for monthly (e.g., sudo ./sql-backup.sh h)

## Example Cron Job entry:
> 0 0 * * 0 /home/cool/sql-backup.sh w
