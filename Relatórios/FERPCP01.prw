#INCLUDE "TOPCONN.CH"
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPRINTSETUP.CH"
#INCLUDE 'TOTVS.CH'

#DEFINE PRETO       RGB(000,000,000)
#DEFINE VERMELHO    RGB(255,000,000)
#DEFINE AZUL        RGB(000,000,128)
#DEFINE MAX_LINE 600
#Define PAD_LEFT    0
#Define PAD_RIGHT   1
#Define PAD_CENTER  2
#Define PAD_JUSTIFY 3

/*
*{Protheus.doc} 
*    User Function FERPCP01 
*
*    Relatório de Ficha Técnica
* 
*    @type  Function
*    @author Natan Jorge 
*    @since 05/06/2024
*/
User Function FERPCP01() 
    
    Local aArea := GetArea()

	Private cTitle	:= "Impressão do Relatório de Ordem de Produção"
    Private aDados	:= {}

    Processa({|| MontaRel()}, "Aguarde....", "Imprimindo Relatório", .F.)

    RestArea(aArea)
Return         

Static Function MontaRel()
    Local cCaminho := "C:\"                
    Local cArquivo := U_FEAFAT32("FERPCP01")
    //Local cNumOrd  := SC2->C2_NUM
    Local nRecSC2   := SC2->(Recno())
    Local cNumOP    := ""
    Local cPedid    := ""
    Private nLinhaItens := 15
    Private nPgAtu := 1
    Private aProd  := {}
    Private cProdOrg := SC2->C2_PRODUTO

	Private oPrint   := FwMsPrinter():New(cArquivo, IMP_PDF, .F., "", .T., /*TREP*/, @oPrint, "", /*LServ*/, /*Compatibilidade*/, /*Raw, Binario*/, .T., /**/)
    Private oFont5   := TFont():New('Arial',/*Compat.*/, 5 /*Tamanho*/, /*Compat.*/, .F. /*Negrito*/,/*Compat.*/,/*Compat.*/,/*Compat.*/,/*Compat.*/, .F./*Sublinhado*/, .F./*Itálico*/)
    Private oFont7   := TFont():New('Arial',/*Compat.*/, 7 /*Tamanho*/, /*Compat.*/, .F. /*Negrito*/,/*Compat.*/,/*Compat.*/,/*Compat.*/,/*Compat.*/, .F./*Sublinhado*/, .F./*Itálico*/)
    Private oFont7B  := TFont():New('Arial',/*Compat.*/, 7 /*Tamanho*/, /*Compat.*/, .T. /*Negrito*/,/*Compat.*/,/*Compat.*/,/*Compat.*/,/*Compat.*/, .F./*Sublinhado*/, .F./*Itálico*/)
    Private oFont75  := TFont():New('Arial',/*Compat.*/, 7.5 /*Tamanho*/, /*Compat.*/, .F. /*Negrito*/,/*Compat.*/,/*Compat.*/,/*Compat.*/,/*Compat.*/, .F./*Sublinhado*/, .F./*Itálico*/)
    Private oFont8   := TFont():New('Arial',/*Compat.*/, 8 /*Tamanho*/, /*Compat.*/, .F. /*Negrito*/,/*Compat.*/,/*Compat.*/,/*Compat.*/,/*Compat.*/, .F./*Sublinhado*/, .F./*Itálico*/)
    Private oFont8B  := TFont():New('Arial',/*Compat.*/, 8 /*Tamanho*/, /*Compat.*/, .T. /*Negrito*/,/*Compat.*/,/*Compat.*/,/*Compat.*/,/*Compat.*/, .F./*Sublinhado*/, .F./*Itálico*/)
    Private oFont9   := TFont():New('Arial',/*Compat.*/, 9 /*Tamanho*/, /*Compat.*/, .F. /*Negrito*/,/*Compat.*/,/*Compat.*/,/*Compat.*/,/*Compat.*/, .F./*Sublinhado*/, .F./*Itálico*/)
    Private oFont10  := TFont():New('Arial',/*Compat.*/, 10.5 /*Tamanho*/, /*Compat.*/, .F. /*Negrito*/,/*Compat.*/,/*Compat.*/,/*Compat.*/,/*Compat.*/, .F./*Sublinhado*/, .F./*Itálico*/)
    Private oFont10B := TFont():New('Arial',/*Compat.*/, 10.5 /*Tamanho*/, /*Compat.*/, .T. /*Negrito*/,/*Compat.*/,/*Compat.*/,/*Compat.*/,/*Compat.*/, .F./*Sublinhado*/, .F./*Itálico*/)
    Private oFont12  := TFont():New('Arial',/*Compat.*/, 12 /*Tamanho*/, /*Compat.*/, .F. /*Negrito*/,/*Compat.*/,/*Compat.*/,/*Compat.*/,/*Compat.*/, .F./*Sublinhado*/, .F./*Itálico*/)
    Private oFont14B := TFont():New('Arial',/*Compat.*/, 14 /*Tamanho*/, /*Compat.*/, .T. /*Negrito*/,/*Compat.*/,/*Compat.*/,/*Compat.*/,/*Compat.*/, .F./*Sublinhado*/, .F./*Itálico*/)
    Private oFont22B := TFont():New('Arial',/*Compat.*/, 22 /*Tamanho*/, /*Compat.*/, .T. /*Negrito*/,/*Compat.*/,/*Compat.*/,/*Compat.*/,/*Compat.*/, .F./*Sublinhado*/, .F./*Itálico*/)
    Private cLogo    := "\system\lgmid01.PNG" //FisxLogo("1")

	Private aEmp := {}
    Private aRot := {}
    Private nLinPed := 0

    ProcRegua(3)

    oPrint:CPathPDF := cCaminho
    oPrint:SetPortrait()
    oPrint:SetPaperSize(9)

    oPrint:StartPage()

    cNumOP  := AllTrim(SC2->(C2_NUM + C2_ITEM + C2_SEQUEN))
    cPedid := SC2->(C2_PEDIDO)
    Cabecalho(cNumOP) 
    buscaEmp(cProdOrg)

    buscaRot(SC2->(C2_ROTEIRO),SC2->(C2_PRODUTO))

    if EMPTY(cPedid) .AND. !EMPTY(SC2->(C2_PEDIDO))
        cPedid := SC2->(C2_PEDIDO)
        oPrint:SayAlign(nLinPed, 360, cPedid, oFont8,  600,,,  PAD_LEFT,  )
    endif 

    ImpItens()
    SC2->(DbGoTo(nRecSC2))
    oPrint:Preview()

