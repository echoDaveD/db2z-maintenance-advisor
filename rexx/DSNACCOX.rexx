/* REXX */
/*********************************************************************/
/* DSNACCOX DRIVER - Db2 for z/OS 13                                 */
/*                                                                   */
/* Public reference implementation                                        */
/*                                                                   */
/*                                                                   */
/* DDs:                                                              */
/*   ACCOXPAR  - DSNACCOX thresholds and local policy                */
/*   ACCOXOUT  - result / maintenance advisor output                 */
/*                                                                   */
/* Parameters that are NOT specified in ACCOXPAR are passed as NULL to       */
/* DSNACCOX. DSNACCOX therefore uses the IBM default.    */
/*                                                                   */
/* Example ACCOXPAR:                                                */
/*                                                                   */
/*   CRUPDATEDPAGESPCT   30                                          */
/*   CRDAYSNCLASTCOPY    14                                          */
/*   RRTDELETESPCT       30                                          */
/*   RRTUNCLUSTINSPCT    15                                          */
/*   RRTINDREFLIMIT       5                                          */
/*   SRTINSDELUPDPCT     25                                          */
/*   EXTENTLIMIT         200                                         */
/*                                                                   */
/* For many DSNACCOX criteria, a negative value disables the      */
/* corresponding criterion.                                      */
/*********************************************************************/

ARG SSID

IF SSID = '' THEN
   SSID = 'DB2A'


/*********************************************************************/
/* DSNREXX INITIALIZATION                                            */
/*********************************************************************/

ADDRESS TSO "SUBCOM DSNREXX"

IF RC <> 0 THEN
   RC = RXSUBCOM('ADD','DSNREXX','DSNREXX')


/*********************************************************************/
/* DSNACCOX BASE PARAMETERS                                           */
/*********************************************************************/

qtype  = 'ALL'
otype  = 'ALL'
ictype = 'B'
cats   = 'SYSIBM'
locals = 'DSNACC'
chklvl = 40
crit   = ''

/* Db2 13 SPECIALPARM consists of 4-byte sections.                  */
/* Section 1 = RRIEmptyLimit, section 2 = RRTHashOvrFlwRatio.       */
/* Blank section means: use the IBM default.                         */
rriemptylimit_sp = ''
rriemptylimit_sp_set = 0
rrthashratio_sp = ''
rrthashratio_sp_set = 0
spec = COPIES(' ',160)

/* Local automatic REORG policy. These are NOT DSNACCOX inputs.     */
min_reorg_size_mb = -1
max_reorg_size_gb = -1
min_days_reorg = -1
process_areo = 'YES'
process_reorp = 'YES'
reorp_override = 'YES'
require_size_known = 'YES'
output_only_auto = 'NO'
excludedb.= ''
excludedb.0 = 0
excludeobj. = ''
excludeobj.0 = 0
size_cursor_declared = 0
profile_cursor_declared = 0


/*********************************************************************/
/* DSNACCOX THRESHOLDS                                             */
/*                                                                   */
/* All indicators are initially -1 = SQL NULL.                           */
/* This causes DSNACCOX to use its own IBM default.                */
/*********************************************************************/

/*-------------------------------------------------------------------*/
/* COPY                                                              */
/*-------------------------------------------------------------------*/

crupdatedpagespct  = 0
crupdatedpagespct_i = -1

crupdatedpagesabs  = 0
crupdatedpagesabs_i = -1

crchangespct       = 0
crchangespct_i     = -1

crdaysnclastcopy   = 0
crdaysnclastcopy_i = -1

icrupdatedpagespct   = 0
icrupdatedpagespct_i = -1

icrupdatedpagesabs   = 0
icrupdatedpagesabs_i = -1

icrchangespct       = 0
icrchangespct_i     = -1

crindexsize         = 0
crindexsize_i       = -1


/*-------------------------------------------------------------------*/
/* REORG TABLESPACE                                                  */
/*-------------------------------------------------------------------*/

rrtinsertspct       = 0
rrtinsertspct_i     = -1

rrtinsertsabs       = 0
rrtinsertsabs_i     = -1

rrtdeletespct       = 0
rrtdeletespct_i     = -1

rrtdeletesabs       = 0
rrtdeletesabs_i     = -1

rrtunclustinspct    = 0
rrtunclustinspct_i  = -1

rrtdisorglobpct     = 0
rrtdisorglobpct_i   = -1

rrtdataspacerat     = 0
rrtdataspacerat_i   = -1

rrtmassdellimit     = 0
rrtmassdellimit_i   = -1

rrtindreflimit      = 0
rrtindreflimit_i    = -1


/*-------------------------------------------------------------------*/
/* REORG INDEX                                                       */
/*-------------------------------------------------------------------*/

rriinsertspct       = 0
rriinsertspct_i     = -1

rriinsertsabs       = 0
rriinsertsabs_i     = -1

rrideletespct       = 0
rrideletespct_i     = -1

rrideletesabs       = 0
rrideletesabs_i     = -1

rriappendinsertpct   = 0
rriappendinsertpct_i = -1

rripseudodeletepct   = 0
rripseudodeletepct_i = -1

rrimassdellimit      = 0
rrimassdellimit_i    = -1

rrileaflimit         = 0
rrileaflimit_i       = -1

rrinumlevelslimit    = 0
rrinumlevelslimit_i  = -1


/*-------------------------------------------------------------------*/
/* RUNSTATS TABLESPACE                                               */
/*-------------------------------------------------------------------*/

srtinsdelupdpct      = 0
srtinsdelupdpct_i    = -1

srtinsdelupdabs      = 0
srtinsdelupdabs_i    = -1

srtmassdellimit      = 0
srtmassdellimit_i    = -1


/*-------------------------------------------------------------------*/
/* RUNSTATS INDEX                                                    */
/*-------------------------------------------------------------------*/

sriinsdelpct         = 0
sriinsdelpct_i       = -1

sriinsdelabs         = 0
sriinsdelabs_i       = -1

srimassdellimit      = 0
srimassdellimit_i    = -1


/*-------------------------------------------------------------------*/
/* EXTENTS                                                           */
/*-------------------------------------------------------------------*/

extentlimit          = 0
extentlimit_i        = -1


/*********************************************************************/
/* READ PARAMETERS FROM ACCOXPAR                                      */
/*********************************************************************/

CALL ReadParameters
CALL BuildSpecialParm


/*********************************************************************/
/* DISPLAY EFFECTIVE PARAMETERS                                     */
/*********************************************************************/

CALL ShowParameters


/*********************************************************************/
/* DB2 CONNECT                                                       */
/*********************************************************************/

ADDRESS DSNREXX "CONNECT" SSID

IF SQLCODE <> 0 THEN DO
   SAY 'CONNECT FAILED SQLCODE=' SQLCODE
   EXIT 8
END


/*********************************************************************/
/* DSNACCOX OUTPUT PARAMETERS                                         */
/*********************************************************************/

laststatement = COPIES(' ',8012)
returncode    = COPIES(' ',11)
errormsg      = COPIES(' ',1331)
ifcarc        = COPIES(' ',11)
ifcarsn       = COPIES(' ',11)
xsbytes       = COPIES(' ',11)

laststatement_i = 0
returncode_i    = 0
errormsg_i      = 0
ifcarc_i        = 0
ifcarsn_i       = 0
xsbytes_i       = 0


/*********************************************************************/
/* DSNACCOX CALL                                                     */
/*********************************************************************/

callsql = "EXECSQL CALL SYSPROC.DSNACCOX("

callsql = callsql ":qtype,"
callsql = callsql ":otype,"
callsql = callsql ":ictype,"
callsql = callsql ":cats,"
callsql = callsql ":locals,"
callsql = callsql ":chklvl,"
callsql = callsql ":crit,"
callsql = callsql ":spec,"

/*-------------------------------------------------------------------*/
/* COPY                                                              */
/*-------------------------------------------------------------------*/

callsql = callsql ":crupdatedpagespct :crupdatedpagespct_i,"
callsql = callsql ":crupdatedpagesabs :crupdatedpagesabs_i,"
callsql = callsql ":crchangespct :crchangespct_i,"
callsql = callsql ":crdaysnclastcopy :crdaysnclastcopy_i,"

callsql = callsql ":icrupdatedpagespct :icrupdatedpagespct_i,"
callsql = callsql ":icrupdatedpagesabs :icrupdatedpagesabs_i,"
callsql = callsql ":icrchangespct :icrchangespct_i,"
callsql = callsql ":crindexsize :crindexsize_i,"

/*-------------------------------------------------------------------*/
/* REORG TABLESPACE                                                  */
/*-------------------------------------------------------------------*/

callsql = callsql ":rrtinsertspct :rrtinsertspct_i,"
callsql = callsql ":rrtinsertsabs :rrtinsertsabs_i,"
callsql = callsql ":rrtdeletespct :rrtdeletespct_i,"
callsql = callsql ":rrtdeletesabs :rrtdeletesabs_i,"
callsql = callsql ":rrtunclustinspct :rrtunclustinspct_i,"
callsql = callsql ":rrtdisorglobpct :rrtdisorglobpct_i,"
callsql = callsql ":rrtdataspacerat :rrtdataspacerat_i,"
callsql = callsql ":rrtmassdellimit :rrtmassdellimit_i,"
callsql = callsql ":rrtindreflimit :rrtindreflimit_i,"

/*-------------------------------------------------------------------*/
/* REORG INDEX                                                       */
/*-------------------------------------------------------------------*/

callsql = callsql ":rriinsertspct :rriinsertspct_i,"
callsql = callsql ":rriinsertsabs :rriinsertsabs_i,"
callsql = callsql ":rrideletespct :rrideletespct_i,"
callsql = callsql ":rrideletesabs :rrideletesabs_i,"
callsql = callsql ":rriappendinsertpct :rriappendinsertpct_i,"
callsql = callsql ":rripseudodeletepct :rripseudodeletepct_i,"
callsql = callsql ":rrimassdellimit :rrimassdellimit_i,"
callsql = callsql ":rrileaflimit :rrileaflimit_i,"
callsql = callsql ":rrinumlevelslimit :rrinumlevelslimit_i,"

/*-------------------------------------------------------------------*/
/* RUNSTATS TABLESPACE                                               */
/*-------------------------------------------------------------------*/

callsql = callsql ":srtinsdelupdpct :srtinsdelupdpct_i,"
callsql = callsql ":srtinsdelupdabs :srtinsdelupdabs_i,"
callsql = callsql ":srtmassdellimit :srtmassdellimit_i,"

/*-------------------------------------------------------------------*/
/* RUNSTATS INDEX                                                    */
/*-------------------------------------------------------------------*/

callsql = callsql ":sriinsdelpct :sriinsdelpct_i,"
callsql = callsql ":sriinsdelabs :sriinsdelabs_i,"
callsql = callsql ":srimassdellimit :srimassdellimit_i,"

/*-------------------------------------------------------------------*/
/* EXTENTS                                                           */
/*-------------------------------------------------------------------*/

callsql = callsql ":extentlimit :extentlimit_i,"

/*-------------------------------------------------------------------*/
/* OUTPUT PARAMETERS                                                 */
/*-------------------------------------------------------------------*/

callsql = callsql ":laststatement :laststatement_i,"
callsql = callsql ":returncode :returncode_i,"
callsql = callsql ":errormsg :errormsg_i,"
callsql = callsql ":ifcarc :ifcarc_i,"
callsql = callsql ":ifcarsn :ifcarsn_i,"
callsql = callsql ":xsbytes :xsbytes_i)"

SAY 'DSNACCOX CALL:'
SAY callsql

ADDRESS DSNREXX callsql

IF SQLCODE < 0 THEN
   SIGNAL SQLERR


SAY ' '
SAY 'DSNACCOX RETURN CODE :' STRIP(returncode)
SAY 'DSNACCOX MESSAGE     :' STRIP(errormsg)

