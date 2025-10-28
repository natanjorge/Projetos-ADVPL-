#Include "Rwmake.ch"
#Include "TopConn.ch"
#Include 'FWMVCDEF.CH'
#Include 'Protheus.ch'

/* 
* {Protheus.doc} REAINT06
* Função para fazer a varredura dos registros da ZZA e enviar os e-mails. Chamada via menu e sched.
* @type user function
* @author Natan Jorge
* @since 18/08/2025
* @see: U_REAINT06() and Sched
/*/
User Function REAINT06(lSched)

	Local cMsgAux   := ""
	Local cMensagem := ""
	Local aInfo	    := {}
	Local aDados    := {}
	Local aRecEnv   := {}
	Local nCont 	:= 0
	DEFAULT lSched := .T.
    DEFAULT aParam := {"02","01"}

    If Select("SX6") == 0 
		RpcClearEnv() 
		RpcSetType(3) //Informa ao Server que a RPC não consumirá licenças
		RpcSetEnv(aParam[1],aParam[2],,,"COM") //aPar[01] Empresa, aPar[02] Filial
		SetModulo("SIGACOM","COM")
		InitPublic()
        SetsDefault()
	Endif
    
	If !lSched
		If !ValidPerg()
			Return
		EndIf
	Endif 

	cQryAux := " SELECT ZZA_DOC, ZZA_SERIE, ZZA_COD, ZZA_STATUS, ZZA_OBS, ZZA_MAILEN, ZZA.R_E_C_N_O_ AS RECZZA " + CRLF
	cQryAux += " FROM " + RetSQLName("ZZA") + " ZZA " + CRLF
	cQryAux += " WHERE D_E_L_E_T_ = ' ' "

	If lSched
		cQryAux += " AND ZZA_MAILEN  = 'F' "  + CRLF
	Else 
		cQryAux += " AND ZZA_FILIAL BETWEEN '" + MV_PAR01  + "' AND '" + MV_PAR02  + "' "  + CRLF
		cQryAux += " AND ZZA_DATA   BETWEEN '" + DTOS(MV_PAR03)  + "' AND '" + DTOS(MV_PAR04)  + "' "  + CRLF
		If ALLTRIM(MV_PAR05) == "1"
			cQryAux += " AND ZZA_MAILEN  = 'T' "  + CRLF
		Elseif ALLTRIM(MV_PAR05) == "2"
			cQryAux += " AND ZZA_MAILEN  = 'F' "  + CRLF
		Endif 
	Endif 
	cQryAux += " ORDER BY RECZZA DESC " + CRLF

	aDados := QryArray(cQryAux)

	For nCont := 1 to len(aDados)
		cMsgAux := '     <td align="Left">'  + aDados[nCont][1] + '</td>'
		cMsgAux += '     <td align="Left">'  + aDados[nCont][2] + '</td>'
		cMsgAux += '     <td align="Left">'  + aDados[nCont][3] + '</td>'
		cMsgAux += '     <td align="Left">'  + IIF(ALLTRIM(aDados[nCont][4]) == "1","Importado", "Não Importado") + '</td>'
		cMsgAux += '     <td align="Left">'  + ALLTRIM(aDados[nCont][5]) + '</td>'
		AADD( aInfo, cMsgAux)
		
		If aDados[nCont][6] == 'F' //! Se não foi enviado
			AADD( aRecEnv, aDados[nCont][7])
		EndIf 
	Next

    if !EMPTY(aInfo)
        cMensagem := GeraBody(.T., aInfo)
        EnvMail("Importação de XMLs - Genial", cMensagem, lSched)

		If !EMPTY(aRecEnv)
			DBSELECTAREA("ZZA")
			ZZA->(DBSETORDER(1))
			For nCont := 1 to len(aRecEnv)
				ZZA->(DBGOTO( aRecEnv[nCont]))
				RECLOCK("ZZA",.F.)
					ZZA->ZZA_MAILEN	:= .T.	
				MSUNLOCK()		
			Next
		Endif 
    Endif
	
Return 

