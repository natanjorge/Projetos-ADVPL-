#Include "TOTVS.ch"
#Include "TOPCONN.ch"

/*/{Protheus.doc} NTNFAT02
    Exibe uma tela de log/mensagem em modal com conteúdo multiline, opções de confirmação e botão para salvar em .txt.
    @type User Function
    @author Natan Jorge
    @since 15/02/2026
    @version 1.0.0
    @param cMsg, Character, Texto da mensagem/log a ser exibido
    @param cTitulo, Character, Título da janela
    @param nTipe, Numeric, Tipo de tela: 1=Somente OK | 2=Confirmar/Cancelar
    @param lEdit, Logical, .T. permite editar o texto na tela; .F. somente leitura
    @return lRetMens, Logical, .T. se confirmou/OK; .F. se cancelou ou fechou
/*/
User Function NTNFAT02(cMsg, cTitulo, nTipe, lEdit) //! Tela do Log

    Local lRetMens := .F.
    Local oDlgMens
    Local oBtnOk, cTxtConf := ""
    Local oBtnCnc, cTxtCancel := ""
    Local oBtnSlv
    Local oFntTxt := TFont():New("Lucida Console",,-015,,.F.,,,,,.F.,.F.)
    Local oMsg
    Default cMsg    := "..."
    Default cTitulo := "Log Mensagem"
    Default nTipe   := 1 // 1=Ok; 2= Confirmar e Cancelar
    Default lEdit   := .F.
     
    If(nTipe == 1)
        cTxtConf:='&Ok'
    Else
        cTxtConf:='&Confirmar'
        cTxtCancel:='C&ancelar'
    EndIf
 

    DEFINE MSDIALOG oDlgMens TITLE cTitulo FROM 000, 000  TO 500, 800 COLORS 0, 16777215 PIXEL
        @ 002, 004 GET oMsg VAR cMsg OF oDlgMens MULTILINE SIZE 391, 210 FONT oFntTxt COLORS 0, 16777215 HSCROLL PIXEL

        If !lEdit
            oMsg:lReadOnly := .T.
        EndIf
         
        If (nTipe==1)
            @ 220, 345 BUTTON oBtnOk  PROMPT cTxtConf   SIZE 051, 019 ACTION (lRetMens:=.T., oDlgMens:End()) OF oDlgMens PIXEL
            oBtnOk:SetCSS("QPushButton{ background-color: #4CAF50; color: #FFFFFF; border-radius: 3px; }" +;
                        "QPushButton:hover{ background-color: #45a049; }")
        ElseIf(nTipe==2)

            @ 220, 275 BUTTON oBtnCnc PROMPT cTxtCancel SIZE 051, 019 ACTION (lRetMens:=.F., oDlgMens:End()) OF oDlgMens PIXEL
            oBtnCnc:SetCSS("QPushButton{ background-color: #f44336; color: #FFFFFF; border-radius: 3px; }" +;
                           "QPushButton:hover{ background-color: #da190b; }")
        
            @ 220, 345 BUTTON oBtnOk  PROMPT cTxtConf   SIZE 051, 019 ACTION (lRetMens:=.T., oDlgMens:End()) OF oDlgMens PIXEL
            oBtnOk:SetCSS("QPushButton{ background-color: #4CAF50; color: #FFFFFF; border-radius: 3px; }" +;
                          "QPushButton:hover{ background-color: #45a049; }")
        EndIf   
        
        @ 220, 004 BUTTON oBtnSlv PROMPT "&Salvar em .txt" SIZE 051, 019 ACTION (fSalvArq(cMsg, cTitulo)) OF oDlgMens PIXEL
        oBtnSlv:SetCSS("QPushButton{ background-color: #2196F3; color: #FFFFFF; border-radius: 3px; }" +;
                        "QPushButton:hover{ background-color: #0b7dda; }")
    ACTIVATE MSDIALOG oDlgMens CENTERED
 
Return lRetMens

/*/{Protheus.doc} fSalvArq
    Solicita um caminho e salva o conteúdo do log em arquivo .txt, adicionando cabeçalho com usuário/data/hora.
    @type Static Function
    @author Natan Jorge
    @since 15/02/2026
    @version 1.0.0
    @param cMsg, Character, Texto do log/mensagem a salvar
    @param cTitulo, Character, Título usado na seção "Mensagem" do arquivo
    @return Nil, Nil, Grava arquivo via MemoWrite() quando confirmado pelo usuário
/*/
Static Function fSalvArq(cMsg, cTitulo)
    Local cFileNom :='\x_arq_'+dToS(Date())+StrTran(Time(),":")+".txt"
    Local cQuebra  := CRLF + "+=======================================================================+" + CRLF
    Local lOk      := .T.
    Local cTexto   := ""
     
    cFileNom := cGetFile( "Arquivo TXT *.txt | *.txt", "Arquivo .txt...",,'',.T., GETF_LOCALHARD)
 
    If !Empty(cFileNom)
        If ! ExistDir(SubStr(cFileNom,1,RAt('\',cFileNom)))
            Alert("Diretório não existe:" + CRLF + SubStr(cFileNom, 1, RAt('\',cFileNom)) + "!")
            Return
        EndIf
         
        cTexto := "Função   - "+ FunName()       + CRLF
        cTexto += "Usuário  - "+ cUserName       + CRLF
        cTexto += "Data     - "+ dToC(dDataBase) + CRLF
        cTexto += "Hora     - "+ Time()          + CRLF
        cTexto += "Mensagem - "+ cTitulo + cQuebra  + cMsg + cQuebra
         
        If File(cFileNom)
            lOk := MsgYesNo("Arquivo já existe, deseja substituir?", "Atenção")
        EndIf
         
        If lOk
            MemoWrite(cFileNom, cTexto)
            MsgInfo("Arquivo Gerado com Sucesso:"+CRLF+cFileNom,"Atenção")
        EndIf
    EndIf
Return