IF STRIP(laststatement) <> '' THEN
   SAY 'LAST STATEMENT       :' STRIP(laststatement)


/*********************************************************************/
/* RESULT SET LOCATORS                                               */
/*********************************************************************/

ADDRESS DSNREXX ,
 "EXECSQL ASSOCIATE LOCATORS (:loc1, :loc2)",
 "WITH PROCEDURE SYSPROC.DSNACCOX"

IF SQLCODE < 0 THEN
   SIGNAL SQLERR


/*********************************************************************/
/* RESULT SET 1                                                      */
/*********************************************************************/

ADDRESS DSNREXX ,
 "EXECSQL ALLOCATE C101 CURSOR FOR RESULT SET :loc1"

IF SQLCODE < 0 THEN
   SIGNAL SQLERR


rs_sequence = 0
rs_data     = COPIES(' ',80)
rs1.0       = 0


DO FOREVER

   ADDRESS DSNREXX ,
      "EXECSQL FETCH C101 INTO :rs_sequence, :rs_data"
   IF SQLCODE = 100 THEN
      LEAVE

   IF SQLCODE < 0 THEN
      SIGNAL SQLERR

   rs1.0 = rs1.0 + 1
   rx = rs1.0
   rs1.rx = RIGHT(rs_sequence,5) !! ' ' !! STRIP(rs_data,'T')
   say 'RS1:' rs1.rx

   SAY RIGHT(rs_sequence,5) STRIP(rs_data,'T')

END


ADDRESS DSNREXX "EXECSQL CLOSE C101"


/*********************************************************************/
/* RESULT SET 2                                                      */
/*********************************************************************/

ADDRESS DSNREXX ,
 "EXECSQL ALLOCATE C102 CURSOR FOR RESULT SET :loc2"

IF SQLCODE < 0 THEN
   SIGNAL SQLERR


/*********************************************************************/
/* RESULT SET CHAR / VARCHAR / TIMESTAMP                              */
/*********************************************************************/

db              = COPIES(' ',24)
name            = COPIES(' ',128)
clone           = COPIES(' ',1)
objecttype      = COPIES(' ',2)
indexspace      = COPIES(' ',24)
creator         = COPIES(' ',128)
objectstatus    = COPIES(' ',40)

imagecopy       = COPIES(' ',4)
runstats        = COPIES(' ',3)
extents         = COPIES(' ',3)
reorg           = COPIES(' ',3)

inexcepttable   = COPIES(' ',40)
associatedts    = COPIES(' ',128)

copylasttime    = COPIES(' ',26)
loadrlasttime   = COPIES(' ',26)
rebuildlasttime = COPIES(' ',26)
reorglasttime   = COPIES(' ',26)
statslasttime   = COPIES(' ',26)


/*********************************************************************/
/* RESULT SET NUMERIC                                                */
/*********************************************************************/

partition       = 0
instance        = 0

crupdpgspct     = 0
crupdpgsabs     = 0
crcpychgpct     = 0
crdayscelstcpy  = 0
crindexsize_rs  = 0

rrtinsertspct_rs    = 0
rrtinsertsabs_rs    = 0
rrtdeletespct_rs    = 0
rrtdeletesabs_rs    = 0
rrtuncinspct_rs     = 0
rrtdisorglobpct_rs  = 0
rrtdatsprat_rs      = 0
rrtmassdelete_rs    = 0
rrtindref_rs        = 0

rriinsertspct_rs    = 0
rriinsertsabs_rs    = 0
rrideletespct_rs    = 0
rrideletabs_rs      = 0
rriappinspct_rs     = 0
rripsddelpct_rs     = 0
rrimassdelete_rs    = 0
rrileaf_rs          = 0
rrinumlevels_rs     = 0

srtinsdelupdpct_rs  = 0
srtinsdelupdabs_rs  = 0
srtmassdelete_rs    = 0

sriinsdelpct_rs     = 0
sriinsdelabs_rs     = 0
srimassdelete_rs    = 0

totalextents        = 0
rriemptylimit_rs    = 0
rrthashovrflwrat_rs = 0
rrtpbgspacepct_rs   = 0


/*********************************************************************/
/* NULL INDICATORS RESULT SET                                        */
/*********************************************************************/

clone_i            = 0
indexspace_i       = 0
creator_i          = 0
objectstatus_i     = 0

imagecopy_i        = 0
runstats_i         = 0
extents_i          = 0
reorg_i            = 0

inexcepttable_i    = 0
associatedts_i     = 0

copylasttime_i     = 0
loadrlasttime_i    = 0
rebuildlasttime_i  = 0
reorglasttime_i    = 0
statslasttime_i    = 0

crupdpgspct_i      = 0
crupdpgsabs_i      = 0
crcpychgpct_i      = 0
crdayscelstcpy_i   = 0
crindexsize_rs_i   = 0

rrtinsertspct_rs_i   = 0
rrtinsertsabs_rs_i   = 0
rrtdeletespct_rs_i   = 0
rrtdeletesabs_rs_i   = 0
rrtuncinspct_rs_i    = 0
rrtdisorglobpct_rs_i = 0
rrtdatsprat_rs_i     = 0
rrtmassdelete_rs_i   = 0
rrtindref_rs_i       = 0

rriinsertspct_rs_i   = 0
rriinsertsabs_rs_i   = 0
rrideletespct_rs_i   = 0
rrideletabs_rs_i     = 0
rriappinspct_rs_i    = 0
rripsddelpct_rs_i    = 0
rrimassdelete_rs_i   = 0
rrileaf_rs_i         = 0
rrinumlevels_rs_i    = 0

srtinsdelupdpct_rs_i = 0
srtinsdelupdabs_rs_i = 0
srtmassdelete_rs_i   = 0

sriinsdelpct_rs_i    = 0
sriinsdelabs_rs_i    = 0
srimassdelete_rs_i   = 0

totalextents_i        = 0
rriemptylimit_rs_i    = 0
rrthashovrflwrat_rs_i = 0
rrtpbgspacepct_rs_i   = 0


/*********************************************************************/
/* OPEN OUTPUT                                                    */
/*********************************************************************/

ADDRESS TSO "EXECIO 0 DISKW ACCOXOUT (OPEN"


/*********************************************************************/
/* HEADER                                                            */
/*********************************************************************/

outrec = LEFT('DBNAME',24) ,
         LEFT('NAME',32) ,
         RIGHT('PART',5) ,
         LEFT('OT',2) ,
         LEFT('ASSOCIATEDTS',32) ,
         LEFT('INDEXSPACE',24) ,
         LEFT('PROFILE_TABLE',64) ,
         LEFT('COPY',4) ,
         LEFT('RUN',3) ,
         LEFT('REO',3) ,
         LEFT('EXT',3) ,
         LEFT('AUTO',4) ,
         RIGHT('PRIO',4) ,
         RIGHT('SIZE_MB',10) ,
         LEFT('STATUS',18) ,
         LEFT('POLICY',100) ,
         LEFT('RECOMMENDATION REASON',220) ,
         LEFT('COPYLASTTIME',26) ,
         LEFT('REORGLASTTIME',26) ,
         LEFT('STATSLASTTIME',26)

QUEUE outrec
ADDRESS TSO "EXECIO 1 DISKW ACCOXOUT"


outrec = COPIES('-',24) ,
         COPIES('-',32) ,
         COPIES('-',5) ,
         COPIES('-',2) ,
         COPIES('-',32) ,
         COPIES('-',24) ,
         COPIES('-',64) ,
         COPIES('-',4) ,
         COPIES('-',3) ,
         COPIES('-',3) ,
         COPIES('-',3) ,
         COPIES('-',4) ,
         COPIES('-',4) ,
         COPIES('-',10) ,
         COPIES('-',18) ,
         COPIES('-',100) ,
         COPIES('-',220) ,
         COPIES('-',26) ,
         COPIES('-',26) ,
         COPIES('-',26)

QUEUE outrec
ADDRESS TSO "EXECIO 1 DISKW ACCOXOUT"


/*********************************************************************/
/* FETCH RESULT SET 2                                                */
/*********************************************************************/

