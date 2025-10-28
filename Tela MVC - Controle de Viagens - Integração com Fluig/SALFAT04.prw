#Include "Totvs.ch"
#Include "FWMVCDef.ch"
 
/*/{Protheus.doc} SALFAT04
	Tela seleção de produtos do grid detalhamento de produtos Programação de Viagens x Coletas
	@author Natan Jorge
	@since 10/06/2025
	@type User function
/*/
User Function SALFAT04(aDadosRec, cPedVen)
    Local aArea         := GetArea()
    Local aCampos := {}
    Local oTempTable := Nil
    Local aColunas := {}
    Local cFontPad    := 'Tahoma'
    Local oFontGrid   := TFont():New(cFontPad,,-14)
    Private oDlgMark
    Private oPanGrid
    Private oMarkBrowse
    Private cAliasTmp := GetNextAlias()
    Private aRotina   := MenuDef()
    //Tamanho da janela
    Private aTamanho := MsAdvSize()
    Private nJanLarg := aTamanho[5]/2
    Private nJanAltu := aTamanho[6]/2
    Private nRecMarc  := 0
    DEFAULT aDadosRec := {}

    //Adiciona as colunas que serão criadas na temporária
    aAdd(aCampos, { 'OK',      'C',  2, 0}) //Flag para marcação
    aAdd(aCampos, { 'B1_COD',  'C', 15, 0}) //Produto
    aAdd(aCampos, { 'B1_DESC', 'C', 50, 0}) //Descrição
    aAdd(aCampos, { 'B1_ITEM', 'C',  2, 0}) //ITEM PV
    aAdd(aCampos, { 'B1_QUANT','C', 20, 0}) //Quantidade
 
    oTempTable:= FWTemporaryTable():New(cAliasTmp)
    oTempTable:SetFields( aCampos )
    oTempTable:Create()  
 
    Processa({|| fPopula(aDadosRec)}, 'Processando...')
 
    aColunas := fCriaCols()
      
    DEFINE MSDIALOG oDlgMark TITLE 'Tela para Marcação de Produtos' FROM 000, 000  TO nJanAltu, nJanLarg COLORS 0, 16777215 PIXEL
        //Dados
        oPanGrid := tPanel():New(001, 001, '', oDlgMark, , , , RGB(000,000,000), RGB(254,254,254), (nJanLarg/2)-1,     (nJanAltu/2 - 1))
        oMarkBrowse := FWMarkBrowse():New()
        oMarkBrowse:SetAlias(cAliasTmp)                
        oMarkBrowse:SetDescription('Produtos')
        oMarkBrowse:DisableFilter()
        oMarkBrowse:DisableConfig()
        oMarkBrowse:DisableSeek()
        oMarkBrowse:DisableSaveConfig()
        oMarkBrowse:SetFontBrowse(oFontGrid)
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
 
Static Function MenuDef()

    Local aRotina := {}

    ADD OPTION aRotina TITLE 'Continuar'  ACTION 'u_SALFT04' OPERATION 2 ACCESS 0

Return aRotina
  
Static Function fPopula(aDadosRec)
    Local nCont     := 0
 
    For nCont := 1 To LEN(aDadosRec)      
        If RecLock(cAliasTmp, .T.)            
            (cAliasTmp)->OK := Space(2)
            (cAliasTmp)->B1_COD   := aDadosRec[nCont][1]
            (cAliasTmp)->B1_DESC  := aDadosRec[nCont][2]
            (cAliasTmp)->B1_ITEM  := aDadosRec[nCont][3]
            (cAliasTmp)->B1_QUANT := transform(aDadosRec[nCont][4],"@E 999,999,999.99")
            (cAliasTmp)->(MsUnlock())
        EndIf
    Next

    (cAliasTmp)->(DbGoTop())
Return

Static Function fCriaCols()
    Local nAtual       := 0 
    Local aColunas := {}
    Local aEstrut  := {}
    Local oColumn
     
    aAdd(aEstrut, { 'B1_COD',   'Produto',   'C', 15, 0, ''})
    aAdd(aEstrut, { 'B1_DESC',  'Descrição', 'C', 50, 0, ''})
    aAdd(aEstrut, { 'B1_ITEM',  'Item',      'C',  2, 0, ''})
    aAdd(aEstrut, { 'B1_QUANT', 'Quantidade','C', 20, 0, ''})
 
    For nAtual := 1 To Len(aEstrut)
        oColumn := FWBrwColumn():New()
        oColumn:SetData(&('{|| ' + cAliasTmp + '->' + aEstrut[nAtual][1] +'}'))
        oColumn:SetTitle(aEstrut[nAtual][2])
        oColumn:SetType(aEstrut[nAtual][3])
        oColumn:SetSize(aEstrut[nAtual][4])
        oColumn:SetDecimal(aEstrut[nAtual][5])
        oColumn:SetPicture(aEstrut[nAtual][6])
 
        aAdd(aColunas, oColumn)
    Next
Return aColunas
 
User Function SALFT04()
    Processa({|| fProcessa()}, 'Processando...')
Return
 
Static Function fProcessa()
    Local aArea     := FWGetArea()
    Local cMarca    := oMarkBrowse:Mark()
    Local nAtual    := 0
    Local nTotal    := 0
    Local nTotMarc  := 0
    
    DbSelectArea(cAliasTmp)
    (cAliasTmp)->(DbGoTop())
    Count To nTotal
    ProcRegua(nTotal)
     
    nRecMarc := 0 
    (cAliasTmp)->(DbGoTop())
    While !(cAliasTmp)->(EoF())
        nAtual++
        IncProc('Analisando registro ' + cValToChar(nAtual) + ' de ' + cValToChar(nTotal) + '...')
        If oMarkBrowse:IsMark(cMarca)
            nTotMarc++
            nRecMarc := nAtual
        EndIf
        (cAliasTmp)->(DbSkip())
    EndDo

    If nTotMarc == 1
        oDlgMark:End()
    ElseIf nTotMarc > 1
        FWAlertInfo('Selecione apenas um produto! ', 'TOTVS')
    Elseif nTotMarc == 0
        FWAlertInfo('Nenhum registro selecionado! ', 'TOTVS')
    Endif  
 
    FWRestArea(aArea)
Return

