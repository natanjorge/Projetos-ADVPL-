#INCLUDE "TOPCONN.CH"
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPRINTSETUP.CH"
#INCLUDE 'TOTVS.CH'

#DEFINE PRETO       RGB(000,000,000)
#DEFINE AZUL        RGB(000,000,255)
#DEFINE MAX_LINE 750
#Define PAD_LEFT    0
#Define PAD_RIGHT   1
#Define PAD_CENTER  2
#Define PAD_JUSTIFY 3

/*
*{Protheus.doc} 
*    User Function FERPCP03 
*
*    Relatório de Packing List  
* 
*    @type  Function
*    @author Natan Jorge 
*    @since 05/06/2024
*/
User Function FERPCP03() 
    
    Local aArea := GetArea()
    Local cPerg := ""

	Private cTitle	:= "Impressão do Relatório de Packing List"
    Private aTexto	:= {}
    Private aDados	:= {}
    Private nIdioma	:= 1
    Private cLogo    := "\"+GetNewPar("ZZ_PREPIMG", "repositimgs" ) +"\Logos\logolayoutF.png" 

    If !fPerg(cPerg)
        msgInfo("Cancelado pelo operador.")
    Else
        Processa({|| MontaRel()}, "Aguarde....", "Imprimindo Relatório", .F.)
    endif 

    RestArea(aArea)
Return         

Static Function MontaRel()
    Local cCaminho := "C:\"                
    Local cArquivo := "FERPCP03" + "_" + dToS(Date()) + "_" + StrTran(Time(), ':','')+".pdf" 
    Private nLinhaItens := 15
    Private nPgAtu := 1
    Private aProd  := {}

	Private oPrint   := FwMsPrinter():New(cArquivo, IMP_PDF, .F., "", .T., /*TREP*/, @oPrint, "", /*LServ*/, /*Compatibilidade*/, /*Raw, Binario*/, .T., /**/)
    Private oFont5   := TFont():New('Arial',/*Compat.*/, 5 /*Tamanho*/, /*Compat.*/, .F. /*Negrito*/,/*Compat.*/,/*Compat.*/,/*Compat.*/,/*Compat.*/, .F./*Sublinhado*/, .F./*Itálico*/)
    Private oFont7   := TFont():New('Arial',/*Compat.*/, 7 /*Tamanho*/, /*Compat.*/, .F. /*Negrito*/,/*Compat.*/,/*Compat.*/,/*Compat.*/,/*Compat.*/, .F./*Sublinhado*/, .F./*Itálico*/)
    Private oFont7B  := TFont():New('Arial',/*Compat.*/, 7 /*Tamanho*/, /*Compat.*/, .T. /*Negrito*/,/*Compat.*/,/*Compat.*/,/*Compat.*/,/*Compat.*/, .F./*Sublinhado*/, .F./*Itálico*/)
    Private oFont75  := TFont():New('Arial',/*Compat.*/, 7.5 /*Tamanho*/, /*Compat.*/, .F. /*Negrito*/,/*Compat.*/,/*Compat.*/,/*Compat.*/,/*Compat.*/, .F./*Sublinhado*/, .F./*Itálico*/)
    Private oFont8   := TFont():New('Arial',/*Compat.*/, 8 /*Tamanho*/, /*Compat.*/, .F. /*Negrito*/,/*Compat.*/,/*Compat.*/,/*Compat.*/,/*Compat.*/, .F./*Sublinhado*/, .F./*Itálico*/)
    Private oFont8B  := TFont():New('Arial',/*Compat.*/, 8 /*Tamanho*/, /*Compat.*/, .T. /*Negrito*/,/*Compat.*/,/*Compat.*/,/*Compat.*/,/*Compat.*/, .F./*Sublinhado*/, .F./*Itálico*/)
    Private oFont10  := TFont():New('Arial',/*Compat.*/, 10.5 /*Tamanho*/, /*Compat.*/, .F. /*Negrito*/,/*Compat.*/,/*Compat.*/,/*Compat.*/,/*Compat.*/, .F./*Sublinhado*/, .F./*Itálico*/)
    Private oFont10B := TFont():New('Arial',/*Compat.*/, 10.5 /*Tamanho*/, /*Compat.*/, .T. /*Negrito*/,/*Compat.*/,/*Compat.*/,/*Compat.*/,/*Compat.*/, .F./*Sublinhado*/, .F./*Itálico*/)
    Private oFont12  := TFont():New('Arial',/*Compat.*/, 12 /*Tamanho*/, /*Compat.*/, .F. /*Negrito*/,/*Compat.*/,/*Compat.*/,/*Compat.*/,/*Compat.*/, .F./*Sublinhado*/, .F./*Itálico*/)
    Private oFont12B := TFont():New('Arial',/*Compat.*/, 12 /*Tamanho*/, /*Compat.*/, .T. /*Negrito*/,/*Compat.*/,/*Compat.*/,/*Compat.*/,/*Compat.*/, .F./*Sublinhado*/, .F./*Itálico*/)
    Private oFont14B := TFont():New('Arial',/*Compat.*/, 14 /*Tamanho*/, /*Compat.*/, .T. /*Negrito*/,/*Compat.*/,/*Compat.*/,/*Compat.*/,/*Compat.*/, .F./*Sublinhado*/, .F./*Itálico*/)
    Private oFont22B := TFont():New('Arial',/*Compat.*/, 22 /*Tamanho*/, /*Compat.*/, .T. /*Negrito*/,/*Compat.*/,/*Compat.*/,/*Compat.*/,/*Compat.*/, .F./*Sublinhado*/, .F./*Itálico*/)

	Private aEmp := {}
    Private aRot := {}

    ProcRegua(3)

    oPrint:CPathPDF := cCaminho
    oPrint:SetPortrait()
    oPrint:SetPaperSize(9)

    oPrint:StartPage()
    Cabecalho() 
    oPrint:Preview()

    
