/* REXX */
/*********************************************************************/
/* DB2UTGEN - Generate Db2 utility JCL from DSNACCOX ACCOXOUT    */
/*                                                                   */
/* Input DD:                                                         */
/*   ACCOXOUT - output created by DSNACCOX policy REXX              */
/*                                                                   */
/* Input DD:                                                         */
/*   UTGENPAR - generator parameters                                 */
/*                                                                   */
/* Invocation:                                                       */
/*   %DB2UTGEN                                                       */
/*                                                                   */
/* Job name NONE, '-' or blank disables that utility.                */
/*                                                                   */
/* Output members:                                                   */
/*   <prefix>R  REORG TABLESPACE / REORG INDEX                      */
/*   <prefix>I  Incremental COPY TABLESPACE                          */
/*   <prefix>F  Full COPY TABLESPACE / INDEXSPACE                    */
/*   <prefix>S  RUNSTATS TABLESPACE / INDEX                          */
/*                                                                   */
/* ASSOCIATEDTS is used to suppress redundant index utilities:       */
/* - a TS REORG recommendation suppresses related IX REORG           */
/* - a TS RUNSTATS recommendation suppresses related IX RUNSTATS     */
/* - multiple IX RUNSTATS for one TS become one INDEX(ALL) run       */
/*                                                                   */
/* MEMBER is the default member prefix (1-7 characters).            */
/* Utility-specific member names can override the derived names.     */
/* MAXOBJECTS is the global limit; utility MAX values can override.  */
/*                                                                   */
/* No positional parameters are required.                            */
/*********************************************************************/

/*********************************************************************/
/* Defaults and UTGENPAR                                             */
/*********************************************************************/

outlib = ''
basemem = ''
ssid = 'DB2A'
maxobj = 20
jobclass = 'A'
msgclass = 'X'
itemerror = 'SKIP'
genempty = 'YES'

jobr = ''
jobi = ''
jobf = ''
jobs = ''

memr = ''
memi = ''
memf = ''
mems = ''

reorgmax = 0
reorgretpd = 16
reorgunit = 'SYSALLDA'
reorghlq = 'USER.DB2MAINT'
reorgshr = 'CHANGE'
reorgauto = 'YES'
reorgindex = 'YES'
reorgpreview = 'NO'

icopymax = 0
icopyretpd = 16
icopyunit = 'SYSALLDA'
icopyhlq = 'USER.DB2MAINT'
icopyshr = 'CHANGE'
icopypreview = 'NO'

fullmax = 0
fullretpd = 16
fullunit = 'SYSALLDA'
fullhlq = 'USER.DB2MAINT'
fullshr = 'CHANGE'
fullindex = 'YES'
fullpreview = 'NO'

runmax = 0
runshr = 'CHANGE'
runupdate = 'ALL'
runindex = 'YES'
runprofile = 'YES'
runpreview = 'NO'

CALL ReadParameters
CALL ResolveParameters
CALL CheckInput
CALL ShowParameters

/*********************************************************************/
/* Read ACCOXOUT                                                     */
/*********************************************************************/

in. = ''
ADDRESS TSO "EXECIO * DISKR ACCOXOUT (STEM IN. FINIS"
IF RC <> 0 THEN DO
   SAY 'DB2UTGEN ERROR: CANNOT READ DD ACCOXOUT. RC=' RC
   EXIT 12
END

/*********************************************************************/
/* Candidate arrays                                                  */
/*********************************************************************/

r. = ''
i. = ''
f. = ''
s. = ''

rcnt = 0
icnt = 0
fcnt = 0
scnt = 0
exclcnt = 0

/*********************************************************************/
/* Fixed-width ACCOXOUT layout                                       */
/*                                                                   */
/* DBNAME          1-24                                              */
/* NAME           26-57                                              */
/* PART           59-63                                              */
/* OT             65-66                                              */
/* ASSOCIATEDTS   68-99                                              */
/* INDEXSPACE    101-124                                             */
/* PROFILE_TABLE 126-189                                             */
/* COPY          191-194                                             */
/* RUN           196-198                                             */
/* REO           200-202                                             */
/* EXT           204-206                                             */
/* AUTO          208-211                                             */
/* PRIO          213-216                                             */
/* SIZE_MB       218-227                                             */
/* STATUS        229-246                                             */
/* POLICY        248-347                                             */
/* REASON        349-568                                             */
/* COPYLAST      570-595                                             */
/* REORGLAST     597-622                                             */
/* STATSLAST     624-649                                             */
/*********************************************************************/