DO FOREVER


   fetchsql = "EXECSQL FETCH C102 INTO"

   fetchsql = fetchsql " :db,"
   fetchsql = fetchsql " :name,"
   fetchsql = fetchsql " :partition,"
   fetchsql = fetchsql " :instance,"

   fetchsql = fetchsql " :clone :clone_i,"
   fetchsql = fetchsql " :objecttype,"

   fetchsql = fetchsql " :indexspace :indexspace_i,"
   fetchsql = fetchsql " :creator :creator_i,"
   fetchsql = fetchsql " :objectstatus :objectstatus_i,"

   fetchsql = fetchsql " :imagecopy :imagecopy_i,"
   fetchsql = fetchsql " :runstats :runstats_i,"
   fetchsql = fetchsql " :extents :extents_i,"
   fetchsql = fetchsql " :reorg :reorg_i,"

   fetchsql = fetchsql " :inexcepttable :inexcepttable_i,"
   fetchsql = fetchsql " :associatedts :associatedts_i,"

   fetchsql = fetchsql " :copylasttime :copylasttime_i,"
   fetchsql = fetchsql " :loadrlasttime :loadrlasttime_i,"
   fetchsql = fetchsql " :rebuildlasttime :rebuildlasttime_i,"

   fetchsql = fetchsql " :crupdpgspct :crupdpgspct_i,"
   fetchsql = fetchsql " :crupdpgsabs :crupdpgsabs_i,"
   fetchsql = fetchsql " :crcpychgpct :crcpychgpct_i,"
   fetchsql = fetchsql " :crdayscelstcpy :crdayscelstcpy_i,"
   fetchsql = fetchsql " :crindexsize_rs :crindexsize_rs_i,"

   fetchsql = fetchsql " :reorglasttime :reorglasttime_i,"

   fetchsql = fetchsql,
      " :rrtinsertspct_rs :rrtinsertspct_rs_i,"

   fetchsql = fetchsql,
      " :rrtinsertsabs_rs :rrtinsertsabs_rs_i,"

   fetchsql = fetchsql,
      " :rrtdeletespct_rs :rrtdeletespct_rs_i,"

   fetchsql = fetchsql,
      " :rrtdeletesabs_rs :rrtdeletesabs_rs_i,"

   fetchsql = fetchsql,
      " :rrtuncinspct_rs :rrtuncinspct_rs_i,"

   fetchsql = fetchsql,
      " :rrtdisorglobpct_rs :rrtdisorglobpct_rs_i,"

   fetchsql = fetchsql,
      " :rrtdatsprat_rs :rrtdatsprat_rs_i,"

   fetchsql = fetchsql,
      " :rrtmassdelete_rs :rrtmassdelete_rs_i,"

   fetchsql = fetchsql,
      " :rrtindref_rs :rrtindref_rs_i,"

   fetchsql = fetchsql,
      " :rriinsertspct_rs :rriinsertspct_rs_i,"

   fetchsql = fetchsql,
      " :rriinsertsabs_rs :rriinsertsabs_rs_i,"

   fetchsql = fetchsql,
      " :rrideletespct_rs :rrideletespct_rs_i,"

   fetchsql = fetchsql,
      " :rrideletabs_rs :rrideletabs_rs_i,"

   fetchsql = fetchsql,
      " :rriappinspct_rs :rriappinspct_rs_i,"

   fetchsql = fetchsql,
      " :rripsddelpct_rs :rripsddelpct_rs_i,"

   fetchsql = fetchsql,
      " :rrimassdelete_rs :rrimassdelete_rs_i,"

   fetchsql = fetchsql,
      " :rrileaf_rs :rrileaf_rs_i,"

   fetchsql = fetchsql,
      " :rrinumlevels_rs :rrinumlevels_rs_i,"

   fetchsql = fetchsql " :statslasttime :statslasttime_i,"

   fetchsql = fetchsql,
      " :srtinsdelupdpct_rs :srtinsdelupdpct_rs_i,"

   fetchsql = fetchsql,
      " :srtinsdelupdabs_rs :srtinsdelupdabs_rs_i,"

   fetchsql = fetchsql,
      " :srtmassdelete_rs :srtmassdelete_rs_i,"

   fetchsql = fetchsql,
      " :sriinsdelpct_rs :sriinsdelpct_rs_i,"

   fetchsql = fetchsql,
      " :sriinsdelabs_rs :sriinsdelabs_rs_i,"

   fetchsql = fetchsql,
      " :srimassdelete_rs :srimassdelete_rs_i,"

   fetchsql = fetchsql,
      " :totalextents :totalextents_i,"

   fetchsql = fetchsql,
      " :rriemptylimit_rs :rriemptylimit_rs_i,"

   fetchsql = fetchsql,
      " :rrthashovrflwrat_rs :rrthashovrflwrat_rs_i,"

   fetchsql = fetchsql,
      " :rrtpbgspacepct_rs :rrtpbgspacepct_rs_i"


   ADDRESS DSNREXX fetchsql


   IF SQLCODE = 100 THEN
      LEAVE

   IF SQLCODE <> 0 THEN
      SIGNAL SQLERR


   /******************************************************************/
   /* NULL CHAR VALUES                                                */
   /******************************************************************/

   IF imagecopy_i < 0 THEN
      imagecopy = ''

   IF runstats_i < 0 THEN
      runstats = ''

   IF reorg_i < 0 THEN
      reorg = ''

   IF extents_i < 0 THEN
      extents = ''

   IF objectstatus_i < 0 THEN
      objectstatus = ''

   IF copylasttime_i < 0 THEN
      copylasttime = ''

   IF reorglasttime_i < 0 THEN
      reorglasttime = ''

   IF statslasttime_i < 0 THEN
      statslasttime = ''

   IF associatedts_i < 0 THEN
      associatedts = ''


   /******************************************************************/
   /* RECOMMENDATION REASONS                                         */
   /*                                                                */
   /* IMPORTANT:                                                       */
   /* A result-set indicator < 0 means SQL NULL.                     */
   /* DSNACCOX returns numeric criteria as non-NULL only when the       */
   /* corresponding threshold has been exceeded.                */
   /******************************************************************/

   reason   = ''
   copywhy  = 0
   reorgwhy = 0
   runwhy   = 0
   extwhy   = 0
   profile_table = ''

   objtyp   = TRANSLATE(STRIP(objecttype))
   copyrec  = TRANSLATE(STRIP(imagecopy))
   runrec   = TRANSLATE(STRIP(runstats))
   reorgrec = TRANSLATE(STRIP(reorg))
   extrec   = TRANSLATE(STRIP(extents))

   /******************************************************************/
   /* COPY                                                           */
   /******************************************************************/

   IF copyrec <> '' & copyrec <> 'NO' THEN DO

      IF copyrec = 'INC' THEN DO
         cppctn = 'ICRUPDATEDPAGESPCT'
         cppcti = icrupdatedpagespct_i
         cppctv = icrupdatedpagespct
         cpabsn = 'ICRUPDATEDPAGESABS'
         cpabsi = icrupdatedpagesabs_i
         cpabsv = icrupdatedpagesabs
         cpchgn = 'ICRCHANGESPCT'
         cpchgi = icrchangespct_i
         cpchgv = icrchangespct
      END
      ELSE DO
         cppctn = 'CRUPDATEDPAGESPCT'
         cppcti = crupdatedpagespct_i
         cppctv = crupdatedpagespct
         cpabsn = 'CRUPDATEDPAGESABS'
         cpabsi = crupdatedpagesabs_i
         cpabsv = crupdatedpagesabs
         cpchgn = 'CRCHANGESPCT'
         cpchgi = crchangespct_i
         cpchgv = crchangespct
      END

      IF crupdpgspct_i >= 0 & crupdpgsabs_i >= 0 THEN DO
         lpct = GetLimit(cppctn,cppcti,cppctv)
         labs = GetLimit(cpabsn,cpabsi,cpabsv)
         rtxt = 'COPY UPDATED_PAGES PCT=' !! STRIP(crupdpgspct)
         rtxt = rtxt !! ' LIMIT=' !! lpct
         rtxt = rtxt !! ' ABS=' !! STRIP(crupdpgsabs)
         rtxt = rtxt !! ' LIMIT=' !! labs
         IF objtyp = 'IX' & crindexsize_rs_i >= 0 THEN DO
            lix = GetLimit('CRINDEXSIZE',crindexsize_i,crindexsize)
            rtxt = rtxt !! ' INDEXPAGES=' !! STRIP(crindexsize_rs)
            rtxt = rtxt !! ' MIN=' !! lix
         END
         CALL AddReason rtxt
         copywhy = 1
      END

      IF crcpychgpct_i >= 0 THEN DO
         lchg = GetLimit(cpchgn,cpchgi,cpchgv)
         rtxt = 'COPY CHANGE_PCT=' !! STRIP(crcpychgpct)
         rtxt = rtxt !! ' LIMIT=' !! lchg
         IF objtyp = 'IX' & crindexsize_rs_i >= 0 THEN DO
            lix = GetLimit('CRINDEXSIZE',crindexsize_i,crindexsize)
            rtxt = rtxt !! ' INDEXPAGES=' !! STRIP(crindexsize_rs)
            rtxt = rtxt !! ' MIN=' !! lix
         END
         CALL AddReason rtxt
         copywhy = 1
      END

      IF crdayscelstcpy_i >= 0 THEN DO
         lday = GetLimit('CRDAYSNCLASTCOPY',
                         crdaysnclastcopy_i,crdaysnclastcopy)
         rtxt = 'COPY DAYS_SINCE_LAST=' !! STRIP(crdayscelstcpy)
         rtxt = rtxt !! ' LIMIT=' !! lday
         CALL AddReason rtxt
         copywhy = 1
      END

      IF copywhy = 0 THEN DO
         IF copylasttime_i < 0 THEN DO
            CALL AddReason 'COPY LAST_COPY_UNKNOWN_OR_NEVER'
            copywhy = 1
         END
         ELSE DO
            cpts = STRIP(copylasttime)
            IF loadrlasttime_i >= 0 THEN DO
               IF STRIP(loadrlasttime) > cpts THEN DO
                  CALL AddReason 'COPY LOAD_REPLACE_AFTER_LAST_COPY'
                  copywhy = 1
               END
            END
            IF reorglasttime_i >= 0 THEN DO
               IF STRIP(reorglasttime) > cpts THEN DO
                  CALL AddReason 'COPY REORG_AFTER_LAST_COPY'
                  copywhy = 1
               END
            END
            IF objtyp = 'IX' & rebuildlasttime_i >= 0 THEN DO
               IF STRIP(rebuildlasttime) > cpts THEN DO
                  CALL AddReason 'COPY REBUILD_AFTER_LAST_COPY'
                  copywhy = 1
               END
            END
         END
      END

      IF copywhy = 0 THEN DO
         CALL AddReason 'COPY UNKNOWN_TRIGGER SEE_JOBLOG_DUMP'
         CALL DumpUtilityFields 'COPY'
         copywhy = 1
      END
   END

   /******************************************************************/
   /* EXTENTS                                                        */
   /******************************************************************/

   IF extrec = 'YES' THEN DO
      IF totalextents_i >= 0 THEN DO
         lext = GetLimit('EXTENTLIMIT',extentlimit_i,extentlimit)
         rtxt = 'EXTENTS ACTUAL=' !! STRIP(totalextents)
         rtxt = rtxt !! ' LIMIT=' !! lext
         CALL AddReason rtxt
         extwhy = 1
      END
      ELSE DO
         CALL AddReason 'EXTENTS LIMIT_EXCEEDED'
         extwhy = 1
      END
   END

   /******************************************************************/
   /* REORG TABLESPACE / LOB / XML                                   */
   /******************************************************************/

   ists = 0
   IF objtyp = 'TS' THEN ists = 1
   IF objtyp = 'LS' THEN ists = 1
   IF objtyp = 'XS' THEN ists = 1

   IF reorgrec = 'YES' & ists THEN DO

      IF rrtinsertspct_rs_i >= 0 & rrtinsertsabs_rs_i >= 0 THEN DO
         lpct = GetLimit('RRTINSERTSPCT',
                         rrtinsertspct_i,rrtinsertspct)
         labs = GetLimit('RRTINSERTSABS',
                         rrtinsertsabs_i,rrtinsertsabs)
         rtxt = 'REORG INSERTS PCT=' !! STRIP(rrtinsertspct_rs)
         rtxt = rtxt !! ' LIMIT=' !! lpct
         rtxt = rtxt !! ' ABS=' !! STRIP(rrtinsertsabs_rs)
         rtxt = rtxt !! ' LIMIT=' !! labs
         CALL AddReason rtxt
         reorgwhy = 1
      END

      IF rrtdeletespct_rs_i >= 0 & rrtdeletesabs_rs_i >= 0 THEN DO
         lpct = GetLimit('RRTDELETESPCT',
                         rrtdeletespct_i,rrtdeletespct)
         labs = GetLimit('RRTDELETESABS',
                         rrtdeletesabs_i,rrtdeletesabs)
         rtxt = 'REORG DELETES PCT=' !! STRIP(rrtdeletespct_rs)
         rtxt = rtxt !! ' LIMIT=' !! lpct
         rtxt = rtxt !! ' ABS=' !! STRIP(rrtdeletesabs_rs)
         rtxt = rtxt !! ' LIMIT=' !! labs
         CALL AddReason rtxt
         reorgwhy = 1
      END

      IF rrtuncinspct_rs_i >= 0 THEN DO
         lim = GetLimit('RRTUNCLUSTINSPCT',
                        rrtunclustinspct_i,rrtunclustinspct)
         rtxt = 'REORG UNCLUST_INSERT_PCT=' !! STRIP(rrtuncinspct_rs)
         rtxt = rtxt !! ' LIMIT=' !! lim
         CALL AddReason rtxt
         reorgwhy = 1
      END

      IF rrtdisorglobpct_rs_i >= 0 THEN DO
         lim = GetLimit('RRTDISORGLOBPCT',
                        rrtdisorglobpct_i,rrtdisorglobpct)
         rtxt = 'REORG DISORG_LOB_PCT=' !! STRIP(rrtdisorglobpct_rs)
         rtxt = rtxt !! ' LIMIT=' !! lim
         CALL AddReason rtxt
         reorgwhy = 1
      END

      IF rrtdatsprat_rs_i >= 0 THEN DO
         lim = GetLimit('RRTDATASPACERAT',
                        rrtdataspacerat_i,rrtdataspacerat)
         rtxt = 'REORG DATA_SPACE_RATIO=' !! STRIP(rrtdatsprat_rs)
         rtxt = rtxt !! ' LIMIT=' !! lim
         CALL AddReason rtxt
         reorgwhy = 1
      END

      IF rrtmassdelete_rs_i >= 0 THEN DO
         lim = GetLimit('RRTMASSDELLIMIT',
                        rrtmassdellimit_i,rrtmassdellimit)
         rtxt = 'REORG MASS_DELETE=' !! STRIP(rrtmassdelete_rs)
         rtxt = rtxt !! ' LIMIT=' !! lim
         CALL AddReason rtxt
         reorgwhy = 1
      END

      IF rrtindref_rs_i >= 0 THEN DO
         lim = GetLimit('RRTINDREFLIMIT',
                        rrtindreflimit_i,rrtindreflimit)
         rtxt = 'REORG INDREF_PCT=' !! STRIP(rrtindref_rs)
         rtxt = rtxt !! ' LIMIT=' !! lim
         CALL AddReason rtxt
         reorgwhy = 1
      END

      IF rrthashovrflwrat_rs_i >= 0 THEN DO
         lim = GetSpecialLimit('HASH')
         rtxt = 'REORG HASH_OVERFLOW_RATIO='
         rtxt = rtxt !! STRIP(rrthashovrflwrat_rs)
         rtxt = rtxt !! ' LIMIT=' !! lim
         CALL AddReason rtxt
         reorgwhy = 1
      END

      /* RRTPBGSPACEPCT is reserved for future use in Db2 13. */

      IF extrec = 'YES' THEN
         reorgwhy = 1

      IF reorgwhy = 0 & reorglasttime_i < 0 THEN DO
         CALL AddReason 'REORG LAST_REORG_UNKNOWN_OR_NEVER'
         reorgwhy = 1
      END

      IF reorgwhy = 0 & STRIP(objectstatus) <> '' THEN DO
         rtxt = 'REORG OBJECT_STATUS=' !! STRIP(objectstatus)
         CALL AddReason rtxt
         reorgwhy = 1
      END

      IF reorgwhy = 0 THEN DO
         CALL AddReason 'REORG UNKNOWN_TRIGGER SEE_JOBLOG_DUMP'
         CALL DumpUtilityFields 'REORG-TS'
         reorgwhy = 1
      END
   END

   /******************************************************************/
   /* REORG INDEX                                                    */
   /******************************************************************/

   IF reorgrec = 'YES' & objtyp = 'IX' THEN DO

      IF rriinsertspct_rs_i >= 0 & rriinsertsabs_rs_i >= 0 THEN DO
         lpct = GetLimit('RRIINSERTSPCT',
                         rriinsertspct_i,rriinsertspct)
         labs = GetLimit('RRIINSERTSABS',
                         rriinsertsabs_i,rriinsertsabs)
         rtxt = 'REORG-IX INSERTS PCT=' !! STRIP(rriinsertspct_rs)
         rtxt = rtxt !! ' LIMIT=' !! lpct
         rtxt = rtxt !! ' ABS=' !! STRIP(rriinsertsabs_rs)
         rtxt = rtxt !! ' LIMIT=' !! labs
         CALL AddReason rtxt
         reorgwhy = 1
      END

      IF rrideletespct_rs_i >= 0 & rrideletabs_rs_i >= 0 THEN DO
         lpct = GetLimit('RRIDELETESPCT',
                         rrideletespct_i,rrideletespct)
         labs = GetLimit('RRIDELETESABS',
                         rrideletesabs_i,rrideletesabs)
         rtxt = 'REORG-IX DELETES PCT=' !! STRIP(rrideletespct_rs)
         rtxt = rtxt !! ' LIMIT=' !! lpct
         rtxt = rtxt !! ' ABS=' !! STRIP(rrideletabs_rs)
         rtxt = rtxt !! ' LIMIT=' !! labs
         CALL AddReason rtxt
         reorgwhy = 1
      END

      IF rriappinspct_rs_i >= 0 THEN DO
         lim = GetLimit('RRIAPPENDINSERTPCT',
                        rriappendinsertpct_i,rriappendinsertpct)
         rtxt = 'REORG-IX APPEND_INSERT_PCT='
         rtxt = rtxt !! STRIP(rriappinspct_rs)
         rtxt = rtxt !! ' LIMIT=' !! lim
         CALL AddReason rtxt
         reorgwhy = 1
      END

      IF rripsddelpct_rs_i >= 0 THEN DO
         lim = GetLimit('RRIPSEUDODELETEPCT',
                        rripseudodeletepct_i,rripseudodeletepct)
         rtxt = 'REORG-IX PSEUDO_DELETE_PCT='
         rtxt = rtxt !! STRIP(rripsddelpct_rs)
         rtxt = rtxt !! ' LIMIT=' !! lim
         CALL AddReason rtxt
         reorgwhy = 1
      END

      IF rrimassdelete_rs_i >= 0 THEN DO
         lim = GetLimit('RRIMASSDELLIMIT',
                        rrimassdellimit_i,rrimassdellimit)
         rtxt = 'REORG-IX MASS_DELETE=' !! STRIP(rrimassdelete_rs)
         rtxt = rtxt !! ' LIMIT=' !! lim
         CALL AddReason rtxt
         reorgwhy = 1
      END

      IF rrileaf_rs_i >= 0 THEN DO
         lim = GetLimit('RRILEAFLIMIT',rrileaflimit_i,rrileaflimit)
         rtxt = 'REORG-IX LEAF_SPLIT_PCT=' !! STRIP(rrileaf_rs)
         rtxt = rtxt !! ' LIMIT=' !! lim
         CALL AddReason rtxt
         reorgwhy = 1
      END

      IF rrinumlevels_rs_i >= 0 THEN DO
         lim = GetLimit('RRINUMLEVELSLIMIT',
                        rrinumlevelslimit_i,rrinumlevelslimit)
         rtxt = 'REORG-IX NUMLEVEL_CHANGE='
         rtxt = rtxt !! STRIP(rrinumlevels_rs)
         rtxt = rtxt !! ' LIMIT=' !! lim
         CALL AddReason rtxt
         reorgwhy = 1
      END

      IF rriemptylimit_rs_i >= 0 THEN DO
         lim = GetSpecialLimit('EMPTY')
         rtxt = 'REORG-IX EMPTY_LEAF_PCT='
         rtxt = rtxt !! STRIP(rriemptylimit_rs)
         rtxt = rtxt !! ' LIMIT=' !! lim
         CALL AddReason rtxt
         reorgwhy = 1
      END

      IF extrec = 'YES' THEN
         reorgwhy = 1

      IF reorgwhy = 0 THEN DO
         IF reorglasttime_i < 0 & rebuildlasttime_i < 0 THEN DO
            CALL AddReason 'REORG-IX REORG_AND_REBUILD_UNKNOWN'
            reorgwhy = 1
         END
      END

      IF reorgwhy = 0 & STRIP(objectstatus) <> '' THEN DO
         rtxt = 'REORG-IX OBJECT_STATUS=' !! STRIP(objectstatus)
         CALL AddReason rtxt
         reorgwhy = 1
      END

      IF reorgwhy = 0 THEN DO
         CALL AddReason 'REORG-IX UNKNOWN_TRIGGER SEE_JOBLOG_DUMP'
         CALL DumpUtilityFields 'REORG-IX'
         reorgwhy = 1
      END
   END

   /******************************************************************/
   /* RUNSTATS TABLESPACE / LOB / XML                                */
   /******************************************************************/

   IF LEFT(runrec,1) = 'Y' & ists THEN DO

      IF srtinsdelupdpct_rs_i >= 0 & ,
         srtinsdelupdabs_rs_i >= 0 THEN DO
         lpct = GetLimit('SRTINSDELUPDPCT',
                         srtinsdelupdpct_i,srtinsdelupdpct)
         labs = GetLimit('SRTINSDELUPDABS',
                         srtinsdelupdabs_i,srtinsdelupdabs)
         rtxt = 'RUNSTATS CHANGE PCT=' !! STRIP(srtinsdelupdpct_rs)
         rtxt = rtxt !! ' LIMIT=' !! lpct
         rtxt = rtxt !! ' ABS=' !! STRIP(srtinsdelupdabs_rs)
         rtxt = rtxt !! ' LIMIT=' !! labs
         CALL AddReason rtxt
         runwhy = 1
      END

      IF srtmassdelete_rs_i >= 0 THEN DO
         lim = GetLimit('SRTMASSDELLIMIT',
                        srtmassdellimit_i,srtmassdellimit)
         rtxt = 'RUNSTATS MASS_DELETE=' !! STRIP(srtmassdelete_rs)
         rtxt = rtxt !! ' LIMIT=' !! lim
         CALL AddReason rtxt
         runwhy = 1
      END

      IF runwhy = 0 & statslasttime_i < 0 THEN DO
         CALL AddReason 'RUNSTATS LAST_STATS_UNKNOWN_OR_NEVER'
         runwhy = 1
      END

      IF runwhy = 0 THEN DO
         stts = STRIP(statslasttime)
         IF loadrlasttime_i >= 0 THEN DO
            IF STRIP(loadrlasttime) > stts THEN DO
               CALL AddReason 'RUNSTATS LOAD_AFTER_LAST_STATS'
               runwhy = 1
            END
         END
         IF reorglasttime_i >= 0 THEN DO
            IF STRIP(reorglasttime) > stts THEN DO
               CALL AddReason 'RUNSTATS REORG_AFTER_LAST_STATS'
               runwhy = 1
            END
         END
      END

      /******************************************************************/
      /* RUNSTATS PROFILE                                               */
      /*                                                                */
      /* DSNACCOX can recommend RUNSTATS when a RUNSTATS profile was    */
      /* updated after the statistics for the table space were created. */
      /******************************************************************/

      IF runwhy = 0 THEN DO

         profinfo = GetLatestProfileUpdate()

         IF profinfo <> '' THEN DO
            PARSE VAR profinfo proftab profupd

            IF statslasttime_i < 0 THEN DO
               profile_table = proftab
               rtxt = 'RUNSTATS PROFILE_EXISTS_STATS_UNKNOWN'
               CALL AddReason rtxt
               runwhy = 1
            END
            ELSE DO
               IF profupd > STRIP(statslasttime) THEN DO
                  profile_table = proftab
                  rtxt = 'RUNSTATS PROFILE_UPDATE_AFTER_LAST_STATS'
                  rtxt = rtxt !! ' PROFILE=' !! profupd
                  rtxt = rtxt !! ' STATS=' !! STRIP(statslasttime)
                  CALL AddReason rtxt
                  runwhy = 1
               END
            END

         END

      END


      IF runwhy = 0 THEN DO
         CALL AddReason 'RUNSTATS UNKNOWN_TRIGGER SEE_JOBLOG_DUMP'
         CALL DumpUtilityFields 'RUNSTATS-TS'
         runwhy = 1
      END
   END

   /******************************************************************/
   /* RUNSTATS INDEX                                                 */
   /******************************************************************/

   IF LEFT(runrec,1) = 'Y' & objtyp = 'IX' THEN DO

      IF sriinsdelpct_rs_i >= 0 & sriinsdelabs_rs_i >= 0 THEN DO
         lpct = GetLimit('SRIINSDELPCT',sriinsdelpct_i,sriinsdelpct)
         labs = GetLimit('SRIINSDELABS',sriinsdelabs_i,sriinsdelabs)
         rtxt = 'RUNSTATS-IX CHANGE PCT=' !! STRIP(sriinsdelpct_rs)
         rtxt = rtxt !! ' LIMIT=' !! lpct
         rtxt = rtxt !! ' ABS=' !! STRIP(sriinsdelabs_rs)
         rtxt = rtxt !! ' LIMIT=' !! labs
         CALL AddReason rtxt
         runwhy = 1
      END

      IF srimassdelete_rs_i >= 0 THEN DO
         lim = GetLimit('SRIMASSDELLIMIT',
                        srimassdellimit_i,srimassdellimit)
         rtxt = 'RUNSTATS-IX MASS_DELETE='
         rtxt = rtxt !! STRIP(srimassdelete_rs)
         rtxt = rtxt !! ' LIMIT=' !! lim
         CALL AddReason rtxt
         runwhy = 1
      END

      IF runwhy = 0 & statslasttime_i < 0 THEN DO
         CALL AddReason 'RUNSTATS-IX LAST_STATS_UNKNOWN_OR_NEVER'
         runwhy = 1
      END

      IF runwhy = 0 THEN DO
         stts = STRIP(statslasttime)
         IF loadrlasttime_i >= 0 THEN DO
            IF STRIP(loadrlasttime) > stts THEN DO
               CALL AddReason 'RUNSTATS-IX LOAD_AFTER_LAST_STATS'
               runwhy = 1
            END
         END
         IF reorglasttime_i >= 0 THEN DO
            IF STRIP(reorglasttime) > stts THEN DO
               CALL AddReason 'RUNSTATS-IX REORG_AFTER_LAST_STATS'
               runwhy = 1
            END
         END
      END

      IF runwhy = 0 THEN DO
         CALL AddReason 'RUNSTATS-IX UNKNOWN_TRIGGER SEE_JOBLOG_DUMP'
         CALL DumpUtilityFields 'RUNSTATS-IX'
         runwhy = 1
      END
   END

   /******************************************************************/
   /* RESTRICTED / ADVISORY STATUS                                   */
   /******************************************************************/

   IF STRIP(objectstatus) <> '' THEN DO
      IF reorgrec <> 'YES' & copyrec = 'NO' & ,
         LEFT(runrec,1) <> 'Y' & extrec <> 'YES' THEN DO
         rtxt = 'OBJECT_STATUS=' !! STRIP(objectstatus)
         CALL AddReason rtxt
      END
   END

   /******************************************************************/
   /* LOCAL AUTOMATIC REORG POLICY                                   */
   /******************************************************************/

   auto_reorg = '-'
   priority = 0
   objsize_mb = -1
   policy_reason = ''

   object_excluded = IsObjectExcluded(db,name)
   IF object_excluded THEN DO
      auto_reorg = 'NO'
      CALL AddPolicy 'OBJECT_EXCLUDED'
   END
   ELSE DO
     IF reorgrec = 'YES' THEN DO
        auto_reorg = 'YES'
        st = TRANSLATE(STRIP(objectstatus))
        isreorp = (POS('REORP',st) > 0)
        isareo = 0
        IF POS('AREO',st) > 0 THEN isareo = 1
        IF POS('ARBDP',st) > 0 THEN isareo = 1
        IF POS('RBDPM',st) > 0 THEN isareo = 1

        IF isreorp THEN priority = 1
        ELSE IF isareo THEN priority = 2
        ELSE IF extrec = 'YES' THEN priority = 3
        ELSE priority = 4

        IF IsDbExcluded(STRIP(db)) THEN DO
           auto_reorg = 'NO'
           CALL AddPolicy 'DBNAME_EXCLUDED'
        END

        IF isreorp & process_reorp <> 'YES' THEN DO
           auto_reorg = 'NO'
           CALL AddPolicy 'REORP_DISABLED'
        END

        IF isareo & process_areo <> 'YES' THEN DO
           auto_reorg = 'NO'
           CALL AddPolicy 'ADVISORY_STATUS_DISABLED'
        END

        bypass = 0
        IF isreorp & process_reorp = 'YES' & ,
           reorp_override = 'YES' THEN bypass = 1

        IF bypass = 0 THEN DO
           IF min_days_reorg >= 0 THEN DO
              rd = DaysSinceReorg()
              IF rd >= 0 & rd < min_days_reorg THEN DO
                 auto_reorg = 'NO'
                 ptxt = 'LAST_REORG=' !! rd !! 'D<' !! min_days_reorg
                 CALL AddPolicy ptxt
              END
           END

           needsize = 0
           IF min_reorg_size_mb >= 0 THEN needsize = 1
           IF max_reorg_size_gb >= 0 THEN needsize = 1
           IF needsize & auto_reorg = 'YES' THEN DO
              objsize_mb = GetObjectSizeMB()
              IF objsize_mb < 0 THEN DO
                 CALL AddPolicy 'SIZE_UNKNOWN'
                 IF require_size_known = 'YES' THEN auto_reorg = 'NO'
              END
              ELSE DO
                 IF min_reorg_size_mb >= 0 THEN DO
                    IF objsize_mb < min_reorg_size_mb THEN DO
                       auto_reorg = 'NO'
                       ptxt = 'SIZE<' !! min_reorg_size_mb !! 'MB'
                       CALL AddPolicy ptxt
                    END
                 END
                 IF max_reorg_size_gb >= 0 THEN DO
                    maxmb = max_reorg_size_gb * 1024
                    IF objsize_mb > maxmb THEN DO
                       auto_reorg = 'NO'
                       ptxt = 'SIZE>' !! max_reorg_size_gb !! 'GB'
                       CALL AddPolicy ptxt
                    END
                 END
              END
           END
        END
        ELSE CALL AddPolicy 'REORP_OVERRIDES_SIZE_AND_AGE'

        IF auto_reorg = 'YES' & policy_reason = '' THEN
           CALL AddPolicy 'ELIGIBLE'
     END
   END

   /******************************************************************/
   /* OUTPUT                                                         */
   /******************************************************************/

   IF objsize_mb < 0 THEN sizetxt = ''
   ELSE sizetxt = FORMAT(objsize_mb,10,1)

   outrec = LEFT(STRIP(db),24) ,
            LEFT(STRIP(name),32) ,
            RIGHT(partition,5) ,
            LEFT(STRIP(objecttype),2) ,
            LEFT(STRIP(associatedts),32) ,
            LEFT(STRIP(indexspace),24) ,
            LEFT(STRIP(profile_table),64) ,
            LEFT(STRIP(imagecopy),4) ,
            LEFT(STRIP(runstats),3) ,
            LEFT(STRIP(reorg),3) ,
            LEFT(STRIP(extents),3) ,
            LEFT(auto_reorg,4) ,
            RIGHT(priority,4) ,
            RIGHT(sizetxt,10) ,
            LEFT(STRIP(objectstatus),18) ,
            LEFT(STRIP(policy_reason),100) ,
            LEFT(STRIP(reason),220) ,
            LEFT(STRIP(copylasttime),26) ,
            LEFT(STRIP(reorglasttime),26) ,
            LEFT(STRIP(statslasttime),26)


   writeit = 1
   IF output_only_auto = 'YES' & auto_reorg <> 'YES' THEN writeit = 0
   IF writeit THEN DO
      QUEUE outrec
      ADDRESS TSO "EXECIO 1 DISKW ACCOXOUT"
   END

