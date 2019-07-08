# Bash-SQLBackup
MySQL FTP backup script designed to be used as a Cron job. Includes rotational feature to cycle through and purge older backups.

Invocation must include either "h" for hourly, "d" for daily, "w" for weekly, or "m" for monthly (e.g., sudo sql-backup.sh h)
