#Include 'totvs.ch'
#INCLUDE 'TOPCONN.CH'

/*/{Protheus.doc} User Function SALFAT08
    Função que executa uma requisição Post de dataset do fluig para inicio de solicitação 
    @type  Function
    @author Natan Jorge
    @since 03/06/2025
/*/
User Function SALFAT08(aOpcSuc)
	// Local aAreas       := Lj7GetArea({})
	// local oFluigAPI    := APIFluigRest():new()
	// local oResponse    := nil
	Local nLinhaFilho  := 0
	local cBody        := ""
	local oJson        := JSONObject():New()
	local oProgramacao := JSONObject():New()
	local oConstraint  := JSONObject():New()
	Local oCabecalho   := {}
	Local oItens       := {}
    Local cJson        
	Local oModel      := FWModelActive()
    Private oModelPai   := oModel:GetModel('ZZAMASTER')
    Private oModelFilho := oModel:GetModel('ZZBDETAIL')
    Private oModelNeto  := oModel:GetModel('ZZCDETAIL')

	DEFAULT aOpcSuc := {}

    For nLinhaFilho := 1 To LEN(aOpcSuc)
        
        oModelFilho:GoLine(aOpcSuc[nLinhaFilho])

		oJson["name"] := "dsInitProcess_programacaoColeta"
		oJson["constraints"] := {}

		oCabecalho := getCabecalho()
		oItens     := getItens()

		oProgramacao["Programacao"] := {}
		aadd(oProgramacao["Programacao"], JSONObject():New())
		oProgramacao["Programacao"][len(oProgramacao["Programacao"])]["Cabec"] := oCabecalho
		oProgramacao["Programacao"][len(oProgramacao["Programacao"])]["itens"] := oItens

		cJson := oProgramacao:toJson()
		cJson := StrTran(cJson, '"', "'")


		// Cria a constraint Principal
		oConstraint["_field"] := "SOLICITACAOPROGRAMACAO"
		oConstraint["_initialValue"] := cJson
		oConstraint["_finalValue"] :=  ""
		oConstraint["_type"] := 1
		oConstraint["_likeSearch"] := .F.
		aadd(oJson["constraints"], oConstraint)

		cBody := oJson:toJson()

		oFluigAPI:setURLFluig(oFluigAPI:getUrlFluig())
		oResponse := oFluigAPI:connect(/*cVerb*/"POST","/api/public/ecm/dataset/datasets"/*cPath*/,/*cQueryParams*/,cBody/*xBody*/)
		oRetorno  := oResponse["content"]["values"]

	Next
	// Lj7RestArea(aAreas)

Return oRetorno

Static Function getCabecalho()
    local oCampos := JSONObject():New()
    local oCampo
    local nI
	local aCabecalho := {}
	Local cFilOrig   := oModelPai:GetValue("ZZA_FILORI")

	aCabecalho := { ;
					{"nrProgramacao"   , oModelPai:GetValue("ZZA_PROG")                 }, ; // ZZA_PROG
					{"nrPedVenda"      , oModelPai:GetValue("ZZA_PV")                   }, ; // ZZA_PV
					{"nrPedCompra"     , oModelFilho:GetValue("ZZB_NUM")                }, ; // ZZB_NUM
					{"dataProgramacao" , oModelPai:GetValue("ZZA_DATA")                 }, ; // ZZA_DATA
					{"placaVeiculo"    , oModelFilho:GetValue("ZZB_PLACA")              }, ; // ZZB_PLACA
					{"regiao"          , oModelPai:GetValue("ZZA_REG")                  }, ; // ZZA_REG
					{"motorista"       , oModelPai:GetValue("ZZA_MOTORI")               }, ; // ZZA_MOTORI
					{"codMotorista"    , oModelFilho:GetValue("ZZB_MOTORI")             }, ; // ZZB_MOTORI
					{"ajudante"        , oModelFilho:GetValue("ZZB_AJUD")               }, ; // ZZB_AJUD
					{"comprador"       , oModelPai:GetValue("ZZA_COMP")                 }, ; // ZZA_COMP
					{"status"          , oModelFilho:GetValue("ZZB_STATUS")             }, ; // ZZB_STATUS
					{"fornecedor"      , Posicione("SA2",1,xFilial("SA2")+oModelFilho:GetValue("ZZB_FORNEC"),"A2_NOME") }, ; // SA2->A2_NOME
					{"codFornec"       , oModelFilho:GetValue("ZZB_FORNEC")             }, ; // ZZB_FORNEC
					{"lojaFornec"      , oModelFilho:GetValue("ZZB_LJFOR")              }, ; // ZZB_LJFOR
					{"cidadeFornec"    , Posicione("SA2",1,xFilial("SA2")+oModelFilho:GetValue("ZZB_FORNEC"),"A2_MUN") }, ; 
					{"dataPrevColeta"  , oModelFilho:GetValue("ZZB_COLETA")             }, ; // ZZB_COLETA
					{"cliente"         , oModelPai:GetValue("A1_NOME")                  }, ; // A1_NOME
					{"codCliente"      , oModelPai:GetValue("ZZA_CLI")                  }, ; // ZZA_CLI
					{"lojaCli"         , oModelPai:GetValue("ZZA_LOJA")                 }, ; // ZZA_LOJA
					{"endereco"        , Posicione("SA1",1,xFilial("SA1")+oModelFilho:GetValue("ZZB_FORNEC"),"A1_END") }, ; // A1_END
					{"cidadeCli"       , Posicione("SA1",1,xFilial("SA1")+oModelFilho:GetValue("ZZB_FORNEC"),"A1_MUN") }, ; // A1_MUN
					{"dataPrevEntrega" , oModelFilho:GetValue("ZZB_ENTREGA")            }, ; // ZZB_ENTREGA
					{"fornecEmiteNota" , "S"          									}, ; // S/N
					{"transfFilial"    , IIF(cFilOrig<>oModelFilho:GetValue("ZZB_FILDES"), "S", "N") }, ; // transf?
					{"filial"          , cFilOrig               }  ; // ZZA_FILORI
				}
					//{"pesoTotal"       , nPesoTotal                                   }, ; // Confirmar com Paulo

   oCampos["campos"] := {}

    for nI := 1 to len(aCabecalho)
        oCampo := JSONObject():New()
        oCampo["nome"] := aCabecalho[nI][1]
        oCampo["valor"] := aCabecalho[nI][2]

		aadd(oCampos["campos"], oCampo)
	next nI

Return oCampos

Static Function getItens()
    local oCampos := JSONObject():New()
    local oCampo
    local nI
	local aItens := {}
	Local nLinhaNeto := 0

	For nLinhaNeto := 1 To oModelNeto:Length()
		oModelNeto:GoLine(nLinhaNeto)
		nItemAtu := oModelNeto:GetValue("ZZC_ITEM")

		AADD(aItens, { ;
						{"codProduto___1"   , ModelNeto:GetValue("ZZC_PROD") },;
						{"descProduto___1"  , Posicione('SB1', 1, FWxFilial( 'SB1' ) + ModelNeto:GetValue("ZZC_PROD"), 'B1_DESC') },;
						{"qtdProgramada___1", ModelNeto:GetValue("ZZC_QTDORI")          };
					})
	Next

    oCampos["campos"] := {}

    for nI := 1 to len(aItens)
        oCampo := JSONObject():New()
        oCampo["nome"] := aItens[nI][1]
        oCampo["valor"] := aItens[nI][2]

		aadd(oCampos["campos"], oCampo)
	next nI

Return oCampos



	