Return

Static Function Cabecalho()
 
    Local nCorAzul    := RGB(220, 230, 241) 
    Local nCorCinza   := RGB(217, 217, 217) 
    Local nCorCinCl   := RGB(200, 200, 200) 
    Local oBrushAzul  := TBRUSH():New(,nCorAzul)
    Local oBrushCinza := TBRUSH():New(,nCorCinza)
    Local oBrushCiCl  := TBRUSH():New(,nCorCinCl)
    Local dDatAtu     := date()
    Local dDatemi     := ""
    Local cObsProd    := ""
    Local cDescProd   := ""
    Local cVolAnt     := ""
    Local cAlias      := GeraQry()
    Local nLarImg     := 70
    Local nRegsum     := 0
    Local lPassou     := .F.

    If Empty(cAlias)
        Return
    Endif 

    AdcIdioma()

    dbSelectArea("SC5")
    dbSetOrder(1)
    MsSeek(xFilial("SC5")+(cAlias)->(D2_PEDIDO))

    nIdioma := MV_PAR02

    IncProc("Criando relatório 1 de 3 ...")
	
    oPrint:SayAlign(825, 0, alltrim(str(nPgAtu)), oFont8, 580,, AZUL, PAD_RIGHT, )

    oPrint:Box(nLinhaItens, 020, 820, 580, '-8')
    oPrint:SayBitMap(nLinhaItens+10, 25,cLogo,nLarImg, 30)

    dDatemi := STOD((cAlias)->(F2_EMISSAO))

    oPrint:SayAlign(nLinhaItens, 0,        "PACKING LIST Nº " + alltrim((cAlias)->(EEC_PREEMB)), oFont12B, 570,, AZUL, PAD_RIGHT, )
    oPrint:SayAlign(nLinhaItens+=10, 100,  "Vila Anhanguera, Km 320 - CEP 14070-730", oFont8B, 600,, , PAD_LEFT, )
    oPrint:SayAlign(nLinhaItens, 0,        aTexto[18, nIdioma]+DTOC(dDatAtu), oFont8B, 570,, , PAD_RIGHT, )
    oPrint:SayAlign(nLinhaItens+=10, 100,  "Brasil - Ribeirão Preto - SP - Fone +55 16 3615 0055 / +55 16 3934 1055", oFont8B, 600,, , PAD_LEFT, )
    oPrint:SayAlign(nLinhaItens+5, 370,    "CNPJ", oFont12B, 600,, AZUL, PAD_LEFT, )
    oPrint:SayAlign(nLinhaItens+5, 370,    space(12)+"43.490.424/0001-94", oFont12B, 600,, , PAD_LEFT, )
    oPrint:SayAlign(nLinhaItens+=10, 100,  "suportevendas02@ferrazmaquinas.com.br | www.ferrazmaquinas.com.br", oFont8B, 600,, , PAD_LEFT, )

    oPrint:FillRect({nLinhaItens+=20,    20.5, nLinhaItens + 50, 578.5}, oBrushAzul)
    oPrint:Line(nLinhaItens, 20, nLinhaItens, 580, PRETO, "-6") //! LINHA HORIZONTAL
    oPrint:Line(nLinhaItens,        245, (nLinhaItens+145),  245, PRETO, "-8") //! Linhas verticais
    oPrint:SayAlign(nLinhaItens,     25,  aTexto[1, nIdioma], oFont8B, 600,, AZUL, PAD_LEFT,  ) //* Importador: 
    oPrint:SayAlign(nLinhaItens,    250,  aTexto[2, nIdioma],  oFont8B, 600,, AZUL, PAD_LEFT, ) //* Dirección: 

    oPrint:SayAlign(nLinhaItens+=10, 25, (cAlias)->(A1_NOME),      oFont8B,  600,,, PAD_LEFT, )
    oPrint:SayAlign(nLinhaItens,    250, (cAlias)->(A1_END), oFont8B,  600,,, PAD_LEFT, )

    oPrint:SayAlign(nLinhaItens+=10, 25, "RUC: " + alltrim(SC5->C5_ZZRUC),  oFont8B,  600,,, PAD_LEFT, )
    oPrint:SayAlign(nLinhaItens,    250, (cAlias)->(A1_BAIRRO), oFont8B,  600,,, PAD_LEFT, )

    oPrint:SayAlign(nLinhaItens+=10, 25, (cAlias)->(A1_CONTATO), oFont8B,  600,,, PAD_LEFT, )
    oPrint:SayAlign(nLinhaItens,    250, "TEL.: " + (cAlias)->(A1_TEL), oFont8B,  600,,, PAD_LEFT, )

    oPrint:SayAlign(nLinhaItens+=10, 25, (cAlias)->(A1_EMAIL), oFont8B,  600,,, PAD_LEFT, )

    oPrint:Line(nLinhaItens+=10, 20, nLinhaItens, 580, PRETO, "-6") //! LINHA HORIZONTAL

    oPrint:SayAlign(nLinhaItens+=5, 25,  aTexto[3, nIdioma], oFont8B, 600,, AZUL, PAD_LEFT, ) //* Consignatario: 
    oPrint:SayAlign(nLinhaItens,    100, (cAlias)->(A1_CONTATO), oFont8,  600,,, PAD_LEFT, )

    oPrint:SayAlign(nLinhaItens,    250, "REF "+alltrim(SC5->C5_ZZREF), oFont7,  600,,, PAD_LEFT, )

    oPrint:Line(nLinhaItens+=10, 20, nLinhaItens, 580, PRETO, "-6") //! LINHA HORIZONTAL

    oPrint:SayAlign(nLinhaItens+=5,  20,  aTexto[4, nIdioma], oFont8B, 250,, AZUL, PAD_CENTER, )  //* Puerto de Embarque
    oPrint:SayAlign(nLinhaItens,    100,  aTexto[5, nIdioma],  oFont8B, 580,, AZUL, PAD_CENTER, ) //* Puerto de Destino

    oPrint:SayAlign(nLinhaItens+=10, 20,  "RIBEIRÃO PRETO - SP - BRASIL",    oFont8B, 250,,, PAD_CENTER, ) //!  Puerto de Embarque
    oPrint:SayAlign(nLinhaItens,     100, ALLTRIM((cAlias)->(YA_DESCR))+" - "+ALLTRIM((cAlias)->(A1_EST))+" - "+ALLTRIM((cAlias)->(A1_MUN)), oFont8B, 580,,, PAD_CENTER, ) //!  Puerto de Destino

    oPrint:Line(nLinhaItens+=10, 20, nLinhaItens, 580, PRETO, "-6") //! LINHA HORIZONTAL

    oPrint:FillRect({200, 20.5, 220, 578.5}, oBrushCinza)

    oPrint:Line(nLinhaItens,     75, 820,  75, PRETO, "-8") //! Linhas verticais
    oPrint:Line(nLinhaItens,    150, 820, 150, PRETO, "-8") //! Linhas verticais
    oPrint:Line(nLinhaItens,    420, 820, 420, PRETO, "-8") //! Linhas verticais
    oPrint:Line(nLinhaItens+45, 500, 820, 500, PRETO, "-8") //! Linhas verticais

    oPrint:SayAlign(nLinhaItens+=5,  22.5,  aTexto[6, nIdioma],            oFont8B, 50,, AZUL, PAD_CENTER, ) //* Transporte 
    oPrint:SayAlign(nLinhaItens+20,  20,  Alltrim(Posicione("SA4",1,FWxFilial("SA4") + (cAlias)->(F2_TRANSP),"A4_VIA")), oFont8,  50,,, PAD_CENTER, )
    oPrint:Line(nLinhaItens+10, 20, nLinhaItens+10, 580, PRETO, "-6") //! LINHA HORIZONTAL

    While (cAlias)->(!EOF())
        If cVolAnt <> alltrim((cAlias)->(EEC_EMBAFI)) //! Imprime o volume, se for outro 
            nRegsum++
        Endif 
        cVolAnt := alltrim((cAlias)->(EEC_EMBAFI))
        (cAlias)->(dbSkip())
    EndDo
    (cAlias)->(dbGoTop())
    cVolAnt := ""

    oPrint:SayAlign(nLinhaItens,     60,  aTexto[7, nIdioma],           oFont8B, 100,, AZUL, PAD_CENTER, ) //* EMBALAJE
    oPrint:SayAlign(nLinhaItens+20,  60,  alltrim(str(nRegsum))+aTexto[19, nIdioma], oFont8, 100,,, PAD_CENTER, )

    oPrint:SayAlign(nLinhaItens,     30,  aTexto[8, nIdioma],           oFont8B, 350,, AZUL, PAD_CENTER, ) //* FECHA DE EMBARQUE
    oPrint:SayAlign(nLinhaItens+20,  30,  MesExtenso(dDatemi) + ', '+ Year2Str(dDatemi),        oFont8, 350,,, PAD_CENTER, )

    oPrint:SayAlign(nLinhaItens,    150,  aTexto[9, nIdioma],           oFont8B, 350,, AZUL, PAD_CENTER, ) //* Pais de Origem 
    oPrint:SayAlign(nLinhaItens+10, 150,  "BRASIL", oFont8, 350,,, PAD_CENTER, )
    oPrint:Line(nLinhaItens+20, 245, nLinhaItens+20, 580, PRETO, "-6") //! LINHA HORIZONTAL

    oPrint:SayAlign(nLinhaItens,    250,  aTexto[10, nIdioma],           oFont8B, 500,, AZUL, PAD_CENTER, ) //* Pais de Destino 
    oPrint:SayAlign(nLinhaItens+10, 250,  ALLTRIM((cAlias)->(YA_DESCR)), oFont8, 500,,, PAD_CENTER, )

    oPrint:SayAlign(nLinhaItens+=20, 150, aTexto[11, nIdioma],           oFont8B, 350,, AZUL, PAD_CENTER, ) //* PESO BRUTO KG
    oPrint:SayAlign(nLinhaItens+10,  150, ALLTRIM(STR((cAlias)->(F2_PBRUTO),,2)),                 oFont8, 350,,, PAD_CENTER, )

    oPrint:SayAlign(nLinhaItens,    250,  aTexto[12, nIdioma],           oFont8B, 500,, AZUL, PAD_CENTER, ) //* PESO NETO KG
    oPrint:SayAlign(nLinhaItens+10, 250,  ALLTRIM(STR((cAlias)->(F2_PLIQUI),,2)),                  oFont8, 500,,, PAD_CENTER, )

    oPrint:Line(nLinhaItens+=20, 20, nLinhaItens, 580, PRETO, "-6") //! LINHA HORIZONTAL

    oPrint:SayAlign(nLinhaItens+=5, 20,   aTexto[13, nIdioma], oFont8B,  50,, AZUL, PAD_CENTER, ) //* ITEM
    oPrint:SayAlign(nLinhaItens,    60,   aTexto[14, nIdioma], oFont8B, 100,, AZUL, PAD_CENTER, ) //* QUANT
    oPrint:SayAlign(nLinhaItens,     0,   aTexto[15, nIdioma], oFont8B, 550,, AZUL, PAD_CENTER, ) //* DESCRIÇÃO
    oPrint:SayAlign(nLinhaItens,   250,   aTexto[12, nIdioma], oFont8B, 420,, AZUL, PAD_CENTER, ) //* PESO NETO KG
    oPrint:SayAlign(nLinhaItens,   250,   aTexto[11, nIdioma], oFont8B, 580,, AZUL, PAD_CENTER, ) //* PESO BRUTO KG

    oPrint:Line(nLinhaItens+=15, 20, nLinhaItens, 580, PRETO, "-6") //! LINHA HORIZONTAL 

    while (cAlias)->(!EOF())
        if nLinhaItens >= MAX_LINE 
            VeriQuebPg()

            oPrint:Box(nLinhaItens, 020, 820, 580, '-8')

            oPrint:FillRect({nLinhaItens+0.5, 20.5, nLinhaItens+25, 578.5}, oBrushCinza)

            oPrint:Line(nLinhaItens,     75, 820,  75, PRETO, "-8") //! Linhas verticais
            oPrint:Line(nLinhaItens,    150, 820, 150, PRETO, "-8") //! Linhas verticais
            oPrint:Line(nLinhaItens,    420, 820, 420, PRETO, "-8") //! Linhas verticais
            oPrint:Line(nLinhaItens,    500, 820, 500, PRETO, "-8") //! Linhas verticais

            oPrint:SayAlign(nLinhaItens+=5, 20,   aTexto[13, nIdioma], oFont8B,  50,, AZUL, PAD_CENTER, ) //* ITEM
            oPrint:SayAlign(nLinhaItens,    60,   aTexto[14, nIdioma], oFont8B, 100,, AZUL, PAD_CENTER, ) //* QUANT
            oPrint:SayAlign(nLinhaItens,     0,   aTexto[15, nIdioma], oFont8B, 550,, AZUL, PAD_CENTER, ) //* DESCRIÇÃO
            oPrint:SayAlign(nLinhaItens,   250,   aTexto[12, nIdioma], oFont8B, 420,, AZUL, PAD_CENTER, ) //* PESO NETO KG
            oPrint:SayAlign(nLinhaItens,   250,   aTexto[11, nIdioma], oFont8B, 580,, AZUL, PAD_CENTER, ) //* PESO BRUTO KG


            oPrint:Line(nLinhaItens+=20, 20, nLinhaItens, 580, PRETO, "-6")

            oPrint:SayAlign(825, 0, alltrim(str(nPgAtu)), oFont8, 580,, AZUL, PAD_RIGHT, )

        endif
        lPassou := .F.
        If cVolAnt <> alltrim((cAlias)->(EEC_EMBAFI)) //! Imprime o volume, se for outro 
            oPrint:Line(nLinhaItens, 20, nLinhaItens, 580, PRETO, "-6") //! LINHA HORIZONTAL 
            oPrint:FillRect({nLinhaItens+0.5, 20.5, nLinhaItens+19.5, 578.5}, oBrushCiCl)
            oPrint:SayAlign(nLinhaItens+=5, 20, "VOLUME - ", oFont8B, 50 ,,, PAD_CENTER, )
            oPrint:SayAlign(nLinhaItens,    60, alltrim((cAlias)->(EEC_EMBAFI)), oFont8B, 50 ,,, PAD_CENTER, )
            oPrint:SayAlign(nLinhaItens,   150, alltrim((cAlias)->(EE5_DESC)), oFont8B, 50 ,,, PAD_CENTER, )
            oPrint:SayAlign(nLinhaItens,   420, aTexto[16, nIdioma], oFont8B, 600,,, PAD_LEFT, )
            oPrint:SayAlign(nLinhaItens,   470, alltrim(STR((cAlias)->(EE5_HALT)))+" mm x " +alltrim(STR( (cAlias)->(EE5_LLARG)))+" mm x " +alltrim(STR( (cAlias)->(EE5_CCOM)))+" mm", oFont8B, 600,,, PAD_LEFT, )

            oPrint:Line(nLinhaItens+=15, 20, nLinhaItens, 580, PRETO, "-6") //! LINHA HORIZONTAL 
            nLinhaItens+=10
            
            oPrint:SayAlign(nLinhaItens, 160, aTexto[17, nIdioma], oFont8B, 600,, AZUL, PAD_LEFT, ) //* O QUE CONTEM DENTRO DA CAIXA
            lPassou := .T.
        Endif 

        oPrint:SayAlign(nLinhaItens, 20,   alltrim((cAlias)->(D2_ITEM)),       oFont8B, 50 ,,, PAD_CENTER, )
        oPrint:SayAlign(nLinhaItens,     60,   alltrim(str((cAlias)->(D2_QUANT))), oFont8B, 100,,, PAD_CENTER, )
        //oPrint:SayAlign(nLinhaItens,    160,   aTexto[16, nIdioma],                oFont8B, 600,, AZUL, PAD_LEFT, ) //* DIMENSÕES 
        //oPrint:SayAlign(nLinhaItens,    220,   alltrim(STR((cAlias)->(B5_ECPROFU)))+" mm x " +alltrim(STR( (cAlias)->(B5_LARG)))+" mm x " +alltrim(STR( (cAlias)->(B5_ALTURA)))+" mm", oFont8B, 600,,, PAD_LEFT, )

        oPrint:SayAlign(nLinhaItens,   250,    alltrim(STR((cAlias)->(B1_PESO),,2)),   oFont8B, 420,,, PAD_CENTER, )
        oPrint:SayAlign(nLinhaItens,   250,    alltrim(STR((cAlias)->(B1_PESBRU),,2)), oFont8B, 580,,, PAD_CENTER, )

        //oPrint:SayAlign(nLinhaItens+=10, 160, aTexto[17, nIdioma],         oFont8B, 600,, AZUL, PAD_LEFT, ) //* O QUE CONTEM DENTRO DA CAIXA

        //oPrint:SayAlign(nLinhaItens+=10, 160, (cAlias)->(B1_DESC), oFont8B, 600,,, PAD_LEFT, )
        If !lPassou
            nLinhaItens-=10
        Endif 

        cDescProd := GeraConsulta((cAlias)->(D2_PEDIDO), (cAlias)->(D2_ITEMPV))

        if Empty(cDescProd)
            cDescProd := (cAlias)->(DESCPROD)
        Else 
            cDescProd := MSMM(cDescProd, 100)
        Endif 

        VeriQuebLn(cDescProd, 55, 160)

        IF nIdioma == 1
            cObsProd := posicione("SB1",1,xFilial("SB1")+(cAlias)->(D2_COD),"B1_ZZPKLT")
        Elseif nIdioma == 2
            cObsProd := posicione("SB1",1,xFilial("SB1")+(cAlias)->(D2_COD),"B1_ZZPKIN")
        Elseif nIdioma == 3
            cObsProd := posicione("SB1",1,xFilial("SB1")+(cAlias)->(D2_COD),"B1_ZZPKES")
        endif 
        
        VeriQuebLn(cObsProd, 110, 160)
        nLinhaItens+=20

        cVolAnt := alltrim((cAlias)->(EEC_EMBAFI))

        (cAlias)->(DbSkip())
    end