Return

Static Function Cabecalho(cNumOP)

    Local nLarImg  := 100
    Local nLarg    := 100
    Local nAlt     := 30
    Local cTime    := Time()
    Local dDatAtu  := date()
    Local cObsRot  := ""
    Local cNomeCli := ""
    
    Private cLogo    := "\"+GetNewPar("ZZ_PREPIMG", "repositimgs" ) +"\Logos\logolayoutF.png" 

    IncProc("Criando relatório 1 de 3 ...")

    oPrint:SayAlign(nLinhaItens, 0, 'ORDEM DE PRODUÇÃO', oFont14B,  600,,,  PAD_CENTER,  )
    oPrint:SayBitMap(nLinhaItens+15, 20,cLogo,nLarImg, 40)

    oPrint:Code128(nLinhaItens+20/*nRow*/, 250/*nCol*/, cNumOP/*cCode*/,0.4/*nWidth*/, nAlt/*nHeigth*/,.F./*lSay*/,,nLarg)
    oPrint:SayAlign(nLinhaItens+50, 0, ALLTRIM(cNumOP), oFont14B,  600,,,  PAD_CENTER,  )

    oPrint:SayAlign(nLinhaItens, 0,     "Data: "+DTOC(dDatAtu), oFont8B,  580,,,  PAD_RIGHT,  )
    oPrint:SayAlign(nLinhaItens+=15, 0, "Hora: "+cTime,         oFont8B,  580,,,  PAD_RIGHT,  )

    //! DADOS CABEÇALHO ESQUERDA
    oPrint:SayAlign(nLinhaItens+=65,  20, "Ordem de Produção:", oFont8B,  600,,,  PAD_LEFT,  )
    oPrint:SayAlign(nLinhaItens,     100, ALLTRIM(cNumOP),       oFont8,  600,,,  PAD_LEFT,  )

    oPrint:SayAlign(nLinhaItens+=10,  20, "Produto:",  oFont8B,  600,,,  PAD_LEFT,  )
    oPrint:SayAlign(nLinhaItens,     100, SC2->(C2_PRODUTO),  oFont8,  600,,,  PAD_LEFT,  )
   
    oPrint:SayAlign(nLinhaItens+=10,  20, "Cod. do Desenho:",  oFont8B,  600,,,  PAD_LEFT,  )
    oPrint:SayAlign(nLinhaItens,     100, Posicione("SB1",1,xFilial("SB1")+SC2->(C2_PRODUTO),"B1_ZZSWORK"), oFont8,  600,,,  PAD_LEFT,  )
   
    oPrint:SayAlign(nLinhaItens+=10,  20, "Item Ferraz:",  oFont8B,  600,,,  PAD_LEFT,  )
    oPrint:SayAlign(nLinhaItens,     100, SC2->C2_ZZITFE, oFont8,  600,,,  PAD_LEFT,  )

    oPrint:SayAlign(nLinhaItens+=10,  20, "Quantidade:", oFont8B,  600,,,  PAD_LEFT,  )
    oPrint:SayAlign(nLinhaItens,     100, AllTrim(strTran((STR(SC2->(C2_QUANT),,2)), ",", "." )) + AllTrim(SC2->(C2_UM)), oFont8,  600,,,  PAD_LEFT,  )

    dbSelectArea("SC5")
    SC5->(dbSetOrder(1))
    If SC5->(dbSeek(FWxFilial("SC5") + SC2->(C2_PEDIDO)))
        cNomeCli := Posicione("SA1",1,xFilial("SA1") + SC5->C5_CLIENTE + SC5->C5_LOJACLI,"A1_NOME")
    EndIf

    oPrint:SayAlign(nLinhaItens+=10,  20, "Cliente:",  oFont8B,  600,,,  PAD_LEFT,  )
    oPrint:SayAlign(nLinhaItens,     100, cNomeCli, oFont8,  600,,,  PAD_LEFT,  )

    oPrint:SayAlign(nLinhaItens+=10,  20, "Emissão:",   oFont8B,  600,,,  PAD_LEFT,  )
    oPrint:SayAlign(nLinhaItens,     100, DTOC(SC2->(C2_EMISSAO)),  oFont8,  600,,,  PAD_LEFT,  )

    oPrint:SayAlign(nLinhaItens+=10,  20, "Início Previsto:", oFont8B,  600,,,  PAD_LEFT,  )
    oPrint:SayAlign(nLinhaItens,     100, DTOC(SC2->(C2_DATPRI)),        oFont8,  600,,,  PAD_LEFT,  )

    oPrint:SayAlign(nLinhaItens+=10,  20, "Local:", oFont8B,  600,,,  PAD_LEFT,  )
    oPrint:SayAlign(nLinhaItens,     100, SC2->(C2_LOCAL) +' - '+ ALLTRIM(Posicione("NNR",1,xFilial("NNR")+SC2->(C2_LOCAL),"NNR_DESCRI")) ,     oFont8,  600,,,  PAD_LEFT,  )

    //! DADOS CABEÇALHO DIREITA
    nLinhaItens:= 95
    oPrint:SayAlign(nLinhaItens,      280, "Status:",  oFont8B,  600,,,  PAD_LEFT,  )
    oPrint:SayAlign(nLinhaItens,      360, IIF(SC2->(C2_TPOP) == "F", "Firme", "Prevista"), oFont8,  600,,,  PAD_LEFT,  )

    oPrint:SayAlign(nLinhaItens+=10,  280, "Descrição:",  oFont8B,  600,,,  PAD_LEFT,  )
    nLinhaItens-=15
    VeriQuebLn(Posicione("SB1",1,xFilial("SB1")+SC2->(C2_PRODUTO),"B1_DESC"), 52, 360, 2, oFont8, oFont8) //* Descrição

    oPrint:SayAlign(nLinhaItens+=20,  280, "Pedido:", oFont8B,  600,,,  PAD_LEFT,  )
    oPrint:SayAlign(nLinhaItens,      360, SC2->(C2_PEDIDO), oFont8,  600,,,  PAD_LEFT,  )
    nLinPed := nLinhaItens 
    oPrint:SayAlign(nLinhaItens+=10,  280, "Término Previsto:", oFont8B,  600,,,  PAD_LEFT,  )
    oPrint:SayAlign(nLinhaItens,      360, DTOC(SC2->(C2_DATPRF)),         oFont8,  600,,,  PAD_LEFT,  )

    oPrint:SayAlign(nLinhaItens+=10,  280, "Centro de custo:", oFont8B,  600,,,  PAD_LEFT,  )
    oPrint:SayAlign(nLinhaItens,      360, alltrim(posicione("CTT",1,xFilial("CTT")+SC2->(C2_CC),"CTT_DESC01")),         oFont8,  600,,,  PAD_LEFT,  )

    oPrint:SayAlign(nLinhaItens+=30,  20, "Obs.:",             oFont8B,  600,,,  PAD_LEFT,  )
    nLinhaItens-=15
    cObsRot := Posicione("SC2",1,xFilial("SC2")+SC2->(C2_NUM+C2_ITEM+C2_SEQUEN+C2_ITEMGRD),"C2_ZZOBS")
    VeriQuebLn(cObsRot, 105, 50,1000) 

