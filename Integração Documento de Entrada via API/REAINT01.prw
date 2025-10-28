#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "FILEIO.CH"
#INCLUDE "rwmake.ch"

/* 
* {Protheus.doc} REAINT01
* A função recebe um XML de Nota Fiscal de entrada e executa duas etapas principais:
*     Gera um Pedido de Compras (SC7) via MSExecAuto da rotina MATA121 com os itens do XML.
*     Gera a Pré-Nota (SF1/SD1) via MSExecAuto da rotina MATA140, vinculando os itens à OC gerada.
* @type user function
* @author Natan Jorge
* @since 18/08/2025
* @Return: 
*     lRetInt (boolean): sucesso/fracasso da importação
*     cMsgRet (texto): mensagem descritiva do resultado
*     cCodStats (código): status de processamento (mapa completo abaixo)
* @see: U_REAINT04()
/*/
User Function REAINT01()

    Local lRetInt  := .F.

    Private cMotivo := ""
    Private __lSEVlBld := .F. // Desativa validacao do balde
    Private nItens 

    Private lMsHelpAuto    := .T.
    Private lMsErroAuto    := .F.
    Private lAutoErrNoFile := .T.
    Private cEmpresa       := ""
    Private cFilEmp        := ""

    If oXml == NIL
        cMsgRet   := "Nao Importado - Corrompido"  
        cCodStats := "407"
    else

        cNFProb := oXML:_NOTAFISCAL:_NUMERONF:TEXT
        cSrProb := oXML:_NOTAFISCAL:_SERIE:TEXT
        cChvNFe := oXML:_NOTAFISCAL:_CHAVENFE:TEXT

        if !ValidEmp()
            cMsgRet   := "Nao Importado - Falha inicializacao do Ambiente" //! especificar registro
            cCodStats := "408"
            Return lRetInt
        endif

        if GrvReg()
            
            cMsgRet   := "Registro Importado - Doc: " + ALLTRIM(cNFProb) + "' Serie: " + ALLTRIM(cSrProb) + " Empresa/Filial: '" + ALLTRIM(cEmpresa) +'/'+ALLTRIM(cFilEmp) +"' "
            cCodStats := "201"
            lRetInt   := .T. 

        else
            If Empty(cMsgRet)
                cMsgRet   := 'Erro na gravacao do pedido de compras.'
                cCodStats := '404'
            Endif 
        endif
    endif

    

Return lRetInt

