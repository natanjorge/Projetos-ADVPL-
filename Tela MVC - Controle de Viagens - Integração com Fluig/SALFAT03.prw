#Include "Totvs.ch"
#Include "FWMVCDef.ch"

/*/{Protheus.doc} SALFAT03
	Rotina de validação ao clicar em confirmar na tela Programação de Viagens x Coletas
	@author Natan Jorge
	@since 10/06/2025
	@type User function
/*/
User Function SALFAT03(nChamada)

    Local oModel      := FWModelActive()
    Local nOpc        := oModel:GetOperation()
    Local lRet        := .T.
    Local cMsg        := "A coleta pode ser salva sem detalhamento. Nenhum produto adicionado na(s) linha(s) do grid de pedidos de compras: "
    Local nLinhaFilho := 0
    Local cPedVen     := ""
    Local cProgViag   := ""

    Private oModelPai   := oModel:GetModel('ZZAMASTER')
    Private oModelFilho := oModel:GetModel('ZZBDETAIL')
    Private oModelNeto  := oModel:GetModel('ZZCDETAIL')

    DEFAULT nChamada  := 1

    cPedVen     := oModelPai:GetValue("ZZA_PV")
    cProgViag   := oModelPai:GetValue("ZZA_PROG")

    if nChamada == 1
        //Percorre as informações da grid dos filhos
        For nLinhaFilho := 1 To oModelFilho:Length()
            oModelFilho:GoLine(nLinhaFilho)
            If oModelNeto:Length() == 0
                cMsg += CRLF+"Sequência - "+oModelFilho:GetValue("ZZB_SEQUEN") 
                lRet := .F.
            EndIf
        Next

        If !lRet
            U_SALFAT05(cMsg, "SALFAT03 - Coleta sem produto adicionado", 1, .F.)
        Else 
            //Se for Inclusão
            If nOpc == MODEL_OPERATION_INSERT .OR. nOpc == MODEL_OPERATION_UPDATE 
                DbSelectArea('SC5')
                SC5->(DbSetOrder(1))  
                
                If SC5->(DbSeek(FWxFilial('SC5') + cPedVen))
                    RecLock('SC5', .F.)
                        SC5->C5_ZZPROGV := cProgViag
                    SC5->(MsUnlock())
                EndIf
                
                GeraPedCom(cProgViag)

            //Se for Alteração
            ElseIf nOpc == MODEL_OPERATION_UPDATE
                RecLock('ZZ1', .F.)
                    ZZ1_DESC := cDescri
                ZZ1->(MsUnlock())
                
                ExibeHelp("Atenção", "Alteração realizada!", "TOTVS")

            //Se for Exclusão
            ElseIf nOpc == MODEL_OPERATION_DELETE
                RecLock('ZZ1', .F.)
                    DbDelete()
                ZZ1->(MsUnlock())
                
                ExibeHelp("Atenção", "Exclusão realizada!", "TOTVS")

            EndIf
        EndIf
    EndIf
Return lRet


