USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [MIGRATION].[UpdatePostedColumn]    Script Date: 10.04.2024 14:31:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [MIGRATION].[UpdatePostedColumn]
AS
BEGIN
UPDATE [SAP Documents] SET [Posted]=1 WHERE [SAP Company]='2000' AND [Document No_]='20210001013237'
UPDATE [SAP Documents] SET [Posted]=1 WHERE [SAP Company]='3000' AND [Document No_] IN ('20220001001917','20220001001920')

UPDATE [SAP Documents] SET [Posted]=1 WHERE [Document No_] IN ('20220001001226','20220001001227') AND [SAP Company]='4000'
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20220001017421 + 20220001018424 wg. falscher KST' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20220001017421','20220001018424') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20220001017637 + 20230001000187 wg. unwirksame Buchung' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20220001017637','20230001000187') 

-- 26.01.23 Christopher Schönemann per Zoom am gleichen Tag 10:45: JA21 gebuchte AfA musste noch einmal in SAP gebucht werden +++ 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='AfA aus 20210001017150 + 20210001017151 bereits zuvor in NAV gebucht' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001017150','20210001017151') 
DELETE FROM [SAP Document Balance]
 WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001017150','20210001017151') 
-- 26.01.23 Christopher Schönemann per Zoom am gleichen Tag 10:45: JA21 gebuchte AfA musste noch einmal in SAP gebucht werden ---

-- 30.01.23 Christopher Schönemann per Zoom am 30.01.23: JA21 gebuchte AfA musste noch einmal in SAP gebucht werden +++ 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='AfA aus 20210001017152 + 20210001017153 bereits zuvor in NAV gebucht' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001017152','20210001017153') 
DELETE FROM [SAP Document Balance]
 WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001017152','20210001017153') 