static function GrvReg()
    Local aCabec        := {}
    Local aItens        := {}
    Local aLinha        := {}
    Local nX            := 0
    Local lRet          := .T.
    Local cTesPrd       := ""
    Local cProdut       := ""
    Local cNota         := ""
    Local cSerie        := ""
    Local cForn	        := ""
    Local cLojFor       := ""
    Local cCCCod        := ""
    Local nVUnit        := 0
    Local nTamNF        := TamSx3("F1_DOC")[1]
    Local nTamSer       := TamSx3("F1_SERIE")[1]
    Local nTamFor       := TamSx3("F1_FORNECE")[1]
    Local nTamLoj       := TamSx3("F1_LOJA")[1]
    Local lZZVLDCHNF    := SuperGetMv("ZZ_VLDCHNF",,.f.)
    Local cOldFName     := FunName()
    Local nError        := 1
    Local aErrorLog     := {}
    Local cMsgStatsrLog := ""
    
    dbSelectArea("SC7")
    dbSelectArea("SB1")
    dbSelectArea("SF4")
    dbSelectArea("SE4")
    dbSelectArea("SA2")
    dbSelectArea("SF1")
    dbSelectArea("CTT")

    if VALTYPE(XmlChildEx(oXML:_NOTAFISCAL:_PRODUTOS,"_PRODUTO"))== "U" .or. VALTYPE(XmlChildEx(oXML:_NOTAFISCAL,"_FRETE"))== "U"
        cMsgRet := "Falha na Montagem da TAG Produto"
        cCodStats := "413"
        Return .F.
    endif

    XmlCloneNode(oXML:_NOTAFISCAL:_PRODUTOS:_PRODUTO, "_PRODUTO")

    cNota  := Alltrim(oXml:_NOTAFISCAL:_NUMERONF:TEXT)
    cNota  := cNota + Space(nTamNF - len(cNota))
      
    cSerie := Alltrim(oXml:_NOTAFISCAL:_SERIE:TEXT)
    cSerie := cSerie + Space(nTamSer - len(cSerie))
    
    cForn  := Alltrim(SUBS(oXML:_NOTAFISCAL:_CODIGOFORNECEDOR:TEXT,1,6))
    cForn  := cForn + Space(nTamFor - len(cForn))
     
    cLojFor := Alltrim(SUBS(oXML:_NOTAFISCAL:_CODIGOFORNECEDOR:TEXT,7,2))
    cLojFor := cLojFor + Space(nTamLoj - len(cLojFor))

    dbSelectArea("SF1")
    SF1->(dbSetOrder(1))
    
    if SF1->(dbSeek(xFilial("SF1") + cNota + cSerie + cForn + cLojFor))
        cMsgRet := "Nota fiscal ja existe no sistema. Importacao deste arquivo abortada."
        cCodStats := "407"
        Return .F.
    endif

    cCCCod := oXML:_NOTAFISCAL:_CODIGOCENTROCUSTO:TEXT

    dbSelectArea("SB1")
    dbSetOrder(1)
    for nX := 1 to len(oXML:_NOTAFISCAL:_PRODUTOS:_PRODUTO) - 1
        
        cProdut := oXML:_NOTAFISCAL:_PRODUTOS:_PRODUTO[nX]:_CODIGO:TEXT

        if !SB1->(dbSeek(xFilial("SB1") + cProdut)) .or. Empty(cProdut) 
            cMsgRet := "Produto: " + cProdut + " nao informado ou nao cadastrado!"
            cCodStats := "408"
            Return .F.
        Else    
            If SB1->B1_MSBLQL == "1"
                cMsgRet := "Produto: " + cProdut + " com bloqueio!"
                cCodStats := "418"
                Return .F.
            EndIf
        EndIf

        cTesPrd := POSICIONE("SB1",1, xFilial("SB1") + cProdut,"B1_TE")

        dbSelectArea("SF4")
        dbSetOrder(1)
        If !SF4->(MsSeek(xFilial("SF4") + cTesPrd)) .or. Empty(cTesPrd)
            cMsgRet := "Nao há TES cadastrado para o produto: " + cProdut
            cCodStats := "409"
            Return .F.
        Else
            If SF4->F4_MSBLQL == "1"
                cMsgRet := "TES com bloqueio!"
                cCodStats := "420"   
                Return .F.
            Endif 
        Endif

        if !VeriBalde(cProdut,cCCCod)
            Return .F.
        endif    

    next

    dbSelectArea("SE4")
    dbSetOrder(1)
    If !SE4->(MsSeek(xFilial("SE4") + oXML:_NOTAFISCAL:_CONDICAOPAGAMENTO:TEXT)) .or. Empty(oXML:_NOTAFISCAL:_CONDICAOPAGAMENTO:TEXT)
        cMsgRet := "Cond.Pagto nao cadastrada"    
        cCodStats := "410"
        Return .F.
    EndIf

    dbSelectArea("SA2")
    dbSetOrder(1)
    If !SA2->(MsSeek(xFilial("SA2") + SUBS(oXML:_NOTAFISCAL:_CODIGOFORNECEDOR:TEXT,1,6) + SUBS(oXML:_NOTAFISCAL:_CODIGOFORNECEDOR:TEXT,7,2))) .or. Empty(oXML:_NOTAFISCAL:_CODIGOFORNECEDOR:TEXT)
        cMsgRet := "Fornecedor nao cadastrado!"
        cCodStats := "411"
        Return .F.
    Else    
        If SA2->A2_MSBLQL == "1"
            cMsgRet := "Fornecedor com bloqueio!"
            cCodStats := "417"   
            Return .F.
        Endif 
    EndIf

    dbSelectArea("CTT")
    dbSetOrder(1)
    if !CTT->(MsSeek(xFilial("CTT") + cCCCod)) .or. Empty(cCCCod)
        cMsgRet := "Centro de Custos: " + cCCCod + " nao cadastrado!"
        cCodStats := "412"
        Return .F.
    Else
        If CTT->CTT_BLOQ == "1"
            cMsgRet := "Centro de Custos com bloqueio!"
            cCodStats := "419"   
            Return .F.
        Endif 
    endif
    
    if lZZVLDCHNF .and. Empty(oXML:_NOTAFISCAL:_CHAVENFE:TEXT) .and. Alltrim(oXml:_NOTAFISCAL:_ESPECIE:TEXT) = "SPED"
        cMsgRet   := "Chave da NFe: " + oXml:_NOTAFISCAL:_NUMERONF:TEXT + " nao Preenchida!"
        cCodStats := "414"
        Return .F.
    endif    

    aCabec := {}
    aItens := {}
     
    cPedCom := GetNumSC7()
        
    aadd(aCabec,{"C7_NUM", cPedCom})
    aadd(aCabec,{"C7_EMISSAO", dDataBase})
    aadd(aCabec,{"C7_FORNECE", SUBS(oXML:_NOTAFISCAL:_CODIGOFORNECEDOR:TEXT,1,6)})
    aadd(aCabec,{"C7_LOJA", SUBS(oXML:_NOTAFISCAL:_CODIGOFORNECEDOR:TEXT,7,2)})
    aadd(aCabec,{"C7_COND", oXML:_NOTAFISCAL:_CONDICAOPAGAMENTO:TEXT})
    aadd(aCabec,{"C7_CONTATO", ""})
    aadd(aCabec,{"C7_FILENT", cFilAnt})
    aadd(aCabec,{"C7_ZZCONTR","0"})
    aadd(aCabec,{"C7_ZZIMPOK","0"})
    aadd(aCabec,{"C7_TPFRETE","C"})
    aadd(aCabec,{"C7_FRETE",Val(oXML:_NOTAFISCAL:_FRETE:TEXT)})
    aadd(aCabec,{"C7_DESPESA",Val(oXML:_NOTAFISCAL:_DESPESAS:TEXT)})
    aadd(aCabec,{"C7_SEGURO",Val(oXML:_NOTAFISCAL:_SEGURO:TEXT)})

    For nX := 1 To len(oXML:_NOTAFISCAL:_PRODUTOS:_PRODUTO) - 1
        aLinha := {}

        nVUnit := ROUND(VAL(oXML:_NOTAFISCAL:_PRODUTOS:_PRODUTO[nX]:_VALORTOTAL:TEXT) / VAL(oXML:_NOTAFISCAL:_PRODUTOS:_PRODUTO[nX]:_QUANTIDADE:TEXT),2)
       
        aadd(aLinha,{"C7_ITEM",    oXML:_NOTAFISCAL:_PRODUTOS:_PRODUTO[nX]:_NUMEROITEM:TEXT,Nil} )
        aadd(aLinha,{"C7_PRODUTO", oXML:_NOTAFISCAL:_PRODUTOS:_PRODUTO[nX]:_CODIGO:TEXT, Nil})
        aadd(aLinha,{"C7_QUANT",   ROUND(VAL(oXML:_NOTAFISCAL:_PRODUTOS:_PRODUTO[nX]:_QUANTIDADE:TEXT),2), Nil})
        aadd(aLinha,{"C7_PRECO",   nVUnit, Nil})
        aadd(aLinha,{"C7_CC",      cCCCod, Nil})
        aadd(aLinha,{"C7_OBS",     "OC GENIAL " + Alltrim(oXML:_NOTAFISCAL:_PRODUTOS:_PRODUTO[nX]:_CODIGOOC:TEXT), Nil})
        aadd(aLinha,{"C7_ORIGEM" , "REAINT01", Nil})
        aadd(aItens,aLinha)
    Next nX

    nItens := len(aItens)

	SetFunName("MATA121")

	lMsHelpAuto    := .T.
	lMsErroAuto    := .F.
	lAutoErrNoFile := .T.

	Begin Transaction

	    MSExecAuto({| u,v,x| MATA121(u,v,x)}, aCabec, aItens, 3)
	
		If lMsErroAuto
			
	    	aErrorLog := GETAUTOGRLOG()
	    	
	    	For nError := 1 To Len(aErrorLog)
	    	
	    		cMsgStatsrLog += aErrorLog[nError] + Chr(13) + Chr(10)
	    	
	    	Next nError
	    	
	    	While __lSx8
				RollBackSxe()
			End
			
            cMsgRet := "Erro na inclusao no pedido de compras"
            cCodStats := "415"
	    	lRet := .F.
	    	DisarmTransaction()
	    Else

	    	ConfirmSx8()
			While __lSx8
				ConfirmSx8()
			End
			
	     	lRet :=  GrvPreNota(cPedCom)

	    EndIf
    
    End Transaction
    
    SetFunName(cOldFName)
