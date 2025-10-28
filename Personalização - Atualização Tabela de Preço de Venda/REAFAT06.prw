//Bibliotecas
#Include "TOTVS.ch"
#Include "TopConn.ch"
#Include "FWMVCDef.ch"

/*/{Protheus.doc} REAFAT06
    Tela para Marcação de Produtos
    @type User function  
    @author Natan Jorge
    @since 9/9/2025
/*/ 
User Function REAFAT06()
    Local nLargBtn      := 50
    Local aArea         := GetArea()
    Local aCampos := {}
    Local oTempTable := Nil
    Local aColunas := {}
    Local cFontPad    := 'Tahoma'
    Private oFont14  := TFont():New(cFontPad,, -14)
    Private oFont14B := TFont():New(cFontPad,, -14,,.T.)
    Private oFont18  := TFont():New(cFontPad,, -18)
    Private oDlgMark
    Private oPanGrid
    Private oMarkBrowse
    Private oFontSubN   := TFont():New("Tahoma", , -20, , .T.)
    Private cAliasTmp := GetNextAlias()
    //Private aRotina   := MenuDef()
    //Tamanho da janela
    Private aTamanho := MsAdvSize()
    Private nJanLarg := aTamanho[5]
    Private nJanAltu := aTamanho[6]
    Private nRecMarc := 0
    Private oSayTitulo 

    //Status 
    Private oSayStatus
    Private cSayStatus := 'Status'
    Private oCmbStatus
    Private cCmbStatus := '4-Todos'
    Private aCmbStatus := {'1-Pendente', '2-Não Aprovado', '3-Integrado', '4-Todos'}
    //Fornecedor 
    Private oSayFornec
    Private cSayFornec := 'Fornecedor'
    Private oCmbFornec
    Private cCmbFornec := Space(TamSX3( 'A2_COD' )[1])
    //Loja Fornec
    Private oSayLoja
    Private cSayLoja   := 'Loja'
    Private oCmbLoja
    Private cCmbLoja   := Space(TamSX3( 'A2_LOJA' )[1])
    //Origem 
    Private oSayOrigem
    Private cSayOrigem := 'Origem'
    Private oCmbOrigem
    Private cCmbOrigem := '3-Ambos'
    Private aCmbOrigem :={'1-Apontamento de Produção', '2-Documento de Entrada', '3-Ambos'}
    //Cod 
    Private oSayCod
    Private cSayCod     := 'Cod'
    Private oCmbCod
    Private cCmbCod     := Space(TamSX3( 'ZZB_COD' )[1])
    //Prod 
    Private oSayProd
    Private cSayProd   := 'Produto'
    Private oCmbProd
    Private cCmbProd   := Space(TamSX3( 'B1_COD' )[1])
    //Data 
    Private oSayData
    Private cSayData   := 'Data'
    Private oCmbData
    Private cCmbData   := sToD("")

    DEFAULT aParam 	  := {"99","01"}

    If Select("SX6") == 0 
		RpcClearEnv() 
		RpcSetType(3) //Informa ao Server que a RPC nÃ£o consumirÃ¡ licenÃ§as
		RpcSetEnv(aParam[1],aParam[2],"","","COM") //aPar[01] Empresa, aPar[02] Filial
		SetModulo("SIGACOM","COM")
		InitPublic()
        SetsDefault()
	Endif

    //Adiciona as colunas que serão criadas na temporária
    aadd(aCampos, {'OK'       , 'C', 2 , 0}) // Flag para marcação
    aadd(aCampos, {'STATUS',    'C',  1, 0}) // Status  
    aadd(aCampos, {'ITEM'     , 'C',  4, 0}) // Item
    aadd(aCampos, {'CODPRDO'  , 'C', 15, 0}) // Produto
    aadd(aCampos, {'DESCPROD' , 'C', 40, 0}) // Descrição
    aadd(aCampos, {'FORNEC'   , 'C', 10, 0}) // Fornecedor  
    aadd(aCampos, {'LOJAFORN' , 'C', 2,  0}) // Loja Fornecedor  
    aadd(aCampos, {'NOMEFORN' , 'C', 30, 0}) // Nome Fornecedor  
    aadd(aCampos, {'ORIGEM'   , 'C', 1,  0}) // Origem (ex.: "Documento de Entrada" / "Apontamento de Produção")
    aadd(aCampos, {'NUMDOC'   , 'C', 15, 0}) // Numero do documento
    aadd(aCampos, {'RECNUM'   , 'N', 15, 0}) // Recno
    aadd(aCampos, {'DIVERG'   , 'C', 5 , 0}) // Divergência (ex.: 2,50 / -3,00)
    aadd(aCampos, {'PRE_CALC' , 'C', 12, 0}) // Preço Incluído (ex.: 20,00 / 30,00)
    aadd(aCampos, {'DATAEMI'  , 'C', 12, 0}) // Preço Final (ex.: 22,50 / 27,00)

    oTempTable:= FWTemporaryTable():New(cAliasTmp)
    oTempTable:SetFields( aCampos )
    oTempTable:Create()  
 
    Processa({|| U_REAFAT07(.F.)}, 'Processando...')
 
    aColunas := fCriaCols()
      
    DEFINE MSDIALOG oDlgMark TITLE 'Tela para Marcação de Produtos' FROM 000, 000  TO nJanAltu, nJanLarg  PIXEL

            //Criando a camada
        oFwLayer := FwLayer():New()
        oFwLayer:init(oDlgMark,.F.)
 
        //Adicionando 3 linhas, a de tÃ­tulo, a superior e a do calendÃ¡rio
        oFWLayer:addLine("TIT", 10, .F.)
        oFWLayer:addLine("COR", 90, .F.)
 
        //Adicionando as colunas das linhas
        oFWLayer:addCollumn("HEADERTEXT",   080, .T., "TIT")
        //oFWLayer:addCollumn("BLANKBTN",     020, .T., "TIT")
        oFWLayer:addCollumn("BTNSAIR",      020, .T., "TIT")
        oFWLayer:addCollumn("COLGRID",      100, .T., "COR")
 
        //Criando os paineis
        oPanHeader := oFWLayer:GetColPanel("HEADERTEXT", "TIT")
        oPanSair   := oFWLayer:GetColPanel("BTNSAIR",    "TIT")
        oPanGrid   := oFWLayer:GetColPanel("COLGRID",    "COR")

        //oSayTitulo := TSay():New(010, 030, {|| 'Produtos Testando'}, oPanHeader, "", oFontSubN,  , , , .T., RGB(031, 073, 125), , 500, 30, , , , , , .F., , )

        //Criando os botÃµes
        oBtnPesq := TButton():New(018, 600, "Pesquisar",   oPanHeader, {|| U_REAFAT07()},   nLargBtn, 018, , oFont14, , .T., , , , , , )
        oBtnSair := TButton():New(018, 001, "Cancelar",    oPanSair,   {|| oDlgMark:End()}, nLargBtn, 018, , oFont14, , .T., , , , , , )
        oBtnConf := TButton():New(018, 061, "Aprovar",     oPanSair,   {|| U_REAFT06A()},    nLargBtn, 018, , oFont14, , .T., , , , , , )
        oBtnConf:SetCSS("TButton { font: bold;     background-color: qlineargradient(x1: 0, y1: 0, x2: 0, y2: 1,stop: 0 #3DAFCC, stop: 1 #0D9CBF);    color: #FFFFFF;     border-width: 1px;     border-style: solid;     border-radius: 3px;     border-color: #369CB5; }TButton:focus {    padding:0px; outline-width:1px; outline-style:solid; outline-color: #51DAFC; outline-radius:3px; border-color:#369CB5;}TButton:hover {    color: #FFFFFF;     background-color : qlineargradient(x1: 0, y1: 0, x2: 0, y2: 1,stop: 0 #3DAFCC, stop: 1 #1188A6);    border-width: 1px;     border-style: solid;     border-radius: 3px;     border-color: #369CB5; }TButton:pressed {    color: #FFF;     background-color : qlineargradient(x1: 0, y1: 0, x2: 0, y2: 1,stop: 0 #1188A6, stop: 1 #3DAFCC);    border-width: 1px;     border-style: solid;     border-radius: 3px;     border-color: #369CB5; }TButton:disabled {    color: #FFFFFF;     background-color: #4CA0B5; }")
        oBtnReprv := TButton():New(018, 660, "Reprovar",   oPanHeader,  {|| U_REAFT06A(.F.)},   nLargBtn, 018, , oFont14, , .T., , , , , , )
        oBtnReprv:SetCSS("TButton { font: bold; background-color: qlineargradient(x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #E15B5B, stop: 1 #C43C3C); color: #FFFFFF; border-width: 1px; border-style: solid; border-radius: 3px; border-color: #B23A3A; } TButton:focus { padding:0px; outline-width:1px; outline-style:solid; outline-color: #F17B7B; outline-radius:3px; border-color:#B23A3A; } TButton:hover { color: #FFFFFF; background-color: qlineargradient(x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #E15B5B, stop: 1 #A93232); border-width: 1px; border-style: solid; border-radius: 3px; border-color: #B23A3A; } TButton:pressed { color: #FFF; background-color: qlineargradient(x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #A93232, stop: 1 #E15B5B); border-width: 1px; border-style: solid; border-radius: 3px; border-color: #B23A3A; } TButton:disabled { color: #FFFFFF; background-color: #D16A6A; }")

        //! Status
        nObjLinha := 8
        nObjColun := 20
        nObjLargu := 35
        nObjAltur := 20
        oSayStatus  := TSay():New(nObjLinha, nObjColun, {|| cSayStatus}, oPanHeader, /*cPicture*/, oFont14B, , , , .T. , /*nClrText*/, /*nClrBack*/, nObjLargu, nObjAltur, , , , , , /*lHTML*/)
 
        nObjLinha := 20
        nObjLargu := 60
        nObjAltur := 35
        oCmbStatus  := TComboBox():New(nObjLinha, nObjColun, {|u| Iif(PCount() > 0 , cCmbStatus := u, cCmbStatus)}, aCmbStatus, nObjLargu, nObjAltur, oPanHeader, , /*{|| fAtuCmb()}*/, /*bValid*/, /*nClrText*/, /*nClrBack*/, .T. , oFont14)
        oCmbStatus:SetHeight( nObjAltur ) 


        //! Fornecedor
        nObjLinha := 8
        nObjColun := 100
        nObjLargu := 50
        nObjAltur := 20
        oSayFornec  := TSay():New(nObjLinha, nObjColun, {|| cSayFornec}, oPanHeader, /*cPicture*/, oFont14B, , , , .T., /*nClrText*/, /*nClrBack*/, nObjLargu, nObjAltur, , , , , , /*lHTML*/)
  
        nObjLinha := 20
        nObjLargu := 60
        nObjAltur := 14
        lHasButton := .T. // Simbolo de lupa ao invés de interrogacao
        oCmbFornec := TGet():New(nObjLinha, nObjColun, {|u| Iif(PCount() > 0 , cCmbFornec := u, cCmbFornec)}, oPanHeader, nObjLargu, nObjAltur, /*cPict*/, /*bValid*/, /*nClrFore*/, /*nClrBack*/, oFont14, , , .T., /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/, /*uParam19*/, /*bChange*/, /*lReadOnly*/, /*lPassword*/, /*uParam23*/, /*cReadVar*/, /*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton)
        
        //oCmbFornec:cPlaceHold := 'Digite aqui um texto...'   //Texto que sera exibido no campo antes de ter conteudo
        oCmbFornec:cF3    := 'SA2' //Codigo da consulta padrao / F3 que sera habilitada
        oCmbFornec:SetCSS("TGet{ color: #000000; selection-background-color: #369CB5;    background-color: #FFFFFF;     padding-left: 3px;     padding-right: 3px;     border-top-left-radius:3px;    border-bottom-left-radius:3px;    border: 1px solid #C5C9CA;    border-right: 0px; }QPushButton{ border: 1px solid #C5C9CA;   background-color: #FFFFFF;    border-left: 0px;   border-top-right-radius:3px;   border-bottom-right-radius:3px;    outline: none; }TGet:disabled { color: #000000;     border: 1px solid #E8EBF21;    border-right: 0px;    border-top-right-radius: 0px;    border-bottom-right-radius: 0px;    background-color: #E8EBF1;}QPushButton:disabled{ background-color: #E8EBF1; }tLabel{color: #000000;}")
        //oCmbFornec:bValid := {|| fAtuCmb()}           //Funcao para validar o que foi digitado
        //oCmbFornec:lReadOnly  := .T.                         //Para permitir o usuario clicar mas nao editar o campo
 
        //! Loja
        nObjLinha := 8
        nObjColun := 170
        nObjLargu := 20
        nObjAltur := 20
        oSayLoja  := TSay():New(nObjLinha, nObjColun, {|| cSayLoja}, oPanHeader, /*cPicture*/, oFont14B, , , , .T., /*nClrText*/, /*nClrBack*/, nObjLargu, nObjAltur, , , , , , /*lHTML*/)

        nObjLinha := 20
        nObjLargu := 20
        nObjAltur := 14
        lHasButton := .F. // Simbolo de lupa ao invés de interrogacao
        oCmbLoja := TGet():New(nObjLinha, nObjColun, {|u| Iif(PCount() > 0 , cCmbLoja := u, cCmbLoja)}, oPanHeader, nObjLargu, nObjAltur, /*cPict*/, /*bValid*/, /*nClrFore*/, /*nClrBack*/, oFont14, , , .T.)
        //oCmbLoja:lReadOnly  := .T.                         //Para permitir o usuario clicar mas nao editar o campo

        //! Origem
        nObjLinha := 8
        nObjColun += 50
        nObjLargu := 60
        nObjAltur := 20
        oSayOrigem  := TSay():New(nObjLinha, nObjColun, {|| cSayOrigem}, oPanHeader, /*cPicture*/, oFont14B, , , , .T. , /*nClrText*/, /*nClrBack*/, nObjLargu, nObjAltur, , , , , , /*lHTML*/)
 
        nObjLinha := 20
        nObjLargu := 80
        nObjAltur := 35
        oCmbOrigem  := TComboBox():New(nObjLinha, nObjColun, {|u| Iif(PCount() > 0 , cCmbOrigem := u, cCmbOrigem)}, aCmbOrigem, nObjLargu, nObjAltur, oPanHeader, , /*{|| fAtuCmb()}*/, /*bValid*/, /*nClrText*/, /*nClrBack*/, .T. , oFont14)
        oCmbOrigem:SetHeight( nObjAltur ) 

        //! DOC
        nObjLinha := 8
        nObjColun += 100
        nObjLargu := 60
        nObjAltur := 20
        oSayCod  := TSay():New(nObjLinha, nObjColun, {|| cSayCod}, oPanHeader, /*cPicture*/, oFont14B, , , , .T., /*nClrText*/, /*nClrBack*/, nObjLargu, nObjAltur, , , , , , /*lHTML*/)

        nObjLinha := 20
        nObjAltur := 14
        nObjLargu := 70
        lHasButton := .T. // Simbolo de lupa ao invés de interrogacao
        oCmbCod     := TGet():New(nObjLinha, nObjColun, {|u| Iif(PCount() > 0 , cCmbCod := u, cCmbCod)}, oPanHeader, nObjLargu, nObjAltur, /*cPict*/, /*bValid*/, /*nClrFore*/, /*nClrBack*/, oFont14, , , .T., /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/, /*uParam19*/, /*bChange*/, /*lReadOnly*/, /*lPassword*/, /*uParam23*/, /*cReadVar*/, /*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton)
        oCmbCod:cF3 := 'ZZB' //Codigo da consulta padrao / F3 que sera habilitada
        oCmbCod:SetCSS("TGet{ color: #000000; selection-background-color: #369CB5;    background-color: #FFFFFF;     padding-left: 3px;     padding-right: 3px;     border-top-left-radius:3px;    border-bottom-left-radius:3px;    border: 1px solid #C5C9CA;    border-right: 0px; }QPushButton{ border: 1px solid #C5C9CA;   background-color: #FFFFFF;    border-left: 0px;   border-top-right-radius:3px;   border-bottom-right-radius:3px;    outline: none; }TGet:disabled { color: #000000;     border: 1px solid #E8EBF21;    border-right: 0px;    border-top-right-radius: 0px;    border-bottom-right-radius: 0px;    background-color: #E8EBF1;}QPushButton:disabled{ background-color: #E8EBF1; }tLabel{color: #000000;}")
        //oCmbCod:cPlaceHold := 'Digite aqui um texto...'   //Texto que sera exibido no campo antes de ter conteudo
        //oCmbCod:bValid := {|| fAtuCmb()}           //Funcao para validar o que foi digitado
        //oCmbCod:lReadOnly  := .T.                         //Para permitir o usuario clicar mas nao editar o campo

        //! Produto
        nObjLinha := 8
        nObjColun += nObjLargu+20
        nObjLargu := 50
        nObjAltur := 20
        oSayProd  := TSay():New(nObjLinha, nObjColun, {|| cSayProd}, oPanHeader, /*cPicture*/, oFont14B, , , , .T., /*nClrText*/, /*nClrBack*/, nObjLargu, nObjAltur, , , , , , /*lHTML*/)

        nObjLinha := 20
        nObjLargu := 80
        nObjAltur := 14
        lHasButton := .T. // Simbolo de lupa ao invés de interrogacao
        oCmbProd := TGet():New(nObjLinha, nObjColun, {|u| Iif(PCount() > 0 , cCmbProd := u, cCmbProd)}, oPanHeader, nObjLargu, nObjAltur, /*cPict*/, /*bValid*/, /*nClrFore*/, /*nClrBack*/, oFont14, , , .T., /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/, /*uParam19*/, /*bChange*/, /*lReadOnly*/, /*lPassword*/, /*uParam23*/, /*cReadVar*/, /*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton)
        oCmbProd:cF3    := 'SB1' //Codigo da consulta padrao / F3 que sera habilitada
        oCmbProd:SetCSS("TGet{ color: #000000; selection-background-color: #369CB5;    background-color: #FFFFFF;     padding-left: 3px;     padding-right: 3px;     border-top-left-radius:3px;    border-bottom-left-radius:3px;    border: 1px solid #C5C9CA;    border-right: 0px; }QPushButton{ border: 1px solid #C5C9CA;   background-color: #FFFFFF;    border-left: 0px;   border-top-right-radius:3px;   border-bottom-right-radius:3px;    outline: none; }TGet:disabled { color: #000000;     border: 1px solid #E8EBF21;    border-right: 0px;    border-top-right-radius: 0px;    border-bottom-right-radius: 0px;    background-color: #E8EBF1;}QPushButton:disabled{ background-color: #E8EBF1; }tLabel{color: #000000;}")
        //oCmbProd:bValid := /*{|| fAtuCmb()}*/           //Funcao para validar o que foi digitado
        //oCmbProd:lReadOnly  := .T.                         //Para permitir o usuario clicar mas nao editar o campo

        //! Data
        nObjLinha := 8
        nObjColun += nObjLargu+20
        nObjLargu := 30
        nObjAltur := 20
        oSayData  := TSay():New(nObjLinha, nObjColun, {|| cSayData}, oPanHeader, /*cPicture*/, oFont14B, , , , .T., /*nClrText*/, /*nClrBack*/, nObjLargu, nObjAltur, , , , , , /*lHTML*/)

        nObjLinha := 20
        nObjLargu := 80
        nObjAltur := 14
        lHasButton := .T. // Simbolo de lupa ao invés de interrogacao
        oCmbData := TGet():New(nObjLinha, nObjColun, {|u| Iif(PCount() > 0 , cCmbData := u, cCmbData)}, oPanHeader, nObjLargu, nObjAltur, /*cPict*/, /*bValid*/, /*nClrFore*/, /*nClrBack*/, oFont14, , , .T., /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/, /*uParam19*/, /*bChange*/, /*lReadOnly*/, /*lPassword*/, /*uParam23*/, /*cReadVar*/, /*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton)        
        oCmbData:SetCSS("TGet{ color: #000000; selection-background-color: #369CB5;    background-color: #FFFFFF;     padding-left: 3px;     padding-right: 3px;     border-top-left-radius:3px;    border-bottom-left-radius:3px;    border: 1px solid #C5C9CA;    border-right: 0px; }QPushButton{ border: 1px solid #C5C9CA;   background-color: #FFFFFF;    border-left: 0px;   border-top-right-radius:3px;   border-bottom-right-radius:3px;    outline: none; }TGet:disabled { color: #000000;     border: 1px solid #E8EBF21;    border-right: 0px;    border-top-right-radius: 0px;    border-bottom-right-radius: 0px;    background-color: #E8EBF1;}QPushButton:disabled{ background-color: #E8EBF1; }tLabel{color: #000000;}")
        //oCmbData:cPlaceHold := 'Digite aqui um texto...'   //Texto que sera exibido no campo antes de ter conteudo
        //oCmbData:bValid := /*{|| fAtuCmb()}*/           //Funcao para validar o que foi digitado
        //oCmbData:lReadOnly  := .T.                         //Para permitir o usuario clicar mas nao editar o campo


        //status, fornecedor, OP, produto e data
        //Dados
        oPanGrid := tPanel():New(050, 001, '', oDlgMark, , , , RGB(000,000,000), RGB(254,254,254), (nJanLarg/2)-1,     (nJanAltu/2)-50)
        oMarkBrowse := FWMarkBrowse():New()
        oMarkBrowse:SetDataTable()
        //oMarkBrowse:SetInsert(.F.)
        //oMarkBrowse:SetDelete(.F., { || .F. })
        oMarkBrowse:SetAlias(cAliasTmp)
        //oMarkBrowse:SetEditCell(.T., {|| .T.})
        //oMarkBrowse:SetDescription('Produtos')
        oMarkBrowse:DisableReport()
        oMarkBrowse:DisableFilter()
        oMarkBrowse:DisableConfig()
        oMarkBrowse:DisableSeek()
        oMarkBrowse:DisableSaveConfig()
        oMarkBrowse:SetFontBrowse(oFont14)
        oMarkBrowse:SetFieldMark('OK')
        oMarkBrowse:SetTemporary(.T.)
        oMarkBrowse:SetColumns(aColunas)
        oMarkBrowse:SetOwner(oPanGrid)
        oMarkBrowse:Activate()

    ACTIVATE MsDialog oDlgMark CENTERED
     
    oTempTable:Delete()
    oMarkBrowse:DeActivate()
     
    RestArea(aArea)
Return nRecMarc
 
//Static Function MenuDef()
        //
        //    Local aRotina := {}
        //
        //    ADD OPTION aRotina TITLE 'Continuar'  ACTION 'u_REAFT06A' OPERATION 2 ACCESS 0
        //
//Return aRotina

Static Function fCriaCols()
    Local nAtual   := 0 
    Local aColunas := {}
    Local aEstrut  := {}
    Local oColumn
     
    aAdd(aEstrut, { 'STATUS'   , 'Status'               , 'C',  1, 0, '', .T., {"1=Pendente", "2=Reprovado", "3=Integrado"}})
    aAdd(aEstrut, { 'ITEM'     , 'Item'                 , 'C', 15, 0, '', .F., NIL })
    aAdd(aEstrut, { 'CODPRDO'  , 'Produto'              , 'C', 15, 0, '', .F., NIL })
    aAdd(aEstrut, { 'DESCPROD' , 'Descrição'            , 'C', 40, 0, '', .F., NIL })
    aAdd(aEstrut, { 'FORNEC'   , 'Fornecedor'           , 'C', 15, 0, '', .F., NIL })
    aAdd(aEstrut, { 'LOJAFORN' , 'Loja'                 , 'C', 2,  0, '', .F., NIL })
    aAdd(aEstrut, { 'NOMEFORN' , 'Nome Fornecedor'      , 'C', 40, 0, '', .F., NIL })
    aAdd(aEstrut, { 'ORIGEM'   , 'Origem'               , 'C', 30, 0, '', .T., {"1=Apontamento de Produção", "2=Documento de Entrada"}})
    aAdd(aEstrut, { 'NUMDOC'   , 'Documento'            , 'C', 15, 0, '', .F., NIL })
    aAdd(aEstrut, { 'DIVERG'   , 'Divergência'          , 'C',  5, 0, '', .F., NIL })
    aAdd(aEstrut, { 'PRE_CALC' , 'Preço Incluído'      , 'C', 12, 0, '', .F., NIL })
    aAdd(aEstrut, { 'DATAEMI'  , 'Data de Emissão'      , 'C', 12, 0, '', .F., NIL })

    For nAtual := 1 To Len(aEstrut)
        oColumn := FWBrwColumn():New()
        oColumn:SetData(&('{|| ' + cAliasTmp + '->' + aEstrut[nAtual][1] +'}'))
        oColumn:SetTitle(aEstrut[nAtual][2])
        oColumn:SetType(aEstrut[nAtual][3])
        oColumn:SetSize(aEstrut[nAtual][4])
        oColumn:SetDecimal(aEstrut[nAtual][5])
        oColumn:SetPicture(aEstrut[nAtual][6])

        //Se for ser possível ter o duplo clique
        If aEstrut[nAtual][7]
            oColumn:SetEdit(.T.)
            oColumn:SetReadVar(aEstrut[nAtual][1])
        EndIf

        //Se tiver opções do combo
        If !Empty(aEstrut[nAtual][8])
            oColumn:SetOptions(aEstrut[nAtual][8])
        EndIf
        
        aAdd(aColunas, oColumn)
    Next
Return aColunas
 
User Function REAFT06A(lInclui)
    DEFAULT lInclui := .T.
    Processa({|| fProcessa(lInclui)}, 'Processando...')
Return
 
Static Function fProcessa(lInclui)
    Local aArea     := FWGetArea()
    Local cMarca    := oMarkBrowse:Mark()
    Local nAtual    := 0
    Local nTotal    := 0
    Local nTotMarc  := 0
    Local nCont     := 0
    Local cMsgComp  := ""
    Local cMsgErro  := ""
    Local cMsgSuc   := ""
    Local cMsgReprv := ""
    Local cMsgApres := ""
    Local cOpcReprov := ""
    Local cAprovReg := IIF(lInclui, "aprovar", "reprovar")
    Local aProdMarc := {} 
    Local lContinua := .T.
    Local cTabAtu   :=  AllTrim(GETNEWPAR("ZZ_TABPRC", "001"))

    DbSelectArea(cAliasTmp)
    (cAliasTmp)->(DbGoTop())
    While !(cAliasTmp)->(EoF())
        If oMarkBrowse:IsMark(cMarca)
            If (cAliasTmp)->STATUS <> "1"
                lContinua := .F.
                cMsgErro += "O produto " + ALLTRIM((cAliasTmp)->CODPRDO) + " - " + ALLTRIM((cAliasTmp)->DESCPROD) + " não pode ser "+IIF(lInclui, "aprovado", "reprovado")+" porque já foi " +  IIF((cAliasTmp)->STATUS == "2", "reprovado.", "integrado.")  + CRLF + CRLF
            Endif 
            nAtual++
        EndIf
        (cAliasTmp)->(DbSkip())
    EndDo

    If !EMPTY(nAtual) 
        If lContinua
            if !MsgYesNo("Deseja "+cAprovReg+" os registros selecionados", "TOTVS")
                FWAlertInfo('Operação cancelada! ', 'TOTVS')
                (cAliasTmp)->(DbGoBottom())
                (cAliasTmp)->(DbGoTop())
                oMarkBrowse:Refresh(.T.)
                Return  
            Endif
        Else
            cMsgComp += "**********************************"+ CRLF
            cMsgComp += "Erro! Produtos abaixo não podem ser atualizados "  + CRLF
            cMsgComp += "**********************************"+  CRLF
            cMsgComp += cMsgErro
            cMsgErro := ""
        Endif 
    Else
        FWAlertInfo('Nenhum registro selecionado ', 'TOTVS')
        (cAliasTmp)->(DbGoBottom())
        (cAliasTmp)->(DbGoTop())
        oMarkBrowse:Refresh(.T.)
        Return  
    Endif 

    If lContinua
        Count To nTotal
        ProcRegua(nTotal)
        
        nRecMarc := 0 
        nAtual   := 0 
        (cAliasTmp)->(DbGoTop())
        While !(cAliasTmp)->(EoF())
            nAtual++
            IncProc('Analisando registro ' + cValToChar(nAtual) + ' de ' + cValToChar(nTotal) + '...')
            If oMarkBrowse:IsMark(cMarca)
                nTotMarc++
                nRecMarc := nAtual
                
                If lInclui //! Se for inclusão
                    if ALLTRIM((cAliasTmp)->STATUS) == "2"
                        cMsgReprv += "O produto " + ALLTRIM((cAliasTmp)->CODPRDO) + " - " + ALLTRIM((cAliasTmp)->DESCPROD) + CRLF  
                    endif 
                    nPos := aScan(aProdMarc,{|x| ALLTRIM(x) == ALLTRIM((cAliasTmp)->CODPRDO)})
                
                    If nPos == 0
                        AADD(aProdMarc, {ALLTRIM((cAliasTmp)->CODPRDO), (cAliasTmp)->RECNUM, ALLTRIM((cAliasTmp)->DESCPROD), ALLTRIM((cAliasTmp)->PRE_CALC)})
                    Else 
                        lContinua := .F.
                        cMsgErro += "O produto " + ALLTRIM((cAliasTmp)->CODPRDO) + " - " + ALLTRIM((cAliasTmp)->DESCPROD) + " foi selecionado mais de uma vez. " + CRLF  
                    Endif 
                Else 
                    AADD(aProdMarc, {ALLTRIM((cAliasTmp)->CODPRDO), (cAliasTmp)->RECNUM, ALLTRIM((cAliasTmp)->DESCPROD), ALLTRIM((cAliasTmp)->PRE_CALC)})
                    cOpcReprov += "O produto " + ALLTRIM((cAliasTmp)->CODPRDO) + " - " + ALLTRIM((cAliasTmp)->DESCPROD) + " foi reprovado. " + CRLF  
                Endif 
            EndIf
            (cAliasTmp)->(DbSkip())
        EndDo


        If !EMPTY(cMsgReprv)

            cMsgApres += "Registros selecionados estão com status Reprovado " + CRLF + cMsgReprv

            If !MsgYesNo(cMsgApres, "Deseja atualizar assim mesmo?")
                lContinua := .F.
                FWAlertInfo('Operação cancelada! ', 'TOTVS')

                (cAliasTmp)->(DbGoBottom())
                (cAliasTmp)->(DbGoTop())
                oMarkBrowse:Refresh(.T.)
                Return  
            EndIf

        Endif
        If lContinua
            If !Empty(aProdMarc)
                DbSelectArea('DA1')
                DA1->(DbSetOrder(1)) //DA1_FILIAL+DA1_CODTAB+DA1_CODPRO+DA1_INDLOT+DA1_ITEM
                DbSelectArea('ZZB')
                ZZB->(DbSetOrder(1))

                For nCont := 1 to len(aProdMarc)
                    ZZB->(DbGoTop())
                    
                    //Pega as informações do produto da grid e preço
                    cCodProd  := aProdMarc[nCont,1] //TMP1->CK_PRODUTO
                    nRecnum   := aProdMarc[nCont,2] //Recno
                    cDescProd := aProdMarc[nCont,3]
                    nPrcProd  := aProdMarc[nCont,4] // PREÇO_FINAL
                    If lInclui //! Se for inclusão
                        DA1->(DbGoTop())

                        //nPrcProd := 100//TMP1->CK_PRCVEN

                        //Se conseguir posicionar na tabela de preço + produto
                        If DA1->(DbSeek(FWxFilial('DA1') + cTabAtu + cCodProd ))
                            //Verifica se o preço do produto no orçamento é maior que o preço máximo da tabela

                            RecLock("DA1", .F.)  
                                DA1->DA1_PRCVEN := VAL(StrTran(StrTran(nPrcProd, ".", ""), ",", "."))
                            DA1->(MsUnlock())

                            ZZB->(DbGoTo(nRecnum))
                            RecLock("ZZB", .F.)  
                                ZZB->ZZB_STATUS := "3" //! Status Integrado
                            ZZB->(MsUnlock())

                            cMsgSuc +=  "O produto " + cCodProd + " foi atualizado " + CRLF + "Valor: R$" + ALLTRIM(cValToChar(nPrcProd)) + " na tabela: "+ cTabAtu + CRLF + CRLF
                        Else
                            cMsgErro += "O produto " + cCodProd + " não existe na tabela de preços: "+ cTabAtu + CRLF 
                        EndIf
                    Else
                        ZZB->(DbGoTo(nRecnum))
                        RecLock("ZZB", .F.)  
                            ZZB->ZZB_STATUS := "2" //! Status Reprovado
                        ZZB->(MsUnlock())
                    EndIf
                Next
            Else
                FWAlertInfo('Nenhum registro selecionado! ', 'TOTVS')
            Endif  
        Endif
    Endif 

    If !EMPTY(cOpcReprov)
        cMsgComp += "**********************************"+ CRLF
        cMsgComp += "Registros reprovados com sucesso: " + CRLF
        cMsgComp += "**********************************"+  CRLF
        cMsgComp += cOpcReprov
    Elseif !EMPTY(cMsgSuc) .OR. !EMPTY(cMsgErro)
        If !EMPTY(cMsgSuc)
            cMsgComp += "**********************************"+ CRLF
            cMsgComp += "Registros alterados com sucesso: " + CRLF
            cMsgComp += "**********************************"+  CRLF
            cMsgComp += cMsgSuc + CRLF+ CRLF
        Endif
        If !EMPTY(cMsgErro)
            cMsgComp += "**********************************"+ CRLF
            cMsgComp += "Registros não existentes na tabela de preços: " + cTabAtu + CRLF
            cMsgComp += "**********************************"+  CRLF
            cMsgComp += cMsgErro + CRLF
        Endif
    Endif

    If !EMPTY(cMsgComp)  
        U_REAFAT08(cMsgComp, "Log Processamento", 1, .F.) //! Tela do Log
    Endif

    U_REAFAT07(.T.)

    FWRestArea(aArea)
Return


/*
    Campo (SX3)	Título	                Tipo	Tam	    Dec	    Picture	            Observação

    ZZB_PROD	Código do Produto	    C	    15	    0	    @!	                Código do produto (SB1)
    ZZB_CFOR	Código do Fornecedor	C	    6	    0	    @!	                Código do fornecedor (SA2)
    ZZB_ORIG	Origem do Preço	        C	    1	    0	    @!	                E = Última Entrada / O = Ordem de Produção
    ZZB_NF	    Nº NF	                C	    9	    0	    @!	                Usado quando Origem = Entrada
    ZZB_SERIE	Série NF	            C	    3	    0	    @!	                Usado quando Origem = Entrada
    ZZB_NROP	Nº OP	                C	    9	    0	    @!	                Usado quando Origem = OP
    ZZB_DATA	Data	                D	    8	    —	    @D	                Usado quando Origem = OP
    ZZB_IMP	    Impostos %	            N	    5	    2	    @E 999.99	        Percentual total de impostos (definido em projeto)
    ZZB_PRECO	Preço Calculado	        N	    14	    4	    @E 999,999,999.9999	Calculado pela fórmula
    ZZB_STATUS	Status	                C	    1	    0	    @!	                1 = Pendente / 2 = Não Aprovado / 3 = Integrado
*/


/*/{Protheus.doc} Consulta padrão ZZB - Valida a de origem
/*/
User Function REAFT06B()
    Local lRet    := .T.
    Local cOpcEsc := Substring(cCmbOrigem,1,1) 
    
    If cOpcEsc <> "3"
        lRet := ZZB->ZZB_ORIG == Substring(cCmbOrigem,1,1) 
    Endif 

Return lRet