-- 30.01.23 Christopher Schönemann per Zoom am 30.01.23: JA21 gebuchte AfA musste noch einmal in SAP gebucht werden ---

 -- Storno noch nicht implementiert, daher beide nicht importiert ++
 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Storno noch nicht implementiert, daher beide nicht importiert' WHERE [SAP Company]='2000' AND [Document No_] IN('20210001000430','20210001001264') 
 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Storno noch nicht implementiert, daher beide nicht importiert' WHERE [SAP Company]='2000' AND [Document No_] IN('20210001000524','20210001001293')
 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Storno noch nicht implementiert, daher beide nicht importiert' WHERE [SAP Company]='2000' AND [Document No_] IN('20210001000165','20210001001376')
 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Storno noch nicht implementiert, daher beide nicht importiert' WHERE [SAP Company]='2000' AND [Document No_] IN('20210001000157','20210001002007')
 -- Storno noch nicht implementiert, daher beide nicht importiert --

 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='email Anja Henning 08.03.21 10:30' WHERE [SAP Company]='2000' AND [Document No_] IN('20210001000141') -- email Anja Henning 08.03.21 10:30


 --email Anja Henning Do 18.03.2021 19:22 ++
 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='email Anja Henning Do 18.03.2021 19:22' WHERE [SAP Company]='2000' AND [Document No_] IN('20210001002996','20210001002997','20210001002998','20210001002999','20210001003000','20210001003001','20210001003002','20210001003003','20210001003004','20210001003005','20210001003006','20210001003007','20210001003008','20210001003009','20210001003011','20210001003012','20210001003013','20210001003014','20210001003015','20210001003016','20210001003017','20210001003018','20210001003010')
 --email Anja Henning Do 18.03.2021 19:22 --

 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Termin 18.03.21 Kto 490022' WHERE [SAP Company]='2000' AND [Document No_] IN('20210001000166') --Termin 18.03.21 Kto 490022
 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Termin 18.03.21 Kto 490022' WHERE [SAP Company]='2000' AND [Document No_] IN('20210001002419') --Termin 18.03.21 Kto 490022
 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Storno und Original zu Fehlbuchung wg. Währungswechselkursproblem bei SAP-Export' WHERE [SAP Company]='2000' AND [Document No_] IN('20210001003508','20210001000492') -- Storno und Original zu Fehlbuchung wg. Währungswechselkursproblem bei SAP-Export

 --Email Paul Jedich 01.04.21 11:23 ++
 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Paul Jedich 01.04.21 11:23' WHERE [SAP Company]='2000' AND [Document No_] BETWEEN '20218000000000' AND '20218000000012' 
 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Paul Jedich 01.04.21 11:23' WHERE [SAP Company] IN ('3002','4000','5002') AND [Document No_] IN('20218000000000')
 --Email Paul Jedich 01.04.21 11:23 --

 --Email Anh Pham Dienstag, 6. April 2021 15:02 ++
 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Email Anh Pham Di 06.04.2021 15:02' WHERE [SAP Company] IN ('5002') AND [Document No_] IN('20218000000001','20218000000002','20218000000003') 
 --Email Anh Pham Dienstag, 6. April 2021 15:02 --

 -- Email Falko Remmert Mi 12.05.2021 09:27 ++
 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Email Falko Remmert Mi 12.05.2021 09:27' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001001416','20210001001417','20210001001418','20210001001419','20210001001420','20210001001421','20210001001431','20210001001474','20210001001474','20210001001482','20210001001483','20210001001485','20210001001486','20210001001487','20210001001488','20210001001499','20210001001512','20210001001517','20210001001517','20210001001614','20210001001819','20210001001831')
 -- Email Falko Remmert Mi 12.05.2021 09:27 --

 -- Absprache mit Anja Henning : Bein einem Anlagen Einkauf buch SAP über das technische Komto 59900 ++
 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Anja Henning 14.05.21 : Bei Anlagen Einkauf bucht SAP über das technische Komto 59900' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001005428') 
 -- Absprache mit Anja Henning : Bein einem Anlagen Einkauf buch SAP über das technische Komto 59900 ++

 -- Buchung + Storno mit falschen Kostenträgern 08.07.21 ++
 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno mit falschen Kostenträgern 08.07.21' WHERE [SAP Company] IN ('3000') AND [Document No_] IN('20210001000336','20210001000342') 
 -- Buchung + Storno mit falschen Kostenträgern 08.07.21 ++

 -- Bitte Buchung ignorieren, wurde wieder storniert. Anja Henning 8.7.21 14:29 ++
 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno mit falschen Kostenträgern 08.07.21' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210030000907','20210030000918') 
 -- Bitte Buchung ignorieren, wurde wieder storniert. Anja Henning 8.7.21 14:29 ++
 
 -- Buchung + Storno mit Hauswährung = 0 13.08.21 ++
 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno mit Hauswährung = 0 13.08.21' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001008842','20210001009227') 
 -- Buchung + Storno mit Hauswährung = 0 13.08.21 ++

 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno mit mit falschen Kostenstellen 13.08.21' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001013237') 

 -- Buchung + Storno mit mit falschen Kostenstellen 13.08.21 ++
 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno mit mit falschen Kostenstellen 13.08.21' WHERE [SAP Company] IN ('4000') AND [Document No_] IN('20210001000496','20210001000515') 
 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno mit mit falschen Kostenstellen 13.08.21' WHERE [SAP Company] IN ('3004') AND [Document No_] IN('20210001000234','20210001000245') 
 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno mit mit falschen Kostenstellen 13.08.21' WHERE [SAP Company] IN ('3004') AND [Document No_] IN('20210001000240','20210001000247') 
 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno mit mit falschen Kostenstellen 13.08.21' WHERE [SAP Company] IN ('3004') AND [Document No_] IN('20210001000241','20210001000249') 
 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno mit mit falschen Kostenstellen 13.08.21' WHERE [SAP Company] IN ('3001') AND [Document No_] IN('20210001000380','20210001000409') 
 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno mit mit falschen Kostenstellen 13.08.21' WHERE [SAP Company] IN ('3001') AND [Document No_] IN('20210001000394','20210001000411') 
 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno mit mit falschen Kostenstellen 13.08.21' WHERE [SAP Company] IN ('3000') AND [Document No_] IN('20210001000391','20210001000417') 
 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno mit mit falschen Kostenstellen 13.08.21' WHERE [SAP Company] IN ('3000') AND [Document No_] IN('20210001000400','20210001000419') 
 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno mit mit falschen Kostenstellen 13.08.21' WHERE [SAP Company] IN ('3000') AND [Document No_] IN('20210001000401','20210001000421') 
 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno mit mit falschen Kostenstellen 13.08.21' WHERE [SAP Company] IN ('3002') AND [Document No_] IN('20210001000439','20210001000456') 
 -- Buchung + Storno mit mit falschen Kostenstellen 13.08.21 ++

 -- Buchung + Storno Email Paul Jedich Fr 03.09.2021 10:33 ++
 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno Email Paul Jedich Fr 03.09.2021 10:33' WHERE [SAP Company] IN ('5002') AND [Document No_] IN('20210001000454','20210001000274') 
 -- Buchung + Storno Email Paul Jedich Fr 03.09.2021 10:33 ++

 -- Buchung + Storno mit mit falschen Kreditor 20.08.21 ++
 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno mit mit falschen Kreditor 20.08.21' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001009279','20210001009330') 
 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno mit mit falschen Kreditor 25.08.21' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001009353','20210001009389') 
 -- Buchung + Storno mit mit falschen Kreditor 20.08.21 ++

 -- Buchung + Storno mit falschem Kostenträger 17.09.21 ++
 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno mit falschem Kostenträger 17.09.21' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001009547','20210001010446') 
 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno mit falschem Kostenträger 17.09.21' WHERE [SAP Company] IN ('3002') AND [Document No_] IN('20210001000492','20210001000520') 
 -- Buchung + Storno mit falschem Kostenträger 17.09.21 ++

 -- Buchung + Storno 17.09.21 ++
 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001000431 + 20210001000448' WHERE [SAP Company] IN ('4000') AND [Document No_] IN('20210001000431','20210001000448') 
 UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001000432 + 20210001000449' WHERE [SAP Company] IN ('4000') AND [Document No_] IN('20210001000432','20210001000449') 
 -- Buchung + Storno 17.09.21 ++