Return

Static Function ImpItens()
    Local nCont    := 0
    Local nCont2   := 0
    Local nAlt     := 30
    Local cQtdTot  := ""
    Local cDescriLoc  := ""
    Local cObsRot  := ""
    Local aDescIt  := {"CÓDIGO","DESCRIÇÃO","QTDE.",/*"U.M.",*/"LOCAL","END.","CÓDIGO DO DESENHO"}
    Local aPosIt   := {      20,         80,    220, /*  250, */   270,   400,   495}

    //! IMPRESSÃO DOS EMPENHOS 
    oPrint:SayAlign(nLinhaItens+=20, 0, 'EMPENHOS',            oFont14B,  600,,,  PAD_CENTER,  )
    nLinhaItens+=15
    For nCont := 1 to LEN(aDescIt)
        oPrint:SayAlign(nLinhaItens,  aPosIt[nCont], aDescIt[nCont],   oFont10B,  600,,,  PAD_LEFT,  )
    Next

    For nCont := 1 to Len(aEmp)
        cDescriLoc := aEmp[nCont, 5] +' - '+ ALLTRIM(Posicione("NNR",1,xFilial("NNR")+aEmp[nCont, 5],"NNR_DESCRI"))

        cQtdTot := AllTrim(strTran( (STR(aEmp[nCont, 3],,2)), ",", "." )) + aEmp[nCont, 4]
        oPrint:SayAlign(nLinhaItens+=15, aPosIt[1], aEmp[nCont, 1], oFont9, 600,,, PAD_LEFT, ) //* Codigo
        oPrint:SayAlign(nLinhaItens,     aPosIt[3], cQtdTot,        oFont9, 600,,, PAD_LEFT, ) //* Qtd Total + Unidade de Medida
        oPrint:SayAlign(nLinhaItens,     aPosIt[4], cDescriLoc,     oFont9, 600,,, PAD_LEFT, ) //* Local
        oPrint:SayAlign(nLinhaItens,     aPosIt[5], aEmp[nCont, 6], oFont9, 600,,, PAD_LEFT, ) //* END.
        oPrint:SayAlign(nLinhaItens,     aPosIt[6], aEmp[nCont, 7], oFont9, 600,,, PAD_LEFT, ) //* Lote
        nLinhaItens-=15
        VeriQuebLn(aEmp[nCont, 2], 30, aPosIt[2],1000, oFont9) //* Descrição

        if nLinhaItens >= 600
            VeriQuebPg()
        endif

    Next
    
    //! IMPRESSÃO DO ROTEIRO 
    aDescIt := {"COD","OPERAÇÃO","RECURSO","FERR.","INI REAL","HR. INI","FIM REAL","HR. FIM"}
    aPosIt  := {   20,        50,      140,   220,       300,      375,       450,      525}

    oPrint:SayAlign(nLinhaItens+=20, 0, 'ROTEIRO',            oFont14B,  600,,,  PAD_CENTER,  )
    nLinhaItens+=15
    For nCont := 1 to LEN(aDescIt)
        oPrint:SayAlign(nLinhaItens,  aPosIt[nCont], aDescIt[nCont],   oFont10B,  600,,,  PAD_LEFT,  )
    Next

    oPrint:Line(nLinhaItens+=10, 20, nLinhaItens, 580, PRETO, "-6") 
    

    For nCont := 1 to Len(aRot)

        if nLinhaItens >= 600
            VeriQuebPg()
        endif

        oPrint:SayAlign(nLinhaItens+=15,  aPosIt[1], aRot[nCont, 3],                  oFont10, 600,,, PAD_LEFT, ) //! COD 
        oPrint:SayAlign(nLinhaItens,      aPosIt[2], aRot[nCont, 2],                  oFont10, 600,,, PAD_LEFT, ) //! OPERAÇÃO
        oPrint:SayAlign(nLinhaItens,      aPosIt[3], aRot[nCont, 1],                  oFont10, 600,,, PAD_LEFT, ) //! RECURSO
        oPrint:SayAlign(nLinhaItens,      aPosIt[4], aRot[nCont, 5],                  oFont10, 600,,, PAD_LEFT, ) //! FERR.
        oPrint:SayAlign(nLinhaItens,      aPosIt[5], "__ / __ / ____",                oFont10, 600,,, PAD_LEFT, ) //! INI REAL
        oPrint:SayAlign(nLinhaItens,      aPosIt[6], "___:___",                       oFont10, 600,,, PAD_LEFT, ) //! HR. INI
        oPrint:SayAlign(nLinhaItens,      aPosIt[7], "__ / __ / ____",                oFont10, 600,,, PAD_LEFT, ) //! FIM REAL
        oPrint:SayAlign(nLinhaItens,      aPosIt[8], "___:___",                       oFont10, 600,,, PAD_LEFT, ) //! HR. FIM

        oPrint:Code128(nLinhaItens+10/*nRow*/, aPosIt[2]/*nCol*/, aRot[nCont, 3]/*cCode*/,0.4/*nWidth*/, nAlt/*nHeigth*/,.F./*lSay*/,,35) //! IMPRESSAO CODBAR
        If !EMPTY(aRot[nCont, 1])
        oPrint:Code128(nLinhaItens+10/*nRow*/, aPosIt[3]/*nCol*/, aRot[nCont, 1]/*cCode*/,0.4/*nWidth*/, nAlt/*nHeigth*/,.F./*lSay*/,,35) //! IMPRESSAO CODBAR
        Endif 
        oPrint:SayAlign(nLinhaItens+=20,  aPosIt[5], "OPERADOR: ",                   oFont10B, 600,,, PAD_LEFT, ) //! OPERADOR
        oPrint:SayAlign(nLinhaItens,      aPosIt[5], SPACE(25) + REPLICATE("_", 45),  oFont10, 600,,, PAD_LEFT, ) //! ________

        nLinhaItens+=10
    
        cObsRot := Posicione("SG2",1,xFilial("SG2")+aRot[nCont, 6]+aRot[nCont, 4]+aRot[nCont, 3],"G2_ZZOBS")
        VeriQuebLn(cObsRot, 120, aPosIt[1],1000) //! TESTE


        VeriImg(aRot[nCont, 6]) //* Passando o código do produto
        For nCont2 := 1 to len(aProd) 
            if ALLTRIM(aProd[nCont2, 1]) == ALLTRIM(aRot[nCont, 3]) //! Se a operação for a mesma imprime a imagem 
                
                oPrint:SayBitmap(nLinhaItens+=10,     225, aProd[nCont2, 2], 150, 150)                 
                nLinhaItens+=160

                if nLinhaItens >= 600 
                    VeriQuebPg()
                endif
            Endif 
        Next

        oPrint:Line(nLinhaItens+=25, 20, nLinhaItens, 580, PRETO, "-6") 

    Next

    VeriImg(cProdOrg)//* Passando o código do produto

    if !EMPTY(aProd)
        For nCont2 := 1 to len(aProd) 
            if Empty(ALLTRIM(aProd[nCont2, 1])) //! Imprime as operações vazias no final   AC9_ZZROTE = ' '
                oPrint:SayBitmap(nLinhaItens+=10,     225, aProd[nCont2, 2], 150, 150)                 
                nLinhaItens+=160

                if nLinhaItens >= 600
                    VeriQuebPg()
                endif
            Endif 
        Next

        oPrint:Line(nLinhaItens+=25, 20, nLinhaItens, 580, PRETO, "-6") 
    endif 

