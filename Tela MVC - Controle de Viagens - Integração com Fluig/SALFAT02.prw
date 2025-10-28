#Include "Totvs.ch"
#Include "FWMVCDef.ch"
 
Static cTitulo 	 := "Programação de Viagens x Coletas"
Static cTabPai   := "ZZA"
Static cTabFilho := "ZZB"
Static cTabNeto  := "ZZC"

/*/{Protheus.doc} SALFAT02
	Rotina responsável pelo vizualização da ZZA, ZZB e ZZC - Programação de Viagens x Coletas.
	@author Natan Jorge
    @since 10/06/2025
	@type User function
/*/
User Function SALFAT02()
    Local aArea   := GetArea()
    Local oBrowse
    Private aRotina := {}
 
    //Definicao do menu
    aRotina := MenuDef()
 
    //Instanciando o browse
    oBrowse := FWMBrowse():New()
    oBrowse:SetAlias(cTabPai)
    oBrowse:SetDescription(cTitulo)
    oBrowse:DisableDetails()
 
    oBrowse:AddLegend( "ZZA->ZZA_STAT == '1'", "GREEN",  "Em Aberto"  )
    oBrowse:AddLegend( "ZZA->ZZA_STAT == '2'", "ORANGE", "Parcialmente enviado"  )
    oBrowse:AddLegend( "ZZA->ZZA_STAT == '3'", "RED",    "Finalizado" )

    //Ativa a Browse
    oBrowse:Activate()
 
    RestArea(aArea)
Return Nil
 
Static Function MenuDef()
    Local aRotina := {}
 
    //Adicionando opcoes do menu
    ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.SALFAT02" OPERATION 1 ACCESS 0
    ADD OPTION aRotina TITLE "Incluir"    ACTION "VIEWDEF.SALFAT02" OPERATION 3 ACCESS 0
    ADD OPTION aRotina TITLE "Alterar"    ACTION "VIEWDEF.SALFAT02" OPERATION 4 ACCESS 0
    ADD OPTION aRotina TITLE "Excluir"    ACTION "VIEWDEF.SALFAT02" OPERATION 5 ACCESS 0
    ADD OPTION aRotina TITLE "Legenda"    ACTION "U_SALFT02B()"     OPERATION 9 ACCESS 0

Return aRotina
 
