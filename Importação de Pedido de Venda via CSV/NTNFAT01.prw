#Include "TOTVS.ch"
#Include "TOPCONN.ch"

/*/{Protheus.doc} NTNFAT01
    Importa pedidos de venda a partir de arquivos CSV em uma pasta (pares *_header.csv e *_itens.csv),
    validando dados e gerando log de sucesso/erro ao final.
    @type User Function
    @author Natan Jorge
    @since 15/02/2026
    @version 1.0.0
/*/
User Function NTNFAT01()
    Local cDirIni     := GetTempPath()
    Local cTipArq     := "CSV files (*.csv) "
    Local cTitulo     := "Seleção de Pasta para Importar os Pedidos de Vendas"
    Local cMenLog     := ""
    Local lSalvar     := .F.
    Local nCont       := 0
    Local aArquivos   := {}
    Local aImportacao := {}

    Private cPasta    := ""
    Private cMsgPC    := ""
    Private cMsgError := ""

    DEFAULT aParam := {"99","01"}

    If Select("SX6") == 0 
		RpcClearEnv() 
		RpcSetType(3) //Informa ao Server que a RPC não consumira licenças
		RpcSetEnv(aParam[1],aParam[2],"","","COM")
		SetModulo("SIGACOM","COM")
		InitPublic()
        SetsDefault()
	Endif

    //Chama a função para buscar arquivos
    cPasta := tFileDialog(cTipArq, cTitulo, , cDirIni, lSalvar, GETF_RETDIRECTORY)
    
    If Empty(cPasta)
        FWALERTINFO("Nenhuma pasta foi selecionada!", "Atenção")
        Return
    EndIf
    
    // Busca todos os arquivos CSV na pasta
    aArquivos := Directory(cPasta + "*.csv")
    
    If EMPTY(aArquivos)
        FWALERTINFO("Nenhum arquivo CSV encontrado na pasta selecionada!", "Atenção")
        Return
    EndIf
    
    // Identifica os pares de arquivos (header + itens)
    aImportacao := BuscaPares(aArquivos)    
    If EMPTY(aImportacao)
        FWALERTINFO("Nenhum par de arquivos (header/itens) encontrado na pasta!" + CRLF + ;
                    "Padrão esperado: *_header.csv e *_itens.csv", "Atenção")
        Return
    EndIf
    
    // Confirma a importação
    If !MsgYesNo("Foram encontrados " + cValToChar(Len(aImportacao)) + " arquivo(s) para importação." + CRLF + ;
                 "Deseja continuar?", "Confirmar Importação")
        Return
    EndIf
    
    // Processa cada par de arquivos
    For nCont := 1 To Len(aImportacao)
        If aImportacao[nCont][2] // Caso tenha cabec e item 
            ProcImport(aImportacao[nCont][1])
        Endif 
    Next
    
    if !EMPTY(cMsgError)
        cMenLog := "********** PEDIDOS NÃO GERADOS **********" + CRLF + CRLF + cMsgError + CRLF + "*********************************" + CRLF
    endif

    if !EMPTY(cMsgPC)
        cMenLog += "********** PEDIDOS GERADOS COM SUCESSO **********" + CRLF + cMsgPC + CRLF + "*********************************" + CRLF
    endif

    if !EMPTY(cMenLog)
        U_NTNFAT02(cMenLog, "Log Importação PV", 1, .F.)
    endif
    
Return

