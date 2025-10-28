#INCLUDE "PROTHEUS.CH"
#INCLUDE "PARMTYPE.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "FILEIO.CH"

WSRESTFUL zWSNotasGenial DESCRIPTION 'Integração Protheus x Genial'

    WSMETHOD POST NOTAS DESCRIPTION    'Importação de notas fiscais' WSSYNTAX '/zWSNotasGenial/notas' PATH 'notas' PRODUCES APPLICATION_JSON

END WSRESTFUL

//! NOTAS  
WSMETHOD POST NOTAS WSSERVICE zWSNotasGenial

    Local lRet := .T.
    Local oObjRet
    Local cStatus := ""
	Private cCodStats := "", cMsgRet := "" 

    lRet := U_REAINT04(self:getContent(), self:GetHeader("Authorization"))
    
    cStatus := IIF(lRet, "Sucesso", "Erro") // Códigos 2XX são sucesso

    oObjRet := JsonObject():New()
    oObjRet['status']   := cStatus //! Colocar uma lógica for erros em array
    oObjRet['mensagem'] := cMsgRet  
    oObjRet['codigo']   := cCodStats  

    cJson := FWJsonSerialize(oObjRet,.F.,.F.)

    ::SetResponse(cJson)

Return lRet