DO x = 1 TO in.0
   line = in.x

   IF STRIP(line) = '' THEN ITERATE
   IF LEFT(line,6) = 'DBNAME' THEN ITERATE
   IF LEFT(line,6) = '------' THEN ITERATE
   IF LENGTH(line) < 156 THEN ITERATE

   offset = 1
   db    = STRIP(SUBSTR(line,offset,24))
   offset = offset + 24 +1

   name  = STRIP(SUBSTR(line,offset,32))
   offset = offset + 32 +1

   part  = STRIP(SUBSTR(line,offset,5))
   offset = offset + 5 +1

   ot    = TRANSLATE(STRIP(SUBSTR(line,offset,2)))
   offset = offset + 2 +1

   assoc = STRIP(SUBSTR(line,offset,32))
   offset = offset + 32 +1

   ixsp  = STRIP(SUBSTR(line,offset,24))
   offset = offset + 24 +1

   proftab = STRIP(SUBSTR(line,offset,64))
   offset = offset + 64 +1

   cp    = TRANSLATE(STRIP(SUBSTR(line,offset,4)))
   offset = offset + 4 +1

   run   = TRANSLATE(STRIP(SUBSTR(line,offset,3)))
   offset = offset + 3 +1

   reo   = TRANSLATE(STRIP(SUBSTR(line,offset,3)))
   offset = offset + 3 + 1

   ext   = TRANSLATE(STRIP(SUBSTR(line,offset,3)))
   offset = offset + 3 + 1

   auto  = TRANSLATE(STRIP(SUBSTR(line,offset,4)))
   offset = offset + 4 +1

   prio  = STRIP(SUBSTR(line,offset,4))
   offset = offset + 4 +1

   offset = offset + 10 + 1 /* SIZE_MB */
   offset = offset + 18 + 1 /* STATUS  */
   policy = STRIP(SUBSTR(line,offset,100))
   offset = offset + 100 + 1
   reason = ''
   IF LENGTH(line) >= offset THEN
      reason = STRIP(SUBSTR(line,offset,220))

   IF db = '' THEN ITERATE
   IF name = '' THEN ITERATE
   IF IsSupportedType(ot) = 0 THEN ITERATE

   IF DATATYPE(part,'W') = 0 THEN part = 0
   IF DATATYPE(prio,'W') = 0 THEN prio = 9

   assoc = NormalizeAssoc(assoc)

   /* A global exclusion is encoded by the advisor as AUTO=NO plus */
   /* POLICY=OBJECT_EXCLUDED. Other AUTO=NO reasons remain REORG-only. */
   object_excluded = 0
   IF auto = 'NO' THEN DO
      IF POS('OBJECT_EXCLUDED',TRANSLATE(policy)) > 0 THEN
         object_excluded = 1
   END

   IF object_excluded = 1 THEN DO
      exclcnt = exclcnt + 1
      SAY 'OBJECT EXCLUDED:' db !! '.' !! name 'PART=' !! part
      ITERATE
   END

   astore = assoc
   IF astore = '' THEN astore = '-'

   isstore = ixsp
   IF isstore = '' THEN isstore = '-'

   pstore = proftab
   IF pstore = '' THEN pstore = '-'

   obj = db !! ' ' !! name !! ' ' !! part
   obj = obj !! ' ' !! prio !! ' ' !! ot
   obj = obj !! ' ' !! astore !! ' ' !! isstore
   obj = obj !! ' ' !! pstore !! ' ' !! reason

   /* REORG: honor local AUTO policy. */
   IF reo = 'YES' THEN DO
      take_reorg = 1
      IF reorgauto = 'YES' & auto = 'NO' THEN take_reorg = 0
      IF take_reorg = 1 THEN DO
        rcnt = rcnt + 1
        r.rcnt = obj
      END
   END

   /* Incremental COPY is not valid for an index space. */
   IF LEFT(cp,3) = 'INC' & ot <> 'IX' THEN DO
      icnt = icnt + 1
      i.icnt = obj
   END

   /* Full COPY supports table spaces and index spaces. */
   IF cp = 'FULL' THEN DO
      fcnt = fcnt + 1
      f.fcnt = obj
   END

   /* RUNSTATS recommendation. */
   IF LEFT(run,1) = 'Y' THEN DO
      scnt = scnt + 1
      s.scnt = obj
   END
END
/* DDY */
do tmpIx = 1 to rcnt
  say "REORG TS: "r.tmpIx
end

/*********************************************************************/
/* Build the four output members                                     */
/*********************************************************************/

rsel = 0
isel = 0
fsel = 0
ssel = 0
rixskip = 0
sixskip = 0

IF jobr <> '' THEN DO
   CALL BuildReorg
   writeit = 0
   IF genempty = 'YES' THEN writeit = 1
   IF rsel > 0 THEN writeit = 1
   IF writeit = 1 THEN CALL WriteMember memr, 'JOR'
END

IF jobi <> '' THEN DO
   CALL BuildIcopy
   writeit = 0
   IF genempty = 'YES' THEN writeit = 1
   IF isel > 0 THEN writeit = 1
   IF writeit = 1 THEN CALL WriteMember memi, 'JOI'
END

IF jobf <> '' THEN DO
   CALL BuildFcopy
   writeit = 0
   IF genempty = 'YES' THEN writeit = 1
   IF fsel > 0 THEN writeit = 1
   IF writeit = 1 THEN CALL WriteMember memf, 'JOF'
END

IF jobs <> '' THEN DO
   CALL BuildRunstats
   writeit = 0
   IF genempty = 'YES' THEN writeit = 1
   IF ssel > 0 THEN writeit = 1
   IF writeit = 1 THEN CALL WriteMember mems, 'JOS'
END

SAY ' '
SAY 'DB2UTGEN COMPLETED'
SAY 'OUTPUT LIBRARY :' outlib
CALL ShowResult 'REORG', memr, jobr, rsel
CALL ShowResult 'ICOPY', memi, jobi, isel
CALL ShowResult 'FULL', memf, jobf, fsel
CALL ShowResult 'RUNSTATS', mems, jobs, ssel
IF jobr <> '' THEN SAY 'IX REORG SKIP  :' rixskip
IF jobs <> '' THEN SAY 'IX RUNSTAT SKIP:' sixskip
SAY 'OBJECT EXCLUDED :' exclcnt

EXIT 0

/*********************************************************************/
/* Build REORG member                                                */
/*********************************************************************/

