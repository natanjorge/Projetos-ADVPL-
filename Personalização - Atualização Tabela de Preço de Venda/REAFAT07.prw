#Include "Protheus.ch"
#include "rwmake.ch"
#include "TbiConn.ch"

/*/{Protheus.doc} REAFAT07
    Realiza a consulta para Tela para Marcação de Produtos buscando os registros salvos na ZZB 
    @type User function  
    @author Natan Jorge
    @since 9/9/2025
/*/ 
User Function REAFAT07(lPesquisa)

	Local nCont         := 0
	Local aDadValid     := {}
    Local cQryAux   	:= ""
	Local cQtdReg       := ""
	Local cOrigemOp     := ""

	DEFAULT aParam      := {"99", "01"}
	DEFAULT lPesquisa   := .T.

 	cQtdReg       := AllTrim(GETNEWPAR("ZZ_QTDREG", "50"))

	cQryAux := " SELECT " + CRLF
	cQryAux += "        ZZB.ZZB_PROD, " + CRLF
	cQryAux += "        SB1.B1_DESC, " + CRLF
	cQryAux += "        SA2.A2_COD, SA2.A2_LOJA, SA2.A2_NOME, " + CRLF
	cQryAux += "        ZZB.ZZB_ORIG, ZZB.ZZB_IMP, ZZB.ZZB_PRECO, ZZB.ZZB_STATUS, ZZB.ZZB_DATA,  " + CRLF
	cQryAux += "        CASE " + CRLF
	cQryAux += "           WHEN ZZB.ZZB_ORIG = 1 " + CRLF
	cQryAux += "              THEN ZZB.ZZB_NROP " + CRLF
	cQryAux += "           WHEN ZZB.ZZB_ORIG = 2 " + CRLF
	cQryAux += "              THEN TRIM(ZZB.ZZB_NF) || '-' || ZZB.ZZB_SERIE " + CRLF
	cQryAux += "        END AS DOC_REF, " + CRLF
	cQryAux += "        ZZB.R_E_C_N_O_ AS RECNUM, ZZB_ITEM " + CRLF
	cQryAux += "   FROM " + RetSQLName("ZZB") + " ZZB " + CRLF
	cQryAux += "   LEFT JOIN " + RetSQLName("SB1") + " SB1 " + CRLF
	cQryAux += "          ON SB1.B1_COD    = ZZB.ZZB_PROD " + CRLF
	cQryAux += "         AND SB1.D_E_L_E_T_ = ' ' " + CRLF
	cQryAux += "         AND SB1.B1_FILIAL  = '" + FWxFilial("SB1") + "' " + CRLF
	cQryAux += "   LEFT JOIN " + RetSQLName("SA2") + " SA2 " + CRLF
	cQryAux += "          ON SA2.A2_COD     = ZZB.ZZB_CFOR " + CRLF
	cQryAux += "         AND SA2.A2_LOJA    = ZZB.ZZB_LJFORN " + CRLF
	cQryAux += "         AND SA2.D_E_L_E_T_ = ' ' " + CRLF
	cQryAux += "         AND SA2.A2_FILIAL  = '" + FWxFilial("SA2") + "' " + CRLF
	cQryAux += "  WHERE ZZB.D_E_L_E_T_  = ' ' " + CRLF
	cQryAux += "    AND ZZB.ZZB_FILIAL  = '" + FWxFilial("ZZB") + "' " + CRLF
	If lPesquisa	

		If !Empty(cCmbProd)
			cQryAux += "    AND ZZB.ZZB_PROD = '" + cCmbProd + "' " + CRLF
		EndIf

		If !Empty(cCmbData)
			cQryAux += "    AND ZZB.ZZB_DATA = '" + Dtos(cCmbData) + "' " + CRLF
		EndIf

		If !Empty(cCmbFornec) .And. !Empty(cCmbLoja)
			cQryAux += "    AND ZZB.ZZB_CFOR   = '" + cCmbFornec + "' " + CRLF
			cQryAux += "    AND ZZB.ZZB_LJFORN = '" + cCmbLoja   + "' " + CRLF
		EndIf

		cOrigemOp := Substring(cCmbOrigem,1,1) 
		If cOrigemOp <> '3' .AND. !EMPTY(cOrigemOp) //! '1|2' =Todos, não precisa filtrar
			cQryAux += "    AND ZZB_ORIG = '" + cOrigemOp + "' " + CRLF
		Endif 

		If !Empty(cCmbCod)
			cQryAux += "    AND ZZB.ZZB_COD = '" + cCmbCod + "' " + CRLF
		EndIf

		If !Empty(cCmbStatus) .AND. Substring(cCmbStatus,1,1) <> "4" //! 4=Todos, não precisa filtrar
			cQryAux += "    AND ZZB.ZZB_STATUS = '" + Substring(cCmbStatus,1,1) + "' " + CRLF
		EndIf
	Endif 
	cQryAux += "  ORDER BY ZZB_DATA DESC, RECNUM DESC " + CRLF
	cQryAux += "  FETCH FIRST " + cQtdReg + " ROWS ONLY " + CRLF

    aDadValid := QryArray(cQryAux)
     
	If lPesquisa

		DbSelectArea(cAliasTmp)
		(cAliasTmp)->(DbGoTop())
			
		While !(cAliasTmp)->(EoF())
			DbDelete()
			(cAliasTmp)->(DbSkip())
		EndDo
		
		(cAliasTmp)->(DbGoBottom())
		(cAliasTmp)->(DbGoTop())
	Endif 

	For nCont := 1 To LEN(aDadValid)      
		If RecLock(cAliasTmp, .T.)            
			(cAliasTmp)->OK        := Space(2) // inicia desmarcado
			(cAliasTmp)->CODPRDO   := aDadValid[nCont][1] // Código do Produto
			(cAliasTmp)->DESCPROD  := aDadValid[nCont][2] // Descrição do Produto
			(cAliasTmp)->FORNEC    := aDadValid[nCont][3] // Fornecedor (código)
			(cAliasTmp)->LOJAFORN  := aDadValid[nCont][4] // Loja do Fornecedor
			(cAliasTmp)->NOMEFORN  := aDadValid[nCont][5] // Nome do Fornecedor
			(cAliasTmp)->ORIGEM    := aDadValid[nCont][6] // Origem "1=Apontamento de Produção", "2=Documento de Entrada"
			(cAliasTmp)->DIVERG    := Alltrim(Transform(aDadValid[nCont][7],"@E 999,999,999.99")) // Divergência
			(cAliasTmp)->PRE_CALC  := Alltrim(Transform(aDadValid[nCont][8],"@E 999,999,999.99")) // Preço Calculado
			(cAliasTmp)->STATUS    := aDadValid[nCont][9] // "1=Pendente", "2=Integrado"
			(cAliasTmp)->DATAEMI   := Transform(STOD(aDadValid[nCont][10]), "@R 99/99/9999" )
			(cAliasTmp)->NUMDOC    := aDadValid[nCont][11] // NumDoc
			(cAliasTmp)->RECNUM    := aDadValid[nCont][12] // Recno
			(cAliasTmp)->ITEM      := aDadValid[nCont][13] // Item
			(cAliasTmp)->(MsUnlock())
		EndIf
	Next

	(cAliasTmp)->(DbGoBottom())
	(cAliasTmp)->(DbGoTop())
	If lPesquisa
		oMarkBrowse:Refresh(.T.)
	Endif 

Return
