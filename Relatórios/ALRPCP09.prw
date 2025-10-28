#INCLUDE "TOPCONN.CH"
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPRINTSETUP.CH"
#INCLUDE 'TOTVS.CH'

#DEFINE PRETO       RGB(000,000,000)
#DEFINE VERMELHO    RGB(255,000,000)
#DEFINE MAX_LINE 600
#Define PAD_LEFT    0
#Define PAD_RIGHT   1
#Define PAD_CENTER  2
#Define PAD_JUSTIFY 3

/*/{Protheus.doc} ALRPCP09
    Criando relatório personalizando para a impressão da ordem de produção.
    @type  Function
    @author Natan Jorge
    @since 10/07/2023
/*/
User Function ALRPCP09()
    Local aArea := GetArea()
    Local cPerg     := ""
	Private cTitle	:= "Impressão de Ordem de Produção"
	Private cTabGen	:= "50" //! Tabela genérica

	If !fPerg(cPerg)
		msgInfo("Cancelado pelo operador.")
	Else
        Processa({|| MontaRel()}, "Aguarde....", "Imprimindo Relatório", .F.)
	Endif

    RestArea(aArea)
Return

Static Function MontaRel()
    Local cCaminho := "C:\"                
    Local cArquivo := "ALRPCP09" + "_" + dToS(Date()) + "_" + StrTran(Time(), ':','')+".pdf" 
    Local nQtdTot  := 0

    Private QREL := ""
    Private nLinha  := 15
    Private nPagins := 1
    Private nLinhaItens := 20

	Private oPrint   := FwMsPrinter():New(cArquivo, IMP_PDF, .F., "", .T., /*TREP*/, @oPrint, "", /*LServ*/, /*Compatibilidade*/, /*Raw, Binario*/, .T., /**/)
    Private oFont5   := TFont():New('Arial',/*Compat.*/, 5 /*Tamanho*/, /*Compat.*/, .F. /*Negrito*/,/*Compat.*/,/*Compat.*/,/*Compat.*/,/*Compat.*/, .F./*Sublinhado*/, .F./*Itálico*/)
    Private oFont7   := TFont():New('Arial',/*Compat.*/, 7 /*Tamanho*/, /*Compat.*/, .F. /*Negrito*/,/*Compat.*/,/*Compat.*/,/*Compat.*/,/*Compat.*/, .F./*Sublinhado*/, .F./*Itálico*/)
    Private oFont8   := TFont():New('Arial',/*Compat.*/, 8 /*Tamanho*/, /*Compat.*/, .F. /*Negrito*/,/*Compat.*/,/*Compat.*/,/*Compat.*/,/*Compat.*/, .F./*Sublinhado*/, .F./*Itálico*/)
    Private oFont8B  := TFont():New('Arial',/*Compat.*/, 8 /*Tamanho*/, /*Compat.*/, .T. /*Negrito*/,/*Compat.*/,/*Compat.*/,/*Compat.*/,/*Compat.*/, .F./*Sublinhado*/, .F./*Itálico*/)
    Private oFont10  := TFont():New('Arial',/*Compat.*/, 10.5 /*Tamanho*/, /*Compat.*/, .F. /*Negrito*/,/*Compat.*/,/*Compat.*/,/*Compat.*/,/*Compat.*/, .F./*Sublinhado*/, .F./*Itálico*/)
    Private cLogo    := "D:\totvs\protheus\producao\protheus_data\system\lgrl01.bmp"
	Private cNumOP	 := ""
	Private aEmp     := {}
	Private aRot     := {}
    
    Private nLar := 33

    ProcRegua(3)

    oPrint:CPathPDF := cCaminho
    oPrint:SetPortrait()
    oPrint:SetPaperSize(9)
    
    QREL := ExecQry()

    While (QREL)->(!Eof())

        oPrint:StartPage()

        cNumOP := AllTrim((QREL)->(C2_NUM + C2_ITEM + C2_SEQUEN))

        nQtdTot := (QREL)->(C2_QUANT)

        buscaEmp(cNumOP, nQtdTot) // Empenhos

        Cabecalho() // Cabeçalho

        if mv_par05 == "S"
            buscaRot((QREL)->(C2_ROTEIRO),(QREL)->(C2_PRODUTO)) // Operações
            Processo() // Imprime as operações
        endif

        ResetVar()

        (QREL)->(DbSkip())
    end

    oPrint:Preview()

    (QREL)->(DbCloseArea())
