USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_BDOEmployee]    Script Date: 10.04.2024 14:31:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
/*
EXEC sp_BDOEmployee 1452
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_BDOEmployee]
  @No int = 0
AS
BEGIN
SELECT E.[No_]
     , [Persis No_]
     , [Last Name]
     , [First Name]
     , E.[Address]
     , [Post Code]
     , E.[City]
     , [Birth Date]
     , CASE WHEN [Gender]=1 THEN 1 ELSE 0 END [Gender F]
     , CASE WHEN [Gender]=2 THEN 1 ELSE 0 END [Gender M]
     , [Social Security No_]
     , [Married]
     , [Place of Birth]
     , COALESCE(N.[Description]+' ('+[Nationality Code]+')',[Nationality Code]) [Nationality]
     , B.[BIC Code]
     , B.[IBAN]
     , '2014-06-01'      [Employment Date]
     , [Employment Date] [Belong to Company Date]
     , [Job Title]
     , COALESCE(O.[Description],'')   [Occupation]
     , [Occupation Code]
     , CASE WHEN SUBSTRING(E.[Occupation Code],6,1) = '1' THEN 1 ELSE 0 END [OC2_1]
     , CASE WHEN SUBSTRING(E.[Occupation Code],6,1) = '2' THEN 1 ELSE 0 END [OC2_2]
     , CASE WHEN SUBSTRING(E.[Occupation Code],6,1) = '3' THEN 1 ELSE 0 END [OC2_3]
     , CASE WHEN SUBSTRING(E.[Occupation Code],6,1) = '4' THEN 1 ELSE 0 END [OC2_4]
     , CASE WHEN SUBSTRING(E.[Occupation Code],6,1) = '9' THEN 1 ELSE 0 END [OC2_9]
     , CASE WHEN SUBSTRING(E.[Occupation Code],7,1) = '1' THEN 1 ELSE 0 END [OC3_1]
     , CASE WHEN SUBSTRING(E.[Occupation Code],7,1) = '2' THEN 1 ELSE 0 END [OC3_2]
     , CASE WHEN SUBSTRING(E.[Occupation Code],7,1) = '3' THEN 1 ELSE 0 END [OC3_3]
     , CASE WHEN SUBSTRING(E.[Occupation Code],7,1) = '4' THEN 1 ELSE 0 END [OC3_4]
     , CASE WHEN SUBSTRING(E.[Occupation Code],7,1) = '5' THEN 1 ELSE 0 END [OC3_5]
     , CASE WHEN SUBSTRING(E.[Occupation Code],7,1) = '6' THEN 1 ELSE 0 END [OC3_6]
     , CASE WHEN SUBSTRING(E.[Occupation Code],7,1) = '9' THEN 1 ELSE 0 END [OC3_9]
     , CASE WHEN [Working Calendar Code] = '41' THEN 1 ELSE 0 END [Fulltime Job]
     , CASE WHEN [Working Calendar Code] = 'TZ' THEN 1 ELSE 0 END [Parttime Job]
     , COALESCE(DV1.[Name]+' ('+[Global Dimension 1 Code]+')','') [Cost center]
     , COALESCE(DV2.[Name]+' ('+[Global Dimension 2 Code]+')','') [Cost carrier]
     , [Temporary Termination Date]
     , CASE WHEN [Temporary Termination Date] = '1753-01-01' THEN 0 ELSE 1 END [Temporary Termination]
     , COALESCE(P.[Description]+' ('+[Persons Group Code]+')','') [Persons Group]
     , [Tax ID]
     , [Tax Office]
     , [Tax Class]
     , [Tax Factor]
     , CH.[String] [Church Tax Code]
     , SUBSTRING([Beitragsgruppe],1,1) [KV]
     , SUBSTRING([Beitragsgruppe],2,1) [RV]
     , SUBSTRING([Beitragsgruppe],3,1) [AV]
     , SUBSTRING([Beitragsgruppe],4,1) [PV]
     , COALESCE(HIC.[Name],'') [Health Insurance Company]
     , HIC.[KK-Betriebsnummer]
     , COALESCE(COALESCE(CASE WHEN LP4.[Pay Type No_] IS NULL THEN '' ELSE V.[BIC Code] END, CASE WHEN LP5.[Pay Type No_] IS NULL THEN '' ELSE K.[BIC Code] END),'') [VWL BIC Code]
     , COALESCE(COALESCE(CASE WHEN LP4.[Pay Type No_] IS NULL THEN '' ELSE V.[IBAN]     END, CASE WHEN LP5.[Pay Type No_] IS NULL THEN '' ELSE K.[IBAN]     END),'') [VWL IBAN]
     , COALESCE(COALESCE(CASE WHEN LP4.[Pay Type No_] IS NULL THEN '' ELSE V.[Receiver] END, CASE WHEN LP5.[Pay Type No_] IS NULL THEN '' ELSE K.[Receiver] END),'') [Receiver]
     , CASE WHEN LP5.[Pay Type No_] IS NULL THEN 'VWL' ELSE 'Pensionskasse' END [Sonder]
     , LP1.[Pay Type No_] [Pay Type 1 No_]
     , LP2.[Pay Type No_] [Pay Type 2 No_]
     , LP3.[Pay Type No_] [Pay Type 3 No_]
     , LP4.[Pay Type No_] [Pay Type 4 No_]
     , LP5.[Pay Type No_] [Pay Type 5 No_]
     , LPT.[Pay Type No_] [Pay Type TZ No_]
     , LP1.[Description] [Pay Type 1 Description]
     , LP2.[Description] [Pay Type 2 Description]
     , LP3.[Description] [Pay Type 3 Description]
     , LP4.[Description] [Pay Type 4 Description]
     , LP5.[Description] [Pay Type 5 Description]
     , LPT.[Description] [Pay Type TZ Description]
     , LP1.[Amount] [Pay Type 1 Amount]
     , LP2.[Amount] [Pay Type 2 Amount]
     , LP3.[Amount] [Pay Type 3 Amount]
     , LP4.[Amount] [Pay Type 4 Amount]
     , LP5.[Amount] [Pay Type 5 Amount]
     , LPT.[Value] [Pay Type TZ Amount]
     , COALESCE(COALESCE(CASE WHEN LP4.[Pay Type No_] IS NULL THEN '' ELSE V.[Purpose] END, CASE WHEN LP5.[Pay Type No_] IS NULL THEN '' ELSE K.[Purpose] END),'') [Purpose]
     , [PV-pfl_ zusätzlich]
     , [Child Tax Free Deduction]
  FROM [HRS$Employee] E
LEFT JOIN [HRS$Nationality] N ON E.[Nationality Code]= N.[Code]
LEFT JOIN [HRS$Employee Bankaccount] B ON B.[Employee No_] = E.[No_] AND B.[Code] = 'LG'
LEFT JOIN [HRS$Employee Bankaccount] V ON V.[Employee No_] = E.[No_] AND V.[Code] = 'VWL1'
LEFT JOIN [HRS$Employee Bankaccount] K ON K.[Employee No_] = E.[No_] AND K.[Code] = 'PENKA'
LEFT JOIN [HRS$Occupation] O ON O.[Code] = LEFT(E.[Occupation Code],5)
LEFT JOIN [HRS$Dimension Value] DV1 ON DV1.[Dimension Code]= 'KOSTENSTELLE' AND DV1.[Code] = [Global Dimension 1 Code]
LEFT JOIN [HRS$Dimension Value] DV2 ON DV2.[Dimension Code]= 'KOSTENTRÄGER' AND DV2.[Code] = [Global Dimension 2 Code]
LEFT JOIN [HRS$Persons Group] P ON P.[Code] = E.[Persons Group Code]
LEFT JOIN [dbo].[Split]('Evangelisch,Römisch-katholisch,Altkatholisch,Jüdisch,Israelitisch,Israelitisch Baden,Israelitisch Württemberg,Israelitisch Frankfurt,Israelitisch Hessen,Frei. Gem. Baden,Frei. Gem. Offenbach,Frei. Gem. Pfalz,Frei. Gem. Mainz,Frei. Gem. Alzey',',') CH ON CH.[Index] = [Church Tax Code]
LEFT JOIN [Health Insurance Company] HIC ON HIC.[No_] = [Health Insurance Company No_]
LEFT JOIN [HRS$Recurring Reg_ Journal Line] LP1 ON LP1.[Employee No_] = E.[No_] AND LP1.[Pay Type No_] = '1000' AND LP1.[Blocked] = 0
LEFT JOIN [HRS$Recurring Reg_ Journal Line] LP2 ON LP2.[Employee No_] = E.[No_] AND LP2.[Pay Type No_] = '6000' AND LP2.[Blocked] = 0 -- Sachbezug private KFZ-Nutzun
LEFT JOIN [HRS$Recurring Reg_ Journal Line] LP3 ON LP3.[Employee No_] = E.[No_] AND LP3.[Pay Type No_] = '5300' AND LP3.[Blocked] = 0 -- Job-Ticket
LEFT JOIN [HRS$Recurring Reg_ Journal Line] LP4 ON LP4.[Employee No_] = E.[No_] AND LP4.[Pay Type No_] = '7000' AND LP4.[Blocked] = 0 -- VWL
LEFT JOIN [HRS$Recurring Reg_ Journal Line] LP5 ON LP5.[Employee No_] = E.[No_] AND LP5.[Pay Type No_] = '7550' AND LP5.[Blocked] = 0 -- Umwandlung Pensionskasse
LEFT JOIN [HRS$Recurring Reg_ Journal Line] LPT ON LPT.[Employee No_] = E.[No_] AND LPT.[Pay Type No_] = '1020' AND LPT.[Blocked] = 0
LEFT JOIN [HRS$Recurring Reg_ Journal Line] LPZ ON LP5.[Employee No_] = E.[No_] AND LP5.[Pay Type No_] = '1020' AND LPZ.[Blocked] = 0
 WHERE (([Last Name] + ', ' + [First Name] IN ('Adali, Nejdet','Aenishänslin, Florian','Ahlert, Anne','Alazar, Azieb','Rosado Bailao, Filipa','Balaguera Duran, Ernesto Alfonso','Basinski, Yvonne','Bäumann, Franziska','Bendler, Martin','Benndorf, Nora','Bienengräber, Fabian','Biester, Marten','Bilgmann, Britta','Bilkay, Ayhan','Blume, Ivonne','Bomba, Ilona','Brown, Daniel','Carstea, Mariana','Celepci, Özkan','Danielczak, Thomas','De Giorgi, Kristina','Dreweke, Jennifer','Ebbers, Claudia','Erlemann, Manuela','Fischer, Benjamin','Flathmann, Julia','Földhazi, Marcel','Freude, Andrea','Fuhr, Johannes','Gencsoy, Hüseyin','Giner-Martinez, Juan Pedro','Giulietti, Elisabetta','Glaubauf, Anna-Katharina','Grötzschel, Claudia','Gussmann, Roland','Güttler, Diana','Hafenstein, Thorsten','Hahn, Philipp','Hahn, Maureen','Hanschmann, Lena','Heinz, Andreas','Hentschel-Garske, Sabrina','Heppekausen, Julia','Herzog, Rebekka','Hogertz, Carsten','Hoppe, Martin','Jansen, Britta Silke','Jonas, Sabrina','Just, Matthias','Keienburg, Lisa','Kipp, Stefan','Klasen, Sonja','Klässig, Julia','Knäpper, Inka','Koch, Christoffer','Kock, Sarah','Koervers, Maike','Krüger, Robert','Laabs, Mareike','Landsiedel, Julia','Lengersdorf, Markus','Lesniewski, Isabella','Liersch, Eva','Lindner, Fabian','Longerich, Regina','Lorenz, Olga','Luik, Jens','Menzel, Stephanie','Mika, Jan','Müller, Tina','Munkler, Daniela','Noe, Nadine Nicole','Oppenländer, Gerd','Péré, Jean','Petzl, Cora','Quint, Sarah-Elin','Rappika, Armin Manfred','Reimann, Michell Daniel','Reinik, Helene','Risters, Manuela','Sander, Andrea','Sareika, Amelie','Schmidt, Sebastian Martin','Schneider, Moritz','Schubert, Sandy','Schulmann, Daniel','Schulte, Katrin','Sciammarella, Stefanie','Sehan, Ebru','Sevindik, Serdar','Sosa Morales, Esther Maria','Stengel, Florian','Stuber, Peter Jens','Suhr, Martin','Talkas, Evangelis','Thielemann, Iris','Thomas, Ina-Verena','Tonndorf, Madeleine','Trendel, Eva','Vento, Nadia','von Wuthenau, Axel','Wapelhorst, Melanie','Wolff, Benjamin','Wünsch, Jana','Yildizdal, Oral','Zeuchner, Luisa') AND @No=0)
    OR @No = E.[No_])
   AND SYSTEM_USER = 'HRS\tma04'
   AND [Grounds for Term_ Code] = ''
ORDER BY    E.[No_]
END
GO