Static Function ModelDef()
    Local oStruPai   := FWFormStruct(1, cTabPai)
    Local oStruFilho := FWFormStruct(1, cTabFilho)
    Local oStruNeto  := FWFormStruct(1, cTabNeto)
    Local aRelFilho  := {}
    Local aRelNeto   := {}
    Local oModel
    Local bPre      := Nil
    Local bPos      := Nil
    //Local bCommit   := Nil
    //Local bCancel   := Nil
    Local aGatilhos := {}
    Local nCont     := 0
    Local lTotaliz  := .F.
    Local bVldCom := {|| u_SALFAT03()} //Validação ao clicar no Confirmar
    Local bVldCan := {|| u_SALFAT03(2)} //Função chamadao ao cancelar
     
    //! Campo de Status
    oStruFilho:AddField( AllTrim(''), AllTrim(''), 'ZZB_LEGEND', 'C', 50, 0, NIL, NIL, NIL, NIL, { || GetCorSt() }, NIL, NIL, .T. )  
                      // [01] C Titulo do campo, [02] C ToolTip do campo, [03] C identificador (ID) do Field, [04] C Tipo do campo, [05] N Tamanho do campo, [06] N Decimal do campo, [07] B Code-block de validação do campo, [08] B Code-block de validação When do campo, [09] A Lista de valores permitido do campo, [10] L Indica se o campo tem preenchimento obrigatório, [11] B Code-block de inicializacao do campo, [12] L Indica se trata de um campo chave, [13] L Indica se o campo pode receber valor em uma operação de update., [14] L Indica se o campo é virtual


    //! Gatilhos - oStruPai
    aAdd(aGatilhos, FWStruTriggger("ZZA_PV",  "ZZA_COMP","SA1->A1_ZZCOMP", .T., "SA1", 1, "xFilial('SA1')+M->ZZA_CLI+M->ZZA_LOJA", "", "01"))
    aAdd(aGatilhos, FWStruTriggger("ZZA_CLI", "ZZA_COMP","SA1->A1_ZZCOMP", .T., "SA1", 1, "xFilial('SA1')+M->ZZA_CLI+M->ZZA_LOJA", "", "01"))
    aAdd(aGatilhos, FWStruTriggger("ZZA_LOJA","ZZA_COMP","SA1->A1_ZZCOMP", .T., "SA1", 1, "xFilial('SA1')+M->ZZA_CLI+M->ZZA_LOJA", "", "01"))

    For nCont := 1 To Len(aGatilhos)     //! oStruPai
        oStruPai:AddTrigger(aGatilhos[nCont][01], aGatilhos[nCont][02], aGatilhos[nCont][03], aGatilhos[nCont][04])
    Next //*                   Campo Origem,         Campo Destino,        Código de validação,  Código de execução
    aGatilhos := {}

    //! Gatilhos - oStruFilho
    aAdd(aGatilhos, FWStruTriggger("ZZB_FORNEC", "ZZB_NOMFOR", "SA2->A2_NOME",    .T., "SA2", 1, "xFilial('SA2')+M->ZZB_FORNEC+M->ZZB_LOJA", "", "01"))
    aAdd(aGatilhos, FWStruTriggger("ZZB_LOJA",   "ZZB_NOMFOR", "SA2->A2_NOME",    .T., "SA2", 1, "xFilial('SA2')+M->ZZB_FORNEC+M->ZZB_LOJA", "", "01"))
    aAdd(aGatilhos, FWStruTriggger("ZZB_MOTORI", "ZZB_AJUD",   "DA4->DA4_AJUDA1", .T., "DA4", 1, "xFilial('DA4')+M->ZZB_MOTORI",             "", "01"))
    
    For nCont := 1 To Len(aGatilhos)
        oStruFilho:AddTrigger(aGatilhos[nCont][01], aGatilhos[nCont][02], aGatilhos[nCont][03], aGatilhos[nCont][04])
    Next //*                   Campo Origem,         Campo Destino,        Código de validação,  Código de execução
    aGatilhos := {}
    
    //! Gatilhos - oStruNeto
    aAdd(aGatilhos, FWStruTriggger("ZZC_QTDORI",  "ZZC_QTPEN", "U_SALFAT2A(M->ZZC_QTDORI, M->ZZC_QTDCOL,1)", .F., "",  0, "", "", "01"))
    aAdd(aGatilhos, FWStruTriggger("ZZC_QTDCOL",  "ZZC_QTPEN", "U_SALFAT2A(M->ZZC_QTDORI, M->ZZC_QTDCOL,2)", .F., "",  0, "", "", "01"))
    aAdd(aGatilhos, FWStruTriggger("ZZC_PROD",    "ZZC_PRODES", "SB1->B1_DESC", .T., "SB1", 1, "xFilial('SB1')+M->ZZC_PROD",  "", "01"))

    For nCont := 1 To Len(aGatilhos)
        oStruNeto:AddTrigger(aGatilhos[nCont][01], aGatilhos[nCont][02], aGatilhos[nCont][03], aGatilhos[nCont][04])
    Next //*                   Campo Origem,         Campo Destino,        Código de validação,  Código de execução

    //Cria o modelo de dados para cadastro SALFT2M
    oModel := MPFormModel():New("SALFT2M", bPre, bPos, bVldCom, bVldCan)
    oModel:AddFields(cTabPai+"MASTER", /*cOwner*/, oStruPai)
    oModel:AddGrid("ZZBDETAIL",cTabPai+"MASTER",oStruFilho,/*bLinePre*/, /*bLinePost*/,/*bPre - Grid Inteiro*/,/*bPos - Grid Inteiro*/,/*bLoad - Carga do modelo manualmente*/)
    oModel:AddGrid("ZZCDETAIL","ZZBDETAIL",oStruNeto,/*bLinePre*/,/*bLinePost*/,/*bPre - Grid Inteiro*/,/*bPos - Grid Inteiro*/,/*bLoad - Carga do modelo manualmente*/)
    
    // Definir chave primária adequada para cada tabela
    oModel:GetModel(cTabPai+"MASTER"):SetPrimaryKey({cTabPai+"_FILIAL", cTabPai+"_PROG"})

    //! oStruPai - Inicializador Padrão
    oStruPai:SetProperty('ZZA_PROG', MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, 'U_SALFT02A()'))  
    oStruPai:SetProperty('ZZA_DATA', MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, 'Date()'))  
    //! oStruFilho - Inicializador Padrão
    oStruFilho:SetProperty('ZZB_STATUS', MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, '1'))  
    
    //Fazendo o relacionamento (pai e filho)
    oStruFilho:SetProperty("ZZB_PROG", MODEL_FIELD_OBRIGAT, .F.)
    aAdd(aRelFilho, {"ZZB_FILIAL", "FWxFilial('ZZB')"} )
    aAdd(aRelFilho, {"ZZB_PROG", cTabPai+"_PROG"})
    oModel:SetRelation("ZZBDETAIL", aRelFilho, ZZB->(IndexKey(1)))
  
    //Fazendo o relacionamento (filho e neto)
    aAdd(aRelNeto, {"ZZC_FILIAL", "FWxFilial('ZZC')"} )
    aAdd(aRelNeto, {"ZZC_PROG", "ZZB_PROG"})
    aAdd(aRelNeto, {"ZZC_ORIG", "ZZB_SEQUEN"})
    oModel:SetRelation("ZZCDETAIL", aRelNeto, ZZC->(IndexKey(2)))
 
    //Definindo campos unicos da linha
    oModel:GetModel("ZZBDETAIL"):SetUniqueLine({'ZZB_SEQUEN'})
    //oModel:GetModel("ZZCDETAIL"):SetUniqueLine({'ZZC_SEQ'})
 
    // Adicionar totalizador apenas se o campo ZZC_QTPEN existir
    If oStruNeto:HasField('ZZC_QTPEN') .AND. lTotaliz
        oModel:AddCalc('TOT_SALDO', 'ZZBDETAIL', 'ZZCDETAIL', 'ZZC_QTPEN', 'XX_TOTAL', 'SUM', , , "Saldo Total:" )
    EndIf