Return

Static Function Cabecalho(lRepet)

    Local cTime := Time()
    Local cCode := ""
    Local nCont := 1

    DEFAULT lRepet := .T.

    oPrint:Line(nLinha, 10, nLinha, 585, PRETO, "-6") 

    cCode := (QREL)->(C2_NUM+C2_ITEM+C2_SEQUEN+C2_ITEMGRD)

    IncProc("Criando relatório 1 de 3 ...")

    oPrint:SayBitMap(nLinhaItens, 10, cLogo,25, 4)
    oPrint:SayAlign(nLinhaItens,  0, 'Folha: ' + ALLTRIM(STR(nPagins)),       oFont5,  585,,,  PAD_RIGHT,  )
    
    oPrint:SayAlign(nLinhaItens+=5, 10, 'SIGA/MATR820.prt/v.12',              oFont5,  600,,,  PAD_LEFT,   )
    oPrint:SayAlign(nLinhaItens,     0, 'ORDEM DE PRODUCAO NRO: ' + Alltrim(cCode),                          oFont7,  600,,,  PAD_CENTER, )
    oPrint:SayAlign(nLinhaItens,     0, 'Dt.Ref: ' + TRANSFORM( STOD((QREL)->(C2_DATRF)), "@R 99/99/9999" ), oFont5,  585,,,  PAD_RIGHT,  )

    oPrint:SayAlign(nLinhaItens+=5, 10, 'Hora: ' + cTime,                     oFont5,  600,,,  PAD_LEFT,   )
    oPrint:SayAlign(nLinhaItens,     0, 'Emissão: ' + DTOC(dDatabase),        oFont5,  585,,,  PAD_RIGHT,  )

    oPrint:SayAlign(nLinhaItens+=5, 10, 'Grupo de Empresa: ' + RTrim(SM0->M0_NOME) + ' / ' + 'Filial: ' + Alltrim(SM0->M0_FILIAL), oFont5,  600,,,  PAD_LEFT,  )

    oPrint:Line(nLinha+=30, 10, nLinha, 585, PRETO, "-6") 

    if lRepet
        //! Cabeçalho com códigos de barra
        //impressão NRO
        oPrint:Code128(nLinha+=5/*nRow*/, 10/*nCol*/,Trim(cCode)/*cCode*/,0.5/*nWidth*/,35/*nHeigth*/,.F./*lSay*/,,75)

        //impressão do código produto cliente em código de barra
        oPrint:Code128(nLinha+=5/*nRow*/, 270/*nCol*/,Trim(Posicione("SB1",1,xFilial("SB1")+(QREL)->(C2_PRODUTO),"B1_ZZCODCL"))/*cCode*/,0.5/*nWidth*/,25/*nHeigth*/,.F./*lSay*/,,60)

        //impressão do produto em código de barra
        oPrint:Code128(nLinha/*nRow*/, 455/*nCol*/,Trim((QREL)->(C2_PRODUTO))/*cCode*/,0.5/*nWidth*/,25/*nHeigth*/,.F./*lSay*/,,125)

        oPrint:SayAlign(nLinhaItens+=60, 10, 'NUMERO DA OP: ',            oFont8B,  600,,,  PAD_LEFT,  )
        oPrint:SayAlign(nLinhaItens,     74,  Alltrim((QREL)->(C2_NUM)),       oFont10,  600,,,  PAD_LEFT,  )

        oPrint:SayAlign(nLinhaItens,      0, 'CODIGO CLIENTE',            oFont8B,  600,,,  PAD_CENTER, )
        oPrint:SayAlign(nLinhaItens+=10,  0, AllTrim((QREL)->(B1_ZZCODCL)), oFont10,  600,,,  PAD_CENTER, )

        oPrint:SayAlign(nLinhaItens-=10, 450, 'PRODUTO: ',                oFont8B,  585,,,  PAD_LEFT,  )
        oPrint:SayAlign(nLinhaItens,     490, AllTrim((QREL)->(C2_PRODUTO)),   oFont10,  585,,,  PAD_LEFT,  )

        oPrint:SayAlign(nLinhaItens+=10,  10, 'ITEM:         SEQUENCIA:', oFont8B,  600,,,  PAD_LEFT, )
        oPrint:SayAlign(nLinhaItens,      35, Alltrim((QREL)->(C2_ITEM)),      oFont8,  600,,,  PAD_LEFT, )
        oPrint:SayAlign(nLinhaItens,      99, Alltrim((QREL)->(C2_SEQUEN)),    oFont8,  600,,,  PAD_LEFT, )

        oPrint:SayAlign(nLinhaItens, 450, 'QUANTIDADE OP: ',              oFont8B,  585,,,  PAD_LEFT, )
        oPrint:SayAlign(nLinhaItens, 515, ALLTRIM(STR((QREL)->(C2_QUANT),,4)), oFont10,  585,,,  PAD_LEFT, )

        oPrint:SayAlign(nLinhaItens+=10,  10, 'PREVISAO INI: __ __ ____   PREVISAO ENTREGA: __ __ ____', oFont8,  600,,,  PAD_LEFT,  )
        oPrint:SayAlign(nLinhaItens,      62, TRANSFORM( STOD((QREL)->(C2_DATPRI)), "@R 99/99/9999" ), oFont8,  600,,,  PAD_LEFT,  )
        oPrint:SayAlign(nLinhaItens,     182, TRANSFORM( STOD((QREL)->(C2_DATPRF)), "@R 99/99/9999" ), oFont8,  600,,,  PAD_LEFT,  )

        oPrint:SayAlign(nLinhaItens+=10,  10, 'OBSERVACAO: ',      oFont8B,  600,,,  PAD_LEFT,  )
        oPrint:SayAlign(nLinhaItens,      65, Alltrim((QREL)->(C2_OBS)), oFont8,  600,,,  PAD_LEFT,  )
        
        if (QREL)->(C2_ZZIMPR) == '1' // Se C2_ZZIMPR for igual a 1, é uma reimpressão
            oPrint:SayAlign(nLinhaItens, 0, "*** REIMPRESSÃO ***", oFont8B, 600,,,  PAD_CENTER, )
        else
            dbselectarea("SC2")
            SC2->(dbgoto((QREL)->(SC2RECNO)))
            reclock("SC2",.F.)
                SC2->C2_ZZIMPR := "1"
            SC2->(msunlock())
        endif        

        oPrint:SayAlign(nLinhaItens+=25,  10, 'Codigo                            Codigo Antigo                    Descricao                                                Qtd Unitaria         Qtd Total         UM         ARM         2ªQtd Unit         2ªQtd Total         2ªUM',      oFont7,  600,,,  PAD_LEFT,  )

        oPrint:Line(nLinha+=110, 10, nLinha, 585, PRETO, "-8")
    
        nLinhaItens+=10

        For nCont := 1 to LEN(aEmp)
            oPrint:SayAlign(nLinhaItens+=15,  10,  AllTrim(aEmp[nCont, 01]),                               oFont7,  600,,,  PAD_LEFT, )
            oPrint:SayAlign(nLinhaItens,      80,  AllTrim(aEmp[nCont, 02]),                               oFont7,  600,,,  PAD_LEFT, )
            oPrint:SayAlign(nLinhaItens,      155, AllTrim(aEmp[nCont, 03]),                               oFont7,  600,,,  PAD_LEFT, )
            oPrint:SayAlign(nLinhaItens,      265, StrTran(ALLTRIM(STR((aEmp[nCont, 04]),,4)), ".", "," ), oFont7,  600,,,  PAD_LEFT, )
            oPrint:SayAlign(nLinhaItens,      315, StrTran(ALLTRIM(STR((aEmp[nCont, 05]),,4)), ".", "," ), oFont7,  600,,,  PAD_LEFT, )
            oPrint:SayAlign(nLinhaItens,      360, AllTrim(aEmp[nCont, 06]),                               oFont7,  600,,,  PAD_LEFT, )
            oPrint:SayAlign(nLinhaItens,      385, AllTrim(aEmp[nCont, 07]),                               oFont7,  600,,,  PAD_LEFT, )
            oPrint:SayAlign(nLinhaItens,      415, StrTran(ALLTRIM(STR((aEmp[nCont, 08]),,4)), ".", "," ), oFont7,  600,,,  PAD_LEFT, )
            oPrint:SayAlign(nLinhaItens,      460, StrTran(ALLTRIM(STR((aEmp[nCont, 09]),,4)), ".", "," ), oFont7,  600,,,  PAD_LEFT, )
            oPrint:SayAlign(nLinhaItens,      510, AllTrim(aEmp[nCont, 10]),                               oFont7,  600,,,  PAD_LEFT, )
            nLinha+=15
        Next

        oPrint:Line(nLinha+=15, 10, nLinha, 585, PRETO, "-8") 

        IncProc("Criando relatório 2 de 3 ...")
    Endif