Return

Static Function VeriQuebPg() 
    
    oPrint:EndPage()
    oPrint:StartPage()

    nLinhaItens := 20
    nPgAtu++
Return

Static Function VeriQuebLn(cString, nLineTam, nCol, nLinQtd,oFontNeg,oFontMenor)
    
    Local nI := 1
    Local aDadostxt := {}
    
    DEFAULT oFontNeg := oFont10B
    DEFAULT oFontMenor := oFont10

    DEFAULT nLinQtd := 3

    Q_MemoArray(cString, @aDadostxt, nLineTam)

    nLinhaItens+=5
    For nI := 1 To LEN(aDadostxt)

        cTxtLinha := aDadostxt[nI]

        If (nI <= nLinQtd)
            if nLinhaItens >= MAX_LINE
                VeriQuebPg()
            endif
            if      "*V*" $ cTxtLinha //!IMPRIME A LINHA NA COR VERMELHA EM NEGRITO
                oPrint:SayAlign(nLinhaItens+=10, nCol, ALLTRIM(Substring(cTxtLinha,4,len(cTxtLinha))), oFontNeg, 600,,VERMELHO, PAD_LEFT, )
            elseif  "*A*" $ cTxtLinha //!IMPRIME A LINHA NA COR AZUL EM NEGRITO
                oPrint:SayAlign(nLinhaItens+=10, nCol, ALLTRIM(Substring(cTxtLinha,4,len(cTxtLinha))), oFontNeg, 600,,AZUL, PAD_LEFT, )
            elseif  "*B*" $ cTxtLinha //!IMPRIME A LINHA EM NEGRITO
                oPrint:SayAlign(nLinhaItens+=10, nCol, ALLTRIM(Substring(cTxtLinha,4,len(cTxtLinha))), oFontNeg, 600,,, PAD_LEFT, )
            Else 
                oPrint:SayAlign(nLinhaItens+=10, nCol, ALLTRIM(cTxtLinha), oFontMenor, 600,,, PAD_LEFT, )
            Endif 
        EndIf
    Next nI