Static Function ValidPerg()
	
	Local cPerg	:= "Log - Notas Genial"
	Local aPar	:= {}
	Local aCombo1 := {"1=Somente Já Enviados", "2=Somente Não Enviados", "3=Ambos"}
	
	Private Opcoes	:= { || Opcoes() }
	
	Aadd(aPar, {1, "Filial de ",           Space(TamSX3("TL_FILIAL")[1]),     "",     "",  "SM0",    "",  4, .F.}) // MV_PAR01
	Aadd(aPar, {1, "Filial até ",          Space(TamSX3("TL_FILIAL")[1]),     "",     "",  "SM0",    "",  4, .F.}) // MV_PAR02
	Aadd(aPar, {1, "Data de " ,               STOD(""),                      "",     "",    "",     "", 50,  .F.}) // MV_PAR03
	Aadd(aPar, {1, "Data até ",               STOD(""),                      "",     "",    "",     "", 50,  .F.}) // MV_PAR04
    aAdd(aPar, {2, "Opção ",       				   "1",                 aCombo1,    100, ".F.",			     .F.}) // MV_PAR05

Return (ParamBox(aPar, "Log - Notas Genial",,,,,,,, cPerg, .T., .T.))

Static Function GeraBody(lFisrt, aNotas)

	Local cMsg      := ""
	Local _n1, nCont := 0

	Default lFisrt := .T.

	If lFisrt
		cMsg := '<HTML><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'
		cMsg += '<html xmlns="http://www.w3.org/1999/xhtml">'
		cMsg += '     <style type="text/css">'
		cMsg += '          .tituloPag { FONT-SIZE: 20px; COLOR: #666699; FONT-FAMILY: Arial, Helvetica, sans-serif; TEXT-DECORATION: none; font-weight: bold; }'
		cMsg += '          .formulario { FONT-SIZE: 10px; COLOR: #000000; FONT-FAMILY: Verdana, Arial, Helvetica, sans-serif; TEXT-DECORATION: none; font-weight: bold; }'
		cMsg += '          .formulario2{ FONT-SIZE: 11px; COLOR: #333333; FONT-FAMILY: Verdana, Arial, Helvetica, sans-serif; TEXT-DECORATION: none; }'
		cMsg += '          .formularioTit { FONT-SIZE: 13px; COLOR: #000000; FONT-FAMILY: Verdana, Arial, Helvetica, sans-serif; TEXT-DECORATION: none; font-weight: bold; }'
		cMsg += '     </style>'
		cMsg += ' <head>'
		cMsg += '     <title>Email de NFs Importadas</title>'
		cMsg += '</head>'
		cMsg += "<body>"
		cMsg += '     <table width="95%" border="0" align="center">'    
		cMsg += '          <tr>'
		cMsg += '               <td colspan="6" bgcolor="#FFE4C4">'
		cMsg += '                    <div align="center"></br><span class="formularioTit">Resultado da Importação XML - Relação de Notas</span></br></div>'
		cMsg += '               </td>'
		cMsg += '          </tr>'
		cMsg += '          <tr>'                          
		cMsg += '               <td bgcolor="white" class="formulario"><p>&nbsp;</p></td>'
		cMsg += '          </tr>'
		cMsg += '     </table>'
		cMsg += '     <table width="95%" border="1" align="center" cellpadding="0" cellspacing="0" bordercolor="#cccccc" class="formulario2">'
		cMsg += '          <tr>'
		cMsg += '               <td colspan="6" bgcolor="#FFE4C4"><div align="center"><span class="formulario">Foram Importadas as seguintes Notas:&nbsp;</span></div></td>'
		cMsg += '          </tr>'
		cMsg += '          <tbody>'
		cMsg += '               <tr bgcolor="#FFFFE0">'
		cMsg += '                    <td width="10%" align="Left"    bgcolor="#FFE4C4" class="formulario">Número NF</td>'
		cMsg += '                    <td width="10%" align="Left"    bgcolor="#FFE4C4" class="formulario">Série</td>'
		cMsg += '                    <td width="10%" align="Left"    bgcolor="#FFE4C4" class="formulario">Codigo da Importação</td>'
		cMsg += '                    <td width="10%" align="Left"    bgcolor="#FFE4C4" class="formulario">Status</td>'
		cMsg += '                    <td width="20%" align="Left"    bgcolor="#FFE4C4" class="formulario">Motivo</td>'
		cMsg += '               </tr>'
		cMsg += '          </tbody>'
	EndIf

	For _n1 := 1 To Len(aNotas)                                          
		If Mod(nCont++, 2) = 0
			cMsg += '<tr bgcolor="#f3f3f3">'
		Else                                                          
			cMsg += '<tr bgcolor="white">'
		Endif       

		cMsg += aNotas[_n1]  + '</td>'
		cMsg += ' </tr>'
        
	Next _n1

	If lFisrt  
		cMsg += '          <tr>'
		cMsg += '               <td colspan="6" class="formulario"><p>&nbsp;</p></td>'
		cMsg += '          </tr>'        
		cMsg += '          <tr>'
		cMsg += '               <td colspan="6" bgcolor="#FFE4C4"><div align="center"><span class="formulario"></span></div></td>'
		cMsg += '          </tr>'
		cMsg += '     </table>'
		cMsg += '</body>'
		cMsg += '</html>'
	EndIf