BuildReorg:

   rj. = ''
   rj.0 = 0
   rsel = 0
   rixskip = 0

   CALL AddR "//" !! LEFT(jobr,8) !!,
             " JOB  'DB2MAINT',"
   CALL AddR "//             CLASS=" !! jobclass !!","
   CALL AddR "//             MSGCLASS=" !! msgclass !!","
   CALL AddR "//             REGION=0M"
   CALL AddR "//******************************************************"
   CALL AddR "//* DESCRIPTION : Db2 Daily Maintenance Utilities          "
   CALL AddR "//*               Auto Generated Reorg Job by DB2UTGEN  "
   CALL AddR "//*                                                     "
   CALL AddR "//*       AUTHOR: DB2UTGEN                              "
   CALL AddR "//*    GENERATED : "date()"                              "
   CALL AddR "//******************************************************"
   CALL AddR "//UTIL     EXEC PGM=DSNUTILB,PARM='" !! ssid !!,
             "," !! LEFT(memr,8) !! "'"
   CALL AddR "//STEPLIB  DD  DSN=DSN.V13.SDSNLOAD,"
   CALL AddR "//             DISP=SHR"
   CALL AddR "//SYSUT1   DD UNIT=SYSDA,SPACE=(CYL,(5,5))"
   CALL AddR "//SORTOUT  DD UNIT=SYSDA,SPACE=(CYL,(5,5))"
   CALL AddR "//SYSERR   DD UNIT=SYSDA,SPACE=(CYL,(5,5))"
   CALL AddR "//SYSMAP   DD UNIT=SYSDA,SPACE=(CYL,(5,5))"
   CALL AddR "//SYSREC   DD UNIT=SYSDA,SPACE=(CYL,(5,5))"
   CALL AddR "//SYSPRINT DD SYSOUT=*"
   CALL AddR "//UTPRINT  DD SYSOUT=*"
   CALL AddR "//SYSOUT   DD SYSOUT=*"
   CALL AddR "//SYSIN    DD *"
   optline = 'OPTIONS'
   IF reorgpreview = 'YES' THEN optline = optline !! ' PREVIEW'
   optline = optline !! ' EVENT(ITEMERROR,' !! itemerror !! ')'
   CALL AddR optline
   CALL AddR 'TEMPLATE RGCOPY'
   CALL AddR "  DSN('" !! reorghlq !!,
             ".RC&JU(3,5)..P&HO.&MI.&PA(3)..&DB..&TS.')"
   CALL AddR '  UNIT ' !! reorgunit
   CALL AddR '  DISP(NEW,CATLG,DELETE)'
   CALL AddR '  RETPD ' !! reorgretpd

   /* Process table spaces before indexes within each priority. */
   DO p = 1 TO 9
      DO pass = 1 TO 2
         DO z = 1 TO rcnt
            PARSE VAR r.z zdb zname zpart zpr zot zassoc zixsp zproftab rest
            IF zassoc = '-' THEN zassoc = ''
            IF zixsp = '-' THEN zixsp = ''
             IF zproftab = '-' THEN zproftab = ''
            IF zpr <> p THEN ITERATE

            IF pass = 1 & zot = 'IX' THEN ITERATE
            IF pass = 2 & zot <> 'IX' THEN ITERATE

            IF rsel >= reorgmax THEN LEAVE

            IF zot = 'IX' THEN DO
               IF reorgindex <> 'YES' THEN ITERATE
               /* Parent TS REORG makes separate IX REORG redundant. */
               IF zassoc <> '' THEN DO
                  hasparent = HasTsReorg(zdb,zassoc)
                  IF hasparent = 1 THEN DO
                     rixskip = rixskip + 1
                     SAY "Index "zname" skipped because TS "zassoc!!,
                              " is on Reorg List"
                     ITERATE
                  END
               END

               IF zixsp = '' THEN DO
                  CALL AddR '-- IX SKIPPED: INDEXSPACE UNKNOWN'
                  CALL AddR '-- DB=' !! zdb !! ' INDEX=' !! zname
                  rixskip = rixskip + 1
                  ITERATE
               END

               CALL AddR '-- IX ' !! zname
               CALL AddR '-- INDEXSPACE ' !! zdb !! '.' !! zixsp
               IF zassoc <> '' THEN
                  CALL AddR '-- ASSOCIATED TS ' !! zassoc
               CALL AddR 'REORG INDEXSPACE ' !! zdb !! '.' !! zixsp
               IF zpart > 0 THEN
                  CALL AddR '      PART ' !! zpart
               CALL AddR '      SHRLEVEL ' !! reorgshr
               rsel = rsel + 1
               ITERATE
            END

            CALL AddR '-- TS ' !! zdb !! '.' !! zname
            CALL AddR 'REORG TABLESPACE ' !! zdb !! '.' !! zname

            /* LOB REORG does not support PART and requires LOG NO. */
            IF zot = 'LS' THEN DO
               CALL AddR '      SHRLEVEL ' !! reorgshr !! ' LOG NO'
               CALL AddR '      COPYDDN(RGCOPY)'
            END
            ELSE DO
               IF zpart > 0 THEN
                  CALL AddR '      PART ' !! zpart
               CALL AddR '      SHRLEVEL ' !! reorgshr
               CALL AddR '      COPYDDN(RGCOPY)'
            END

            rsel = rsel + 1
         END
         IF rsel >= reorgmax THEN LEAVE
      END
      IF rsel >= reorgmax THEN LEAVE
   END

   IF rsel = 0 THEN CALL AddR '-- NO REORG OBJECTS SELECTED'
   CALL AddR '/*'

RETURN

/*********************************************************************/
/* Build Incremental COPY member                                     */
/*********************************************************************/