Return oModel

Static Function ViewDef()
    Local oModel     := FWLoadModel("SALFAT02")
    Local oStruPai   := FWFormStruct(2, cTabPai)
    Local oStruFilho := FWFormStruct(2, cTabFilho)
    Local oStruNeto  := FWFormStruct(2, cTabNeto)
    Local oView
    Local oStTot     := Nil
    Local lTotaliz   := .F.

    //! Campo de Status
    oStruFilho:AddField( 'ZZB_LEGEND', "00", AllTrim(''), AllTrim(''), { 'Legenda' }, 'C', '@BMP', NIL, '', .F., NIL, NIL, NIL, NIL, NIL, .T., NIL, NIL )  
                          // [01] C Nome do Campo, [02] C Ordem, [03] C Titulo do campo, [04] C Descricao do campo, [05] A Array com Help, [06] C Tipo do campo, [07] C Picture, [08] B Bloco de Picture Var, [09] C Consulta F3, [10] L Indica se o campo é alteravel, [11] C Pasta do campo, [12] C Agrupamento do campo, [13] A Lista de valores permitido do campo (Combo), [14] N Tamanho maximo da maior opção do combo, [15] C Inicializador de Browse, [16] L Indica se o campo é virtual, [17] C Picture Variavel, [18] L Indica pulo de linha após o campo

    //Define a consulta padrão  
    //*oStruPai
    oStruPai:SetProperty("ZZA_PV", MVC_VIEW_LOOKUP, {|| "ZZSC5"})
    oStruPai:SetProperty("ZZA_FILORI", MVC_VIEW_LOOKUP, {|| "FWSM0"})
    //*oStruFilho
    oStruFilho:SetProperty("ZZB_FILDES", MVC_VIEW_LOOKUP, {|| "FWSM0"})
    oStruFilho:SetProperty("ZZB_MOTORI", MVC_VIEW_LOOKUP, {|| "DA4"})
    //*oStruNeto
    oStruNeto:SetProperty("ZZC_PROD", MVC_VIEW_LOOKUP, {|| "ZZA01"})


    //Cria a visualizacao do cadastro
    oView := FWFormView():New()
    oView:SetModel(oModel)
    oView:AddField("VIEW_"+cTabPai, oStruPai, cTabPai+"MASTER")
    oView:AddGrid("VIEW_ZZB",  oStruFilho,  "ZZBDETAIL")
    oView:AddGrid("VIEW_ZZC",  oStruNeto,  "ZZCDETAIL")
    
    // Adicionar view do totalizador apenas se existir no model
    If oModel:GetModel('TOT_SALDO') != Nil .AND. lTotaliz
        oStTot := FWCalcStruct(oModel:GetModel('TOT_SALDO'))
        oView:AddField('VIEW_TOT', oStTot,'TOT_SALDO')
    EndIf

    //Partes da tela - Ajustar proporções
    If oStTot != Nil .AND. lTotaliz
        oView:CreateHorizontalBox("CABEC_PAI", 25)
        oView:CreateHorizontalBox("GRID_FILHO", 35)
        oView:CreateHorizontalBox("GRID_NETO", 30)
        oView:CreateHorizontalBox('TOTAL', 10)
        oView:SetOwnerView('VIEW_TOT','TOTAL')
    Else
        oView:CreateHorizontalBox("CABEC_PAI", 30)
        oView:CreateHorizontalBox("GRID_FILHO", 40)
        oView:CreateHorizontalBox("GRID_NETO", 30)
    EndIf

    oView:SetOwnerView("VIEW_"+cTabPai, "CABEC_PAI")
    oView:SetOwnerView("VIEW_ZZB", "GRID_FILHO")
    oView:SetOwnerView("VIEW_ZZC", "GRID_NETO")
 
    //Titulos
    oView:EnableTitleView("VIEW_"+cTabPai, "Dados da Programação")
    oView:EnableTitleView("VIEW_ZZB", "Coletas/Entregas")
    oView:EnableTitleView("VIEW_ZZC", "Detalhamento Coletas/Entregas")
 
    //Removendo Campos 
    oStruFilho:RemoveField("ZZB_PROG")
    oStruFilho:RemoveField("ZZB_STATUS")

    oStruNeto:RemoveField("ZZC_PROG")
    oStruNeto:RemoveField("ZZC_ORIG")

    //Adicionando campo incremental na grid
    oView:AddIncrementField("VIEW_ZZB", "ZZB_SEQUEN")
    oView:AddIncrementField("VIEW_ZZC", "ZZC_SEQ")

    //Adiciona botões no outras ações
    oView:addUserButton("Legenda - Status Coletas/Entregas", "MAGIC_BMP", {|| U_SALFT02B(2)}, , , , .T.)
 
