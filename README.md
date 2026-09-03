# ID-Generator

MDG-F ID / number generator framework, converted from the `/S4E/` namespace
to the `Z` customer namespace. abapGit repo, `PREFIX` folder logic, source
under `src/`.

## Framework

| Object | Role |
|---|---|
| `ZIF_MDG_ID_NUMBER_GEN` | Number generator interface (`GENERATE_NUMBER`, `SPLIT_NUMBER`) |
| `ZCL_MDG_ID_NUMGEN_BASE` | Template-method base class: buffers the input structure, resolves the MDG staging table, reads existing IDs (`QUERYING_DB`), structure validation |
| `ZCL_MDG_ID_NUMGEN_FACTORY` | Maps `(entity, project code)` to the concrete generator class / structure |
| `ZCL_MDG_ID_UIBB_FEEDER` | Generic FPM GUIBB form feeder; on `ZATTR_SELECTED` calls the factory and writes the ID into event key `GENERATED_ID` |
| `ZIF_MDG_ID_CONSTANTS` | Central constants (project codes, attribute names, fixed values) |
| `ZCL_MDG_ID_LOGGING` | Application-log wrapper (stub – wire to your BAL log) |
| `ZCL_MDG_ID_SG_UTIL` | Company code ↔ plant assignment (buffered stub) |
| `ZCL_MDG_CCTR_RULES` | Rule type container (`TT_FUNC`) |

### Fixes applied during the conversion

* `ZCL_MDG_ID_NUMGEN_BASE=>QUERYING_DB` now clears `IT_MY_DATA` at the start
  (the original appended on every re-query, contaminating the gap scan).
* Dynamic `WHERE` literals use `CL_ABAP_DYN_PRG=>QUOTE` instead of `QUOTE_STR`.
* Guard in `ZCL_MDG_ID_NUMGEN_FACTORY=>GET_NUMBER_GENERATOR` when no class /
  structure is mapped (avoids a dump on empty `CREATE OBJECT` / `CREATE DATA`).
* `ZCL_MDG_SE_PCTR_ID_GEN` uses an explicit loop instead of
  `READ TABLE ... WITH KEY comp+off(len) = ...` and drops the stray trailing
  space in the reference template.

## Example generators

| Object | Entity / Project |
|---|---|
| `ZCL_MDG_SE_PCTR_ID_GEN` | Profit Center / SE – full implementation |
| `ZCL_MDG_CCTRID_RULE` | Cost Center entity feeder base |
| `ZCL_MDG_SE_CCTRID_RULE` | Cost Center / SE feeder (OVS + BRF+) |

## ACCOUNT ID generator (SGRE) – scaffold

| Object | Role |
|---|---|
| `ZCL_MDG_SG_ACCT_ID_GEN` | Concrete generator, entity ACCOUNT / project SGRE – **`GENERATE_NUMBER` / `SPLIT_NUMBER` are stubs pending the functional spec** |
| `ZCL_MDG_ACCTID_RULE` | ACCOUNT entity feeder base (`FD_ENTITY = ACCOUNT`) |
| `ZCL_MDG_SG_ACCTID_RULE` | ACCOUNT / SGRE feeder (`FD_PROJECT_NAME = 'SGRE'`) |
| `ZMDG_S_SG_ACCT_NAMING` | UIBB structure (`STRUCTURE_TYPE` parameter) – draft fields |

`ZCL_MDG_ID_NUMGEN_FACTORY` already routes `(ACCOUNT, SGRE)` →
`ZCL_MDG_SG_ACCT_ID_GEN` / `ZMDG_S_SG_ACCT_NAMING`.