BuildIcopy:

   ij. = ''
   ij.0 = 0
   isel = 0

   CALL AddI "//" !! LEFT(jobi,8) !!" JOB 'DB2MAINT',"
   CALL AddI "//             CLASS=" !! jobclass !!","
   CALL AddI "//             MSGCLASS=" !! msgclass !!","
   CALL AddI "//             REGION=0M"
   CALL AddI "//******************************************************"
   CALL AddI "//* DESCRIPTION : Db2 Daily Maintenance Utilities          "
   CALL AddI "//*               Auto Generated ICopy Job by DB2UTGEN  "
   CALL AddI "//*                                                     "
   CALL AddI "//*       AUTHOR: DB2UTGEN                              "
   CALL AddI "//*    GENERATED : "date()"                              "
   CALL AddI "//******************************************************"
   CALL AddI "//UTIL EXEC PGM=DSNUTILB,PARM='" !! ssid !!,
             "," !! LEFT(memi,8) !! "'"
   CALL AddI "//STEPLIB  DD  DSN=DSN.V13.SDSNLOAD,"
   CALL AddI "//             DISP=SHR"
   CALL AddI "//SYSUT1   DD UNIT=SYSDA,SPACE=(CYL,(5,5))"
   CALL AddI "//SORTOUT  DD UNIT=SYSDA,SPACE=(CYL,(5,5))"
   CALL AddI "//SYSERR   DD UNIT=SYSDA,SPACE=(CYL,(5,5))"
   CALL AddI "//SYSMAP   DD UNIT=SYSDA,SPACE=(CYL,(5,5))"
   CALL AddI "//SYSREC   DD UNIT=SYSDA,SPACE=(CYL,(5,5))"
   CALL AddI "//SYSPRINT DD SYSOUT=*"
   CALL AddI "//UTPRINT  DD SYSOUT=*"
   CALL AddI "//SYSOUT   DD SYSOUT=*"
   CALL AddI "//SYSIN    DD *"
   optline = 'OPTIONS'
   IF icopypreview = 'YES' THEN optline = optline !! ' PREVIEW'
   optline = optline !! ' EVENT(ITEMERROR,' !! itemerror !! ')'
   CALL AddI optline
   CALL AddI 'TEMPLATE CPINCR'
   CALL AddI "  DSN('" !! icopyhlq !!,
             ".IC&JU(3,5)..P&HO.&MI.&PA(3)..&DB..&TS.')"
   CALL AddI '  UNIT ' !! icopyunit
   CALL AddI '  DISP(NEW,CATLG,DELETE)'
   CALL AddI '  RETPD ' !! icopyretpd

   DO z = 1 TO icnt
      IF isel >= icopymax THEN LEAVE
      PARSE VAR i.z zdb zname zpart zpr zot zassoc zixsp zproftab rest
      IF zassoc = '-' THEN zassoc = ''

      /* Safety: Incremental COPY of index spaces is invalid. */
      IF zot = 'IX' THEN ITERATE

      CALL AddI '-- TS ' !! zdb !! '.' !! zname
      CALL AddI 'COPY TABLESPACE ' !! zdb !! '.' !! zname
      IF zpart > 0 THEN CALL AddI '     DSNUM ' !! zpart
      CALL AddI '     COPYDDN(CPINCR)'
      CALL AddI '     FULL NO SHRLEVEL ' !! icopyshr
      isel = isel + 1
   END

   IF isel = 0 THEN CALL AddI '-- NO INCREMENTAL COPY OBJECTS SELECTED'
   CALL AddI '/*'

RETURN

/*********************************************************************/
/* Build Full COPY member                                            */
/*********************************************************************/

BuildFcopy:

   fj. = ''
   fj.0 = 0
   fsel = 0

   CALL AddF "//" !! LEFT(jobf,8) !!" JOB 'DB2MAINT',"
   CALL AddF "//             CLASS=" !! jobclass !!","
   CALL AddF "//             MSGCLASS=" !! msgclass !!","
   CALL AddF "//             REGION=0M"
   CALL AddF "//******************************************************"
   CALL AddF "//* DESCRIPTION : Db2 Daily Maintenance Utilities          "
   CALL AddF "//*               Auto Generated FCopy Job by DB2UTGEN  "
   CALL AddF "//*                                                     "
   CALL AddF "//*       AUTHOR: DB2UTGEN                              "
   CALL AddF "//*    GENERATED : "date()"                              "
   CALL AddF "//******************************************************"
   CALL AddF "//UTIL EXEC PGM=DSNUTILB,PARM='" !! ssid !!,
             "," !! LEFT(memf,8) !! "'"
   CALL AddF "//STEPLIB  DD  DSN=DSN.V13.SDSNLOAD,"
   CALL AddF "//             DISP=SHR"
   CALL AddF "//SYSUT1   DD UNIT=SYSDA,SPACE=(CYL,(5,5))"
   CALL AddF "//SORTOUT  DD UNIT=SYSDA,SPACE=(CYL,(5,5))"
   CALL AddF "//SYSERR   DD UNIT=SYSDA,SPACE=(CYL,(5,5))"
   CALL AddF "//SYSMAP   DD UNIT=SYSDA,SPACE=(CYL,(5,5))"
   CALL AddF "//SYSREC   DD UNIT=SYSDA,SPACE=(CYL,(5,5))"
   CALL AddF "//SYSPRINT DD SYSOUT=*"
   CALL AddF "//UTPRINT  DD SYSOUT=*"
   CALL AddF "//SYSOUT   DD SYSOUT=*"
   CALL AddF "//SYSIN    DD *"
   optline = 'OPTIONS'
   IF fullpreview = 'YES' THEN optline = optline !! ' PREVIEW'
   optline = optline !! ' EVENT(ITEMERROR,' !! itemerror !! ')'
   CALL AddF optline
   CALL AddF 'TEMPLATE CPFULL'
   CALL AddF "  DSN('" !! fullhlq !!,
             ".FC&JU(3,5)..P&HO.&MI.&PA(3)..&DB..&TS.')"
   CALL AddF '  UNIT ' !! fullunit
   CALL AddF '  DISP(NEW,CATLG,DELETE)'
   CALL AddF '  RETPD ' !! fullretpd

   DO z = 1 TO fcnt
      IF fsel >= fullmax THEN LEAVE
      PARSE VAR f.z zdb zname zpart zpr zot zassoc zixsp zproftab rest
      IF zassoc = '-' THEN zassoc = ''

      IF zot = 'IX' THEN DO
         IF fullindex <> 'YES' THEN ITERATE
         CALL AddF '-- IX ' !! zdb !! '.' !! zname
         IF zassoc <> '' THEN
            CALL AddF '-- ASSOCIATED TS ' !! zassoc
         CALL AddF 'COPY INDEXSPACE ' !! zdb !! '.' !! zname
      END
      ELSE DO
         CALL AddF '-- TS ' !! zdb !! '.' !! zname
         CALL AddF 'COPY TABLESPACE ' !! zdb !! '.' !! zname
      END

      IF zpart > 0 THEN CALL AddF '     DSNUM ' !! zpart
      CALL AddF '     COPYDDN(CPFULL)'
      CALL AddF '     FULL YES SHRLEVEL ' !! fullshr
      fsel = fsel + 1
   END

   IF fsel = 0 THEN CALL AddF '-- NO FULL COPY OBJECTS SELECTED'
   CALL AddF '/*'

RETURN