-- Buchung + Storno 08.10.21 ++
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001010879 + 20210001010877' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001010879','20210001010877') 
-- Buchung + Storno 08.10.21 ++

-- Buchung + Storno 12.10.21 ++
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001010729 + 20210001011261' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001010729','20210001011261') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001010989 + 20210001011262' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001010989','20210001011262') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001011126 + 20210001011264' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001011126','20210001011264') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001011127 + 20210001011266' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001011127','20210001011266') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001011129 + 20210001011268' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001011129','20210001011268') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001011131 + 20210001011270' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001011131','20210001011270') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001011134 + 20210001011272' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001011134','20210001011272') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001011135 + 20210001011274' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001011135','20210001011274') 
-- Buchung + Storno 12.10.21 ++

-- Buchung + Storno 13.10.21 ++
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001000518 + 20210001000524' WHERE [SAP Company] IN ('3001') AND [Document No_] IN('20210001000518','20210001000524') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001000519 + 20210001000525' WHERE [SAP Company] IN ('3001') AND [Document No_] IN('20210001000519','20210001000525') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001000520 + 20210001000526' WHERE [SAP Company] IN ('3001') AND [Document No_] IN('20210001000520','20210001000526') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001000521 + 20210001000527' WHERE [SAP Company] IN ('3001') AND [Document No_] IN('20210001000521','20210001000527') 
-- Buchung + Storno 13.10.21 ++

-- Buchung + Storno 09.11.21 ++
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001000192 + 20210001000305' WHERE [SAP Company] IN ('1000') AND [Document No_] IN('20210001000192','20210001000305') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001000208 + 20210001000306' WHERE [SAP Company] IN ('1000') AND [Document No_] IN('20210001000208','20210001000306') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001000222 + 20210001000307' WHERE [SAP Company] IN ('1000') AND [Document No_] IN('20210001000222','20210001000307') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001000237 + 20210001000308' WHERE [SAP Company] IN ('1000') AND [Document No_] IN('20210001000237','20210001000308') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001000254 + 20210001000309' WHERE [SAP Company] IN ('1000') AND [Document No_] IN('20210001000254','20210001000309') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001000269 + 20210001000310' WHERE [SAP Company] IN ('1000') AND [Document No_] IN('20210001000269','20210001000310') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001000283 + 20210001000311' WHERE [SAP Company] IN ('1000') AND [Document No_] IN('20210001000283','20210001000311') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001000293 + 20210001000312' WHERE [SAP Company] IN ('1000') AND [Document No_] IN('20210001000293','20210001000312') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001000300 + 20210001000313' WHERE [SAP Company] IN ('1000') AND [Document No_] IN('20210001000300','20210001000313') 
-- Buchung + Storno 09.11.21 ++

