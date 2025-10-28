#Include "Rwmake.ch"
#Include "TopConn.ch"
#Include 'FWMVCDEF.CH'
#Include 'Protheus.ch'

#define MODEL_FORMSTRUCT 	1
#define VIEW_FORMSTRUCT  	2

#define FUNCTION_NAME funname()
#define MODEL_NAME "REINT05"
				   
#define TABLE_HEADER "ZZA"
#define TABLE_GRID   ""

#define HEADER_DESCRIPTION "Log - Notas Genial"
#define GRID_DESCRIPTION ""

#define BROWSE_DESCRIPTION "Visualização do " + HEADER_DESCRIPTION

/*/{Protheus.doc} UNCFAT01 

Rotina responsável pelo vizualização da ZZA - Cadastro de Região x Cidades.
@author Natan Jorge
@since 10/06/2025
@type User function

/*/
User Function REAINT05()

	Local oBrowse	:= nil

	oBrowse := FWMBrowse():New()
	oBrowse:SetDescription( BROWSE_DESCRIPTION)
	oBrowse:SetAlias( TABLE_HEADER )

	oBrowse:Activate()
Return NIL


/**
 * Opções do browse
 */
static Function MenuDef()
	Local aRotina := {}

	ADD OPTION aRotina TITLE 'Visualizar'       ACTION 'VIEWDEF.'+FUNCTION_NAME OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE 'Envio de e-mails' ACTION "U_REAINT06(.F.)"	OPERATION 4 ACCESS 0			

	//ADD OPTION aRotina TITLE 'Incluir' ACTION 'VIEWDEF.'+FUNCTION_NAME OPERATION 3 ACCESS 0
	//ADD OPTION aRotina TITLE 'Alterar' ACTION 'VIEWDEF.'+FUNCTION_NAME OPERATION 4 ACCESS 0
	//ADD OPTION aRotina TITLE 'Excluir' ACTION 'VIEWDEF.'+FUNCTION_NAME OPERATION 5 ACCESS 0

return aRotina

Static Function ModelDef()

	Local oModel
	Local oStructCab := FWFormStruct( MODEL_FORMSTRUCT, TABLE_HEADER)

	oModel := MPFormModel():New(MODEL_NAME, /*bPreInsert*/, /*bVldPos*/, /*bVldCom*/, /*bVldCan*/) 
	oModel:AddFields('MASTER', nil, oStructCab)

	oStructCab:SetProperty('ZZA_COD',   MODEL_FIELD_INIT,    FwBuildFeature(STRUCT_FEATURE_INIPAD,  'GetSXENum("ZZA", "ZZA_COD")'))         //Ini Padrão

	oModel:SetDescription( BROWSE_DESCRIPTION )
	oModel:GetModel( 'MASTER' ):SetDescription( HEADER_DESCRIPTION)

	oModel:SetPrimaryKey({"ZZA_FILIAL", "ZZA_COD"})


Return oModel

/**
 * Interface Visual
 */
static Function ViewDef()
	Local oView      := FWFormView():New()
	Local oModel     := FWLoadModel( FUNCTION_NAME )
	Local oStructCab := FWFormStruct( VIEW_FORMSTRUCT, TABLE_HEADER)

	oView:SetModel(oModel)
	oView:AddField('VIEW_ZZA', oStructCab, 'MASTER')

	oView:CreateHorizontalBox('TELA', 100)

	oView:SetOwnerView('VIEW_ZZA', 'TELA')

Return oView