Return

Static Function VeriQuebPg() 
    
    oPrint:EndPage()
    oPrint:StartPage()

    nLinhaItens := 20
    nPgAtu++
Return

Static Function VeriQuebLn(cString, nLineTam, nCol, nLinQtd)
    
    Local nI := 1
    Local nQtdLine := MLCount(cString, nLineTam)
    
    DEFAULT nLinQtd  := 100

    For nI := 1 To nQtdLine

        cTxtLinha := MemoLine(cString, nLineTam, nI)

        If !Empty(cTxtLinha) .AND. (nI <= nLinQtd)
            if nLinhaItens >= MAX_LINE
                VeriQuebPg()
            endif

            oPrint:SayAlign(nLinhaItens+=10, nCol, cTxtLinha, oFont10, 600,,, PAD_LEFT, )

        EndIf
    Next nI

Return

Static Function GeraQry()

	Local cQuery  := ""
    Local cAlias2 := GetNextAlias()

    cQuery := " SELECT EE9_NF, EE9_SERIE,EEC_PEDFAT, EE9_PEDIDO,EE9_FATIT,                       " + CRLF
    cQuery += " A1_NOME, A1_END, A1_BAIRRO, A1_CONTATO, A1_TEL, A1_EMAIL, A1_EST, A1_MUN,        " + CRLF
    IF nIdioma == 1
        cQuery += " B1_DESC AS DESCPROD, " + CRLF //! Descrição em Português 
    Elseif nIdioma == 2
        cQuery += " B1_ZZDSCI AS DESCPROD,  " + CRLF //! Descrição em Ingles
    Elseif nIdioma == 3
        cQuery += " B1_ZZDSCE AS DESCPROD, " + CRLF //! Descrição em Espanhol
    endif 
    cQuery += " B1_PESO, B1_PESBRU,                                                              " + CRLF
    cQuery += " YA_DESCR,                                                                        " + CRLF
    cQuery += " EEC_PREEMB,                                                                      " + CRLF
    cQuery += " F2_EMISSAO, F2_TRANSP, F2_PBRUTO, F2_PLIQUI,                                     " + CRLF
    cQuery += " D2_ITEM, D2_QUANT, D2_COD, D2_PEDIDO, D2_ITEMPV,                                " + CRLF
    cQuery += " EE5_DESC, EE5_CCOM, EE5_LLARG, EE5_HALT, EE5_PESO,                              " + CRLF
    cQuery += " EEC_EMBAFI,                                                                      " + CRLF
    cQuery += " B5_ALTURA, B5_LARG, B5_ECPROFU                                                   " + CRLF
    cQuery += " FROM " + RetSqlName("EEC") + " EEC                                               " + CRLF
    cQuery += " INNER JOIN " + RetSqlName("EE9") + " EE9 ON EE9_PREEMB = EEC_PREEMB AND EEC_FILIAL = EE9_FILIAL AND EE9.D_E_L_E_T_ = ' '                         " + CRLF
    cQuery += " INNER JOIN " + RetSqlName("SF2") + " SF2 ON F2_FILIAL = EE9_FILIAL AND F2_DOC = EE9_NF AND F2_SERIE = EE9_SERIE AND SF2.D_E_L_E_T_ = ' '       " + CRLF
    cQuery += " INNER JOIN " + RetSqlName("SD2") + " SD2 ON D2_FILIAL = F2_FILIAL AND D2_DOC = F2_DOC AND D2_SERIE = F2_SERIE AND EE9_COD_I = D2_COD AND SD2.D_E_L_E_T_ = ' ' " + CRLF
    cQuery += " INNER JOIN " + RetSqlName("SA1") + " SA1 ON A1_FILIAL = '" + FWxFilial("SA1") + "' AND A1_COD = F2_CLIENTE AND A1_LOJA = F2_LOJA AND SA1.D_E_L_E_T_ = ' ' " + CRLF
    cQuery += " INNER JOIN " + RetSqlName("SB1") + " SB1 ON B1_FILIAL = '" + FWxFilial("SB1") + "' AND B1_COD = D2_COD AND SB1.D_E_L_E_T_ = ' '                                         " + CRLF
    cQuery += " LEFT JOIN  " + RetSqlName("EE5") + " EE5 ON EE5_FILIAL = '' AND EEC_EMBAFI = EE5_CODEMB AND EE5.D_E_L_E_T_ = ' ' " + CRLF
    cQuery += " LEFT JOIN  " + RetSqlName("SYA") + " SYA ON YA_FILIAL = '" + FWxFilial("SYA") + "' AND YA_CODGI = A1_PAIS AND  SYA.D_E_L_E_T_ = ' '                                     " + CRLF
    cQuery += " LEFT JOIN  " + RetSqlName("SB5") + " SB5 ON B5_FILIAL = '" + FWxFilial("SB1") + "' AND B1_COD = B5_COD AND SB5.D_E_L_E_T_ = ' '                                         " + CRLF
    cQuery += " WHERE EEC.D_E_L_E_T_ = ' '                                                                                                                      " + CRLF
    cQuery += " AND EEC_PREEMB = '" + mv_par01 + "' " + CRLF
    cQuery += " ORDER BY EEC_EMBAFI, D2_ITEM " + CRLF //TESTE COM:     EMB-24/0001

    TCQUERY cQuery ALIAS (cAlias2) NEW

    (cAlias2)->(DbGoTop())

    if (cAlias2)->(EOF())
       cAlias2 := '' 
    endif