/*********************************************************************/
/* Build RUNSTATS member                                             */
/*********************************************************************/

BuildRunstats:

   sj. = ''
   sj.0 = 0
   ssel = 0
   sixskip = 0
   srp. = ''
   srpcnt = 0

   CALL AddS "//" !! LEFT(jobs,8) !!" JOB 'DB2MAINT',"
   CALL AddS "//             CLASS=" !! jobclass !!","
   CALL AddS "//             MSGCLASS=" !! msgclass !!","
   CALL AddS "//             REGION=0M"
   CALL AddS "//******************************************************"
   CALL AddS "//* DESCRIPTION : Db2 Daily Maintenance Utilities          "
   CALL AddS "//*               Auto Generated RUN   Job by DB2UTGEN  "
   CALL AddS "//*                                                     "
   CALL AddS "//*       AUTHOR: DB2UTGEN                              "
   CALL AddS "//*    GENERATED : "date()"                              "
   CALL AddS "//******************************************************"
   CALL AddS "//UTIL EXEC PGM=DSNUTILB,PARM='" !! ssid !!,
             "," !! LEFT(mems,8) !! "'"
   CALL AddS "//STEPLIB  DD  DSN=DSN.V13.SDSNLOAD,"
   CALL AddS "//             DISP=SHR"
   CALL AddS "//SYSUT1   DD UNIT=SYSDA,SPACE=(CYL,(5,5))"
   CALL AddS "//SORTOUT  DD UNIT=SYSDA,SPACE=(CYL,(5,5))"
   CALL AddS "//SYSERR   DD UNIT=SYSDA,SPACE=(CYL,(5,5))"
   CALL AddS "//SYSMAP   DD UNIT=SYSDA,SPACE=(CYL,(5,5))"
   CALL AddS "//SYSREC   DD UNIT=SYSDA,SPACE=(CYL,(5,5))"
   CALL AddS "//SYSPRINT DD SYSOUT=*"
   CALL AddS "//UTPRINT  DD SYSOUT=*"
   CALL AddS "//RNPRIN01 DD SYSOUT=*"
   CALL AddS "//STPRIN01 DD SYSOUT=*"
   CALL AddS "//SYSOUT   DD SYSOUT=*"
   CALL AddS "//SYSIN    DD *"
   optline = 'OPTIONS'
   IF runpreview = 'YES' THEN optline = optline !! ' PREVIEW'
   optline = optline !! ' EVENT(ITEMERROR,' !! itemerror !! ')'
   CALL AddS optline

   /* First generate table-space RUNSTATS. */
   DO z = 1 TO scnt
      IF ssel >= runmax THEN LEAVE
      PARSE VAR s.z zdb zname zpart zpr zot zassoc zixsp zproftab rest
      IF zassoc = '-' THEN zassoc = ''
      IF zixsp = '-' THEN zixsp = ''
      IF zproftab = '-' THEN zproftab = ''
      IF zot = 'IX' THEN ITERATE

      useprof = 0
      IF zproftab <> '' & runprofile = 'YES' THEN useprof = 1

      CALL AddS '-- TS ' !! zdb !! '.' !! zname
      IF useprof = 1 THEN CALL AddS '-- PROFILE ' !! zproftab
      CALL AddS 'RUNSTATS TABLESPACE ' !! zdb !! '.' !! zname
      IF zpart > 0 THEN CALL AddS '         PART ' !! zpart

      IF useprof = 1 THEN DO
         CALL AddS '         TABLE (' !! zproftab !! ')'
         CALL AddS '         USE PROFILE'
      END
      ELSE DO
         IF zot <> 'LS' THEN DO
            CALL AddS '         TABLE(ALL) INDEX(ALL)'
            CALL AddS '         TABLESAMPLE SYSTEM AUTO'
         END
      END

      CALL AddS '         SHRLEVEL ' !! runshr !!,
                ' UPDATE ' !! runupdate

      ssel = ssel + 1
   END

   /* Then generate isolated index recommendations. */
   IF ssel < runmax THEN DO
      DO z = 1 TO scnt
         IF ssel >= runmax THEN LEAVE
         PARSE VAR s.z zdb zname zpart zpr zot zassoc zixsp zproftab rest
         IF zassoc = '-' THEN zassoc = ''
         IF zixsp = '-' THEN zixsp = ''
         IF zproftab = '-' THEN zproftab = ''
         IF zot <> 'IX' THEN ITERATE
         IF runindex <> 'YES' THEN ITERATE

         /* Without ASSOCIATEDTS no safe RUNSTATS target exists. */
         IF zassoc = '' THEN DO
            sixskip = sixskip + 1
            ITERATE
         END

         /* TS RUNSTATS TABLE(ALL) INDEX(ALL) already covers it. */
         IF HasTsRunstats(zdb,zassoc) = 1 THEN DO
            sixskip = sixskip + 1
            ITERATE
         END

         /* Multiple IX recommendations for one TS need one run only. */
         IF RunParentDone(zdb,zassoc) = 1 THEN DO
            sixskip = sixskip + 1
            ITERATE
         END

         CALL AddS '-- IX RECOMMENDATION FOR TS ' !!,
                   zdb !! '.' !! zassoc
         CALL AddS 'RUNSTATS TABLESPACE ' !!,
                   zdb !! '.' !! zassoc
         CALL AddS '         INDEX(ALL)'
         CALL AddS '         SHRLEVEL ' !! runshr !!,
                   ' UPDATE ' !! runupdate

         srpcnt = srpcnt + 1
         srp.srpcnt = zdb !! ' ' !! zassoc
         ssel = ssel + 1
      END
   END

   IF ssel = 0 THEN CALL AddS '-- NO RUNSTATS OBJECTS SELECTED'
   CALL AddS '/*'

RETURN

/*********************************************************************/
/* Does related TS have an eligible REORG recommendation?            */
/*********************************************************************/