Return oView

// Legendas das telas
User Function SALFT02B(nOpc)
    Local aLegenda := {}
    DEFAULT nOpc := 1

    If nOpc == 1
        aAdd(aLegenda,{"BR_VERDE",      "Em Aberto"})
        aAdd(aLegenda,{"BR_VERMELHO",   "Finalizado"})

        BrwLegenda("Status", "Status Coleta", aLegenda)
    Else
        aAdd(aLegenda,{"BR_BRANCO",     "Pendente"})
        aAdd(aLegenda,{"BR_AZUL",       "Enviado para o Fluig"})
        aAdd(aLegenda,{"BR_VERDE",      "Iniciado"})
        aAdd(aLegenda,{"BR_VERMELHO",   "Finalizado"})
        aAdd(aLegenda,{"BR_CINZA",      "Cancelado"})

        BrwLegenda("Status", "Status Fluig", aLegenda)
    Endif 

Return

// Função para validar a cor da legenda
Static Function GetCorSt()
    Local oModel := FWModelActive()
    Local cRet   := ""
    Local nOpc   := oModel:GetOperation()
    Local cStats := ""

    If nOpc == 3   
        cRet := "BR_BRANCO" // 1=Pendente
        Return cRet 
    Else 
        cStats := ZZB->ZZB_STATUS
    endif 

    If cStats == "2" // 2=Iniciada
        cRet := "BR_VERDE"
    Elseif cStats == "3" // 3=Finalizado
        cRet := "BR_VERMELHO"
    Elseif cStats == "4" // 4=Cancelado
        cRet := "BR_CINZA"
    Else 
        cRet := "BR_BRANCO" // 1=Pendente
    Endif 

Return cRet 

// Função para validar a quantidade 
User Function SALFAT2A(nQtdOri, nQtdCol, nOpc)
    Local nRet   := 0
    Local oModel := FWModelActive()
    Local oModelNeto  := oModel:GetModel('ZZCDETAIL')
    DEFAULT nQtdOri := 0, nQtdCol := 0

    nRet := (nQtdOri - nQtdCol)
    if nRet < 0
        FwAlertInfo("Valor inválido!" +CRLF+ "A quantidade coletada não pode ser maior que a quantidade original do PV.", "TOTVS")
        nRet := nQtdOri
        If nOpc == 2
            oModelNeto:SetValue("ZZC_QTDCOL", 0)
        Endif 
    endif

Return nRet 

