#Include "Rwmake.ch"
#Include "TopConn.ch"
#Include 'FWMVCDEF.CH'
#Include 'Protheus.ch'

/*/{Protheus.doc} REAFAT09
    Realiza Inclusão de registros na tabela ZZB
    @type User function  
    @author Natan Jorge
    @since 9/9/2025
    @params nTipo = 1 Apontamento de Produção - nTipo = 2 Documento de entrada
/*/ 
User Function REAFAT10(nTipo) 

    Local cChaveSD1   := ""
    Local cNewCod     := "" 
    Local cMsgComp    := "" 
    Local nTaxPerc    := 0
    Local nTaxVal     := 0
    Local nDifPercent := 0
    Local nUltPrec    := 0
    Local nMarkup     := 0
    Local cTabAtu     := AllTrim(GETNEWPAR("ZZ_TABPRC", "001"))
	Local cCodProd     := ""
    DEFAULT nTipo      := 1 
    DEFAULT aParam     := {"99","01"}
	
    If Select("SX6") == 0 
		RpcClearEnv() 
		RpcSetType(3) //Informa ao Server que a RPC nÃ£o consumirÃ¡ licenÃ§as
		RpcSetEnv(aParam[1],aParam[2],"","","COM") //aPar[01] Empresa, aPar[02] Filial
		SetModulo("SIGACOM","COM")
		InitPublic()
        SetsDefault()
	Endif

    If nTipo == 1
        dbSelectArea("SC2")
        SC2->(dbSetOrder(1))
        dbSelectArea("ZZB")
        ZZB->(dbSetOrder(1))                      

        cNumNR := SUBSTRING(M->D3_OP, 1, TamSX3("C2_NUM")[1])

        IF SC2->(dbSeek(AllTrim(cNumNR)))
            While (SC2->(!EoF()) .And. SC2->C2_NUM == cNumOrd)
                
                cCodProd += IIF(!EMPTY(cCodProd), ",", "") + SC2->C2_PRODUTO

                SC2->(dbSkip())
            EndDo

            cCodProd := "'"+ StrTran(cCodProd, ",", "','")+"'"

        ENDIF
        If EMPTY(cCodProd)
            cCodProd := M->D3_COD
        Endif 

        nCustRepos := ValTpPrc(cCodProd)
        nPrcVend   := PrecoVend(cCodProd)

        If nPrcVend > 0
            nDifPercent := ((nCustRepos - nPrcVend) / nPrcVend) * 100

            nDifPercent := IIF(nDifPercent < 0, nDifPercent*-1 ,nDifPercent) // limite superior/inferior

            nMarkup := Posicione('SB1', 1, FWxFilial('SB1') + M->D3_COD, 'B1_ZZMARK')
            nMarkup := IIF(nMarkup < 0, nMarkup*-1 ,nMarkup) // limite superior/inferior
        EndIf

        If (nDifPercent > nMarkup)  

            nValDiv := nPrcVend - nCustRepos
            nValDiv := IIF(nValDiv < 0, nValDiv*-1 ,nValDiv) // limite superior/inferior

            ZZB->(RecLock("ZZB", .T.))

                ZZB->ZZB_FILIAL := FWxFilial("ZZB")
                ZZB->ZZB_ITEM   := SUBSTRING(M->D3_OP, TamSX3("C2_NUM")[1]+1, TamSX3("C2_ITEM")[1])
                ZZB->ZZB_COD    := cNewCod
                ZZB->ZZB_PROD   := M->D3_COD      
                ZZB->ZZB_CFOR   := M->D3_CODFOR
                ZZB->ZZB_LJFORN := M->D3_LOJAFOR
                ZZB->ZZB_ORIG   := AllTrim(Str(nTipo))
                ZZB->ZZB_NF     := ""
                ZZB->ZZB_SERIE  := ""
                ZZB->ZZB_NROP   := cNumNR
                ZZB->ZZB_DATA   := DATE()
                ZZB->ZZB_IMP    := 0
                ZZB->ZZB_PRECO  := nValDiv
                ZZB->ZZB_STATUS := "1"

            ZZB->(MsUnlock())

            cMsgComp += "Registro de número: " + Alltrim(cNewCod) + " - Produto: " + Alltrim(M->D3_COD)
        EndIf
    Else 
        cChaveSD1 := SF1->F1_FILIAL+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA
        
        dbSelectArea("SD1")
        SD1->(dbSetOrder(1))
        dbSelectArea("ZZB")
        ZZB->(dbSetOrder(1))               // Índice 1 de ZZB: Filial+Código (chave primária)
    
        if SD1->(dbSeek(cChaveSD1))
            while !SD1->(eof()) .and. SD1->D1_FILIAL+SD1->D1_DOC+SD1->D1_SERIE+SD1->D1_FORNECE+SD1->D1_LOJA == cChaveSD1
    
                nDifPercent := 0
                nUltPrec    := 0
                nMarkup     := 0

                If DA1->(DbSeek(FWxFilial('DA1') + cTabAtu + SD1->D1_COD ))  
                    nUltPrec := DA1->DA1_PRCVEN
                Else
                    nUltPrec := 0
                Endif 

                If nUltPrec > 0
                    nDifPercent := ((SD1->D1_VUNIT - nUltPrec) / nUltPrec) * 100

                    nDifPercent := IIF(nDifPercent < 0, nDifPercent*-1 ,nDifPercent) // limite superior/inferior

                    nMarkup := Posicione('SB1', 1, FWxFilial('SB1') + SD1->D1_COD, 'B1_ZZMARK')
                    nMarkup := IIF(nMarkup < 0, nMarkup*-1 ,nMarkup) // limite superior/inferior
                EndIf

                If (nDifPercent > nMarkup)  

                    cNewCod := GeraCodg()

                    ZZB->(RecLock("ZZB", .T.))

                    ZZB->ZZB_FILIAL  := FWxFilial("ZZB")          // Filial do registro (mesma filial da NF)
                    ZZB->ZZB_ITEM    := SD1->D1_ITEM             // Item
                    ZZB->ZZB_COD     := cNewCod                  // Código sequencial único do registro ZZB
                    ZZB->ZZB_PROD    := SD1->D1_COD              // Código do produto do item (mesmo de SD1)
                    ZZB->ZZB_CFOR    := SF1->F1_FORNECE          // Código do fornecedor (cabeçalho da NF)
                    ZZB->ZZB_LJFORN  := SF1->F1_LOJA             // Loja do fornecedor 
                    ZZB->ZZB_ORIG    := Alltrim(STR(nTipo))
                    ZZB->ZZB_NF      := SF1->F1_DOC              // Número da Nota Fiscal (documento)
                    ZZB->ZZB_SERIE   := SF1->F1_SERIE            // Série da Nota Fiscal
                    ZZB->ZZB_NROP    := ""                       // Número da Ordem de Produção (se houver)
                    ZZB->ZZB_DATA    := DATE()                   
                    // Calcular percentual de impostos sobre o valor do item
                    nTaxVal  := SD1->D1_VALICM + SD1->D1_VALIPI //* Alteração por solicitação da Beth onde paramos de utilizar Planilha Financeira - Dia 05/10/2025 
                    nTaxPerc := 0
                    IF SD1->D1_TOTAL > 0
                        nTaxPerc := ( nTaxVal / SD1->D1_TOTAL ) * 100
                    Endif
                    ZZB->ZZB_IMP    := nTaxPerc                  // Impostos (%) do item em relação ao total
                    ZZB->ZZB_PRECO  := SD1->D1_VUNIT             // Preço (valor total) do item da NF
                    ZZB->ZZB_STATUS := "1"                       // Status da Nota Fiscal (campo de SF1)
            
                    ZZB->(MsUnlock())
                    
                    cMsgComp += "Registro de número: " + Alltrim(cNewCod) + " - Produto: " + Alltrim(SD1->D1_COD)+CRLF

                    SD1->(DbSkip())
                Endif
            ENDDO
        Endif 

    Endif

    If !EMPTY(cMsgComp) 
        cMsgComp := "Registros incluídos com sucesso: " +CRLF+Replicate("*", 15)+CRLF+CRLF+cMsgComp
        U_REAFAT08(cMsgComp, "Log Processamento", 1, .F.) //! Tela do Log
    Endif

