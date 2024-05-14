/*
DATA: 14/05/2024
NOME DO JOB: [TI] - RETIRADA BLACKLIST
AUTOR: JOÃO LUIZ - TI
SOLICITANTE: MELHORIA
MOTIVO: Estavam solicitando retirada agendada da BlackList mas não tinha nenhum processo de retirada de tal.

*/

DECLARE @DT_ATUAL					DATE; 
SET		@DT_ATUAL				=	GETDATE();

DECLARE @CONSULTA_CASOS			NVARCHAR(MAX);

SET @DT_ATUAL = GETDATE();-- adicionando a data na variavel para verificar o dia

-- ==================================================================================================================================

DROP TABLE IF EXISTS #RETIRAR_CASOS; -- criando uma tabela para apresentar no e-mail quais casos foram retirados!
SELECT 
			DISTINCT 
			c.CONTRATO_TIT	AS CONTRATO, 
			R.DATA_RETIRADA	AS DT_RETIRADA ,
			C.CREDOR		AS CREDOR_RETIRADA, 
			R.OBS			AS OBS
INTO		#RETIRAR_CASOS
FROM		CONTRATOS_INATIVADOS_BLACKLIST	C
LEFT JOIN	RETIRADA_BLACKlIST				R 
ON			C.CONTRATO_TIT					=	R.CONTRATO_TIT
WHERE		C.CREDOR						=	R.CREDOR
AND			R.DATA_RETIRADA					=	CAST(GETDATE() as date);

--SELECT * FROM #RETIRAR_CASOS

-- ==================================================================================================================================
--select * from RETIRADA_BLACKlIST 

-- Verifica se há registros na tabela com dt_retirada igual a @DT_ATUAL
IF 
	exists (SELECT DATA_RETIRADA 
			FROM RETIRADA_BLACKlIST
			WHERE CONVERT(DATE, DATA_RETIRADA)	= @DT_ATUAL) 
	and exists
	(
	SELECT		C.CONTRATO_TIT
	FROM		CONTRATOS_INATIVADOS_BLACKLIST	C
	LEFT JOIN	RETIRADA_BLACKlIST				R 
	ON			C.CONTRATO_TIT					= R.CONTRATO_TIT
	WHERE		C.CREDOR						= R.CREDOR
	AND			R.DATA_RETIRADA					= CAST(GETDATE() as date))
BEGIN

	-- tirando casos da blackList que constam na data de retirada
    DELETE		C
	--SELECT *
    FROM		CONTRATOS_INATIVADOS_BLACKLIST	C
    INNER JOIN	RETIRADA_BLACKlIST				R 
	ON			C.CONTRATO_TIT					= R.CONTRATO_TIT
    WHERE		C.CREDOR						= R.CREDOR
	AND			R.DATA_RETIRADA					= CAST(GETDATE() AS DATE)


	-- preparando o e-mail de casos retirados!
    DECLARE @para VARCHAR(1000) = '';
    DECLARE @assunto VARCHAR(1000) = 'Contratos retirados da blackList';
    DECLARE @mensagem VARCHAR(MAX) = '';

    SET @para += 'joao.reis@novaquest.com.br;';
    SET @para += 'vinicius@novaquest.com.br;';
	SET @para += 'micheli@novaquest.com.br';
	SET @para += 'sistemas@novaquest.com.br';

    SET @mensagem += '<style type="text/css">';
    SET @mensagem += 'table, th, td {border: 1px solid black; border-collapse: collapse; padding: 0 5px 0 5px;}';
    SET @mensagem += 'p {font-size: 12pt;}';
    SET @mensagem += '</style>';
    SET @mensagem += '<style type="text/css">';
    SET @mensagem += 'table, th, td {border: 1px solid black; border-collapse: collapse; padding: 0 5px 0 5px;}';
    SET @mensagem += 'th {background-color: #581845;color:white}'; -- Estilo para o cabeçalho
    SET @mensagem += 'p {font-size: 12pt;}';
    SET @mensagem += '</style>';

    SET @mensagem += '<h3 style="text-align: center;">Contratos retirados da BlackList</h5>';
    SET @mensagem += '</br>';
    SET @mensagem += '<table align="center" style="text-align: center;" >';
    SET @mensagem += '<tr>';
    SET @mensagem += '<th>CONTRATO</th>';
    SET @mensagem += '<th>DATA DA RETIRADA</th>';
    SET @mensagem += '<th>CREDOR</th>';
	SET @mensagem += '<th>Motivo</th>';
    SET @mensagem += '</tr>';
    SET @mensagem += (SELECT
                        '<tr><td>' + CONVERT(NVARCHAR(MAX), CONTRATO) + '</td>' +
                        '<td>' + CONVERT(NVARCHAR(MAX), DT_RETIRADA, 103) + '</td>' +
						'<td>' + CONVERT(NVARCHAR(MAX), CREDOR_RETIRADA) + '</td>' +
                        '<td>' + CONVERT(NVARCHAR(MAX), OBS) + '</td></tr>'
                     FROM #RETIRAR_CASOS
                     FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)');

    SET @mensagem += '</table>';
    SET @mensagem += '</br>';
    SET @mensagem += '<h5 style="text-align: center;">Nome do job: [TI] - Retirada BlakList: </h5>';

    EXEC MSDB.DBO.SP_SEND_DBMAIL
        @recipients = @para,
        @subject = @assunto,
        @body = @mensagem,
        @body_format = 'HTML';
END
else
	begin
		PRINT 'NÃO HÁ CASOS'
END



/*