Return lRet

static function ValidEmp()
    Local cCNPJ := ""
    Local lRet  := .F.

    cCNPJ := ALLTRIM(STRTRAN(STRTRAN(STRTRAN(oXml:_NOTAFISCAL:_EMPRESA:TEXT,"."),"/"),"-"))
    OpenSM0()
    dbSelectArea("SM0")
    SM0->(dbSetOrder(1))
    SM0->(dbGoTop())
    while SM0->(!Eof())
        if SM0->M0_CGC == cCNPJ
            cEmpresa := SM0->M0_CODIGO
            cFilEmp  := allTrim(SM0->M0_CODFIL)
            lRet := .T.
            EXIT
        endif
        SM0->(dbSkip())
    end

    if lRet
        RpcClearEnv()
        RPCSetType(2)
        RpcSetEnv(cEmpresa, cFilEmp, , ,"COM")
    EndIf    

Return lRet

Static function GrvPreNota(cPedNum)
	Local X
	Local aCabec := {}
	Local aItens := {}
	Local aItensPC := {}
	Local lRetNota       := .T.
	Local nVUnit      := 0
	Local nError      := 0
    Local aErrorLog   := {}
    Local cMsgStatsrLog   := ""
 
    aAdd(aCabec,{"F1_DOC"    , oXml:_NOTAFISCAL:_NUMERONF:TEXT,                     Nil})
	aAdd(aCabec,{"F1_SERIE"  , oXml:_NOTAFISCAL:_SERIE:TEXT,                        Nil})
	aAdd(aCabec,{"F1_FORNECE", SUBSTR(oXML:_NOTAFISCAL:_CODIGOFORNECEDOR:TEXT,1,6), Nil})
	aAdd(aCabec,{"F1_LOJA"   , SUBSTR(oXML:_NOTAFISCAL:_CODIGOFORNECEDOR:TEXT,7,2), Nil})
	aAdd(aCabec,{"F1_EMISSAO", STOD(oXML:_NOTAFISCAL:_DATAEMISSAO:TEXT),            Nil})
	aAdd(aCabec,{"F1_DTDIGIT", STOD(oXML:_NOTAFISCAL:_DATAENTRADA:TEXT),            Nil})
	aAdd(aCabec,{"F1_ESPECIE", oXml:_NOTAFISCAL:_ESPECIE:TEXT,                      Nil})
    aadd(aCabec,{"F1_FRETE"	 , Val(oXML:_NOTAFISCAL:_FRETE:TEXT),                   Nil})
    aadd(aCabec,{"F1_DESPESA", Val(oXML:_NOTAFISCAL:_DESPESAS:TEXT),                Nil})
    aadd(aCabec,{"F1_SEGURO" , Val(oXML:_NOTAFISCAL:_SEGURO:TEXT),                  Nil})	
    aAdd(aCabec,{"F1_CHVNFE" , oXML:_NOTAFISCAL:_CHAVENFE:TEXT,                     Nil})
    
    aCabec := FwVetByDic(aCabec, "SF1")
    
    for X := 1 to LEN(oXML:_NOTAFISCAL:_PRODUTOS:_PRODUTO) -1

        nVUnit := ROUND(VAL(oXML:_NOTAFISCAL:_PRODUTOS:_PRODUTO[X]:_VALORTOTAL:TEXT) / VAL(oXML:_NOTAFISCAL:_PRODUTOS:_PRODUTO[X]:_QUANTIDADE:TEXT),2)

        aItensPC:={     {"D1_DOC"    ,oXml:_NOTAFISCAL:_NUMERONF:TEXT,                                  Nil},;
                        {"D1_ITEM"   ,oXML:_NOTAFISCAL:_PRODUTOS:_PRODUTO[X]:_NUMEROITEM:TEXT, 			Nil},;
                        {"D1_COD"    ,oXML:_NOTAFISCAL:_PRODUTOS:_PRODUTO[X]:_CODIGO:TEXT,              Nil},;
                        {"D1_QUANT"  ,VAL(oXML:_NOTAFISCAL:_PRODUTOS:_PRODUTO[X]:_QUANTIDADE:TEXT),     Nil},;
                        {"D1_VUNIT"  ,nVUnit,                                                           Nil},;
                        {"D1_FORNECE",SUBSTR(oXML:_NOTAFISCAL:_CODIGOFORNECEDOR:TEXT,1,6),              Nil},;
                        {"D1_LOJA"   ,SUBSTR(oXML:_NOTAFISCAL:_CODIGOFORNECEDOR:TEXT,7,2),              Nil},;
                        {"D1_EMISSAO",STOD(oXML:_NOTAFISCAL:_DATAEMISSAO:TEXT),                         Nil},;
                        {"D1_DOC"    ,oXml:_NOTAFISCAL:_NUMERONF:TEXT,                                  Nil},;
                        {"D1_SERIE"  ,oXml:_NOTAFISCAL:_SERIE:TEXT,                                     Nil},;
                        {"D1_TIPO"   ,"N",                                                              Nil},;
                        {"D1_PEDIDO" ,cPedNum,                                                           Nil},;
                        {"D1_ITEMPC" ,oXML:_NOTAFISCAL:_PRODUTOS:_PRODUTO[X]:_NUMEROITEM:TEXT,          Nil};
                  }
        aItensPC := FwVetByDic(aItensPC, "SD1")          
        aAdd(aItens,aItensPC) 
    next
    
	SetFunName("MATA140")

	lMsHelpAuto    := .T.
	lMsErroAuto    := .F.
	lAutoErrNoFile := .T.

	MSExecAuto({|x,y,z|Mata140(x,y,z)},aCabec,aItens,3)
	
    If lMsErroAuto
    
    	aErrorLog := GETAUTOGRLOG()
    	
    	For nError := 1 To Len(aErrorLog)
    	
    		cMsgStatsrLog += aErrorLog[nError] + Chr(13) + Chr(10)
    	
    	Next nError
    	
    	While __lSx8
			RollBackSxe()
		End

        cMsgRet := "Erro na GravaÃ§Ã£o da Nota Fiscal" + oXml:_NOTAFISCAL:_NUMERONF:TEXT
        cCodStats := "416"   
        lRetNota := .F.
	Else

	    ConfirmSx8()
		While __lSx8
			ConfirmSx8()
		End

        // Grava status na tabela ARQUIVOS DE DANFE RECEBIDOS - Compila  
        ZB0->(DBSetOrder(1))
        If ZB0->(DBSeek(xFilial("ZB0") + ALLTRIM(oXML:_NOTAFISCAL:_CHAVENFE:TEXT)))
            ZB0->(RecLock("ZB0", .F.))
                ZB0->ZB0_STATUS := "0"
            ZB0->(MSUnLock()) 
		EndIf
    Endif