END


/*********************************************************************/
/* CLEANUP                                                           */
/*********************************************************************/

ADDRESS TSO "EXECIO 0 DISKW ACCOXOUT (FINIS"

ADDRESS DSNREXX "EXECSQL CLOSE C102"

ADDRESS DSNREXX "DISCONNECT"

EXIT 0


/*********************************************************************/
/* READ ACCOXPAR                                                     */
/*********************************************************************/

ReadParameters:

   parm. = ''

   ADDRESS TSO "EXECIO * DISKR ACCOXPAR (STEM PARM. FINIS"

   xrc = RC

   IF xrc <> 0 THEN DO
      SAY ' '
      SAY 'ACCOXPAR COULD NOT BE READ.'
      SAY 'DSNACCOX IBM DEFAULTS WILL BE USED.'
      SAY ' '
      RETURN
   END


   SAY ' '
   SAY 'READING ACCOXPAR'
   SAY '----------------'


   DO px = 1 TO parm.0

      line = STRIP(parm.px)

      IF line = '' THEN
         ITERATE

      IF LEFT(line,1) = '*' THEN
         ITERATE

      IF LEFT(line,2) = '/*' THEN
         ITERATE

      PARSE VAR line pname pvalue

      pname  = TRANSLATE(STRIP(pname))
      pvalue = STRIP(pvalue)

      IF pname = '' THEN ITERATE

      IF pvalue = '' THEN DO
         SAY 'ACCOXPAR ERROR: NO VALUE FOR' pname
         EXIT 12
      END

      CALL SetParameter pname, pvalue

   END


   SAY ' '