// Função para validar a quantidade 
User Function SALFAT2B()
    Local aArea      := GetArea()
    Local oModel     := FWModelActive()
    Local oModelPai  := oModel:GetModel('ZZAMASTER')
    Local cPedVen    := oModelPai:GetValue("ZZA_PV")
    Local cQryAux    := ""
    Local aDados     := {}
    Local lRet       := .F.

    Public __cCodProd  := ""
    Public __cDescProd := ""
    Public __cItemPv   := ""
    Public __nQuanti   := 0

    If !Empty(cPedVen)  

        cFiltro := fGeraFiltro()

        cQryAux := " SELECT C6_PRODUTO, B1_DESC, C6_ITEM, C6_QTDVEN "
        cQryAux += " FROM " + RetSQLName("SC6") + " SC6 " + CRLF
        cQryAux += " INNER JOIN " + RetSQLName("SB1") + " SB1 ON B1_FILIAL = '" + FWxFilial("SB1") + "' AND B1_COD = C6_PRODUTO AND SB1.D_E_L_E_T_ = ' ' " + CRLF
        cQryAux += " WHERE " + CRLF
        cQryAux += " 	 C6_FILIAL = '" + FWxFilial("SC6") + "' " + CRLF
        cQryAux += " AND C6_NUM = '" + cPedVen + "' " + CRLF
        if !EMPTY(cFiltro)
            cQryAux += " AND C6_ITEM NOT IN (" + cFiltro + ") " + CRLF
        endif 
        cQryAux += " AND SC6.D_E_L_E_T_ = ' ' " + CRLF
        cQryAux += " ORDER BY C6_PRODUTO DESC " + CRLF

        aDados := QryArray(cQryAux)

        nPosSel := U_SALFAT04(aDados, cPedVen) //! Tela seleção de produtos

        If !Empty(nPosSel) 
            __cCodProd  := aDados[nPosSel][1]
            __cDescProd := aDados[nPosSel][2]
            __cItemPv   := aDados[nPosSel][3]
            __nQuanti   := aDados[nPosSel][4]
            lRet := .T.
        Endif
    Else 
        FwAlertInfo("Informe o campo 'Número PV' no cabeçalho!", "TOTVS")
    Endif 

    //! Código percorrento todos os registros do grid e colocando um NOT LIKE na query 
    RestArea(aArea)

Return lRet

// Função para retornar o próximo número de programa 
User Function SALFT02A()

    Local cQryAux   := ""
    Local aDados    := {}
	Local cNumRet   := ""

    cQryAux := " SELECT TOP 1 ZZA_PROG"
    cQryAux += " FROM " + RetSQLName("ZZA") + " ZZA " + CRLF
    cQryAux += " WHERE " + CRLF
    cQryAux += "     	 ZZA_FILIAL = '" + FWxFilial("ZZA") + "' " + CRLF
    cQryAux += " ORDER BY ZZA_PROG DESC " + CRLF

    aDados := QryArray(cQryAux)
     
	If EMPTY(aDados)
		cNumRet := "000001"
    Else
	    cNumRet := SOMA1(aDados[1][1])
	EndIf

Return cNumRet


Static Function fGeraFiltro()
    Local aArea       := FWGetArea()
    Local oModel      := FWModelActive()
    Local oModelFilho := oModel:GetModel('ZZBDETAIL')
    Local oModelNeto  := oModel:GetModel('ZZCDETAIL')
    Local nLinhaFilho := 0
    Local nLinhaNeto  := 0
    Local nItemAtu    := ""
    Local cFiltro     := ""
    Local nLinFilBck  := oModelFilho:NLINE
    Local nLinNetBck  := oModelNeto:NLINE
 
    //Percorre as informações da grid dos filhos
    For nLinhaFilho := 1 To oModelFilho:Length()
        
        oModelFilho:GoLine(nLinhaFilho)
        //Percorre as informações da grid dos netos
        For nLinhaNeto := 1 To oModelNeto:Length()
            oModelNeto:GoLine(nLinhaNeto)
            nItemAtu := oModelNeto:GetValue("ZZC_ITEM")
            If !EMPTY(nItemAtu)
                If !EMPTY(cFiltro)
                    cFiltro += ", "
                Endif 
                cFiltro += "'"+ nItemAtu +"'"
            Endif
        Next

        //Volta pra linha 1 dos netos
        If oModelNeto:Length() > 0
            oModelNeto:GoLine(1)
        EndIf

    Next

    //Volta pra linha dos filhos
    If oModelFilho:Length() > 0
        oModelFilho:GoLine(nLinFilBck)
    EndIf

    //Volta pra linha dos netos
    If oModelNeto:Length() > 0
        oModelNeto:GoLine(nLinNetBck)
    EndIf

    FWRestArea(aArea)
Return cFiltro