-- Buchung + Storno 10.11.21 ++
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001011981 + 20210001012549' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001011981','20210001012549') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001012231 + 20210001012551' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001012231','20210001012551') 
-- Buchung + Storno 10.11.21 ++

-- Buchung + Storno 13.12.21 ++
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001013846 + 20210001014120' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001013846','20210001014120') 
-- Buchung + Storno 10.11.21 ++

-- Buchung + Storno 20.01.22 ++
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001014619 + 20210001015264' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001014619','20210001015264') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001015111 + 20210001015266' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001015111','20210001015266') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001015113 + 20210001015267' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001015113','20210001015267') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001015241 + 20210001015270' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001015241','20210001015270') 
-- Buchung + Storno 20.01.22 ++

-- Buchung + Storno 18.02.22 ++
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Vendor No. ''''ALT! NEUER KREDITOR'''' does not exist. ' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20220001000983','20220001001095') 
-- Buchung + Storno 18.02.22 ++

-- Buchung + Storno 23.02.22 ++
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001015594 + 20210001015643 wg. NAV Konto 147000' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001015594','20210001015643') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001015595 + 20210001015644 wg. NAV Konto 147000' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001015595','20210001015644') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001015596 + 20210001015645 wg. NAV Konto 147000' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001015596','20210001015645') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001015597 + 20210001015646 wg. NAV Konto 147000' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001015597','20210001015646') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001015598 + 20210001015647 wg. NAV Konto 147000' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001015598','20210001015647') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001015599 + 20210001015648 wg. NAV Konto 147000' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001015599','20210001015648') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001015600 + 20210001015649 wg. NAV Konto 147000' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001015600','20210001015649') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001015601 + 20210001015650 wg. NAV Konto 147000' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001015601','20210001015650') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001015602 + 20210001015651 wg. NAV Konto 147000' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001015602','20210001015651') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001015603 + 20210001015652 wg. NAV Konto 147000' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001015603','20210001015652') 
-- Buchung + Storno 23.02.22 ++

-- Buchung + Storno 23.02.22 ++
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001015486 + 20210001015663 wg. falscher Kostenstelle ZZ90002000' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001015486','20210001015663') 
-- Buchung + Storno 23.02.22 ++

-- Buchung + Storno 23.02.22 ++
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20220001000026 + 20220001000027 wg. falscher Kostenstelle 0' WHERE [SAP Company] IN ('3004') AND [Document No_] IN('20220001000026','20220001000027') 
-- Buchung + Storno 23.02.22 ++

-- Buchung + Storno 23.02.22 ++
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20220001001204 + 20220001001253' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20220001001204','20220001001253') 
-- Buchung + Storno 23.02.22 ++

-- Buchung + Storno 08.03.22 ++
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20220001000028 + 20220001000041' WHERE [SAP Company] IN ('3004') AND [Document No_] IN('20220001000028','20220001000041') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20220001000039 + 20220001000040' WHERE [SAP Company] IN ('3004') AND [Document No_] IN('20220001000039','20220001000040') 
-- Buchung + Storno 08.03.22 ++

-- Buchung + Storno 09.03.22 ++
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20220001001769 + 20220001001868' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20220001001769','20220001001868') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20220001001848 + 20220001001869' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20220001001848','20220001001869') 
-- Buchung + Storno 09.03.22 ++

-- Buchung + Storno 21.03.22 ++
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001015719 + 20210001015720' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001015719','20210001015720') 
-- Buchung + Storno 21.03.22 ++