/*/{Protheus.doc} BuscaPares
    Identifica prefixos de importação e valida se existem pares completos de arquivos (HEADER/ITENS).
    @type Static Function
    @author Natan Jorge
    @since 15/02/2026
    @version 1.0.0
    @param aArquivos, Array, Retorno do Directory() com nomes de arquivos CSV
    @return aPrefixos, Array, { {cPrefixo, lParCompleto}, ... }
/*/
Static Function BuscaPares(aArquivos)
    Local aPrefixos := {}
    Local cNomeArq  := ""
    Local cPrefixo  := ""
    Local nPos      := 0
    Local nCont
    
    // Primeiro, identifica todos os prefixos baseados nos arquivos _header.csv
    For nCont := 1 To Len(aArquivos)
        cNomeArq := Upper(AllTrim(aArquivos[nCont][1]))
        
        If "_HEADER.CSV" $ cNomeArq
            cPrefixo := StrTran(cNomeArq, "_HEADER.CSV", "")
        Elseif "_ITENS.CSV" $ cNomeArq
            cPrefixo := StrTran(cNomeArq, "_ITENS.CSV", "")
        EndIf

        nPos := aScan(aPrefixos,{|x| x[1] == cPrefixo })
        If nPos == 0
            aAdd(aPrefixos, {cPrefixo, .F.})
        Else    
            aPrefixos[nPos][2] := .T.
        EndIf
    Next nCont
    
    // Monta o retorno apenas com os pares completos
    For nCont := 1 To Len(aPrefixos)
        If !aPrefixos[nCont][2] // Se não tiver par completo
            cMsgError += "Prefixo '" + AllTrim(aPrefixos[nCont][1]) + "' não possui par completo (header/itens)" + CRLF
        EndIf
    Next nCont
    
Return aPrefixos

/*/{Protheus.doc} ProcImport
    Lê os CSVs de header/itens de um prefixo, agrupa itens por PedidoExterno e aciona a inclusão no Protheus.
    @type Static Function
    @author Natan Jorge
    @since 15/02/2026
    @version 1.0.0
    @param cChaveArq, Character, Prefixo base do arquivo (ex: "EXT-2026-0001")
/*/
Static Function ProcImport(cChaveArq)
    Local aHeader  := {}
    Local aItens   := {}
    Local aItAtual := {}
    Local nContCab := 0
    Local nContIt  := 0
    
    // Lê o arquivo de cabeçalho 
    aHeader := LeArqCSV(cChaveArq, "_HEADER")
    
    If EMPTY(aHeader)
        ConOut("ERRO: Nenhum registro encontrado no arquivo header")
        Return
    EndIf
    
    // Lê o arquivo de itens
    aItens := LeArqCSV(cChaveArq, "_ITENS")
    
    If EMPTY(aItens)
        ConOut("ERRO: Nenhum registro encontrado no arquivo de itens")
        Return
    EndIf
    
    // Organiza os dados: agrupa itens por pedido
    For nContCab := 1 To Len(aHeader)
        For nContIt := 1 To Len(aItens)
            If AllTrim(aHeader[nContCab][1]) == AllTrim(aItens[nContIt][1]) // PedidoExterno
                aAdd(aItAtual, aItens[nContIt]) // Adiciona o item ao pedido
            EndIf
        Next
        IncluiPedido(aHeader[nContCab], aItAtual) // Processa cada pedido
        aItAtual := {}
    Next 

Return

/*/{Protheus.doc} LeArqCSV
    Lê um CSV (header ou itens) da pasta selecionada, ignora cabeçalho e retorna linhas separadas por ';'.
    @type Static Function
    @author Natan Jorge
    @since 15/02/2026
    @version 1.0.0
    @param cArquivo, Character, Prefixo base do arquivo
    @param cTipo, Character, "_HEADER" ou "_ITENS"
    @return aRetorno, Array, Linhas do CSV separadas em colunas
/*/
Static Function LeArqCSV(cArquivo, cTipo)
    Local aRetorno := {}
    Local aLinha   := {}
    Local cLinha   := ""
    Local nHandle  := 0
    Local nLinha   := 0
    
    cArquivo := AllTrim(cPasta) + cArquivo + cTipo + ".CSV"

    ConOut("Lendo arquivo: " + cArquivo)
    nHandle := FT_FUse(cArquivo)
    
    If nHandle == -1
        ConOut("ERRO: Não foi possí­vel abrir o arquivo: " + cArquivo)
        Return aRetorno
    EndIf
    
    FT_FGoTop()
    FT_FSkip()     // Pula o cabeçalho
    nLinha++
    
    While !FT_FEof()
        cLinha := FT_FReadLn()
        nLinha++
        
        If Empty(cLinha)
            FT_FSkip()
            Loop
        EndIf
        
        aLinha := Separa(cLinha, ";", .T.)
        
        // Valida a quantidade de colunas esperadas
        If cTipo == "_HEADER"
            If Len(aLinha) < 9
                ConOut("AVISO: Linha " + cValToChar(nLinha) + " com menos colunas que o esperado (9)")
                FT_FSkip()
                Loop
            EndIf
        ElseIf cTipo == "_ITENS"
            If Len(aLinha) < 6
                ConOut("AVISO: Linha " + cValToChar(nLinha) + " com menos colunas que o esperado (6)")
                FT_FSkip()
                Loop
            EndIf
        EndIf
        
        aAdd(aRetorno, aLinha)
        
        FT_FSkip()
    EndDo
    
    FT_FUse()
    
    ConOut("Total de registros lidos: " + cTipo + " - "+ cValToChar(Len(aRetorno)))
    