Return

Static Function buscaEmp(cProdEmp)
	
	Local cQuery   := ""
    Local cAlias2  := GetNextAlias()
    Local cEnderec := ""
 	Default cProdEmp   := ""
	
	If !Empty(cProdEmp)
        cQuery := " SELECT G1_COMP, G1_QUANT, B1_DESC, B1_LOCPAD, B1_UM, B1_ZZSWORK, B1_COD "
        cQuery += " FROM " + RetSqlName("SG1") + " SG1 "
        cQuery += " INNER JOIN " + RetSqlName("SB1") + " SB1 ON SB1.B1_FILIAL= '" + xFilial("SB1") + "' AND SB1.B1_COD=SG1.G1_COMP AND SB1.D_E_L_E_T_=' ' "
        cQuery += " WHERE G1_COD = '" + cProdEmp + "' AND SG1.D_E_L_E_T_=' ' "
 
        TCQUERY cQuery ALIAS (cAlias2) NEW

        (cAlias2)->(DbGoTop())

        If !(cAlias2)->(EOF()) .and. !(cAlias2)->(bOF())

            While (cAlias2)->(!Eof())
                cEnderec := Posicione("SB2",1,xFilial("SB2")+(cAlias2)->(B1_COD),"B2_LOCALIZ")
                Aadd(aEmp,{;
                    (cAlias2)->(G1_COMP),;	 //* Codigo
                    (cAlias2)->(B1_DESC),;	 //* Descrição
                    (cAlias2)->(G1_QUANT),;  //* Qtd Total 
                    (cAlias2)->(B1_UM),;	 //* Unidade de Medida
                    (cAlias2)->(B1_LOCPAD),; //* Local
                    cEnderec,;               //* END.
                    (cAlias2)->(B1_ZZSWORK); //* Código do desenho
                })

                (cAlias2)->(DbSkip())
            EndDo
        EndIf
	    
        (cAlias2)->(dbCloseArea())
    
    EndIf

