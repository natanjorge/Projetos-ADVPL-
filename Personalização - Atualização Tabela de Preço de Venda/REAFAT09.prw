#Include "Rwmake.ch"
#Include "TopConn.ch"
#Include 'FWMVCDEF.CH'
#Include 'Protheus.ch'

/*/{Protheus.doc} REAFAT09
    Realiza deleção de registros considerando o limite de dias
    @type User function  
    @author Natan Jorge
    @since 9/9/2025
/*/ 
User Function REAFAT09() /

	Local aDados    := {}
    Local cQtdReg   := "" 
    Local dNovaData := "" 
    Local cLastExec := "" 
    Local cQryAux   := "" 
    Local nCont     := 0 
    DEFAULT aParam  := {"99","01"}

    cQtdReg   := AllTrim(GETNEWPAR("ZZ_LIMDIAS", "15"))
    dNovaData := DaySum(DATE(), (VAL(cQtdReg)*-1))
    cLastExec := Transform(GETMV("ZZ_DTLIMP"), "@R 99/99/9999" )

    if MsgYesNo("Deseja deletar os registros de data até "+Transform(dNovaData, "@R 99/99/9999" )+"? " + CRLF + CRLF + "Data da última execução: " + cLastExec, "TOTVS")

        cQryAux := " SELECT ZZB.R_E_C_N_O_ AS RECNUM " + CRLF
        cQryAux += " FROM " + RetSQLName("ZZB") + " ZZB " + CRLF
        cQryAux += " WHERE ZZB.D_E_L_E_T_ = ' ' " + CRLF
        cQryAux += "   AND ZZB.ZZB_DATA <= '" + Dtos(dNovaData) + "' " + CRLF

        aDados := QryArray(cQryAux)

        DbSelectArea('ZZB')
        ZZB->(DbSetOrder(1))
        
        If !EMPTY(aDados)

            For nCont := 1 to len(aDados)
                ZZB->(DbGoTo(aDados[nCont,1]))
                RecLock("ZZB", .F.)  
                    DbDelete()
                ZZB->(MsUnlock())
            Next

            PutMV("ZZ_DTLIMP", DATE())

            FWAlertSuccess("Foram deletados " + ALLTRIM(STR(len(aDados))) + " registros com data até: "+Transform(dNovaData, "@R 99/99/9999" ), "TOTVS")

        Else 
            FWAlertInfo("Não existem registros para exclusão até a data "+Transform(dNovaData, "@R 99/99/9999" ) , 'TOTVS')
        Endif 

    else
        FWAlertInfo('Operação cancelada! ', 'TOTVS')
    Endif 

Return 