Return .T.

Static Function GeraCodg()
    
    Local cRet   := ""
    Local aDados := {}

    cQryAux := " SELECT ZZB.ZZB_COD " + CRLF
    cQryAux += " FROM " + RetSQLName("ZZB") + " ZZB " + CRLF
    cQryAux += " WHERE ZZB_FILIAL = " + ValToSQL(XFilial("ZZB")) + CRLF
    cQryAux += " ORDER BY ZZB_COD DESC " + CRLF
    cQryAux += " FETCH FIRST 1 ROWS ONLY " + CRLF

    aDados := QryArray(cQryAux)

    cRet := IIF(EMPTY(aDados), "000001", SOMA1(aDados[1][1]))

Return cRet

Static Function PrecoVend(cCodProd) //	Calcular Custo de Reposição do Produto Acabado 

    Local cTabAtu  :=  AllTrim(GETNEWPAR("ZZ_TABPRC", "001"))
    Local cFilProd :=  AllTrim(GETNEWPAR("ZZ_PROENT", "PA"))  
    Local nRet     := 0
    Local aDados   := {}
    
    DEFAULT cCodProd := ""

    cQryAux := " SELECT DA1_PRCVEN    " + CRLF
    cQryAux += " FROM  " + RetSQLName("DA1") + " DA1  " +  CRLF
    cQryAux += " INNER JOIN " + RetSQLName("SB1") + " SB1 ON B1_COD = DA1_CODPRO  AND SB1.B1_FILIAL = '" + FWxFilial("SB1") + "' AND SB1.D_E_L_E_T_ = ' ' " + CRLF
    cQryAux += " WHERE DA1_CODPRO IN ("+cCodProd+") " + CRLF
    cQryAux += "   AND DA1_CODTAB = '"+cTabAtu+"'   " + CRLF
    cQryAux += "   AND DA1_FILIAL = '"+FWxFilial("DA1")+"'   " + CRLF
    cQryAux += "   AND B1_TIPO = '"+cFilProd+"'  " + CRLF
    cQryAux += "   AND DA1.D_E_L_E_T_ = ' ' " + CRLF

    nRet := IIF(EMPTY(aDados), 0, aDados[1][1])