RETURN


/*********************************************************************/
/* SET PARAMETER                                                     */
/*********************************************************************/

SetParameter:

   PARSE ARG pname, pvalue


   SELECT

      /* DSNACCOX control parameters */

      WHEN pname = 'QUERYTYPE' THEN qtype = TRANSLATE(pvalue)
      WHEN pname = 'OBJECTTYPE' THEN otype = TRANSLATE(pvalue)
      WHEN pname = 'ICTYPE' THEN ictype = TRANSLATE(pvalue)
      WHEN pname = 'CATLGSCHEMA' THEN cats = STRIP(pvalue)
      WHEN pname = 'LOCALSCHEMA' THEN locals = STRIP(pvalue)
      WHEN pname = 'CRITERIA' THEN crit = crit!!pvalue

      WHEN pname = 'CHKLVL' THEN DO
         CALL CheckNumeric pname,pvalue
         chklvl = pvalue
      END

      /* Db2 13 SPECIALPARM sections */

      WHEN pname = 'RRIEMPTYLIMIT' THEN DO
         CALL CheckNumeric pname,pvalue
         rriemptylimit_sp = pvalue
         rriemptylimit_sp_set = 1
      END

      WHEN pname = 'RRTHASHOVRFLWRATIO' THEN DO
         CALL CheckNumeric pname,pvalue
         rrthashratio_sp = pvalue
         rrthashratio_sp_set = 1
      END

      /* Local automatic REORG policy */

      WHEN pname = 'MIN_REORG_SIZE_MB' THEN DO
         CALL CheckNumeric pname,pvalue
         min_reorg_size_mb = pvalue
      END

      WHEN pname = 'MAX_REORG_SIZE_GB' THEN DO
         CALL CheckNumeric pname,pvalue
         max_reorg_size_gb = pvalue
      END

      WHEN pname = 'MIN_DAYS_SINCE_REORG' THEN DO
         CALL CheckNumeric pname,pvalue
         min_days_reorg = pvalue
      END

      WHEN pname = 'PROCESS_AREO' THEN
         process_areo = YesNo(pname,pvalue)

      WHEN pname = 'PROCESS_REORP' THEN
         process_reorp = YesNo(pname,pvalue)

      WHEN pname = 'REORP_OVERRIDE_LIMITS' THEN
         reorp_override = YesNo(pname,pvalue)

      WHEN pname = 'REQUIRE_SIZE_KNOWN' THEN
         require_size_known = YesNo(pname,pvalue)

      WHEN pname = 'OUTPUT_ONLY_AUTO_REORG' THEN
         output_only_auto = YesNo(pname,pvalue)

      WHEN pname = 'EXCLUDE_DBNAME' THEN DO
         excludedb.0 = excludedb.0 + 1
         exn = excludedb.0
         excludedb.exn = TRANSLATE(STRIP(pvalue))
      END

      WHEN pname = 'EXCLUDE_OBJECT' THEN DO
         excludeobj.0 = excludeobj.0 + 1
         exn = excludeobj.0
         excludeobj.exn = TRANSLATE(STRIP(pvalue))
      END

      /* COPY */

      WHEN pname = 'CRUPDATEDPAGESPCT' THEN DO
         CALL CheckNumeric pname,pvalue
         crupdatedpagespct   = pvalue
         crupdatedpagespct_i = 0
      END

      WHEN pname = 'CRUPDATEDPAGESABS' THEN DO
         CALL CheckNumeric pname,pvalue
         crupdatedpagesabs   = pvalue
         crupdatedpagesabs_i = 0
      END

      WHEN pname = 'CRCHANGESPCT' THEN DO
         CALL CheckNumeric pname,pvalue
         crchangespct   = pvalue
         crchangespct_i = 0
      END

      WHEN pname = 'CRDAYSNCLASTCOPY' THEN DO
         CALL CheckNumeric pname,pvalue
         crdaysnclastcopy   = pvalue
         crdaysnclastcopy_i = 0
      END

      WHEN pname = 'ICRUPDATEDPAGESPCT' THEN DO
         CALL CheckNumeric pname,pvalue
         icrupdatedpagespct   = pvalue
         icrupdatedpagespct_i = 0
      END

      WHEN pname = 'ICRUPDATEDPAGESABS' THEN DO
         CALL CheckNumeric pname,pvalue
         icrupdatedpagesabs   = pvalue
         icrupdatedpagesabs_i = 0
      END

      WHEN pname = 'ICRCHANGESPCT' THEN DO
         CALL CheckNumeric pname,pvalue
         icrchangespct   = pvalue
         icrchangespct_i = 0
      END

      WHEN pname = 'CRINDEXSIZE' THEN DO
         CALL CheckNumeric pname,pvalue
         crindexsize   = pvalue
         crindexsize_i = 0
      END


      /* REORG TS */

      WHEN pname = 'RRTINSERTSPCT' THEN DO
         CALL CheckNumeric pname,pvalue
         rrtinsertspct   = pvalue
         rrtinsertspct_i = 0
      END

      WHEN pname = 'RRTINSERTSABS' THEN DO
         CALL CheckNumeric pname,pvalue
         rrtinsertsabs   = pvalue
         rrtinsertsabs_i = 0
      END

      WHEN pname = 'RRTDELETESPCT' THEN DO
         CALL CheckNumeric pname,pvalue
         rrtdeletespct   = pvalue
         rrtdeletespct_i = 0
      END

      WHEN pname = 'RRTDELETESABS' THEN DO
         CALL CheckNumeric pname,pvalue
         rrtdeletesabs   = pvalue
         rrtdeletesabs_i = 0
      END

      WHEN pname = 'RRTUNCLUSTINSPCT' THEN DO
         CALL CheckNumeric pname,pvalue
         rrtunclustinspct   = pvalue
         rrtunclustinspct_i = 0
      END

      WHEN pname = 'RRTDISORGLOBPCT' THEN DO
         CALL CheckNumeric pname,pvalue
         rrtdisorglobpct   = pvalue
         rrtdisorglobpct_i = 0
      END

      WHEN pname = 'RRTDATASPACERAT' THEN DO
         CALL CheckNumeric pname,pvalue
         rrtdataspacerat   = pvalue
         rrtdataspacerat_i = 0
      END

      WHEN pname = 'RRTMASSDELLIMIT' THEN DO
         CALL CheckNumeric pname,pvalue
         rrtmassdellimit   = pvalue
         rrtmassdellimit_i = 0
      END

      WHEN pname = 'RRTINDREFLIMIT' THEN DO
         CALL CheckNumeric pname,pvalue
         rrtindreflimit   = pvalue
         rrtindreflimit_i = 0
      END


      /* REORG IX */

      WHEN pname = 'RRIINSERTSPCT' THEN DO
         CALL CheckNumeric pname,pvalue
         rriinsertspct   = pvalue
         rriinsertspct_i = 0
      END

      WHEN pname = 'RRIINSERTSABS' THEN DO
         CALL CheckNumeric pname,pvalue
         rriinsertsabs   = pvalue
         rriinsertsabs_i = 0
      END

      WHEN pname = 'RRIDELETESPCT' THEN DO
         CALL CheckNumeric pname,pvalue
         rrideletespct   = pvalue
         rrideletespct_i = 0
      END

      WHEN pname = 'RRIDELETESABS' THEN DO
         CALL CheckNumeric pname,pvalue
         rrideletesabs   = pvalue
         rrideletesabs_i = 0
      END

      WHEN pname = 'RRIAPPENDINSERTPCT' THEN DO
         CALL CheckNumeric pname,pvalue
         rriappendinsertpct   = pvalue
         rriappendinsertpct_i = 0
      END

      WHEN pname = 'RRIPSEUDODELETEPCT' THEN DO
         CALL CheckNumeric pname,pvalue
         rripseudodeletepct   = pvalue
         rripseudodeletepct_i = 0
      END

      WHEN pname = 'RRIMASSDELLIMIT' THEN DO
         CALL CheckNumeric pname,pvalue
         rrimassdellimit   = pvalue
         rrimassdellimit_i = 0
      END

      WHEN pname = 'RRILEAFLIMIT' THEN DO
         CALL CheckNumeric pname,pvalue
         rrileaflimit   = pvalue
         rrileaflimit_i = 0
      END

      WHEN pname = 'RRINUMLEVELSLIMIT' THEN DO
         CALL CheckNumeric pname,pvalue
         rrinumlevelslimit   = pvalue
         rrinumlevelslimit_i = 0
      END


      /* RUNSTATS TS */

      WHEN pname = 'SRTINSDELUPDPCT' THEN DO
         CALL CheckNumeric pname,pvalue
         srtinsdelupdpct   = pvalue
         srtinsdelupdpct_i = 0
      END

      WHEN pname = 'SRTINSDELUPDABS' THEN DO
         CALL CheckNumeric pname,pvalue
         srtinsdelupdabs   = pvalue
         srtinsdelupdabs_i = 0
      END

      WHEN pname = 'SRTMASSDELLIMIT' THEN DO
         CALL CheckNumeric pname,pvalue
         srtmassdellimit   = pvalue
         srtmassdellimit_i = 0
      END


      /* RUNSTATS IX */

      WHEN pname = 'SRIINSDELPCT' THEN DO
         CALL CheckNumeric pname,pvalue
         sriinsdelpct   = pvalue
         sriinsdelpct_i = 0
      END

      WHEN pname = 'SRIINSDELABS' THEN DO
         CALL CheckNumeric pname,pvalue
         sriinsdelabs   = pvalue
         sriinsdelabs_i = 0
      END

      WHEN pname = 'SRIMASSDELLIMIT' THEN DO
         CALL CheckNumeric pname,pvalue
         srimassdellimit   = pvalue
         srimassdellimit_i = 0
      END


      /* EXTENTS */

      WHEN pname = 'EXTENTLIMIT' THEN DO
         CALL CheckNumeric pname,pvalue
         extentlimit   = pvalue
         extentlimit_i = 0
      END


      OTHERWISE DO

         SAY 'ACCOXPAR ERROR: UNKNOWN PARAMETER'
         SAY 'PARAMETER=' pname

         EXIT 12

      END

   END


   SAY LEFT(pname,24) pvalue

