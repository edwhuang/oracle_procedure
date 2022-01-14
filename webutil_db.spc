CREATE OR REPLACE PACKAGE IPTV."WEBUTIL_DB" AUTHID CURRENT_USER AS

/*********************************************************************************\
 * WebUtil_DB - Database functions used by the WebUtil_File_Transfer
 * Package.  These functions allow reading and writing direct
 * to the specified BLOB in the database.
 *  The functions should not be called externally from WebUtil
 *********************************************************************************
 * Version 1.0.0
 *********************************************************************************
 * Change History
 *   DRMILLS 11/JAN/2003 - Creation
 *
\*********************************************************************************/

  FUNCTION  OpenBlob(blobTable  in VARCHAR2,
                     blobColumn in VARCHAR2,
                     blobWhere  in VARCHAR2,
                     openMode   in VARCHAR2,
                     chunkSize  in PLS_INTEGER default null) return BOOLEAN;

  FUNCTION  CloseBlob(checksum in PLS_INTEGER) return BOOLEAN;

  PROCEDURE WriteData(data in VARCHAR2);

  FUNCTION ReadData return VARCHAR;

  FUNCTION GetLastError return PLS_INTEGER;

  FUNCTION GetSourceLength  return PLS_INTEGER;

  FUNCTION GetSourceChunks  return PLS_INTEGER;

END WEBUTIL_DB;
/