Return cAlias2

Static Function AdcIdioma()

    aAdd(aTexto,{"IMPORTADOR: ","IMPORTER: ","IMPORTADOR: "})
    aAdd(aTexto,{"ENDEREÇO: ","ADDRESS: ","DIRECCIÓN: "})
    aAdd(aTexto,{"CONSIGNATÁRIO","CONSIGNEE","CONSIGNATARIO"})
    aAdd(aTexto,{"PORTO DE EMBARQUE","PORT OF LOADING","PUERTO DE EMBARQUE"})
    aAdd(aTexto,{"PORTO DE DESTINO","PORT OF DESTINATION","PUERTO DE DESTINO"}) //! 5

    aAdd(aTexto,{"TRANSPORTE","TRANSPORT","TRANSPORTE"})
    aAdd(aTexto,{"EMBALAGEM","PACKAGING","EMBALAJE"})
    aAdd(aTexto,{"DATA DE EMBARQUE","SHIPMENT DATE","FECHA DE EMBARQUE"})
    aAdd(aTexto,{"PAÍS DE ORIGEM","COUNTRY OF ORIGIN","PAIS DE ORIGEN"})
    aAdd(aTexto,{"PAÍS DE DESTINO","COUNTRY OF DESTINATION","PAIS DE DESTINO"}) //! 10

    aAdd(aTexto,{"PESO BRUTO KG","GROSS WEIGHT KG","PESO BRUTO KG"})
    aAdd(aTexto,{"PESO NETO KG","NET WEIGHT KG","PESO NETO KG"})
    aAdd(aTexto,{"ITEM","ITEM","ARTÍCULO"})
    aAdd(aTexto,{"QUANT.","QUANTITY","CANT."})
    aAdd(aTexto,{"DESCRIÇÃO","DESCRIPTION","DESCRIPCIÓN"}) //! 15

    aAdd(aTexto,{"DIMENSÕES: ","DIMENSIONS: ","DIMENSIONES: "})
    aAdd(aTexto,{"O QUE CONTÉM DENTRO: ","WHAT IT CONTAINS INSIDE: ","QUE CONTIENE EN SU INTERIOR: "})
    aAdd(aTexto,{"DATA: ","DATE: ","FECHA: "})
    aAdd(aTexto,{" VOLUMES"," VOLUMES"," VOLÚMENES"})