HasTsReorg:

   PARSE ARG hdb, hts
   found = 0

   DO hz = 1 TO rcnt
      PARSE VAR r.hz hxdb hxname hxpart hxpr hxot hxassoc hxixsp hxproftab hxrest
      IF hxot = 'IX' THEN ITERATE
      IF hxdb <> hdb THEN ITERATE
      IF hxname <> hts THEN ITERATE
      found = 1
      LEAVE
   END

RETURN found

/*********************************************************************/
/* Does related TS have a RUNSTATS recommendation?                   */
/*********************************************************************/

HasTsRunstats:

   PARSE ARG hdb, hts
   found = 0

   DO hz = 1 TO scnt
      PARSE VAR s.hz hxdb hxname hxpart hxpr hxot hxassoc hxixsp hxproftab hxrest
      IF hxot = 'IX' THEN ITERATE
      IF hxdb <> hdb THEN ITERATE
      IF hxname <> hts THEN ITERATE
      found = 1
      LEAVE
   END

RETURN found

/*********************************************************************/
/* Was INDEX(ALL) already generated for this associated TS?          */
/*********************************************************************/

RunParentDone:

   PARSE ARG hdb, hts
   found = 0

   DO hz = 1 TO srpcnt
      PARSE VAR srp.hz hxdb hxts
      IF hxdb = hdb & hxts = hts THEN DO
         found = 1
         LEAVE
      END
   END

RETURN found

/*********************************************************************/
/* Normalize ASSOCIATEDTS                                            */
/*********************************************************************/

NormalizeAssoc:

   PARSE ARG atxt
   atxt = STRIP(atxt)

   /* If DSNACCOX returns DBNAME.TSNAME, keep only TSNAME. */
   apos = LASTPOS('.',atxt)
   IF apos > 0 THEN atxt = SUBSTR(atxt,apos + 1)

RETURN STRIP(atxt)

/*********************************************************************/
/* Write a generated stem to a PDS/PDSE member                      */
/*********************************************************************/

WriteMember:

   PARSE ARG wm, ddn

   target = outlib !! '(' !! wm !! ')'
   cmd = "ALLOC FI(" !! ddn !! ") DA('" !! target !! "')"
   cmd = cmd !! " SHR REUSE"

   ADDRESS TSO cmd
   IF RC <> 0 THEN DO
      SAY 'DB2UTGEN ERROR: ALLOC FAILED FOR' target 'RC=' RC
      EXIT 12
   END

   SELECT
      WHEN ddn = 'JOR' THEN DO
         ADDRESS TSO "EXECIO * DISKW JOR (STEM RJ. FINIS"
      END
      WHEN ddn = 'JOI' THEN DO
         ADDRESS TSO "EXECIO * DISKW JOI (STEM IJ. FINIS"
      END
      WHEN ddn = 'JOF' THEN DO
         ADDRESS TSO "EXECIO * DISKW JOF (STEM FJ. FINIS"
      END
      WHEN ddn = 'JOS' THEN DO
         ADDRESS TSO "EXECIO * DISKW JOS (STEM SJ. FINIS"
      END
      OTHERWISE NOP
   END

   wrc = RC
   cmd = "FREE FI(" !! ddn !! ")"
   ADDRESS TSO cmd

   IF wrc <> 0 THEN DO
      SAY 'DB2UTGEN ERROR: WRITE FAILED FOR' target 'RC=' wrc
      EXIT 12
   END

RETURN

/*********************************************************************/
/* Output stem helpers                                               */
/*********************************************************************/

AddR:
   PARSE ARG txt
   rj.0 = rj.0 + 1
   n = rj.0
   rj.n = txt
RETURN

AddI:
   PARSE ARG txt
   ij.0 = ij.0 + 1
   n = ij.0
   ij.n = txt
RETURN

AddF:
   PARSE ARG txt
   fj.0 = fj.0 + 1
   n = fj.0
   fj.n = txt
RETURN

AddS:
   PARSE ARG txt
   sj.0 = sj.0 + 1
   n = sj.0
   sj.n = txt
RETURN

/*********************************************************************/
/* Object type helper                                                */
/*********************************************************************/

IsSupportedType:
   PARSE ARG typ
   ok = 0
   IF typ = 'TS' THEN ok = 1
   IF typ = 'LS' THEN ok = 1
   IF typ = 'XS' THEN ok = 1
   IF typ = 'IX' THEN ok = 1
RETURN ok

/*********************************************************************/
/* Read UTGENPAR                                                     */
/*********************************************************************/

ReadParameters:

   parm. = ''
   ADDRESS TSO "EXECIO * DISKR UTGENPAR (STEM PARM. FINIS"
   prc = RC

   IF prc <> 0 THEN DO
      SAY 'DB2UTGEN ERROR: CANNOT READ DD UTGENPAR. RC=' prc
      EXIT 12
   END

   DO px = 1 TO parm.0
      pline = STRIP(parm.px)
      IF pline = '' THEN ITERATE
      IF LEFT(pline,1) = '*' THEN ITERATE
      IF LEFT(pline,2) = '/*' THEN ITERATE

      PARSE VAR pline pname pvalue
      pname = TRANSLATE(STRIP(pname))
      pvalue = STRIP(pvalue)

      IF pname = '' THEN ITERATE
      CALL SetParameter pname, pvalue
   END

RETURN

/*********************************************************************/
/* Set one UTGENPAR value                                            */
/*********************************************************************/