Return aRetorno

/*/{Protheus.doc} IncluiPedido
    Valida dados do pedido (cabeçalho e itens), monta arrays do ExecAuto e gera PV via MATA410.
    @type Static Function
    @author Natan Jorge
    @since 15/02/2026
    @version 1.0.0
    @param aHeader, Array, Linha do header (colunas do CSV)
    @param aItens, Array, Linhas de itens relacionadas ao pedido
/*/
Static Function IncluiPedido(aHeader, aItens)
    Local aCab := {}
    Local aItensAuto := {}
    Local cPedExt := ""
    Private lMsErroAuto := .F.
    
    cPedExt := AllTrim(aHeader[1])

    // 1. VALIDA OS DADOS ANTES
    If !ValidDados(aHeader, aItens, cPedExt)
        Return
    EndIf
    
    aCab := MontaCabec(aHeader, cPedExt)
    
    aItensAuto := MontaItens(aItens)
    
    If Len(aItensAuto) == 0
        ConOut("ERRO: Nenhum item válido para o pedido " + cPedExt)
        cMsgError += cPedExt +" | REJEITADO - Todos os itens inválidos"
        Return
    EndIf
    
    // 4. EXECUTA INCLUSÃO
    ConOut("Incluindo pedido " + cPedExt + " com " + cValToChar(Len(aItensAuto)) + " itens...")
    
    MSExecAuto({|a, b, c, d| MATA410(a, b, c, d)}, aCab, aItensAuto, 3, .F.)

    // 5. TRATA RESULTADO
    If lMsErroAuto
        ConOut("ERRO: Falha ao incluir o pedido " + cPedExt)
        cMsgError += "Pedido Externo: " + cPedExt +" | Falha ao incluir o pedido" + CRLF
        MostraErro()
    Else
        ConOut("SUCESSO: Pedido " + cPedExt + " incluído - Número: " + SC5->C5_NUM)
        cMsgPC += "Pedido Externo: " + cPedExt+" - Pedido de venda nº "+ alltrim(SC5->C5_NUM)+ " foi gerado com sucesso!" + CRLF 
    EndIf
    
Return