Return

Static Function buscaRot(cRoteiro,cProduto) //! PCPA129
	
	Local cQuery     := ""
    Local cAlias3    := GetNextAlias()
	Default cRoteiro := ""
	
    If Empty(cRoteiro)
        If !Empty(SB1->B1_OPERPAD)
            cRoteiro := SB1->B1_OPERPAD
        Else
            cRoteiro:="01"
        EndIf
    EndIf

    cQuery += " SELECT SG2.G2_CODIGO, SG2.G2_OPERAC, SG2.G2_RECURSO, SG2.G2_FERRAM, SG2.G2_DESCRI"//SH1.H1_DESCRI
    cQuery += " FROM " + RetSqlName("SG2") + " SG2 "
    cQuery += " WHERE SG2.G2_FILIAL='" + xFilial("SG2") + "'  AND SG2.G2_CODIGO= '" + cRoteiro + "' AND SG2.G2_PRODUTO= '" + cProduto + "' AND SG2.D_E_L_E_T_=' ' "
    cQuery += " ORDER BY G2_ZZSEQ, G2_OPERAC"

    TCQUERY cQuery ALIAS (cAlias3) NEW

    (cAlias3)->(DbGoTop())

    if !(cAlias3)->(EOF()) .and. !(cAlias3)->(BOF())

        While (cAlias3)->(!Eof())

            Aadd(aRot,{;
                (cAlias3)->(G2_RECURSO),;	//* 01 - Recurso
                (cAlias3)->(G2_DESCRI),;	//* 02 - Descrição
                (cAlias3)->(G2_OPERAC),;	//* 03 - Operação
                (cAlias3)->(G2_CODIGO),;	//* 04 - Código
                (cAlias3)->(G2_FERRAM),;    //* 05 - Ferramenta
                cProduto,;                  //* 06 - Produto
            })
            (cAlias3)->(DbSkip())
        EndDo
        
        (cAlias3)->(DbCloseArea())

    endif