SetParameter:

   PARSE ARG pname, pvalue

   SELECT
      WHEN pname = 'LIBRARY' THEN outlib = pvalue
      WHEN pname = 'MEMBER' THEN basemem = TRANSLATE(pvalue)
      WHEN pname = 'SSID' THEN ssid = TRANSLATE(pvalue)
      WHEN pname = 'MAXOBJECTS' THEN maxobj = pvalue
      WHEN pname = 'JOBCLASS' THEN jobclass = TRANSLATE(pvalue)
      WHEN pname = 'MSGCLASS' THEN msgclass = TRANSLATE(pvalue)
      WHEN pname = 'ITEMERROR' THEN itemerror = TRANSLATE(pvalue)
      WHEN pname = 'GENERATEEMPTY' THEN genempty = YesNo(pvalue)

      WHEN pname = 'REORGJOB' THEN jobr = NormalizeJob(pvalue)
      WHEN pname = 'REORGMEMBER' THEN memr = TRANSLATE(pvalue)
      WHEN pname = 'REORGMAX' THEN reorgmax = pvalue
      WHEN pname = 'REORGRETPD' THEN reorgretpd = pvalue
      WHEN pname = 'REORGUNIT' THEN reorgunit = TRANSLATE(pvalue)
      WHEN pname = 'REORGHLQ' THEN reorghlq = TRANSLATE(pvalue)
      WHEN pname = 'REORGSHRLEVEL' THEN reorgshr = TRANSLATE(pvalue)
      WHEN pname = 'REORGONLYAUTO' THEN reorgauto = YesNo(pvalue)
      WHEN pname = 'REORGINDEX' THEN reorgindex = YesNo(pvalue)
      WHEN pname = 'REORGPREVIEW' THEN reorgpreview = YesNo(pvalue)

      WHEN pname = 'ICOPYJOB' THEN jobi = NormalizeJob(pvalue)
      WHEN pname = 'ICOPYMEMBER' THEN memi = TRANSLATE(pvalue)
      WHEN pname = 'ICOPYMAX' THEN icopymax = pvalue
      WHEN pname = 'ICOPYRETPD' THEN icopyretpd = pvalue
      WHEN pname = 'ICOPYUNIT' THEN icopyunit = TRANSLATE(pvalue)
      WHEN pname = 'ICOPYHLQ' THEN icopyhlq = TRANSLATE(pvalue)
      WHEN pname = 'ICOPYSHRLEVEL' THEN icopyshr = TRANSLATE(pvalue)
      WHEN pname = 'ICOPYPREVIEW' THEN icopypreview = YesNo(pvalue)

      WHEN pname = 'FULLCOPYJOB' THEN jobf = NormalizeJob(pvalue)
      WHEN pname = 'FULLCOPYMEMBER' THEN memf = TRANSLATE(pvalue)
      WHEN pname = 'FULLCOPYMAX' THEN fullmax = pvalue
      WHEN pname = 'FULLCOPYRETPD' THEN fullretpd = pvalue
      WHEN pname = 'FULLCOPYUNIT' THEN fullunit = TRANSLATE(pvalue)
      WHEN pname = 'FULLCOPYHLQ' THEN fullhlq = TRANSLATE(pvalue)
      WHEN pname = 'FULLCOPYSHRLEVEL' THEN fullshr = TRANSLATE(pvalue)
      WHEN pname = 'FULLCOPYINDEX' THEN fullindex = YesNo(pvalue)
      WHEN pname = 'FULLCOPYPREVIEW' THEN fullpreview = YesNo(pvalue)

      WHEN pname = 'RUNSTATSJOB' THEN jobs = NormalizeJob(pvalue)
      WHEN pname = 'RUNSTATSMEMBER' THEN mems = TRANSLATE(pvalue)
      WHEN pname = 'RUNSTATSMAX' THEN runmax = pvalue
      WHEN pname = 'RUNSTATSSHRLEVEL' THEN runshr = TRANSLATE(pvalue)
      WHEN pname = 'RUNSTATSUPDATE' THEN runupdate = TRANSLATE(pvalue)
      WHEN pname = 'RUNSTATSINDEX' THEN runindex = YesNo(pvalue)
      WHEN pname = 'RUNSTATSPROFILE' THEN runprofile = YesNo(pvalue)
      WHEN pname = 'RUNSTATSPREVIEW' THEN runpreview = YesNo(pvalue)

      OTHERWISE DO
         SAY 'DB2UTGEN ERROR: UNKNOWN UTGENPAR:' pname
         EXIT 12
      END
   END

RETURN

/*********************************************************************/
/* Resolve derived and inherited settings                            */
/*********************************************************************/

ResolveParameters:

   IF memr = '' THEN memr = basemem !! 'R'
   IF memi = '' THEN memi = basemem !! 'I'
   IF memf = '' THEN memf = basemem !! 'F'
   IF mems = '' THEN mems = basemem !! 'S'

   IF reorgmax = 0 THEN reorgmax = maxobj
   IF icopymax = 0 THEN icopymax = maxobj
   IF fullmax = 0 THEN fullmax = maxobj
   IF runmax = 0 THEN runmax = maxobj

RETURN

/*********************************************************************/
/* Validate parameters                                               */
/*********************************************************************/