Return

Static Function Processo()

    Local nCont := 1
    Local cAuto := ''
    Local cImagem := ''
    Local cCrit:= '', cBarr := ''

    IncProc("Criando relatório 3 de 3 ...")

    For nCont := 1 to len(aRot)
        if nLinha > 680
            VeriQuebPg()
            Cabecalho(.F.)
        endif
        
        oPrint:Say(nLinha+=40, 15, 'PROCESSO',oFont7,,, 270)

        oPrint:Line(nLinha+10, 400, nLinha+90, 400) //! Linhas Verticais
        oPrint:Line(nLinha+10, 460, nLinha+90, 460)
        oPrint:Line(nLinha+10, 520, nLinha+90, 520)

        nLinhaItens := nLinha
        oPrint:SayAlign(nLinhaItens-=35,  25, 'REC:', oFont8,  600,,,  PAD_LEFT,  )
        oPrint:SayAlign(nLinhaItens,  50, AllTrim(aRot[nCont, 01]) + ' - '+ AllTrim(aRot[nCont, 02]), oFont8, 210,,, PAD_LEFT, )
        oPrint:SayAlign(nLinhaItens,  390, 'PREVISTO: '  + AllTrim(aRot[nCont, 05]),  oFont8,  600,,,  PAD_LEFT,  )

        cBarr := AllTrim(aRot[nCont, 11])    
        if !Empty(cBarr)
            oPrint:Code128(nLinhaItens/*nRow*/,480/*nCol*/,cBarr/*cCode*/,0.5/*nWidth*/,15/*nHeigth*/,.F./*lSay*/,,100)
        endif

        If AllTrim(aRot[nCont, 12]) == "S"
            cAuto := ' (APONTAMENTO AUTOMATICO)'
        else
            cAuto := ' '
        Endif
        
        oPrint:SayAlign(nLinhaItens+=12.5,  25, 'OPER: ' + AllTrim(aRot[nCont, 03]) + ' - ' + AllTrim(aRot[nCont, 04]) + cAuto, oFont8B,  375,,,  PAD_LEFT,  )

        oPrint:SayAlign(nLinhaItens+=12.5,  25, 'Qtd Produzida: ', oFont8,  600,,,  PAD_LEFT,  )
        oPrint:SayAlign(nLinhaItens,     165, 'Qtd de Perdas: ', oFont8,  600,,,  PAD_LEFT,  )
        oPrint:SayAlign(nLinhaItens,     390, 'FER: '+ AllTrim(aRot[nCont, 06])+'                           END: '+AllTrim(aRot[nCont, 07]),  oFont8,  600,,,  PAD_LEFT,  )

        oPrint:SayAlign(nLinha, 10, '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -', oFont8,  585,,,  PAD_LEFT,  )

        oPrint:Say(nLinha+=80, 15, 'QUALIDADE',oFont7,,, 270)
        
        nLinhaItens := nLinha

        oPrint:SayAlign(nLinhaItens-=70,  85, 'Controle 1                Controle 2                  Controle 3               Controle 4                 Controle 5               OPER. 1                OPER. 2                  CTQ ', oFont8,  600,,,  PAD_LEFT,  )
        oPrint:SayAlign(nLinhaItens+=10,  25, 'Descricao: ',       oFont8,  600,,,  PAD_LEFT,  )
        ImpriDesc(nCont)     //! Impressão das descrições
        
        oPrint:SayAlign(nLinhaItens+=25,  25, '1ª Peça:                _________              _________                 _________             _________                _________ ',  oFont8,  600,,,  PAD_LEFT,  )
        //oPrint:SayAlign(nLinhaItens+=15,  25, 'Peça Inter.            _________              _________                 _________             _________                _________ ',  oFont8,  600,,,  PAD_LEFT,  )
        oPrint:SayAlign(nLinhaItens+=15,  25, 'Ultima Peça:         _________              _________                 _________             _________                _________ ',  oFont8,  600,,,  PAD_LEFT,  )
        oPrint:SayAlign(nLinhaItens+=15,  25, 'Reinicio Prod:       _________              _________                 _________             _________                _________ ',  oFont8,  600,,,  PAD_LEFT,  )

        cCrit := AllTrim(aRot[nCont, 10])     

        if !Empty(cCrit)
            cImagem := "\system\ctq\CTQ_"+cCrit+".bmp"
            oPrint:SayBitMap(nLinhaItens-=50, 535, cImagem,25, 25)
        endif

        oPrint:Line(nLinha+=20, 10, nLinha, 585, PRETO, "-8") 
    Next

