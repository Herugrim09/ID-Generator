"! <p class="shorttext synchronized">MDG ID Generator - Central Constants</p>
INTERFACE zif_mdg_id_constants
  PUBLIC.

  "! Project codes supported by the ID generator framework
  CONSTANTS:
    BEGIN OF c_project_codes,
      c_se   TYPE ze_mdg_project_code VALUE 'SE',
      c_sgre TYPE ze_mdg_project_code VALUE 'SGRE',
    END OF c_project_codes.

  "! UIBB attribute (component) names
  CONSTANTS:
    BEGIN OF c_attributes,
      company_code  TYPE name_komp VALUE 'COMPANY_CODE',
      plant         TYPE name_komp VALUE 'PLANT',
      func_cts      TYPE name_komp VALUE 'FUNC_CTS',
      profit_center TYPE name_komp VALUE 'PROFIT_CENTER',
    END OF c_attributes.

  "! Fixed attribute values
  CONSTANTS:
    BEGIN OF c_attr_values,
      BEGIN OF coarea,
        co_sg01 TYPE kokrs VALUE 'SG01',
      END OF coarea,
    END OF c_attr_values.

ENDINTERFACE.
