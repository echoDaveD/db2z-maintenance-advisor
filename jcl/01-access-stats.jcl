//* Example only. Issue through your site's Db2 command facility.
//* Externalize in-memory RTS before DSNACCOX analysis.
//COMMAND  EXEC PGM=IKJEFT01
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSTSIN  DD *
  DSN SYSTEM(DB2A)
  -ACCESS DB(*) SP(*) MODE(STATS)
  END
/*