-- Buchung + Storno 30.03.22 ++
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001001036 + 20210001001035' WHERE [SAP Company] IN ('4000') AND [Document No_] IN('20210001001036','20210001001035') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001015969 + 20210001015971' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001015969','20210001015971') 
-- Buchung + Storno 30.03.22 ++

-- Buchung + Storno 11.04.22 ++
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001016099 + 20210001016320 wg. Mapping zu SAP Ktp. 163001 fehlt' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001016099','20210001016320') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001016197 + 20210001016321 wg. Mapping zu SAP Ktp. 121020 fehlt' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001016197','20210001016321') 
-- Buchung + Storno 11.04.22 ++

-- Buchung + Storno 06.05.22 ++
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='ACS-3723 Buchung + Storno 20210001016336 + 20210001016357' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001016336','20210001016357') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='ACS-3723 Buchung + Storno 20210001016338 + 20210001016347' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001016338','20210001016347') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='ACS-3723 Buchung + Storno 20210001016340 + 20210001016351' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001016340','20210001016351') 
-- Buchung + Storno 06.05.22 ++

-- Buchung + Storno 06.05.22 ++
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='ACS-3724 Buchung + Storno 20210001016326 + 20210001016345' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001016326','20210001016345') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='ACS-3724 Buchung + Storno 20210001016328 + 20210001016355' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001016328','20210001016355') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='ACS-3724 Buchung + Storno 20210001016330 + 20210001016353' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001016330','20210001016353') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='ACS-3724 Buchung + Storno 20210001016332 + 20210001016349' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001016332','20210001016349') 
-- Buchung + Storno 06.05.22 ++

-- Buchung + Storno 13.05.22 ++
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001000384 + 20210001000389 wg. NAV Kto 161000 darf nicht direkt bebucht werden' WHERE [SAP Company] IN ('1000') AND [Document No_] IN('20210001000384','20210001000389') 
-- Buchung + Storno 13.05.22 ++

-- Buchung + Storno 11.07.22 Thomas Bicker wollte das NAV Kto 497003 nicht anlegen und hat die belege storniert++
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20220001000011 + 20220001000029 wg. 005 Mapping SAP Kto. 497003 zu NAV Kto. fehlt' WHERE [SAP Company] IN ('1002') AND [Document No_] IN('20220001000011','20220001000029') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20220001000014 + 20220001000025 wg. 005 Mapping SAP Kto. 497003 zu NAV Kto. fehlt' WHERE [SAP Company] IN ('1002') AND [Document No_] IN('20220001000014','20220001000025') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20220001000002 + 20220001000031 wg. 005 Mapping SAP Kto. 497003 zu NAV Kto. fehlt' WHERE [SAP Company] IN ('1002') AND [Document No_] IN('20220001000002','20220001000031') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20220001000003 + 20220001000033 wg. 005 Mapping SAP Kto. 497003 zu NAV Kto. fehlt' WHERE [SAP Company] IN ('1002') AND [Document No_] IN('20220001000003','20220001000033') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20220001000028 + 20220001000035 wg. 005 Mapping SAP Kto. 497003 zu NAV Kto. fehlt' WHERE [SAP Company] IN ('1002') AND [Document No_] IN('20220001000028','20220001000035') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20220001000010 + 20220001000027 wg. 005 Mapping SAP Kto. 497003 zu NAV Kto. fehlt' WHERE [SAP Company] IN ('1002') AND [Document No_] IN('20220001000010','20220001000027') 
-- Buchung + Storno 11.07.22 Thomas Bicker wollte das NAV Kto 497003 nicht anlegen und hat die belege storniert++

-- Buchung + Storno 26.09.22 soll lt. Thomas Bicker als gebucht gekennzeichnet werden, statt neue Konten inNAV anzulegen +++
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001001012 + 20210001001153 wg. fehlendem Mapping' WHERE [SAP Company] IN ('3000') AND [Document No_] IN('20210001001012','20210001001153') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001001089 + 20210001001154 wg. fehlendem Mapping' WHERE [SAP Company] IN ('3000') AND [Document No_] IN('20210001001089','20210001001154') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001000402 + 20210001000403 wg. fehlendem Mapping' WHERE [SAP Company] IN ('1000') AND [Document No_] IN('20210001000402','20210001000403') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001000404 + 20210001000405 wg. fehlendem Mapping' WHERE [SAP Company] IN ('1000') AND [Document No_] IN('20210001000404','20210001000405') 
-- Buchung + Storno 26.09.22 soll lt. Thomas Bicker als gebucht gekennzeichnet werden, statt neue Konten inNAV anzulegen ---