Return

Static Function VeriQuebPg() 
    
    oPrint:EndPage()
    oPrint:StartPage()

    //nLinha      := 45
    //nLinhaItens := 35
    nLinha  := 15
    nLinhaItens := 20

    nPagins++
Return

Static Function ImpriDesc(nJ)

    Local aCol       := {65,110,160,199,242}
    Local aParametro := {13, 14, 15, 16, 17}
    Local nCont      := 1, nQtdLine := 0, nI := 1
    Local cTxtLinha := '', cString := ''

    For nCont := 1 to LEN(aParametro)
        cString := Posicione("ZZ3",1,xFilial("ZZ3")+(aRot[nJ, (aParametro[nCont])]),"ZZ3_DESC")
        if ALLTRIM(cString) == ''
            cString := 'N/A'
        endif
        nQtdLine := MLCount(cString, 12)
        For nI := 1 To nQtdLine
            cTxtLinha := MemoLine(cString, 12, nI)
            if !Empty(cTxtLinha) .AND. (nI == 1)
                oPrint:SayAlign(nLinhaItens,    aCol[nCont], cTxtLinha, oFont8, aCol[nCont]+5,,, PAD_CENTER, )
            elseif !Empty(cTxtLinha) .AND. (nI == 2)
                oPrint:SayAlign(nLinhaItens+10, aCol[nCont], cTxtLinha, oFont8, aCol[nCont]+5,,, PAD_CENTER, )
            endif
        Next
    Next