Return(cMsg)              

Static Function EnvMail(cAssunto,cMensagem,lSched)

	Local nResult
	Local oMsg
	Local lAuthent	:= SuperGetMv("MV_RELAUTH",,.F.)
	Local cMailCop  := AllTrim(GetNewPar("ZZ_GENMAIL","natan.oliveira@totvs.com.br"))
	Local nPrt      := 587
    Local cWarn     := ""
	Local cError    := ""
    Local cWarning  := ""
	Local oMail
	
	Private cPassw	 := NIL
	Private cSrvMail := Nil
	Private cConta	 := NIL
	Private lMVRelSSL  := SuperGetMV("MV_RELSSL",, .F.)
  	Private lMVRelTLS  := SuperGetMV("MV_RELTLS",, .F.)
  	
	cPassw   := iif(cPassw == NIL,GETMV("MV_RELPSW"),cPassw)             
	cSrvMail := iif(cSrvMail == NIL,GETMV("MV_RELSERV"),cSrvMail)           
	cConta   := iif(cConta == NIL,GETMV("MV_RELACNT"),cConta)             
	
	
	cSrvMail := Substr(Alltrim(cSrvMail), 1, At(":", Alltrim(cSrvMail))-1 )
	
   	oMsg := TMailMessage():New()
	oMsg:Clear()
   
	oMsg:cDate	  := cValToChar( Date() )
	oMsg:cFrom 	  := cConta
	oMsg:cTo 	  := Alltrim(cMailCop)  
	oMsg:cSubject := cAssunto
	oMsg:cBody 	  := cMensagem
	oMail := tMailManager():New()
	oMail:SetUseTLS( lMVRelTLS ) 
	oMail:SetUseSSL( lMVRelSSL )
   
	nResult := oMail:Init(  "", cSrvMail, cConta, cPassw, 0, nPrt) 
	if nResult != 0
		FwLogMsg("FATAL", /*cTransactionId*/, "MSG", FunName(), "", "03", "Falha em inicilaizar o Servidor SMTP: " + oMail:GetErrorString( nResult ) + cError + " / " + cWarning, 0, 0, {})
		return
	endif
   
	nResult := oMail:SetSMTPTimeout( 60 ) 
	if nResult != 0
		FwLogMsg("FATAL", /*cTransactionId*/, "MSG", FunName(), "", "03", "Tempo Limite Indefinido " + cProtocol + "  " + cValToChar( nTimeout ) + cError + " / " + cWarning, 0, 0, {})
	endif
   
	nResult := oMail:SMTPConnect()
	if nResult <> 0
		FwLogMsg("FATAL", /*cTransactionId*/, "MSG", FunName(), "", "03", "Não foi possível conectar ao servidor SMTP: " + oMail:GetErrorString( nResult ) + cError + " / " + cWarning, 0, 0, {})
	endif
   
	if lAuthent
		nResult := oMail:SmtpAuth( cConta, cPassw )
		if nResult <> 0
			cWarn := "Could not authenticate on SMTP server: " + oMail:GetErrorString( nResult )
			FwLogMsg("FATAL", /*cTransactionId*/, "MSG", FunName(), "", "03", cWarn + cError + " / " + cWarning, 0, 0, {})
			oMail:SMTPDisconnect()
			return
		endif
   	Endif

	nResult := oMsg:Send( oMail )
	if nResult <> 0
		cWarn := "Não foi possível enviar e-mail: " + oMail:GetErrorString( nResult )
		FwLogMsg("FATAL", /*cTransactionId*/, "MSG", FunName(), "", "03", cWarn + cError + " / " + cWarning, 0, 0, {})
		If !lSched
			FWAlertInfo(cWarn, "TOTVS")
		Endif
	Else
		If !lSched
			FWAlertSuccess("E-mail enviado com sucesso!", "TOTVS")
		Endif 
	endif
   
	nResult := oMail:SMTPDisconnect()
	if nResult <> 0
		cWarn := "Não foi possível desconectar o servidor SMTP: " + oMail:GetErrorString( nResult )
		FwLogMsg("FATAL", /*cTransactionId*/, "MSG", FunName(), "", "03", cWarn + cError + " / " + cWarning, 0, 0, {})
	endif

return