RETURN


/*********************************************************************/
/* PARAMETER LIST FOR JOB LOG                                         */
/*********************************************************************/

ShowParameters:

   SAY ' '
   SAY 'DSNACCOX PARAMETER'
   SAY '=================='
   SAY 'IBM-DEFAULT = Parameter was not overridden'
   SAY ' '

   SAY 'CONTROL / SPECIAL'
   SAY LEFT('QUERYTYPE',24) qtype
   SAY LEFT('OBJECTTYPE',24) otype
   SAY LEFT('ICTYPE',24) ictype
   SAY LEFT('CHKLVL',24) chklvl
   SAY LEFT('RRIEMPTYLIMIT',24) GetSpecialLimit('EMPTY')
   SAY LEFT('RRTHASHOVRFLWRATIO',24) GetSpecialLimit('HASH')
   SAY ' '
   SAY 'LOCAL REORG POLICY'
   SAY LEFT('MIN_REORG_SIZE_MB',24) min_reorg_size_mb
   SAY LEFT('MAX_REORG_SIZE_GB',24) max_reorg_size_gb
   SAY LEFT('MIN_DAYS_SINCE_REORG',24) min_days_reorg
   SAY LEFT('PROCESS_AREO',24) process_areo
   SAY LEFT('PROCESS_REORP',24) process_reorp
   SAY LEFT('REORP_OVERRIDE_LIMITS',24) reorp_override
   SAY LEFT('REQUIRE_SIZE_KNOWN',24) require_size_known
   SAY LEFT('OUTPUT_ONLY_AUTO_REORG',24) output_only_auto
   DO sx = 1 TO excludedb.0
      SAY LEFT('EXCLUDE_DBNAME',24) excludedb.sx
   END
   SAY ' '
   DO sx = 1 TO excludeobj.0
      SAY LEFT('EXCLUDE_OBJECT',24) excludeobj.sx
   END
   SAY ' '

   CALL ShowParm 'CRUPDATEDPAGESPCT',
                 crupdatedpagespct_i,
                 crupdatedpagespct

   CALL ShowParm 'CRUPDATEDPAGESABS',
                 crupdatedpagesabs_i,
                 crupdatedpagesabs

   CALL ShowParm 'CRCHANGESPCT',
                 crchangespct_i,
                 crchangespct

   CALL ShowParm 'CRDAYSNCLASTCOPY',
                 crdaysnclastcopy_i,
                 crdaysnclastcopy

   CALL ShowParm 'ICRUPDATEDPAGESPCT',
                 icrupdatedpagespct_i,
                 icrupdatedpagespct

   CALL ShowParm 'ICRUPDATEDPAGESABS',
                 icrupdatedpagesabs_i,
                 icrupdatedpagesabs

   CALL ShowParm 'ICRCHANGESPCT',
                 icrchangespct_i,
                 icrchangespct

   CALL ShowParm 'CRINDEXSIZE',
                 crindexsize_i,
                 crindexsize


   CALL ShowParm 'RRTINSERTSPCT',
                 rrtinsertspct_i,
                 rrtinsertspct

   CALL ShowParm 'RRTINSERTSABS',
                 rrtinsertsabs_i,
                 rrtinsertsabs

   CALL ShowParm 'RRTDELETESPCT',
                 rrtdeletespct_i,
                 rrtdeletespct

   CALL ShowParm 'RRTDELETESABS',
                 rrtdeletesabs_i,
                 rrtdeletesabs

   CALL ShowParm 'RRTUNCLUSTINSPCT',
                 rrtunclustinspct_i,
                 rrtunclustinspct

   CALL ShowParm 'RRTDISORGLOBPCT',
                 rrtdisorglobpct_i,
                 rrtdisorglobpct

   CALL ShowParm 'RRTDATASPACERAT',
                 rrtdataspacerat_i,
                 rrtdataspacerat

   CALL ShowParm 'RRTMASSDELLIMIT',
                 rrtmassdellimit_i,
                 rrtmassdellimit

   CALL ShowParm 'RRTINDREFLIMIT',
                 rrtindreflimit_i,
                 rrtindreflimit


   CALL ShowParm 'RRIINSERTSPCT',
                 rriinsertspct_i,
                 rriinsertspct

   CALL ShowParm 'RRIINSERTSABS',
                 rriinsertsabs_i,
                 rriinsertsabs

   CALL ShowParm 'RRIDELETESPCT',
                 rrideletespct_i,
                 rrideletespct

   CALL ShowParm 'RRIDELETESABS',
                 rrideletesabs_i,
                 rrideletesabs

   CALL ShowParm 'RRIAPPENDINSERTPCT',
                 rriappendinsertpct_i,
                 rriappendinsertpct

   CALL ShowParm 'RRIPSEUDODELETEPCT',
                 rripseudodeletepct_i,
                 rripseudodeletepct

   CALL ShowParm 'RRIMASSDELLIMIT',
                 rrimassdellimit_i,
                 rrimassdellimit

   CALL ShowParm 'RRILEAFLIMIT',
                 rrileaflimit_i,
                 rrileaflimit

   CALL ShowParm 'RRINUMLEVELSLIMIT',
                 rrinumlevelslimit_i,
                 rrinumlevelslimit


   CALL ShowParm 'SRTINSDELUPDPCT',
                 srtinsdelupdpct_i,
                 srtinsdelupdpct

   CALL ShowParm 'SRTINSDELUPDABS',
                 srtinsdelupdabs_i,
                 srtinsdelupdabs

   CALL ShowParm 'SRTMASSDELLIMIT',
                 srtmassdellimit_i,
                 srtmassdellimit


   CALL ShowParm 'SRIINSDELPCT',
                 sriinsdelpct_i,
                 sriinsdelpct

   CALL ShowParm 'SRIINSDELABS',
                 sriinsdelabs_i,
                 sriinsdelabs

   CALL ShowParm 'SRIMASSDELLIMIT',
                 srimassdellimit_i,
                 srimassdellimit


   CALL ShowParm 'EXTENTLIMIT',
                 extentlimit_i,
                 extentlimit


   SAY ' '

RETURN


/*********************************************************************/
/* DISPLAY SINGLE PARAMETER                                              */
/*********************************************************************/

ShowParm:

   PARSE ARG spname, spind, spvalue

   IF spind < 0 THEN
      SAY LEFT(spname,24) 'IBM-DEFAULT'
   ELSE
      SAY LEFT(spname,24) spvalue

RETURN


/*********************************************************************/
/* LIMIT TEXT                                                        */
/*********************************************************************/