/*/{Protheus.doc} ValidDados
    Valida obrigatoriedade de campos, existência do cliente (SA1) e unicidade do Pedido Externo (SC5).
    @type Static Function
    @author Natan Jorge
    @since 15/02/2026
    @version 1.0.0
    @param aHeader, Array, Dados do cabeçalho
    @param aItens, Array, Dados dos itens
    @param cPedExt, Character, Identificador do pedido externo
/*/
Static Function ValidDados(aHeader, aItens, cPedExt)
    Local cCliente := PadR(AllTrim(aHeader[4]), TamSX3("C5_CLIENTE")[1])
    Local cLoja    := PadR(AllTrim(aHeader[5]), TamSX3("C5_LOJACLI")[1])
    Local nCont    := 0
    Local cCamposCab  := {"Pedido Externo", "Filial", "Emissão", "Cliente", "Loja", "CondPag", "Tabela de Preco", ""/*Vendedor*/, ""/*Obs*/} //* Vazio nao considera
    Local cCamposItm  := {"Pedido Externo", "Item",   "Produto", "Quantidade", "Preço Unitário", ""/*Desconto*/} //* Vazio nao considera
    
    DbSelectArea("SA1")
    SA1->(DbSetOrder(1))

    For nCont := 1 to LEN(aHeader)
        If Empty(aHeader[nCont]) .AND. !Empty(cCamposCab[nCont])
            cMsgError += "O campo " + cCamposCab[nCont] + " está vazio. "
            Return .F.
        Endif 
    Next     

    For nCont := 1 to LEN(aItens)
        If Empty(aItens[nCont]) .AND. !Empty(cCamposItm[nCont])
            cMsgError += "O campo " + cCamposItm[nCont] + " está vazio. "
            Return .F.
        Endif 
    Next     

    If !BuscPedEx(cPedExt) 
        ConOut("O pedido externo de nº " + AllTrim(cPedExt) + " já está cadastrado no sistema.")
        cMsgError += "O pedido externo de nº " + AllTrim(cPedExt) + " já está cadastrado no sistema. " + CRLF + CRLF
        Return .F.
    Endif 
    
    If !SA1->(DbSeek(xFilial("SA1") + cCliente + cLoja))
        ConOut("ERRO: Cliente " + AllTrim(cCliente) + "|" + AllTrim(cLoja) + " não encontrado | Pedido externo de nº " + AllTrim(cPedExt))
        cMsgError += "Cliente " + AllTrim(cCliente) + "|" + AllTrim(cLoja) + " não encontrado | Pedido externo de nº " + AllTrim(cPedExt) + CRLF + CRLF
        Return .F.
    Endif

Return .T.

/*/{Protheus.doc} MontaCabec
    Monta o array de cabeçalho do pedido para MSExecAuto/MATA410, incluindo C5_ZZPEXT se existir.
    @type Static Function
    @author Natan Jorge
    @since 15/02/2026
    @version 1.0.0
    @param aHeader, Array, Dados do CSV header
    @param cPedExt, Character, Pedido externo
/*/
Static Function MontaCabec(aHeader, cPedExt)
    Local aCab := {}
    Local cObs := ""
    Local cDoc := GetSxeNum("SC5", "C5_NUM")
    
    cObs := AllTrim(aHeader[9])

    // Monta array do cabeçalho
    aadd(aCab, {"C5_NUM"     , cDoc                                                 , Nil})
    aAdd(aCab, {"C5_FILIAL"  , PadR(AllTrim(aHeader[2]), TamSX3("C5_FILIAL")[1])    , Nil})
    aAdd(aCab, {"C5_TIPO"    , "N"                                                  , Nil}) // Tipo Normal
    aAdd(aCab, {"C5_CLIENTE" , PadR(AllTrim(aHeader[4]), TamSX3("C5_CLIENTE")[1])   , Nil})
    aAdd(aCab, {"C5_LOJACLI" , PadR(AllTrim(aHeader[5]), TamSX3("C5_LOJACLI")[1])   , Nil})
    aAdd(aCab, {"C5_CONDPAG" , PadR(AllTrim(aHeader[6]), TamSX3("C5_CONDPAG")[1])   , Nil})
    aAdd(aCab, {"C5_TABELA"  , PadR(AllTrim(aHeader[7]), TamSX3("C5_TABELA")[1])    , Nil})
    aAdd(aCab, {"C5_VEND1"   , PadR(AllTrim(aHeader[8]), TamSX3("C5_VEND1")[1])     , Nil})
    aAdd(aCab, {"C5_EMISSAO" , DATE()/*CToD(AllTrim(aHeader[3]))*/                            , Nil})
    
    If !Empty(cObs)
        aAdd(aCab, {"C5_MENNOTA", cObs, Nil})
    EndIf
    
    // Adiciona campo de pedido externo se existir
    If SC5->(FieldPos("C5_ZZPEXT")) > 0
        aAdd(aCab, {"C5_ZZPEXT", PadR(cPedExt, TamSX3("C5_ZZPEXT")[1]), Nil})
    EndIf
        