Return nRet

Static Function ValTpPrc(cCodProd) //	Calcular Custo de Reposição do Produto Acabado 

    Local cFilProd :=  AllTrim(GETNEWPAR("ZZ_FTPPRO", "PA,PI")) //! Filtro tipo produtos que não entram
    Local nRet     := 0
    Local aDados   := {}
    
    DEFAULT cCodProd := ""

    cFilProd := "'"+ StrTran(cFilProd, ",", "','")+"'"

    cQryAux := " SELECT SUM(D1_VUNIT) AS SOMATOT    " + CRLF
    cQryAux += " FROM  " + RetSQLName("SD1") + " SD1  " +  CRLF
    cQryAux += " INNER JOIN " + RetSQLName("SB1") + " SB1 ON B1_COD = D1_COD  AND SB1.B1_FILIAL = '" + FWxFilial("SB1") + "' AND SB1.D_E_L_E_T_ = ' ' " + CRLF
    cQryAux += " WHERE D1_COD IN ("+cCodProd+") " + CRLF
    cQryAux += "   AND D1_FILIAL = '"+FWxFilial("SD1")+"'   " + CRLF
    cQryAux += "   AND B1_TIPO NOT IN ("+cFilProd+")   " + CRLF
    cQryAux += "   AND SD1.D_E_L_E_T_ = ' ' " + CRLF

    nRet := IIF(EMPTY(aDados), 0, aDados[1][1])

Return nRet