-- Buchung + Storno 04.11.22 ++
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20220001014004 + 20220001014005' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20220001014004','20220001014005') 
-- Buchung + Storno 04.11.22 ++

-- ZU-Belege sind technische Ausgleichsbelege, die in SAP automatisch gebucht werden und nicht in NAV nicht verarbeitet werden müssen 08.11.22 ++ CSC18 per Zoom
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='technischer Ausgleichsbeleg 20220001000896' WHERE [SAP Company] IN ('4000') AND [Document No_] IN('20220001000896') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='technischer Ausgleichsbeleg 20220001000897' WHERE [SAP Company] IN ('4000') AND [Document No_] IN('20220001000897') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='technischer Ausgleichsbeleg 20220001000898' WHERE [SAP Company] IN ('4000') AND [Document No_] IN('20220001000898') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='technischer Ausgleichsbeleg 20220001000899' WHERE [SAP Company] IN ('4000') AND [Document No_] IN('20220001000899') 

UPDATE [SAP Documents] SET [Posted]=1, [Comment]='technischer Ausgleichsbeleg 20220001012575' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20220001012575') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='technischer Ausgleichsbeleg 20220001012578' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20220001012578') 

UPDATE [SAP Documents] SET [Posted]=1, [Comment]='technischer Ausgleichsbeleg 20220001000354' WHERE [SAP Company] IN ('3004') AND [Document No_] IN('20220001000354') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='technischer Ausgleichsbeleg 20220001000355' WHERE [SAP Company] IN ('3004') AND [Document No_] IN('20220001000355') 

UPDATE [SAP Documents] SET [Posted]=1, [Comment]='technischer Ausgleichsbeleg 20220001001310' WHERE [SAP Company] IN ('3000') AND [Document No_] IN('20220001001310') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='technischer Ausgleichsbeleg 20220001001422' WHERE [SAP Company] IN ('3000') AND [Document No_] IN('20220001001422') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='technischer Ausgleichsbeleg 20220001001423' WHERE [SAP Company] IN ('3000') AND [Document No_] IN('20220001001423') 

UPDATE [SAP Documents] SET [Posted]=1, [Comment]='technischer Ausgleichsbeleg 20220001014992' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20220001014992') 
-- ZU-Belege sind technische Ausgleichsbelege, die in SAP automatisch gebucht werden und nicht in NAV nicht verarbeitet werden müssen 08.11.22 --

-- falsches Sachkonto 459500 in SAP verwendet 08.11.22 ++ CSC18 per Zoom
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20220001001467 + 20220001001510 wg. falschem Sachkonto' WHERE [SAP Company] IN ('3000') AND [Document No_] IN('20220001001467','20220001001510') 
-- falsches Sachkonto 459500 in SAP verwendet 08.11.22 -- CSC18 per Zoom

-- falsches Sachkonto 459500 in SAP verwendet 08.12.22 ++ CSC18 per Zoom + EMail
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20220001001509 + 20220001001700 wg. falschem Sachkonto' WHERE [SAP Company] IN ('3000') AND [Document No_] IN('20220001001509','20220001001700') 
-- falsches Sachkonto 459500 in SAP verwendet 08.11.22 -- CSC18 per Zoom + EMail

-- Buchung + Storno 06.01.23 ++
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001017145 + 20210001017147 wg. falschem Sachkonto' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001017145','20210001017147') 
-- Buchung + Storno 06.01.23 --
-- Buchung + Storno 16.01.23 ++
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20220001018302 + 20220001018304' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20220001018302','20220001018304') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20220001017421 + 20220001018424 wg. falscher KST' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20220001017421','20220001018424') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20220001017637 + 20230001000187 wg. unwirksame Buchung' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20220001017637','20230001000187') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20220001001226 + 20220001001227 wg. Buchung+Storno' WHERE [SAP Company] IN ('4000') AND [Document No_] IN('20220001001226','20220001001227') 
-- Buchung + Storno 06.01.23 --

UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Kostenstellenumbuchung in SAP' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20220001018706') 

-- Buchung + Storno 20.03.23 ++
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20220001018653 + 20220001018711 wg. falschem Sachkonto' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20220001018653','20220001018711') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20220001001971 + 20220001001990 wg. falschem Sachkonto' WHERE [SAP Company] IN ('3000') AND [Document No_] IN('20220001001971','20220001001990') 
-- Buchung + Storno 20.03.23 --

-- Buchung + Storno 27.03.23 ++
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20220001001995 + 20220001001996' WHERE [SAP Company] IN ('3000') AND [Document No_] IN('20220001001995','20220001001996') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20230001000629 + 20230001000651' WHERE [SAP Company] IN ('3000') AND [Document No_] IN('20230001000629','20230001000651') 
--UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20220001001994 + 20230001000652' WHERE [SAP Company] IN ('3000') AND [Document No_] IN('20220001001994','20230001000652') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20210001017152 + 20210001017153 E-Mail 26.03.23 CSC18' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20210001017152','20210001017153') 
-- Buchung + Storno 27.03.23 --

-- Buchung + Storno 12.07.23 ++
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung + Storno 20230001013875 + 20230001013876' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20230001013875','20230001013876') 
-- Buchung + Storno 12.07.23 ++

-- Buchung ohne Auswirkung auf Sachkonten ausblenden, die wg. fehlender Infos nicht gebucht werden können ++
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Buchung ohne Auswirkung auf Sachkonten ausblenden' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20230001017129','20230001017140','20230001022340') -- 29.09.23
-- Buchung ohne Auswirkung auf Sachkonten ausblenden, die wg. fehlender Infos nicht gebucht werden können --

-- Umbuchung technisches Anlagenkonto +++
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Umbuchung technisches Anlagenkonto' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20230001020057','20230001020937','20230001021520','20230001021522','20230001021524','20230001021636','20240001001827') 
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Umbuchung technisches Anlagenkonto' WHERE [SAP Company] IN ('4000') AND [Document No_] IN('20230001001349','20230001001351','20230001001353')
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Umbuchung ohne Auswirkung' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20230001023215') 
-- Umbuchung technisches Anlagenkonto --

UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Beleg+Storno' WHERE [SAP Company] IN ('2000') AND [Document No_] IN('20230001022197','20230001023213') -- Umbuchung CostUnit 100->C41

UPDATE [SAP Documents] SET [Posted]=1, [Comment]='reiner Ausgleichsbeleg' WHERE [SAP Company] IN ('1000') AND [Document No_] IN('20230001000234') -- 26.01.24 CSC18 über Zoom : "Die ZU-Belege sollten ja eigentlich garnicht in NAV verarbeitet werden, weil es reine Ausgleichsbelege in SAP sind."

-- Auslösung Innenauftrag zur Fehlerbeh. Saldenübert; Chris 12.02.24 +++
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='Auslösung Innenauftrag zur Fehlerbeh. Saldenübert; Chris 12.02.24' WHERE [SAP Company] IN ('2000') AND [Document No_] IN ('20220001018808','20220001018809','20220001018810','20220001018812','20220001018813','20220001018814','20220001018815','20220001018817') 
-- Auslösung Innenauftrag zur Fehlerbeh. Saldenübert; Chris 12.02.24 ---

-- 0-Werte können nicht in NAV gebucht werden; TMA 02.04.24 +++
UPDATE [SAP Documents] SET [Posted]=1, [Comment]='0-Werte können nicht in NAV gebucht werden; TMA 02.04.24' WHERE [SAP Company] IN ('2000') AND [Document No_] IN ('20240001003684','20240001003686','20240001003687','20240001003688','20240001003689','20240001003690') 
-- 0-Werte können nicht in NAV gebucht werden; TMA 02.04.24 ---

UPDATE [SAP Documents] SET [Posted]=1, [Last Error]=[Reversed Comment] WHERE [Reversed]=1
END
GO