Return

Static Function VeriImg(cProdut) 
    
    Local cCaminho := ""
    Local cAliasRot := ""
    aProd := {}

    cAliasRot := fBuscRot(cProdut)

    if !Empty(cAliasRot)

        While !(cAliasRot)->(EOF())                                                                                                    

            if ALLTRIM((cAliasRot)->AC9_ZZFICT) == "1"
                dbselectarea("ACB")
                ACB->(dbsetorder(1))
                if ACB->(dbseek(xfilial("ACB") + ALLTRIM((cAliasRot)->AC9_CODOBJ) ))

                    cCaminho := "/dirdoc/co"+cEmpAnt+"/shared/"+alltrim(ACB->ACB_OBJETO) 

                    AADD(aProd, {(cAliasRot)->AC9_ZZROTE,; //* Roteiro
                                            cCaminho;  //* Caminho Img 
                                } )

                EndIf
            Endif 

            (cAliasRot)->(DbSkip())
        EndDo
    Endif

Return

Static Function fBuscRot(cCodprod)
	
	Local cQuery  := ""
    Local cAlias4 := GetNextAlias()
    DEFAULT cCodprod := ""

        cQuery := " SELECT AC9_ZZROTE, AC9_ZZFICT, AC9_CODOBJ, CASE 
        cQuery += "     WHEN AC9_ZZROTE = ' ' THEN 'ZZ' "
        cQuery += "     ELSE AC9_ZZROTE "
        cQuery += "     END AS RESULTADO "
        cQuery += " FROM " + RetSqlName("AC9") + " AC9 "
        cQuery += " WHERE AC9_FILIAL = '" + xFilial("AC9") + "' AND AC9.D_E_L_E_T_=' ' "
        cQuery += " AND AC9_ENTIDA = 'SB1' AND AC9_FILENT = '" + xFilial("SB1") + "' AND AC9_CODENT  = '" + cCodprod+ "' "
        cQuery += " ORDER BY RESULTADO "

        TCQUERY cQuery ALIAS (cAlias4) NEW

        (cAlias4)->(DbGoTop())

        If !(cAlias4)->(EOF()) .and. !(cAlias4)->(bOF())
            Return cAlias4
        EndIf
	    
    
Return ""


User Function FERPCP1A(cOperac, cLista)
    Local cRet:= Posicione("SVH",1,xFilial("SVH")+SVH->(cLista+cOperac),"VH_ZZSEQ")
Return cRet
