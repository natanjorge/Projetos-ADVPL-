#INCLUDE "PROTHEUS.CH"
#INCLUDE "PARMTYPE.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "FILEIO.CH"

/*  
* {Protheus.doc} REAINT04
* Função orquestradora da integração. Ela:
*  Valida as credenciais Basic Auth recebidas no header (cAutent).
*  Converte o XML recebido em objeto (via XmlParser) e o disponibiliza em oXml.
*  Redireciona o processamento para a rotina específica conforme cOpc:
*  "1" ? U_REAINT01() - Integração da Nota Fiscal de entrada - Integração GENIAL.
*  "2" ? U_REAINT02() - Importação de Produtos (SB1) via XML - Integração GENIAL.
*  "3" ? U_REAINT03() - Importa Centro de Custo (CTT) via MsExecAuto (CTBA030) com dados vindos de oXML - Integração GENIAL.
*  Monta o payload JSON de retorno com status, mensagem e codigo e o envia no response HTTP.
* @type user function
* @author Natan Jorge
* @since 18/08/2025
* @return: 
*     lRet (boolean): sucesso/fracasso da importação
* @see: zWSNotasGenial
*/ 
User Function REAINT04(cBody, cAutent)

    Local lRet    := .T.
    Local cAviso  := ""
    Local cErro   := ""  
    
	Private cChvNFe    := ""
    Private cNFProb    := ""
    Private cSrProb    := ""
    Private cPedCom    := ""

    Private lExiInt    := .T. 
	Private lPost      := .T.  
    Private oXml    
	Private oRequest := Nil
	Private oObjRet	 := NIL

    DEFAULT cBody   := "" 
    DEFAULT cAutent := "" 
    DEFAULT aParam := {"02","01"}

    cMsgRet := ""
    cCodStats := ""

    If Select("SX6") == 0 
        RpcClearEnv() 
        RpcSetType(3) //Informa ao Server que a RPC não consumirá licenças
        if !(RpcSetEnv(aParam[1],aParam[2], "Administrador", "","FAT")) //aPar[01] Empresa, aPar[02] Filial
            cMsgRet   := "Usuário e/ou senha inválidos!" 
            cCodStats := "405"
            lRet := .F.
        EndIf
    EndIf

    If lRet
        oObjRet	 := JsonObject():New()
        
        If !lExiInt
            lRet := .F.
            cMsgRet   := "Funcao nao encontrada 'U_REAINT01'"
            cCodStats := "404"
        Endif 

        If lRet
            oXml := TXmlManager():New()
            oXml := XmlParser( cBody ,"_", @cAviso, @cErro )
            lRet := U_REAINT01() 
        Endif
    Endif 

    GeraLogZZA(lRet)

Return lRet

Static Function GeraLogZZA(lStatus)

    Local cQryAux   := ""
    Local cCodImp   := ""
    Local aDados    := {}
    DEFAULT aParam := {"02","01"}
	
    cQryAux := " SELECT TOP 1 ZZA.ZZA_COD " + CRLF
    cQryAux += " FROM " + RetSQLName("ZZA") + " ZZA " + CRLF
    cQryAux += " WHERE ZZA_FILIAL = " + ValToSQL(XFilial("ZZA")) + CRLF
    cQryAux += " ORDER BY ZZA_COD DESC " + CRLF

    aDados := QryArray(cQryAux)

    cCodImp := IIF(EMPTY(aDados), "000001", SOMA1(aDados[1][1]))

    DbSelectArea('ZZA')
    ZZA->(DbSetOrder(1))  

    RecLock("ZZA", .T.)
        ZZA->ZZA_FILIAL := FWxFilial("ZZA")
        ZZA->ZZA_COD    := cCodImp
        ZZA->ZZA_CHVNF  := cChvNFe
        ZZA->ZZA_DOC    := cNFProb
        ZZA->ZZA_SERIE  := cSrProb
        ZZA->ZZA_PEDCOM := cPedCom
        ZZA->ZZA_DATA   := DATE()
        ZZA->ZZA_HORA   := Time()
        ZZA->ZZA_STATUS := IIF(lStatus, "1", "2")
        ZZA->ZZA_MAILEN := .F.
        ZZA->ZZA_OBS    := ALLTRIM(cCodStats) + " - " + ALLTRIM(cMsgRet)
    ZZA->(MsUnlock())

Return 