Return


Static Function ResetVar()
    
    oPrint:EndPage()

    nPagins++
    nLinha  := 15
    nLinhaItens := 20
    cNumOP	 := ""
	aEmp     := {}
	aRot     := {}

Return


Static Function ExecQry()
    Local cQuery := ''
    Local cAlias := GetNextAlias()

    if mv_par02 == "         "
        mv_par02 := "ZZZZZZZZZ"
    endif
    cQuery += "SELECT SC2.C2_FILIAL, SC2.C2_NUM, SC2.C2_ITEM, SC2.C2_SEQUEN, SC2.C2_ITEMGRD, SC2.C2_DATPRF, "
    cQuery += "        SC2.C2_DATRF, SC2.C2_PRODUTO, SC2.C2_DESTINA, SC2.C2_PEDIDO, SC2.C2_ROTEIRO, SC2.C2_QUJE, "
    cQuery += "        SC2.C2_PERDA, SC2.C2_QUANT, SC2.C2_DATPRI, SC2.C2_CC, SC2.C2_DATAJI, SC2.C2_DATAJF, "
    cQuery += "        SC2.C2_STATUS, SC2.C2_OBS, SC2.C2_TPOP, SC2.C2_ZZIMPR, SC2.C2_LOCAL, "
    cQuery += "        SC2.R_E_C_N_O_  SC2RECNO, SB1.B1_DESC, SB1.B1_ZZCODCL, SB1.B1_UM "
    cQuery += "FROM " + RetSqlName("SC2")+ " SC2 "
    cQuery += "INNER JOIN SB1010 SB1 ON SB1.B1_FILIAL='"+xFilial("SB1")+"' AND SB1.B1_COD=SC2.C2_PRODUTO AND SB1.D_E_L_E_T_=' ' "
    cQuery += "    WHERE SC2.C2_FILIAL = " +xFilial("SC2")+ " AND SC2.D_E_L_E_T_=' ' AND "
    cQuery += "         SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN + SC2.C2_ITEMGRD >= '" + mv_par01 + "' AND "
    cQuery += "         SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN + SC2.C2_ITEMGRD <= '" + mv_par02 + "' AND "
    cQuery += "         SC2.C2_DATPRF BETWEEN '" + Dtos(mv_par03) + "' AND '" + Dtos(mv_par04) + "' "
    if MV_PAR06 != "A"
		cQuery	+=	" AND SC2.C2_TPOP = '" + MV_PAR06 + "' "		
	endIf
    if MV_PAR07 == "N"
		cQuery	+=	" AND SC2.C2_ZZIMPR = ' ' "		
	endIf
    cQuery	+=	" ORDER BY SC2.C2_FILIAL, SC2.C2_NUM, SC2.C2_ITEM, SC2.C2_SEQUEN, SC2.C2_ITEMGRD "
    
	cQuery := ChangeQuery(cQuery)
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAlias,.T.,.T.)
	dbSelectArea(cAlias)