Return

Static Function fPerg(cPerg)

	local aParambox	:= {}
	local lRet		:= .f.
	Local aRet 		:= {}
    Local cTitle	:= "Gerar Packing List"
    Local aOpcoes	:= { "Português", "Inglês", "Espanhol" }

	aAdd(aParambox, {1, "Processo Embarque" , space(TamSx3("EEC_PREEMB")[1]), "@!","" ,"EEC" ,"" , 100, .T.})   //* MV_PAR01 
    aAdd(aParambox, {3, "Idioma:", 1,aOpcoes, 060, "",.T.})                                                  //* MV_PAR02
  
	lRet := ParamBox(aParambox, cTitle, @aRet,,,,,,, cPerg, .T., .T.)

Return lRet

Static Function GeraConsulta(cPed, cItemPv)

    Local cQry   := ""
    Local cRet   := ""
    Local aDados := {}
    DEFAULT cPed    := ""
    DEFAULT cItemPv := ""

    cQry := " SELECT EE8_DESC "+CRLF 
    cQry += " FROM "+RetSqlName("EE7") + " EE7" +CRLF
    cQry += " INNER JOIN " + RetSqlName("EE8") + " EE8 ON EE8_FILIAL = EE7_FILIAL AND EE8_FATIT = '" + cItemPv + "' AND EE7_PEDIDO = EE8_PEDIDO AND EE8.D_E_L_E_T_ = ' ' " + CRLF
    cQry += " WHERE EE7_PEDFAT = '" + cPed + "' AND EE7.D_E_L_E_T_ = '' "

    aDados := QryArray(cQry)

    if !EMPTY(aDados)
        cRet   := aDados[1][1]
    endif 
    
Return cRet