CheckInput:

   outlib = STRIP(outlib)
   basemem = TRANSLATE(STRIP(basemem))
   ssid = TRANSLATE(STRIP(ssid))

   IF LEFT(outlib,1) = "'" THEN outlib = SUBSTR(outlib,2)
   IF RIGHT(outlib,1) = "'" THEN
      outlib = LEFT(outlib,LENGTH(outlib)-1)

   IF outlib = '' THEN CALL ParmError 'LIBRARY IS REQUIRED'
   IF basemem = '' THEN CALL ParmError 'MEMBER IS REQUIRED'
   IF LENGTH(basemem) > 7 THEN
      CALL ParmError 'MEMBER PREFIX MAXIMUM IS 7 CHARACTERS'
   IF ssid = '' THEN CALL ParmError 'SSID IS REQUIRED'

   CALL CheckWhole 'MAXOBJECTS', maxobj, 1
   CALL CheckWhole 'REORGMAX', reorgmax, 0
   CALL CheckWhole 'ICOPYMAX', icopymax, 0
   CALL CheckWhole 'FULLCOPYMAX', fullmax, 0
   CALL CheckWhole 'RUNSTATSMAX', runmax, 0
   CALL CheckWhole 'REORGRETPD', reorgretpd, 0
   CALL CheckWhole 'ICOPYRETPD', icopyretpd, 0
   CALL CheckWhole 'FULLCOPYRETPD', fullretpd, 0

   IF itemerror <> 'SKIP' & itemerror <> 'HALT' THEN
      CALL ParmError 'ITEMERROR MUST BE SKIP OR HALT'

   IF reorgshr <> 'CHANGE' & reorgshr <> 'REFERENCE' THEN
      CALL ParmError 'REORGSHRLEVEL MUST BE CHANGE OR REFERENCE'
   IF icopyshr <> 'CHANGE' & icopyshr <> 'REFERENCE' THEN
      CALL ParmError 'ICOPYSHRLEVEL MUST BE CHANGE OR REFERENCE'
   IF fullshr <> 'CHANGE' & fullshr <> 'REFERENCE' THEN
      CALL ParmError 'FULLCOPYSHRLEVEL MUST BE CHANGE OR REFERENCE'
   IF runshr <> 'CHANGE' & runshr <> 'REFERENCE' THEN
      CALL ParmError 'RUNSTATSSHRLEVEL MUST BE CHANGE OR REFERENCE'

   CALL CheckJobName 'REORG', jobr
   CALL CheckJobName 'ICOPY', jobi
   CALL CheckJobName 'FULLCOPY', jobf
   CALL CheckJobName 'RUNSTATS', jobs

   CALL CheckMember 'REORG', memr
   CALL CheckMember 'ICOPY', memi
   CALL CheckMember 'FULLCOPY', memf
   CALL CheckMember 'RUNSTATS', mems

   IF runupdate <> 'ALL' & runupdate <> 'ACCESSPATH' & ,
      runupdate <> 'SPACE' & runupdate <> 'NONE' THEN
      CALL ParmError 'RUNSTATSUPDATE INVALID'

   IF jobr = '' & jobi = '' & jobf = '' & jobs = '' THEN
      CALL ParmError 'ALL UTILITIES ARE DISABLED'

RETURN

/*********************************************************************/
/* Normalize optional job name                                       */
/*********************************************************************/

NormalizeJob:
   PARSE ARG njob
   njob = TRANSLATE(STRIP(njob))
   IF njob = '-' THEN njob = ''
   IF njob = 'NONE' THEN njob = ''
RETURN njob

/*********************************************************************/
/* Normalize YES/NO                                                  */
/*********************************************************************/

YesNo:
   PARSE ARG yn
   yn = TRANSLATE(STRIP(yn))
   IF yn = 'Y' THEN yn = 'YES'
   IF yn = 'N' THEN yn = 'NO'
   IF yn <> 'YES' & yn <> 'NO' THEN DO
      SAY 'DB2UTGEN ERROR: EXPECTED YES OR NO, GOT' yn
      EXIT 12
   END
RETURN yn

/*********************************************************************/
/* Validate optional job name                                        */
/*********************************************************************/

CheckJobName:
   PARSE ARG jtype, jname
   IF jname = '' THEN RETURN
   IF LENGTH(jname) > 8 THEN DO
      SAY 'DB2UTGEN ERROR:' jtype 'JOBNAME LONGER THAN 8:' jname
      EXIT 8
   END
RETURN

/*********************************************************************/
/* Validate member name                                              */
/*********************************************************************/

CheckMember:
   PARSE ARG mtype, mname
   IF LENGTH(mname) > 8 THEN DO
      SAY 'DB2UTGEN ERROR:' mtype 'MEMBER LONGER THAN 8:' mname
      EXIT 8
   END
RETURN

/*********************************************************************/
/* Validate whole-number parameter                                   */
/*********************************************************************/

CheckWhole:
   PARSE ARG wname, wvalue, wmin
   IF DATATYPE(wvalue,'W') = 0 THEN
      CALL ParmError wname !! ' MUST BE A WHOLE NUMBER'
   IF wvalue < wmin THEN
      CALL ParmError wname !! ' IS BELOW MINIMUM'
RETURN

/*********************************************************************/
/* Parameter error helper                                            */
/*********************************************************************/

ParmError:
   PARSE ARG pmsg
   SAY 'DB2UTGEN PARAMETER ERROR:' pmsg
   EXIT 8
RETURN

/*********************************************************************/
/* Show effective settings                                           */
/*********************************************************************/

ShowParameters:

   SAY ' '
   SAY 'DB2UTGEN EFFECTIVE PARAMETERS'
   SAY '============================='
   SAY 'LIBRARY        =' outlib
   SAY 'MEMBER PREFIX  =' basemem
   SAY 'SSID           =' ssid
   SAY 'MAXOBJECTS     =' maxobj
   SAY 'JOBCLASS       =' jobclass
   SAY 'MSGCLASS       =' msgclass
   SAY 'ITEMERROR      =' itemerror
   SAY 'GENERATEEMPTY  =' genempty
   CALL ShowUParm 'REORG',jobr,memr,reorgmax
   CALL ShowUParm 'ICOPY',jobi,memi,icopymax
   CALL ShowUParm 'FULLCOPY',jobf,memf,fullmax
   CALL ShowUParm 'RUNSTATS',jobs,mems,runmax
   SAY 'REORG AUTO/IX  =' reorgauto '/' reorgindex
   SAY 'REORG PREVIEW  =' reorgpreview
   SAY 'ICOPY PREVIEW  =' icopypreview
   SAY 'FULL IX/PREVIEW=' fullindex '/' fullpreview
   SAY 'RUN IX/PROFILE =' runindex '/' runprofile
   SAY 'RUN PREVIEW    =' runpreview
   SAY ' '

RETURN

ShowUParm:
   PARSE ARG uname, ujob, umem, umax
   IF ujob = '' THEN DO
      SAY LEFT(uname,12) '= DISABLED'
      RETURN
   END
   SAY LEFT(uname,12) '= JOB' ujob 'MEMBER' umem 'MAX' umax
RETURN

/*********************************************************************/
/* Show generated or disabled utility                                */
/*********************************************************************/

ShowResult:
   PARSE ARG stype, smem, sjob, sobjs
   IF sjob = '' THEN DO
      SAY LEFT(stype,16) ': DISABLED'
      RETURN
   END
   SAY LEFT(stype,16) ': MEMBER='smem 'JOB='sjob 'OBJECTS='sobjs
RETURN