GetLimit:

   PARSE ARG glname, glind, glvalue

   IF glind < 0 THEN
      RETURN 'IBM-DEFAULT'

RETURN STRIP(glvalue)


/*********************************************************************/
/* ADD REASON                                                        */
/*********************************************************************/

AddReason:

   PARSE ARG addtxt

   addtxt = STRIP(addtxt)

   IF addtxt = '' THEN
      RETURN

   IF reason = '' THEN
      reason = addtxt
   ELSE
      reason = reason !! '; ' !! addtxt

RETURN


/*********************************************************************/
/* DUMP UTILITY FIELDS FOR UNKNOWN REASON                            */
/*********************************************************************/

DumpUtilityFields:

   PARSE ARG utilname

   utilname = TRANSLATE(STRIP(utilname))

   SAY ' '
   SAY 'UNKNOWN TRIGGER DUMP:' utilname
   SAY 'OBJECT AND FLAGS'
   CALL DumpFld  'UTILITY', utilname
   CALL DumpFld  'DB', db
   CALL DumpFld  'NAME', name
   CALL DumpFld  'OBJECTTYPE', objecttype
   CALL DumpFld  'PARTITION', partition
   CALL DumpFld  'INSTANCE', instance
   CALL DumpFldI 'CLONE', clone, clone_i
   CALL DumpFldI 'INDEXSPACE', indexspace, indexspace_i
   CALL DumpFldI 'CREATOR', creator, creator_i
   CALL DumpFldI 'OBJECTSTATUS', objectstatus, objectstatus_i
   CALL DumpFldI 'INEXCEPTTABLE', inexcepttable, inexcepttable_i
   CALL DumpFldI 'ASSOCIATEDTS', associatedts, associatedts_i

   CALL DumpFldI 'IMAGECOPY', imagecopy, imagecopy_i
   CALL DumpFldI 'RUNSTATS', runstats, runstats_i
   CALL DumpFldI 'REORG', reorg, reorg_i
   CALL DumpFldI 'EXTENTS', extents, extents_i

   CALL DumpFldI 'COPYLASTTIME', copylasttime, copylasttime_i
   CALL DumpFldI 'LOADRLASTTIME', loadrlasttime, loadrlasttime_i
   CALL DumpFldI 'REBUILDLASTTIME', rebuildlasttime, rebuildlasttime_i
   CALL DumpFldI 'REORGLASTTIME', reorglasttime, reorglasttime_i
   CALL DumpFldI 'STATSLASTTIME', statslasttime, statslasttime_i

   SELECT

      WHEN utilname = 'COPY' THEN DO
         SAY 'COPY CRITERIA VALUES'
         CALL DumpFldI 'CRUPDPGSPCT', crupdpgspct, crupdpgspct_i
         CALL DumpFldI 'CRUPDPGSABS', crupdpgsabs, crupdpgsabs_i
         CALL DumpFldI 'CRCPYCHGPCT', crcpychgpct, crcpychgpct_i
         CALL DumpFldI 'CRDAYSCELSTCPY', crdayscelstcpy, crdayscelstcpy_i
         CALL DumpFldI 'CRINDEXSIZE_RS', crindexsize_rs, crindexsize_rs_i
      END

      WHEN utilname = 'REORG-TS' THEN DO
         SAY 'REORG TS/LX/XX VALUES'
         CALL DumpFldI 'RRTINSERTSPCT', rrtinsertspct_rs, rrtinsertspct_rs_i
         CALL DumpFldI 'RRTINSERTSABS', rrtinsertsabs_rs, rrtinsertsabs_rs_i
         CALL DumpFldI 'RRTDELETESPCT', rrtdeletespct_rs, rrtdeletespct_rs_i
         CALL DumpFldI 'RRTDELETESABS', rrtdeletesabs_rs, rrtdeletesabs_rs_i
         CALL DumpFldI 'RRTUNCINSPCT', rrtuncinspct_rs, rrtuncinspct_rs_i
         CALL DumpFldI 'RRTDISORGLOBPCT',
                       rrtdisorglobpct_rs,
                       rrtdisorglobpct_rs_i
         CALL DumpFldI 'RRTDATSPRAT', rrtdatsprat_rs, rrtdatsprat_rs_i
         CALL DumpFldI 'RRTMASSDELETE', rrtmassdelete_rs, rrtmassdelete_rs_i
         CALL DumpFldI 'RRTINDREF', rrtindref_rs, rrtindref_rs_i
         CALL DumpFldI 'RRTHASHOVRFLWRAT',
                       rrthashovrflwrat_rs,
                       rrthashovrflwrat_rs_i
         CALL DumpFldI 'RRTPBGSPACEPCT', rrtpbgspacepct_rs, rrtpbgspacepct_rs_i
      END

      WHEN utilname = 'REORG-IX' THEN DO
         SAY 'REORG IX VALUES'
         CALL DumpFldI 'RRIINSERTSPCT', rriinsertspct_rs, rriinsertspct_rs_i
         CALL DumpFldI 'RRIINSERTSABS', rriinsertsabs_rs, rriinsertsabs_rs_i
         CALL DumpFldI 'RRIDELETESPCT', rrideletespct_rs, rrideletespct_rs_i
         CALL DumpFldI 'RRIDELETABS', rrideletabs_rs, rrideletabs_rs_i
         CALL DumpFldI 'RRIAPPINSPCT', rriappinspct_rs, rriappinspct_rs_i
         CALL DumpFldI 'RRIPSDDELPCT', rripsddelpct_rs, rripsddelpct_rs_i
         CALL DumpFldI 'RRIMASSDELETE', rrimassdelete_rs, rrimassdelete_rs_i
         CALL DumpFldI 'RRILEAF', rrileaf_rs, rrileaf_rs_i
         CALL DumpFldI 'RRINUMLEVELS', rrinumlevels_rs, rrinumlevels_rs_i
         CALL DumpFldI 'RRIEMPTYLIMIT', rriemptylimit_rs, rriemptylimit_rs_i
      END

      WHEN utilname = 'RUNSTATS-TS' THEN DO
         SAY 'RUNSTATS TS/LX/XX VALUES'
         CALL DumpFldI 'SRTINSDELUPDPCT',
                       srtinsdelupdpct_rs,
                       srtinsdelupdpct_rs_i
         CALL DumpFldI 'SRTINSDELUPDABS',
                       srtinsdelupdabs_rs,
                       srtinsdelupdabs_rs_i
         CALL DumpFldI 'SRTMASSDELETE', srtmassdelete_rs, srtmassdelete_rs_i
      END

      WHEN utilname = 'RUNSTATS-IX' THEN DO
         SAY 'RUNSTATS IX VALUES'
         CALL DumpFldI 'SRIINSDELPCT', sriinsdelpct_rs, sriinsdelpct_rs_i
         CALL DumpFldI 'SRIINSDELABS', sriinsdelabs_rs, sriinsdelabs_rs_i
         CALL DumpFldI 'SRIMASSDELETE', srimassdelete_rs, srimassdelete_rs_i
      END

      OTHERWISE DO
         SAY 'NO SPECIFIC FIELD BLOCK FOR UTILITY=' utilname
      END

   END

   CALL DumpRs1Hints STRIP(db), STRIP(name), utilname

   CALL DumpFldI 'TOTALEXTENTS', totalextents, totalextents_i

   SAY ' '

RETURN


/*********************************************************************/
/* RS1 HINTS FOR CURRENT OBJECT                                      */
/*********************************************************************/

DumpRs1Hints:

   PARSE ARG kdb, kname, kutil

   kdb = TRANSLATE(STRIP(kdb))
   kname = TRANSLATE(STRIP(kname))
   kutil = TRANSLATE(STRIP(kutil))

   fullkey = kdb
   IF kdb <> '' & kname <> '' THEN
      fullkey = kdb !! '.' !! kname

   utilkey = kutil
   IF kutil = 'REORG-TS' THEN utilkey = 'REORG'
   IF kutil = 'REORG-IX' THEN utilkey = 'REORG'
   IF kutil = 'RUNSTATS-TS' THEN utilkey = 'RUNSTATS'
   IF kutil = 'RUNSTATS-IX' THEN utilkey = 'RUNSTATS'

   SAY 'RS1 MATCHING LINES'

   hits = 0

   /* 1) exact object key DB.NAME */
   IF fullkey <> '' THEN DO
      DO ri = 1 TO rs1.0
         rline = rs1.ri
         rup = TRANSLATE(rline)
         IF POS(fullkey,rup) > 0 THEN DO
            CALL DumpWrapped LEFT('RS1',22), STRIP(rline), ''
            hits = hits + 1
         END
      END
   END

   /* 2) object name only */
   DO ri = 1 TO rs1.0
      IF hits > 0 THEN LEAVE
   END

   IF hits = 0 THEN DO
      IF kname <> '' THEN DO
         DO ri = 1 TO rs1.0
            rline = rs1.ri
            rup = TRANSLATE(rline)
            IF POS(kname,rup) > 0 THEN DO
               CALL DumpWrapped LEFT('RS1',22), STRIP(rline), ''
               hits = hits + 1
               IF hits >= 10 THEN LEAVE
            END
         END
      END
   END

   /* 3) database only */
   IF hits = 0 THEN DO
      IF kdb <> '' THEN DO
         DO ri = 1 TO rs1.0
            rline = rs1.ri
            rup = TRANSLATE(rline)
            IF POS(kdb,rup) > 0 THEN DO
               CALL DumpWrapped LEFT('RS1',22), STRIP(rline), ''
               hits = hits + 1
               IF hits >= 10 THEN LEAVE
            END
         END
      END
   END

   /* 4) utility keyword */
   IF hits = 0 THEN DO
      IF utilkey <> '' THEN DO
         DO ri = 1 TO rs1.0
            rline = rs1.ri
            rup = TRANSLATE(rline)
            IF POS(utilkey,rup) > 0 THEN DO
               CALL DumpWrapped LEFT('RS1',22), STRIP(rline), ''
               hits = hits + 1
               IF hits >= 10 THEN LEAVE
            END
         END
      END
   END

   /* 5) final fallback sample */
   IF hits = 0 THEN DO
      SAY 'RS1                   NO DIRECT MATCH - FIRST LINES:'
      maxsamp = rs1.0
      IF maxsamp > 10 THEN maxsamp = 10
      DO ri = 1 TO maxsamp
         rline = rs1.ri
         CALL DumpWrapped LEFT('RS1',22), STRIP(rline), ''
      END
      IF rs1.0 = 0 THEN
         SAY 'RS1                   EMPTY RESULT SET'
   END

RETURN


/*********************************************************************/
/* DUMP HELPERS (80-CHAR FRIENDLY)                                  */
/*********************************************************************/

DumpFld:

   PARSE ARG fname, fval

   CALL DumpWrapped LEFT(STRIP(fname),22), STRIP(fval), ''

RETURN


DumpFldI:

   PARSE ARG fname, fval, find

   itxt = 'I=' !! STRIP(find)

   CALL DumpWrapped LEFT(STRIP(fname),22), STRIP(fval), itxt

RETURN


DumpWrapped:

   PARSE ARG lname, vtxt, stxt

   maxv = 40
   pad = COPIES(' ',22)

   IF vtxt = '' THEN vtxt = '<BLANK>'

   IF LENGTH(vtxt) <= maxv THEN DO
      IF stxt = '' THEN
         SAY lname vtxt
      ELSE
         SAY lname LEFT(vtxt,maxv) RIGHT(stxt,12)
      RETURN
   END

   part = SUBSTR(vtxt,1,maxv)
   IF stxt = '' THEN
      SAY lname part
   ELSE
      SAY lname part RIGHT(stxt,12)

   rest = SUBSTR(vtxt,maxv+1)
   DO WHILE rest <> ''
      part = SUBSTR(rest,1,maxv)
      SAY pad part
      IF LENGTH(rest) <= maxv THEN
         LEAVE
      rest = SUBSTR(rest,maxv+1)
   END

