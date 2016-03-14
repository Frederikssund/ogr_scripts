REM ============================================================================================
REM == Upload af spatielle data til MS SQL Server fra vilk�lige datakilder                    ==
REM == OGR2OGR ver 1.11 b�r benyttes                                                          ==
REM == Programm�rer: Bo Victor Thomsen, Frederikssund Kommune                                 ==
REM ============================================================================================

REM =====================================================
REM Inddata check, alle 6 parametre *skal* v�re angivet
REM =====================================================
call "%~dp0ogr_prep_arg.cmd" %*

REM =====================================================
REM Upload af data til MS SQL Server (uden spatiel indeks)
REM =====================================================
@echo Kommando.. ogr2ogr -gt 100000 -skipfailures -overwrite %ogr_xtra% -lco FID="%ogr_fid%" -lco SPATIAL_INDEX=NO -lco GEOM_NAME="%ogr_geom%" -lco OVERWRITE=YES -lco SCHEMA="%xp4%" -nln "%xp5%" %xp11% %xp9% %xp10% -f "MSSQLSpatial" MSSQL:%xp3% %xp1% %xp2% %xp7%
ogr2ogr -gt 100000 -skipfailures -overwrite %ogr_xtra% -lco FID="%ogr_fid%" -lco GEOM_NAME="%ogr_geom%" -lco OVERWRITE=YES -lco SCHEMA="%xp4%" -nln "%xp5%" %xp11% %xp9% %xp10% -f "MSSQLSpatial" MSSQL:%xp3% %xp1% %xp2% %xp7%

REM =====================================================
REM Lav identity column om til alm. integer 
REM =====================================================
@echo Kommando.. ogrinfo -q -sql "EXEC dbo.ChangeIdentityColumn @schema='%xp4%', @table='%xp5%'" MSSQL:%xp3%
ogrinfo -q -sql "EXEC dbo.ChangeIdentityColumn @schema='%xp4%', @table='%xp5%'" MSSQL:%xp3%

REM =====================================================
REM Generer spatielt indeks. 
REM =====================================================
@echo Kommando.. ogrinfo -q -sql "CREATE SPATIAL INDEX  [SPX_%xp5%] ON [%xp4%].[%xp5%] ([%ogr_geom%]) USING GEOMETRY_GRID WITH (BOUNDING_BOX =(%ogr_spatial%))" MSSQL:%xp3%
ogrinfo -q -sql "CREATE SPATIAL INDEX  [SPX_%xp5%] ON [%xp4%].[%xp5%] ([%ogr_geom%]) USING GEOMETRY_GRID WITH (BOUNDING_BOX =(%ogr_spatial%))" MSSQL:%xp3%

REM =====================================================
REM Erstat UTF8 repr�sentation af ��� o.l. til Latin-1 repr�sentation
REM ogr2ogr genererer varchar til tekstfelter. Dette vil f� UTF8 baserede data til at
REM blive misrepr�senteret mht. ��� o.l. Nedenst�ende kommando retter op p� dette.
REM =====================================================
@echo Kommando.. ogrinfo -q -sql "EXEC dbo.ReplaceAccent @schemaname='%xp4%', @tablename='%xp5%'" MSSQL:%xp3%
ogrinfo -q -sql "EXEC dbo.ReplaceAccent @schemaname='%xp4%', @tablename='%xp5%'" MSSQL:%xp3%

REM =====================================================
REM Hvis ogr_dato er sat, autogenereres der et nyt felt, som indeholder dato for indl�gning af data 
REM =====================================================
if not #%ogr_dato%==# (
  @echo Kommando.. ogrinfo -q -sql "ALTER TABLE [%xp4%].[%xp5%] ADD [%ogr_dato%] varchar(10) NULL CONSTRAINT [DF_%xp4%_%xp5%_%ogr_dato%] DEFAULT (CONVERT ( varchar(10), getdate(), 120))" MSSQL:%xp3%
  ogrinfo -q -sql "ALTER TABLE [%xp4%].[%xp5%] ADD [%ogr_dato%] varchar(10) NULL CONSTRAINT [DF_%xp4%_%xp5%_%ogr_dato%] DEFAULT (CONVERT ( varchar(10), getdate(), 120))" MSSQL:%xp3%
  @echo Kommando.. ogrinfo -q -sql "UPDATE [%xp4%].[%xp5%]  SET %ogr_dato%=CONVERT ( varchar(10), getdate(), 120)" MSSQL:%xp3%
  ogrinfo -q -sql "UPDATE [%xp4%].[%xp5%]  SET %ogr_dato%=CONVERT ( varchar(10), getdate(), 120)" MSSQL:%xp3%
)

REM =====================================================
REM OVERWRITE, TRUNCATE f�rdigbehandling 
REM =====================================================
if not %xp5%==%xp12% (
  @echo Kommando.. ogrinfo -q -sql "EXEC dbo.TransferTable @sourceschema='%xp4%', @sourcetable='%xp5%', @targetschema='%xp4%', @targettable='%xp12%'" MSSQL:%xp3%
  ogrinfo -q -sql "EXEC dbo.TransferTable @sourceschema='%xp4%', @sourcetable='%xp5%', @targetschema='%xp4%', @targettable='%xp12%'" MSSQL:%xp3%
)