Return cAlias


Static Function fPerg(cPerg)
	
	local aParambox	:= {}
	local lRet		:= .f.
	Local aRet 		:= {}
    local aSimNao   := {"S=Sim", "N=Não"}
    local aTipo		:= {"F=Firme", "P=Prevista", "A=Ambas"}
	
	aAdd(aParambox, {1, "OP de:"					,space(TamSx3("C2_NUM")[1] + TamSx3("C2_ITEM")[1] + TamSx3("C2_SEQUEN")[1])	,"@!"		,"" ,"SC2"				,"", 060,	.f.})	// MV_PAR01 
	aAdd(aParambox, {1, "OP até:"					,space(TamSx3("C2_NUM")[1] + TamSx3("C2_ITEM")[1] + TamSx3("C2_SEQUEN")[1])	,"@!"		,"" ,"SC2"				,"", 060,	.f.})	// MV_PAR02
	aAdd(aParambox, {1, "Da Data:"				    ,cToD("")															    	,""			,"" ,""					,"", 050,	.t.})	// MV_PAR03
	aAdd(aParambox, {1, "Até a Data:"			    ,cToD("")																    ,""			,"" ,""					,"", 050,	.t.})	// MV_PAR04
    aAdd(aParambox, {2, "Imprime roteiro?"	        ,"1"																	    ,aSimNao	,100,"Pertence('SN')"	,	        .f.})	// MV_PAR05
	aAdd(aParambox, {2, "Tipo OP:"					,"1"																	    ,aTipo		,100,"Pertence('AFP')"	,		    .f.})	// MV_PAR06
	aAdd(aParambox, {2, "Considera Reimpressão?"	,"1"																	    ,aSimNao	,100,"Pertence('SN')"	,	        .f.})	// MV_PAR07

	lRet := ParamBox(aParambox, cTitle, @aRet,,,,,,, cPerg, .T., .T.)
	
Return lRet

Static Function buscaEmp(cOP, nQtdTot)
	
	Local cQuery  := ""
    Local cAlias2 := GetNextAlias()
    Local nQtdUnit := 0, nTot := 0, nSegUnit  :=0, nSegTot  :=0
	Default cOP   := ""
	
	If !Empty(cOP)
        cQuery := " SELECT SD4.D4_COD, SB1.B1_ZZCANT, SB1.B1_DESC, SD4.D4_QTDEORI, SB1.B1_UM, SB1.B1_SEGUM, SD4.D4_LOCAL "
        cQuery += " FROM " + RetSqlName("SD4") + " SD4 "
        cQuery += " INNER JOIN " + RetSqlName("SB1") + " SB1 ON SB1.B1_FILIAL= '" + xFilial("SB1") + "' AND SB1.B1_COD=SD4.D4_COD AND SB1.D_E_L_E_T_=' ' "
        cQuery += " WHERE D4_OP= '" + cOP + "' AND SD4.D_E_L_E_T_=' ' "
        cQuery += " ORDER BY SD4.D4_COD "

        TCQUERY cQuery ALIAS (cAlias2) NEW

        (cAlias2)->(DbGoTop())

        If !(cAlias2)->(EOF()) .and. !(cAlias2)->(bOF())

            While (cAlias2)->(!Eof())
                nQtdUnit := (((cAlias2)->(D4_QTDEORI))/nQtdTot)
                nTot     := ((cAlias2)->(D4_QTDEORI))
                nSegUnit := convum((cAlias2)->(D4_COD),nQtdUnit,0,2)
                nSegTot  := convum((cAlias2)->(D4_COD),nTot,0,2)
                Aadd(aEmp,{;
                    (cAlias2)->(D4_COD),;		 //* Codigo
                    (cAlias2)->(B1_ZZCANT),;	 //* Cod Antigo
                    (cAlias2)->(B1_DESC),;		 //* Descrição
                    nQtdUnit,;                   //* Qtd Unitaria 
                    nTot,;	                     //* Qtd Total
                    (cAlias2)->(B1_UM),;		 //* Unidade de Medida
                    (cAlias2)->(D4_LOCAL),;		 //* ARM
                    nSegUnit,;		             //* 2ªQtd Unit
                    nSegTot,;		             //* 2ªQtd Total 
                    (cAlias2)->(B1_SEGUM);		 //* 2ªUM
                })

                (cAlias2)->(DbSkip())
            EndDo
        EndIf
	    
        (cAlias2)->(dbCloseArea())
    
    EndIf