RETURN


/*********************************************************************/
/* BUILD DB2 13 SPECIALPARM                                          */
/*********************************************************************/

BuildSpecialParm:

   sp1 = COPIES(' ',4)
   sp2 = COPIES(' ',4)

   IF rriemptylimit_sp_set THEN
      sp1 = RIGHT(STRIP(rriemptylimit_sp),4)

   IF rrthashratio_sp_set THEN
      sp2 = RIGHT(STRIP(rrthashratio_sp),4)

   IF LENGTH(sp1) > 4 THEN DO
      SAY 'ACCOXPAR ERROR: SPECIALPARM VALUE > 4 BYTES'
      EXIT 12
   END

   IF LENGTH(sp2) > 4 THEN DO
      SAY 'ACCOXPAR ERROR: SPECIALPARM VALUE > 4 BYTES'
      EXIT 12
   END

   spec = sp1 !! sp2 !! COPIES(' ',152)

RETURN


/*********************************************************************/
/* SPECIALPARM LIMIT TEXT                                            */
/*********************************************************************/

GetSpecialLimit:

   PARSE ARG which

   IF which = 'EMPTY' THEN DO
      IF rriemptylimit_sp_set THEN RETURN STRIP(rriemptylimit_sp)
      RETURN 'IBM-DEFAULT(5)'
   END

   IF which = 'HASH' THEN DO
      IF rrthashratio_sp_set THEN RETURN STRIP(rrthashratio_sp)
      RETURN 'IBM-DEFAULT(15)'
   END

RETURN 'UNKNOWN'


/*********************************************************************/
/* PARAMETER VALIDATION                                              */
/*********************************************************************/

CheckNumeric:

   PARSE ARG nname,nvalue
   IF DATATYPE(STRIP(nvalue),'N') = 0 THEN DO
      SAY 'ACCOXPAR ERROR: NON-NUMERIC VALUE'
      SAY 'PARAMETER=' nname
      SAY 'VALUE    =' nvalue
      EXIT 12
   END

RETURN


YesNo:

   PARSE ARG yname,yvalue
   yvalue = TRANSLATE(STRIP(yvalue))
   IF yvalue <> 'YES' & yvalue <> 'NO' THEN DO
      SAY 'ACCOXPAR ERROR: YES/NO EXPECTED'
      SAY 'PARAMETER=' yname
      SAY 'VALUE    =' yvalue
      EXIT 12
   END

RETURN yvalue


/*********************************************************************/
/* LOCAL POLICY HELPERS                                              */
/*********************************************************************/

AddPolicy:

   PARSE ARG ptxt
   ptxt = STRIP(ptxt)
   IF ptxt = '' THEN RETURN
   IF policy_reason = '' THEN policy_reason = ptxt
   ELSE policy_reason = policy_reason !! '; ' !! ptxt

RETURN


IsDbExcluded:

   PARSE ARG idb
   idb = TRANSLATE(STRIP(idb))
   DO ex = 1 TO excludedb.0
      IF WildMatch(idb,excludedb.ex) THEN RETURN 1
   END

RETURN 0

IsObjectExcluded:

   PARSE ARG idb, iname

   idb   = TRANSLATE(STRIP(idb))
   iname = TRANSLATE(STRIP(iname))

   objkey = idb !! '.' !! iname

   DO ex = 1 TO excludeobj.0
      IF WildMatch(objkey,excludeobj.ex) THEN
         RETURN 1
   END

RETURN 0

WildMatch:

   PARSE ARG text,pat
   text = TRANSLATE(STRIP(text))
   pat = TRANSLATE(STRIP(pat))

   IF pat = '*' THEN RETURN 1
   p = POS('*',pat)
   IF p = 0 THEN RETURN (text = pat)

   pre = SUBSTR(pat,1,p-1)
   post = SUBSTR(pat,p+1)

   IF pre <> '' THEN DO
      IF LEFT(text,LENGTH(pre)) <> pre THEN RETURN 0
   END

   IF post <> '' THEN DO
      IF RIGHT(text,LENGTH(post)) <> post THEN RETURN 0
   END

RETURN 1


DaysSinceReorg:

   IF reorglasttime_i < 0 THEN RETURN -1
   rdate = SUBSTR(STRIP(reorglasttime),1,10)
   rdate = SUBSTR(rdate,1,4) !! SUBSTR(rdate,6,2)
   rdate = rdate !! SUBSTR(STRIP(reorglasttime),9,2)
   IF LENGTH(rdate) <> 8 THEN RETURN -1
   rb = DATE('B',rdate,'S')
   RETURN DATE('B') - rb


SqlQuote:

   PARSE ARG sqtxt
   sqout = ''

   DO WHILE sqtxt <> ''
      sqpos = POS("'",sqtxt)
      IF sqpos = 0 THEN DO
         sqout = sqout !! sqtxt
         sqtxt = ''
      END
      ELSE DO
         IF sqpos > 1 THEN DO
            sqlen = sqpos - 1
            sqout = sqout !! LEFT(sqtxt,sqlen)
         END
         sqout = sqout !! "''"
         sqtxt = SUBSTR(sqtxt,sqpos + 1)
      END
   END

RETURN sqout

/*********************************************************************/
/* GET LATEST RUNSTATS PROFILE FOR CURRENT TABLE SPACE               */
/*                                                                   */
/* Return value:                                                     */
/*   schema.table profile_update                                     */
/*                                                                   */
/* Example:                                                          */
/*   PM110HO.REQUEST 2026-08-19-18.32.22.091                         */
/*********************************************************************/

GetLatestProfileUpdate:

   profschema = COPIES(' ',128)
   proftable  = COPIES(' ',128)
   profupdate = COPIES(' ',26)

   profschema_i = -1
   proftable_i  = -1
   profupdate_i = -1

   qdb = SqlQuote(STRIP(db))
   qts = SqlQuote(STRIP(name))

   profsql = 'SELECT P.SCHEMA, P.TBNAME, P.PROFILE_UPDATE'
   profsql = profsql 'FROM SYSIBM.SYSTABLES T'
   profsql = profsql 'INNER JOIN SYSIBM.SYSTABLES_PROFILES P'
   profsql = profsql 'ON P.SCHEMA = T.CREATOR'
   profsql = profsql 'AND P.TBNAME = T.NAME'
   profsql = profsql "WHERE T.DBNAME='" !! qdb !! "'"
   profsql = profsql "AND T.TSNAME='" !! qts !! "'"
   profsql = profsql "AND P.PROFILE_TYPE='RUNSTATS'"
   profsql = profsql 'ORDER BY P.PROFILE_UPDATE DESC'
   profsql = profsql 'FETCH FIRST 1 ROW ONLY'

   ADDRESS DSNREXX "EXECSQL PREPARE S3 FROM :profsql"

   IF SQLCODE <> 0 THEN DO
      SAY 'WARNING: PROFILE PREPARE FAILED SQLCODE=' SQLCODE
      SAY 'OBJECT=' STRIP(db) STRIP(name)
      RETURN ''
   END

   IF profile_cursor_declared <> 1 THEN DO

      ADDRESS DSNREXX "EXECSQL DECLARE C3 CURSOR FOR S3"

      IF SQLCODE <> 0 THEN DO
         SAY 'WARNING: PROFILE DECLARE FAILED SQLCODE=' SQLCODE
         SAY 'OBJECT=' STRIP(db) STRIP(name)
         RETURN ''
      END

      profile_cursor_declared = 1

   END

   ADDRESS DSNREXX "EXECSQL OPEN C3"

   IF SQLCODE <> 0 THEN DO
      SAY 'WARNING: PROFILE OPEN FAILED SQLCODE=' SQLCODE
      SAY 'OBJECT=' STRIP(db) STRIP(name)
      RETURN ''
   END

   ADDRESS DSNREXX ,
      "EXECSQL FETCH C3 INTO",
      ":profschema :profschema_i,",
      ":proftable :proftable_i,",
      ":profupdate :profupdate_i"

   profrc = SQLCODE

   ADDRESS DSNREXX "EXECSQL CLOSE C3"

   IF profrc = 100 THEN
      RETURN ''

   IF profrc <> 0 THEN DO
      SAY 'WARNING: PROFILE FETCH FAILED SQLCODE=' profrc
      SAY 'OBJECT=' STRIP(db) STRIP(name)
      RETURN ''
   END

   IF profschema_i < 0 THEN RETURN ''
   IF proftable_i  < 0 THEN RETURN ''
   IF profupdate_i < 0 THEN RETURN ''

   proftab = STRIP(profschema) !! '.' !! STRIP(proftable)

RETURN proftab !! ' ' !! STRIP(profupdate)

GetObjectSizeMB:

   objspacekb = 0
   objspacekb_i = -1

   /* REXX cannot use SELECT INTO for this lookup. */
   /* Build a dynamic SELECT and retrieve SPACE via cursor C1/S1. */

   qdb = STRIP(db)
   qname = STRIP(name)

   /* Escape apostrophes for delimited catalog names. */
   qdb = SqlQuote(qdb)
   qname = SqlQuote(qname)

   IF objtyp = 'IX' THEN DO
      sizesql = 'SELECT SPACE'
      sizesql = sizesql 'FROM SYSIBM.SYSINDEXSPACESTATS'
   END
   ELSE DO
      sizesql = 'SELECT SPACE'
      sizesql = sizesql 'FROM SYSIBM.SYSTABLESPACESTATS'
   END

   sizesql = sizesql "WHERE DBNAME='" !! qdb !! "'"
   sizesql = sizesql "AND NAME='" !! qname !! "'"
   sizesql = sizesql 'AND PARTITION=' !! STRIP(partition)
   sizesql = sizesql 'AND INSTANCE=' !! STRIP(instance)
   sizesql = sizesql 'FETCH FIRST 1 ROW ONLY'

   ADDRESS DSNREXX "EXECSQL PREPARE S1 FROM :sizesql"

   IF SQLCODE <> 0 THEN DO
      SAY 'WARNING: SIZE PREPARE FAILED SQLCODE=' SQLCODE
      SAY 'OBJECT=' STRIP(db) STRIP(name) partition
      RETURN -1
   END

   IF size_cursor_declared <> 1 THEN DO
      ADDRESS DSNREXX "EXECSQL DECLARE C1 CURSOR FOR S1"
      IF SQLCODE <> 0 THEN DO
         SAY 'WARNING: SIZE DECLARE FAILED SQLCODE=' SQLCODE
         RETURN -1
      END
      size_cursor_declared = 1
   END

   ADDRESS DSNREXX "EXECSQL OPEN C1"

   IF SQLCODE <> 0 THEN DO
      SAY 'WARNING: SIZE OPEN FAILED SQLCODE=' SQLCODE
      SAY 'OBJECT=' STRIP(db) STRIP(name) partition
      RETURN -1
   END

   ADDRESS DSNREXX ,
      "EXECSQL FETCH C1 INTO :objspacekb :objspacekb_i"

   fetchrc = SQLCODE

   ADDRESS DSNREXX "EXECSQL CLOSE C1"

   IF fetchrc = 100 THEN RETURN -1
   IF fetchrc <> 0 THEN DO
      SAY 'WARNING: SIZE FETCH FAILED SQLCODE=' fetchrc
      SAY 'OBJECT=' STRIP(db) STRIP(name) partition
      RETURN -1
   END

   IF objspacekb_i < 0 THEN RETURN -1
   IF objspacekb < 0 THEN RETURN -1

RETURN objspacekb / 1024

/*********************************************************************/
/* SQL ERROR                                                         */
/*********************************************************************/

SQLERR:

   SAY ' '
   SAY 'SQL ERROR'
   SAY '========='
   SAY 'SQLCODE =' SQLCODE
   SAY 'SQLSTATE=' SQLSTATE
   SAY 'SQLERRMC=' SQLERRMC

   ADDRESS DSNREXX "DISCONNECT"

EXIT 12