Return lRetNota

Static Function VeriBalde(cCodProd,cCodCC)

	Local aCodBalde  := {"", ""}
	Local cMsgInfo   := ""
	Local lRet       := .T.
	Local lMVAtvBald := SubStr(AllTrim(GetMV("MV_ATVBALD")), 1, 1) == "1" // Balde de Compras Ativo
	
	If lMVAtvBald
		aCodBalde := U_TSBaldePai(cCodProd)
	
		CTT->(DBSetOrder(1))
		CTT->(DBSeek(xFilial("CTT") + cCodCC))
		//Verifica se o centro de custo valida balde.
		
		If CTT->CTT_ATVBLD <> "0" // 0=Não; (Vazio e 1)=Sim
			SZG->(DBSetOrder(1))
			SZG->(DBSeek(xFilial("SZG") + aCodBalde[1]))
			//Verifica se o balde pai valida balde.			
		    If SZG->ZG_ATVBLD <> "0" // 0=Não; (Vazio e 1)=Sim
				If !(lRet := (U_TSBaldeOk(aCodBalde[1], cCodProd, cCodCC, dDataBase) > 0))
                    cMsgInfo := "Produto: " + AllTrim(cCodProd)       + "-" + AllTrim(Posicione("SB1", 1, xFilial("SB1") + cCodProd, "B1_DESC")) + " | " + ;
                                "Balde: "   + AllTrim(aCodBalde[1])   + "-" + AllTrim(aCodBalde[2]) + " | " + ;
                                "C.Custo: " + AllTrim(cCodCC)         + "-" + AllTrim(Posicione("CTT", 1, xFilial("CTT") + cCodCC, "CTT_DESC01"))

                    cMsgRet   := "Nao foi encontrado balde para o " + cMsgInfo
                    cCodStats := "421"
				EndIf
			EndIf
		EndIf
	EndIf

Return (lRet)
