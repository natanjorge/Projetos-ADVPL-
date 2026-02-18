//Bibliotecas
#Include "TOTVS.ch"
  
/*/{Protheus.doc} MA410MNU
    Ponto de Entrada na adição de funções no Pedido de Venda
    @author Natan Jorge
    @since 15/02/2026
    @version 1.0
    @type function
    @see https://tdn.totvs.com/display/public/PROT/MA410MNU
/*/
User Function MA410MNU()
    Local aArea    := FWGetArea()
    Local aSubMenu := {}
  
    If EXISTBLOCK("NTNFAT01")
        aAdd(aSubMenu, {"* Importar Pedidos via CSV",   "U_NTNFAT01()",  0, 4, 0, Nil})
    EndIf

    If !EMPTY(aSubMenu)
        aAdd(aRotina, {"Customizações", aSubMenu, 0, 2, 0, Nil})
    Endif 

    FWRestArea(aArea)
Return