Static Function GeraPedCom(cProgViag)
    Local oModel      := FWModelActive()
    Local oModelFilho := oModel:GetModel('ZZBDETAIL')
    Local oModelNeto  := oModel:GetModel('ZZCDETAIL')
    Local nLinhaFilho := 0
    Local nLinhaNeto  := 0
    Local cNumPC      := ""
    Local aCabec      := {}
    Local aItens      := {}
    Local aLinha      := {}
    //Local aOpcSuc     := {}
    Local cMenComplet := ""
    Local cMsgPC      := "***** PEDIDOS GERADOS COM SUCESSO *****"
    Local cMsgErro    := "***** PEDIDOS NÃO GERADOS *****"
    Local lVldError   := .F.
    Local lVldSuc     := .F.

    //Percorre as informações da grid dos filhos
    For nLinhaFilho := 1 To oModelFilho:Length()
        oModelFilho:GoLine(nLinhaFilho)
        
        cNumPC := oModelFilho:GetValue("ZZB_NUM")

        If EMPTY(cNumPC) //! Ainda não foi criado o pedido de compras

            cNumPC := U_SALFT03A() 

            aCabec := {}
            aadd(aCabec,{"C7_EMISSAO" , Date()})
            aadd(aCabec,{"C7_FILIAL"  , xFilial("SC7")})
            aadd(aCabec,{"C7_NUM"     , cNumPC})
            aadd(aCabec,{"C7_FORNECE" , oModelFilho:GetValue("ZZB_FORNEC")})
            aadd(aCabec,{"C7_LOJA"    , oModelFilho:GetValue("ZZB_LOJA")})
            aadd(aCabec,{"C7_COND"    , "001"})
            aadd(aCabec,{"C7_FILENT"  , xFilial("SC7")})//oModelFilho:GetValue("ZZB_FILDES")
            aadd(aCabec,{"C7_ZZPROGV" , cProgViag})
            
            aItens :={}
            For nLinhaNeto := 1 To oModelNeto:Length() //! Percorre as informações da grid dos netos
                oModelNeto:GoLine(nLinhaNeto)

                aLinha := {}
                aAdd(aLinha,{"C7_ITEM"	  ,"0001"				,Nil})			
                aadd(aLinha,{"C7_PRODUTO" , alltrim(oModelNeto:GetValue("ZZC_PROD"))  ,Nil})
                aadd(aLinha,{"C7_QUANT"   , oModelNeto:GetValue("ZZC_QTDCOL") ,Nil})
                aadd(aLinha,{"C7_DATPRF"  , dDatabase                         ,Nil})
                aadd(aLinha,{"C7_PRECO"   , 1                                 ,Nil})
                aadd(aLinha,{"C7_TES"     , "   "                             ,Nil})
                aadd(aLinha,{"C7_LOCAL"   , "2 "                              ,Nil})
                aadd(aItens,aLinha)
            Next

			If !EMPTY(aItens) .and. !EMPTY(aCabec)

                SetFunName("MATA121")

                lMsHelpAuto    := .T.
                lMsErroAuto    := .F.
                lAutoErrNoFile := .T.

                Begin Transaction

                    lPointCriaB2 := .F.
                    //MATA120(01,aCabec,aItens,03)
	                MSExecAuto({| u,v,x| MATA121(u,v,x)}, aCabec, aItens, 3)

                    If lMsErroAuto
                        MostraErro()
                        cMsgErro += CRLF + "Linha "+alltrim(STR(nLinhaFilho))+" - Não foi possível gerar pedido de compra!"
                        lVldError := .T.
                    Else    
                        cMsgPC += CRLF + "Linha "+alltrim(STR(nLinhaFilho))+" - Pedido de compra nº "+ alltrim(cNumPC)+ " foi gerado com sucesso!"
                        lVldSuc := .T.
                        oModelFilho:SetValue("ZZB_NUM", cNumPC)

                        DbSelectArea('ZZB')
                        ZZB->(DbSetOrder(2))                          
                        If ZZB->(DbSeek(FWxFilial('ZZB') + cProgViag + cNumPC))
                            RecLock('ZZB', .F.)
                                ZZB->ZZB_NUM := cNumPC
                            ZZB->(MsUnlock())
                        EndIf

                        //AADD(aOpcSuc, nLinhaFilho)
                    EndIf		
                End Transaction

	   		EndIf
        EndIf
    Next

    If lVldError
        cMenComplet += cMsgErro + CRLF
    Endif 
    If lVldSuc
        cMenComplet += cMsgPC
    Endif 

    If !EMPTY(cMenComplet)      
        U_SALFAT05(cMenComplet, "SALFAT03 - Geração Pedido de Compra", 1, .F.)
    Endif 

    If !EMPTY(aOpcSuc)       
        U_SALFAT08(aOpcSuc) // Função que executa uma requisição Post de dataset do fluig para inicio de solicitação 
    Endif 

Return

// Função para retornar o próximo número de programa 
User Function SALFT03A()

    Local cQryAux   := ""
    Local aDados    := {}
	Local cNumRet   := ""

    cQryAux := " SELECT TOP 1 C7_NUM"
    cQryAux += " FROM " + RetSQLName("SC7") + " SC7 " + CRLF
    cQryAux += " WHERE " + CRLF
    cQryAux += "     	 C7_FILIAL = '" + FWxFilial("SC7") + "' " + CRLF
    cQryAux += " ORDER BY C7_NUM DESC " + CRLF

    aDados := QryArray(cQryAux)
     
	If EMPTY(aDados)
		cNumRet := "000001"
    Else
	    cNumRet := SOMA1(aDados[1][1])
	EndIf

Return cNumRet