Return

Static Function buscaRot(cRoteiro,cProduto)
	
	Local cQuery     := ""
    Local cAlias3    := GetNextAlias()
	Default cRoteiro := ""
	
    If Empty(cRoteiro)
        If !Empty(SB1->B1_OPERPAD)
            cRoteiro:=SB1->B1_OPERPAD
        Else
            If a630SeekSG2(1,(QREL)->(C2_PRODUTO),xFilial("SG2")+(QREL)->(C2_PRODUTO)+"01")
                cRoteiro:="01"
            EndIf
        EndIf
    EndIf

    cQuery += " SELECT SG2.G2_RECURSO, SH1.H1_DESCRI, SH1.H1_ZZOPAUT,SH1.H1_ZZCONT1,SH1.H1_ZZCONT2,SH1.H1_ZZCONT3,SH1.H1_ZZCONT4,SH1.H1_ZZCONT5, SG2.G2_FERRAM, SH4.H4_DESCRI, SG2.G2_OPERAC, SG2.G2_DESCRI, SG2.G2_ZZCODFE, SG2.G2_ZZENDFE, "
    cQuery += " SG2.G2_ZZPREV, SG2.G2_ZZCRIT, SG2.G2_ZZBAR "
    cQuery += " FROM " + RetSqlName("SG2") + " SG2 "
    cQuery += " INNER JOIN " + RetSqlName("SH1") + " SH1 ON SH1.H1_FILIAL= '" + xFilial("SH1") + "' AND SH1.H1_CODIGO=SG2.G2_RECURSO AND SH1.D_E_L_E_T_=' ' "
    cQuery += " LEFT JOIN " + RetSqlName("SH4") + " SH4 ON SH4.H4_FILIAL= '" + xFilial("SH4") + "' AND SH4.H4_CODIGO=SG2.G2_FERRAM AND SH4.D_E_L_E_T_=' ' "
    cQuery += " WHERE SG2.G2_FILIAL='" + xFilial("SG2") + "'  AND SG2.G2_CODIGO= '" + cRoteiro + "' AND SG2.G2_PRODUTO= '" + cProduto + "' AND SG2.D_E_L_E_T_=' ' "

    TCQUERY cQuery ALIAS (cAlias3) NEW

    (cAlias3)->(DbGoTop())

    if !(cAlias3)->(EOF()) .and. !(cAlias3)->(BOF())

        While (cAlias3)->(!Eof())

            Aadd(aRot,{;
                (cAlias3)->(G2_RECURSO),;	//* 01 - Recurso
                (cAlias3)->(H1_DESCRI),;	//* 02 - Descrição
                (cAlias3)->(G2_OPERAC),;	//* 03 - Operação
                (cAlias3)->(G2_DESCRI),;	//* 04 - Ferramenta
                (cAlias3)->(G2_ZZPREV),;	//* 05 - Previsto
                (cAlias3)->(G2_ZZCODFE),;   //* 06 - FER
                (cAlias3)->(G2_ZZENDFE),;   //* 07 - END
                (QREL)->(C2_QUJE),;         //* 08 - Qtd Produzida:         
                (QREL)->(C2_PERDA),;        //* 09 - Qtd de Perdas::  
                (cAlias3)->(G2_ZZCRIT),;    //* 10 - Crit
                (cAlias3)->(G2_ZZBAR),;     //* 11 - CodBar
                (cAlias3)->(H1_ZZOPAUT),;   //* 12 - 'AUTO'
                (cAlias3)->(H1_ZZCONT1),;   //* 13 - 'Controle 1'
                (cAlias3)->(H1_ZZCONT2),;   //* 14 - 'Controle 2'
                (cAlias3)->(H1_ZZCONT3),;   //* 15 - 'Controle 3'
                (cAlias3)->(H1_ZZCONT4),;   //* 16 - 'Controle 4'
                (cAlias3)->(H1_ZZCONT5),;   //* 17 - 'Controle 5'
            })
            (cAlias3)->(DbSkip())
        EndDo

        (cAlias3)->(DbCloseArea())

    endif

Return