Return aCab

/*/{Protheus.doc} MontaItens
    Converte linhas do CSV de itens para o array do ExecAuto (SC6), calculando valores e TES.
    @type Static Function
    @author Natan Jorge
    @since 15/02/2026
    @version 1.0.0
    @param aItens, Array, Linhas do CSV itens
    @return aItensAuto, Array, Itens no padrão MSExecAuto para SC6
/*/
Static Function MontaItens(aItens)
    Local aItensAuto := {}
    Local aItem      := {}
    Local cProduto   := ""
    Local nQuant     := 0
    Local nPrcUnit   := 0
    Local nDesconto  := 0
    Local nCont      := 0
    Local cTES       := ""
        
    DbSelectArea("SB1")
    SB1->(DbSetOrder(1)) // B1_FILIAL + B1_COD
    
    For nCont := 1 To Len(aItens)
        
        cProduto  := PadR(AllTrim(aItens[nCont][3]), TamSX3("C6_PRODUTO")[1])
        nQuant    := Val(StrTran(AllTrim(aItens[nCont][4]), ",", "."))
        nPrcUnit  := Val(StrTran(AllTrim(aItens[nCont][5]), ",", "."))
        nDesconto := Val(StrTran(AllTrim(aItens[nCont][6]), ",", "."))

        cTES := Posicione("SB1", 1, xFilial("SB1") + cProduto, "B1_TS")        // Busca TES padrão do produto

        If Empty(cTES)
            cTES := "501" // TES padrão caso não tenha no cadastro
        EndIf

        // Monta o item
        aItem := {} 
        aAdd(aItem, {"C6_ITEM"    , StrZero(Val(aItens[nCont][2]), 2), Nil})
        aAdd(aItem, {"C6_PRODUTO" , Alltrim(cProduto)                , Nil})
        aAdd(aItem, {"C6_QTDVEN"  , nQuant                           , Nil})
        aAdd(aItem, {"C6_PRCVEN"  , nPrcUnit                         , Nil})
        aAdd(aItem, {"C6_VALOR"   , nQuant * nPrcUnit                , Nil})
        aAdd(aItem, {"C6_TES"     , cTES                             , Nil})
        
        If nDesconto > 0
            aAdd(aItem, {"C6_DESCONT", nDesconto, Nil})
        EndIf
        
        aAdd(aItensAuto, aItem)

    Next nCont
    
Return aItensAuto

/*/{Protheus.doc} BuscPedEx
    Verifica se já existe pedido no SC5 com o mesmo C5_ZZPEXT (pedido externo).
    @type Static Function
    @author Natan Jorge
    @since 15/02/2026
    @version 1.0.0
    @param cPedExt, Character, Pedido externo para validação
    @return lLivre, Logical, .T. se NÃO existe (pode incluir); .F. se já existe
/*/
Static Function BuscPedEx(cPedExt)//Função para retornar ultima versão do orçamento
    Local cAlias := GetNextAlias()
    Local cQuery := ''
    Local lRet   := .T.
    
    cQuery := " SELECT C5_ZZPEXT " + CRLF
    cQuery += " FROM "+ RetSqlName('SC5') + ' SC5' + CRLF
    cQuery += " WHERE C5_ZZPEXT = '" + Alltrim(cPedExt) + "' " + CRLF
    cQuery += " AND SC5.D_E_L_E_T_ = ' '" + CRLF

    TCQUERY cQuery ALIAS &(cAlias) NEW

    &(cAlias)->(DbGoTop())
    
    if &(cAlias)->(!EOF())
        lRet := .F. // Se existir registro com este PedExt retorna false
    endif
        
    &(cAlias)->(DbCloseArea())

Return lRet
