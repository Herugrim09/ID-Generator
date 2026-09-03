"! <p class="shorttext synchronized">MDG ID Gen: SGRE Bank GL Account Rule Tables</p>
"! Hard-coded lookup tables for the SGRE bank GL account concept
"! (AGORA / WP Treasury), transcribed from SGRE_GL_Bank_Account_calculator.xlsx.
"! Used by ZCL_MDG_SG_ACCT_ID_GEN and the ACCOUNT naming-convention feeder
"! (OVS value helps).
"!
"! GL account (10 char) = '00' + group(1-3) + bank code(4-5)
"!                             + currency code(6-7) + planning digit(8)
CLASS zcl_mdg_sg_acct_rules DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_bank,
        code  TYPE ze_mdg_bank_code,
        name  TYPE ze_mdg_bank_name,
        swift TYPE ze_mdg_swift_code,
      END OF ty_bank,
      tt_bank TYPE SORTED TABLE OF ty_bank WITH UNIQUE KEY code.
    TYPES:
      BEGIN OF ty_ccy,
        iso     TYPE waers,
        code    TYPE ze_mdg_currency_code,
        country TYPE text40,
      END OF ty_ccy,
      tt_ccy TYPE SORTED TABLE OF ty_ccy WITH UNIQUE KEY iso.
    TYPES:
      BEGIN OF ty_group,
        kind  TYPE ze_mdg_acct_group_kind,
        grp   TYPE ze_mdg_acct_group,
        descr TYPE text60,
      END OF ty_group,
      tt_group TYPE SORTED TABLE OF ty_group WITH UNIQUE KEY kind.
    TYPES:
      BEGIN OF ty_plvl,
        pmethod TYPE ze_mdg_payment_method,
        digit   TYPE ze_mdg_planning_digit,
        level   TYPE ze_mdg_planning_level,
        descr   TYPE text40,
      END OF ty_plvl,
      tt_plvl TYPE STANDARD TABLE OF ty_plvl WITH DEFAULT KEY.

    CONSTANTS:
      BEGIN OF c_kind,
        main    TYPE ze_mdg_acct_group_kind VALUE 'MAIN',
        int_in  TYPE ze_mdg_acct_group_kind VALUE 'INT_IN',
        int_out TYPE ze_mdg_acct_group_kind VALUE 'INT_OUT',
        ihb     TYPE ze_mdg_acct_group_kind VALUE 'IHB',
        ihb_int TYPE ze_mdg_acct_group_kind VALUE 'IHB_INT',
      END OF c_kind.

    "! Bank list for the OVS value help. Every "(Bank account# N)" entry
    "! is a separate row with its own 2-char code - the user picks the
    "! exact one they want (the sequence is a manual choice, not derived).
    CLASS-METHODS get_bank_codes      RETURNING VALUE(rt_bank)  TYPE tt_bank.
    CLASS-METHODS get_currency_codes  RETURNING VALUE(rt_ccy)   TYPE tt_ccy.
    CLASS-METHODS get_account_groups  RETURNING VALUE(rt_group) TYPE tt_group.
    CLASS-METHODS get_planning_levels RETURNING VALUE(rt_plvl)  TYPE tt_plvl.

    "! 2-char currency code for an ISO currency; INITIAL if unknown.
    CLASS-METHODS currency_code
      IMPORTING iv_iso        TYPE waers
      RETURNING VALUE(rv_code) TYPE ze_mdg_currency_code.

    "! Position 1-3 group for an account group kind.
    CLASS-METHODS group_of_kind
      IMPORTING iv_kind        TYPE ze_mdg_acct_group_kind
      RETURNING VALUE(rv_group) TYPE ze_mdg_acct_group.

    "! Position 8 digit. MAIN -> 0, INT_IN -> 1, INT_OUT -> per payment
    "! method. IHB / IHB_INT: see TODO - not spelled out in the concept.
    CLASS-METHODS planning_digit
      IMPORTING iv_kind           TYPE ze_mdg_acct_group_kind
                iv_payment_method TYPE ze_mdg_payment_method OPTIONAL
      RETURNING VALUE(rv_digit)   TYPE ze_mdg_planning_digit.

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_mdg_sg_acct_rules IMPLEMENTATION.


  METHOD get_bank_codes.
    rt_bank = VALUE #(
      ( code = '01' name = 'Barclays Bank' swift = 'BARCxxxxXXX, BARCGB22' )
      ( code = '02' name = 'Danske Bank' swift = 'DABADKKK' )
      ( code = '03' name = 'Deutsche Bank' swift = 'DEUTDEFFXXX' )
      ( code = '04' name = 'BBVA' swift = 'BBVAESMMXXX, BBVAPTPLXXX' )
      ( code = '05' name = 'BNP Paribas' swift = '' )
      ( code = '06' name = 'Citibank / CITIBANAMEX' swift = 'CITIUS33XXX' )
      ( code = '07' name = 'Kotak Mahindra Bank' swift = '' )
      ( code = '08' name = 'Zabrebacka Banka /Zagrebacka Banka' swift = '' )
      ( code = '09' name = 'UniCredit Bank' swift = '' )
      ( code = '10' name = 'STANDARD CHARTERED BANK' swift = 'SCBLCIABXXX' )
      ( code = '11' name = 'Handelsbanken (Svenska Handelsbanken AB)' swift = '' )
      ( code = '12' name = 'BANCA NAZIONALE DEL LAVORO SPA GRUPPO BNPP (BNL)' swift = 'BNLIITRRXXX' )
      ( code = '13' name = 'Banque Marocaine Pour Le Commerce (BMCI)' swift = 'BMCIMAMCXXX' )
      ( code = '14' name = 'TGBA_TR(Turkiye Garanti Bankasi)' swift = 'TGBATRISXXX' )
      ( code = '15' name = 'Banamex' swift = 'BNMXMXMM' )
      ( code = '16' name = 'Standard Bank' swift = '' )
      ( code = '17' name = 'Credit Du Maroc' swift = '' )
      ( code = '18' name = 'CAIXABANK' swift = '' )
      ( code = '19' name = 'SOCIETE GENERALE' swift = 'BIIMMRMRXXX, SGCICIABXXX' )
      ( code = '20' name = 'BANCO DE CHILE' swift = 'CITILKLXXXX' )
      ( code = '21' name = 'Santander Bank' swift = 'BSCHESMMXXX' )
      ( code = '22' name = 'YAPI_TR (Yapi Ve Kredi Bankasi A.S.)' swift = '' )
      ( code = '23' name = 'ISBK TR(Turkiye IS Bankasi A.S.)' swift = '' )
      ( code = '24' name = 'Scotiabank' swift = 'NOSCTTPSXXX , BSUDPEPL' )
      ( code = '25' name = 'HSBC' swift = '' )
      ( code = '26' name = 'Turk Ekonomi Bankasi A.S.' swift = '' )
      ( code = '27' name = 'T.C.Ziraat Bankasi A.S. Dolayoba' swift = '' )
      ( code = '28' name = 'Turkiye Vakiflar Bankasi T.A.O. Tek' swift = '' )
      ( code = '29' name = 'Fortis Bank' swift = '' )
      ( code = '30' name = 'Nordea' swift = '' )
      ( code = '31' name = 'Bank Pekao S.A. (Bank Polska Kasa Opieki) (Bank account# 2)' swift = 'PKOPPLPWXXX' )
      ( code = '32' name = 'Credit Agricole' swift = '' )
      ( code = '33' name = 'Deutsche Bank (Bank account# 2)' swift = 'DEUTxxxxxx' )
      ( code = '34' name = 'Bank Pasargad' swift = '' )
      ( code = '35' name = 'ING' swift = 'BBRUBEBBXXX' )
      ( code = '36' name = 'VOLKSBANK BH D.D.' swift = '' )
      ( code = '37' name = 'Zemen Bank S.C.' swift = '' )
      ( code = '38' name = 'Sberbank BH D.D.' swift = '' )
      ( code = '39' name = 'Alpha Bank' swift = 'CRBAGRAAXXX, CRBAALTRXXX' )
      ( code = '3A' name = 'Deutsche Bank (Bank account# 3)' swift = 'DEUTxxxxxx' )
      ( code = '3B' name = 'Deutsche Bank (Bank account# 4)' swift = 'DEUTxxxxxx' )
      ( code = '40' name = 'NOVO BANCO, S.A' swift = '' )
      ( code = '41' name = 'SUMITOMO MITSUI BANKING Corp (SCMB)' swift = '' )
      ( code = '42' name = 'BANCO INDUSTRIAL' swift = '' )
      ( code = '43' name = 'Banco De Sabadell, S.A.' swift = '' )
      ( code = '44' name = 'BANCO CMB (Costa Rica)' swift = '' )
      ( code = '45' name = 'BANCO DE HONDURAS SA' swift = '' )
      ( code = '46' name = 'MBANK S.A.' swift = '' )
      ( code = '47' name = 'COMMERZBANK' swift = '' )
      ( code = '48' name = 'BANKINTER (Bankinter)' swift = '' )
      ( code = '49' name = 'Banco Caixa Geral' swift = '' )
      ( code = '50' name = 'International Bank of Azerbaijan' swift = '' )
      ( code = '51' name = 'Raiffeisen Bank' swift = 'RZBSRSBGXXX' )
      ( code = '52' name = 'BANK OF CHINA (BOC)' swift = 'BKCHCNBJ200' )
      ( code = '53' name = 'Bank of the Philippine Islands (BPI)' swift = '' )
      ( code = '54' name = 'STB / Societe Tunisienne de Banque' swift = 'STBKTNTTXXX' )
      ( code = '55' name = 'Silk Road Bank AD Skopje' swift = '' )
      ( code = '56' name = 'KUTXABANK' swift = '' )
      ( code = '57' name = 'SANTANDER SECURITIES SERVICES' swift = 'Santander Securities Services (S3) ' )
      ( code = '58' name = 'BANKIA' swift = '' )
      ( code = '59' name = 'UNICAJA' swift = '' )
      ( code = '60' name = 'CMB Bank' swift = '' )
      ( code = '61' name = 'China Citic Bank )' swift = '' )
      ( code = '62' name = 'Bank of America' swift = '' )
      ( code = '63' name = 'DBS Bank Ltd' swift = '' )
      ( code = '64' name = 'IDFC FIRST Bank / IDFC Bank' swift = '' )
      ( code = '65' name = 'IndusInd Bank' swift = '' )
      ( code = '66' name = 'Mizuho Bank' swift = '' )
      ( code = '67' name = 'Banca March' swift = '' )
      ( code = '68' name = 'Caja Rural de Navarra' swift = '' )
      ( code = '69' name = 'Shanghai Pudong Development Bank' swift = 'SPDBCNSHXXX' )
      ( code = '70' name = 'CAC International Bank' swift = 'CACDDJxxxxxx' )
      ( code = '71' name = 'BANK OF CYPRUS PUBLIC COMPANY LTD' swift = 'BCYPCY2NXXX' )
      ( code = '72' name = 'EXIM BANK (DJIBOUTI) S.A' swift = 'EXTNDJJD' )
      ( code = '73' name = 'NATIONAL BANK OF GREECE' swift = 'ETHNGRxxxxx' )
      ( code = '74' name = 'BANCO DE LA NACION' swift = 'BANCPEPLXXX' )
      ( code = '75' name = 'Vietnam Joint Stock Commercial Bank for Industry and Trade B' swift = 'ICBVVNVX902' )
      ( code = '76' name = 'Targo Bank' swift = 'CMCIESMMXXX' )
      ( code = '77' name = 'Sydbank' swift = 'SYBKDK22XXX' )
      ( code = '78' name = 'HDFC BANK LIMITED' swift = 'HDFCINBBCHE' )
      ( code = '79' name = 'ICICI Bank LTD' swift = 'ICICINBBCTS' )
      ( code = '80' name = 'RBL BANK LTD' swift = 'RATN0000113' )
      ( code = '81' name = 'AXIS BANK' swift = 'AXISINBB168' )
      ( code = '82' name = 'BANCO ITAU BBA SA' swift = 'ITAUBRSPXXX' )
      ( code = '83' name = 'BANCO BRADESCO' swift = 'BBDEBRSPSDR' )
      ( code = '84' name = 'Banco do Brasil S/A' swift = 'BRASBRRJOCO' )
      ( code = '85' name = 'SEB (Skandinaviska Enskilda Banken)' swift = 'ESSESESSXXX' )
      ( code = '86' name = 'Agricultural Bank of China' swift = 'ABOCCNBJ150' )
      ( code = '87' name = 'China Construction Bank Corporation' swift = 'PCBCCNBJSXX' )
      ( code = '88' name = 'Dummy Bank for Interim GL reconcilation (Dummy Bank)' swift = '' )
      ( code = '89' name = 'INTESA SANPAOLO SPA' swift = 'BCITITMMXXX , BCITITMMXXX' )
      ( code = '90' name = 'JP Morgan Chase' swift = '' )
      ( code = '91' name = 'Commercial Bank of Ethiopia' swift = 'CBETETAAXXX' )
      ( code = '92' name = 'Sparkasse' swift = '' )
      ( code = '93' name = 'OTP Bank' swift = '' )
      ( code = '98' name = 'DUMMY house Bank' swift = '' )
      ( code = '99' name = 'IHCSG / IC / SFS/ In house Banking' swift = '' )
      ( code = '9A' name = 'IHCSG / IC / SFS/ In house Banking (Bank account# 2)' swift = '' )
      ( code = '9B' name = 'IHCSG / IC / SFS/ In house Banking (Bank account# 3)' swift = '' )
      ( code = '9C' name = 'IHCSG / IC / SFS/ In house Banking Cash Pooling' swift = '' )
      ( code = 'A1' name = 'Standard Bank (Bank account# 2)' swift = '' )
      ( code = 'A2' name = 'Standard Bank (Bank account# 3)' swift = '' )
      ( code = 'A5' name = 'Alpha Bank (Bank account# 2)' swift = 'CRBAGRAAXXX, CRBAALTRXXX' )
      ( code = 'B1' name = 'Bank Pasargad (Bank Account #2)' swift = '' )
      ( code = 'B2' name = 'Bank Pasargad (Bank Account #3)' swift = '' )
      ( code = 'B6' name = 'BANCO DE CHILE (Bank account# 2)' swift = 'CITILKLXXXX' )
      ( code = 'C1' name = 'Citibank / CITIBANAMEX (Bank account# 2)' swift = '' )
      ( code = 'C2' name = 'Citibank / CITIBANAMEX (Bank account# 3)' swift = '' )
      ( code = 'C3' name = 'Citibank / CITIBANAMEX (Bank account# 4)' swift = '' )
      ( code = 'C4' name = 'Citibank / CITIBANAMEX (Bank account# 5)' swift = '' )
      ( code = 'C5' name = 'Citibank / CITIBANAMEX (Bank account# 6)' swift = '' )
      ( code = 'C6' name = 'Citibank / CITIBANAMEX (Bank account# 7)' swift = '' )
      ( code = 'C7' name = 'Citibank / CITIBANAMEX (Bank account# 8)' swift = '' )
      ( code = 'C8' name = 'Citibank / CITIBANAMEX (Bank account# 9)' swift = '' )
      ( code = 'D1' name = 'BANCO CMB (Costa Rica) (Bank account# 2)' swift = '' )
      ( code = 'D2' name = 'Danske Bank (Bank account# 2)' swift = 'DABADKKK' )
      ( code = 'D5' name = 'Banque Marocaine Pour Le Commerce (BMCI) (Bank account# 2)' swift = 'BMCIMAMCXXX' )
      ( code = 'D6' name = 'Banque Marocaine Pour Le Commerce (BMCI) (Bank account# 3)' swift = 'BMCIMAMCXXX' )
      ( code = 'D7' name = 'Banque Marocaine Pour Le Commerce (BMCI) (Bank account# 4)' swift = 'BMCIMAMCXXX' )
      ( code = 'D8' name = 'Attijariwafa Bank' swift = '' )
      ( code = 'E1' name = 'BANCO DE HONDURAS SA' swift = '' )
      ( code = 'E6' name = 'BANCO DE CREDITO DEL PERU' swift = 'BCPLPEPL' )
      ( code = 'F1' name = 'MBANK S.A.' swift = '' )
      ( code = 'F6' name = 'FIRSTRAND BANK LIMITED' swift = 'FIRNZAJJXXX' )
      ( code = 'F7' name = 'FIRSTRAND BANK LIMITED (Bank account# 2)' swift = 'FIRNZAJJXXX' )
      ( code = 'G1' name = 'TGBA_TR(Turkiye Garanti Bankasi) (Bank account# 2)' swift = 'TGBATRISXXX' )
      ( code = 'G2' name = 'TGBA_TR(Turkiye Garanti Bankasi) (Bank account# 3)' swift = 'TGBATRISXXX' )
      ( code = 'H1' name = 'Handelsbanken (Svenska Handelsbanken AB) (Bank account# 2)' swift = '' )
      ( code = 'H2' name = 'HSBC (Bank account# 2)' swift = '' )
      ( code = 'H3' name = 'HSBC (Bank account# 3)' swift = '' )
      ( code = 'I1' name = 'CMB Bank (Bank account# 2)' swift = '' )
      ( code = 'I5' name = 'Meezan Bank' swift = 'BAK38AV3RA' )
      ( code = 'I6' name = 'Commercial International Bank' swift = 'CIBEEGCXXXX' )
      ( code = 'J1' name = 'Fortis Bank (Bank account# 2)' swift = '' )
      ( code = 'J5' name = 'BANK OF CHINA (BOC) (Bank account# 2)' swift = 'BKCHCNBJ200' )
      ( code = 'J6' name = 'BANK OF CHINA (BOC) (Bank account# 3)' swift = 'BKCHCNBJ200' )
      ( code = 'J7' name = 'BANK OF CHINA (BOC) (Bank account# 4)' swift = 'BKCHCNBJ200' )
      ( code = 'J8' name = 'BANK OF CHINA (BOC) (Bank account# 5)' swift = 'BKCHCNBJ200' )
      ( code = 'J9' name = 'BANK OF CHINA (BOC) (Bank account# 6)' swift = 'BKCHCNBJ200' )
      ( code = 'K1' name = 'Raiffeisen Bank (Bank account# 2)' swift = 'RZBSRSBGXXX' )
      ( code = 'K2' name = 'Raiffeisen Bank (Bank account# 3)' swift = 'RZBSRSBGXXX' )
      ( code = 'K6' name = 'BANCO DE POUPANCA E CREDITO (BPC)' swift = 'BPCLAOLUXXX' )
      ( code = 'L1' name = 'Sberbank BH D.D. (Bank account# 2)' swift = '' )
      ( code = 'L6' name = 'SAMPATH BANK PLC' swift = 'BSAMLKLXXXX' )
      ( code = 'M1' name = 'Credit Du Maroc (Bank account# 2)' swift = '' )
      ( code = 'N1' name = 'Banamex (Bank account# 2)' swift = 'BNMXMXMM' )
      ( code = 'N2' name = 'Banamex (Bank account# 3)' swift = 'BNMXMXMM' )
      ( code = 'N3' name = 'Banamex (Bank account# 4)' swift = 'BNMXMXMM' )
      ( code = 'N6' name = 'Alpha Bank Group' swift = 'CRBAGRAAXXX, CRBAALTRXXX' )
      ( code = 'O1' name = 'Barclays Bank (Bank account# 2)' swift = 'BARCxxxxXXX' )
      ( code = 'O2' name = 'Barclays Bank (Bank account# 3)' swift = 'BARCxxxxXXX' )
      ( code = 'P1' name = 'Bank Pekao S.A. (Bank Polska Kasa Opieki) (Bank account# 3)' swift = 'PKOPPLPWXXX' )
      ( code = 'P2' name = 'Bank Pekao S.A. (Bank Polska Kasa Opieki) (Bank account# 4)' swift = 'PKOPPLPWXXX' )
      ( code = 'P3' name = 'Bank Pekao S.A. (Bank Polska Kasa Opieki) (Bank account# 5)' swift = 'PKOPPLPWXXX' )
      ( code = 'P4' name = 'Bank Pekao S.A. (Bank Polska Kasa Opieki) (Bank account# 6)' swift = 'PKOPPLPWXXX' )
      ( code = 'P6' name = 'Banco Comercial e de Investimentos' swift = 'CGDIMZMAXXX' )
      ( code = 'Q1' name = 'BNP Paribas (Bank account# 2)' swift = '' )
      ( code = 'Q2' name = 'BNP Paribas (Bank account# 3)' swift = '' )
      ( code = 'Q3' name = 'BNP Paribas (Bank account# 4)' swift = '' )
      ( code = 'Q4' name = 'BNP Paribas (Bank account# 5)' swift = '' )
      ( code = 'Q6' name = 'Banco Africano Investimentos' swift = 'BAIPAOLUXXX' )
      ( code = 'Q8' name = 'STANBIC BANK - COTE DIVOIRE' swift = 'SBICCIABXXX' )
      ( code = 'R1' name = 'SANTANDER SECURITIES SERVICES (Bank account# 2)' swift = 'Santander Securities Services (S3) ' )
      ( code = 'R2' name = 'SANTANDER SECURITIES SERVICES (Bank account# 3)' swift = 'Santander Securities Services (S3) ' )
      ( code = 'R5' name = 'Santander Bank (Bank account# 2)' swift = '' )
      ( code = 'S1' name = 'ISBK TR(Turkiye IS Bankasi A.S.) (Bank account# 2)' swift = '' )
      ( code = 'S6' name = 'Scotiabank Trinidad and Tobago Limited' swift = 'NOSCTTPSXXX' )
      ( code = 'T1' name = 'SUMITOMO MITSUI BANKING Corp (SCMB) (Bank account# 2)' swift = '' )
      ( code = 'T6' name = 'Natexis Banque' swift = 'NATXFRPPXXX' )
      ( code = 'T8' name = 'BANK OF TAIWAN' swift = 'BKTWTWTPXXX' )
      ( code = 'T9' name = 'BANK OF TAIWAN (Bank account# 2)' swift = 'BKTWTWTPXXX' )
      ( code = 'U1' name = 'UniCredit Bank (Bank account# 2)' swift = '' )
      ( code = 'U2' name = 'UniCredit Bank (Bank account# 3)' swift = '' )
      ( code = 'V1' name = 'BBVA (Bank account# 2)' swift = 'BBVAESMMXXX, BBVAPTPLXXX' )
      ( code = 'V2' name = 'BBVA (Bank account# 3)' swift = 'BBVAESMMXXX, BBVAPTPLXXX' )
      ( code = 'V3' name = 'BBVA (Bank account# 4)' swift = 'BBVAESMMXXX, BBVAPTPLXXX' )
      ( code = 'V6' name = 'JOINT STOCK COMMERCIAL BANK FOR INVESTMENT AND DEVELOPMENT O' swift = 'BIDVVNVXXXX' )
      ( code = 'V8' name = 'ESBC Erste Bank Group' swift = 'GIBAATWGXXX' )
      ( code = 'W1' name = 'BANCA NAZIONALE DEL LAVORO SPA GRUPPO BNPP (BNL) (Bank accou' swift = 'BNLIITRRXXX' )
      ( code = 'W2' name = 'BANCA NAZIONALE DEL LAVORO SPA GRUPPO BNPP (BNL) (Bank accou' swift = 'BNLIITRRXXX' )
      ( code = 'W6' name = 'Banque marocaine du commerce exterieur (BMCE)' swift = 'BMCEMAMC' )
      ( code = 'W7' name = 'Banque marocaine du commerce exterieur (BMCE) (Bank account#' swift = 'BMCEMAMC' )
      ( code = 'X1' name = 'CAIXABANK (Bank account# 2)' swift = '' )
      ( code = 'X2' name = 'CAIXABANK (Bank account# 3)' swift = '' )
      ( code = 'X3' name = 'CAIXABANK (Bank account# 4)' swift = '' )
      ( code = 'X6' name = 'Banco Millennium ATLANTICO (BANCO PRIVADO ATLANTICO, LUANDA)' swift = 'PRTLAOLUXXX' )
      ( code = 'Y1' name = 'YAPI_TR (Yapi Ve Kredi Bankasi A.S.) (Bank account# 2)' swift = '' )
      ( code = 'Y2' name = 'YAPI_TR (Yapi Ve Kredi Bankasi A.S.) (Bank account# 3)' swift = '' )
      ( code = 'Y6' name = 'Credit du Congo' swift = 'BCMACGCGXXX' )
      ( code = 'Z1' name = 'Zabrebacka Banka /Zagrebacka Banka (Bank account# 2)' swift = '' )
      ( code = 'Z2' name = 'Vietinbank' swift = '' )
      ( code = 'Z3' name = 'Santander Bank Brasil' swift = '' )
      ( code = 'Z4' name = 'Sparkasse (Bank account# 2)' swift = '' )
      ( code = 'Z5' name = 'ICICI Bank LTD (Bank account# 2)' swift = '' )
      ( code = 'Z6' name = 'First Abu Dhabi Bank' swift = '' )
      ( code = 'M6' name = 'ARAB Banking' swift = 'ABCODZALXXX' )
      ( code = 'M7' name = 'ARAB Banking (Bank account# 2)' swift = 'ABCODZALXXX' )
      ( code = 'M8' name = 'ARAB Banking (Bank account# 3)' swift = 'ABCODZALXXX' )
      ( code = 'G6' name = 'United Bank Share Company or HIBRET BANK SHARE COMPANY' swift = 'UNTDETAAXXX' )
      ( code = 'G7' name = 'United Bank Share Company or HIBRET BANK SHARE COMPANY (Bank' swift = 'UNTDETAAXXX' )
      ( code = 'G8' name = 'United Bank Share Company or HIBRET BANK SHARE COMPANY (Bank' swift = 'UNTDETAAXXX' )
    ).
  ENDMETHOD.


  METHOD get_currency_codes.
    rt_ccy = VALUE #(
      ( iso = 'SDG' code = '10' country = 'Sudanese Pound' )
      ( iso = 'MRU' code = '11' country = 'Mauritanian ouguiya' )
      ( iso = 'UYU' code = '12' country = 'Uruguayan Peso (new)' )
      ( iso = 'HNL' code = '13' country = 'Honduran Lempira' )
      ( iso = 'PKR' code = '14' country = 'Pakistan' )
      ( iso = 'CAD' code = '15' country = 'Canada' )
      ( iso = 'MUR' code = '16' country = 'Mauritius' )
      ( iso = 'NAD' code = '17' country = 'Namibia' )
      ( iso = 'TRY' code = '18' country = 'Turkey' )
      ( iso = 'RWF' code = '19' country = 'Rwandan Franc' )
      ( iso = 'SZL' code = '20' country = 'Swaziland' )
      ( iso = 'AUD' code = '21' country = 'Australia' )
      ( iso = 'ZAR' code = '22' country = 'South Africa' )
      ( iso = 'KWD' code = '23' country = 'Kuwait' )
      ( iso = 'INR' code = '24' country = 'India' )
      ( iso = 'NZD' code = '25' country = 'New Zealand' )
      ( iso = 'MXN' code = '26' country = 'Mexico' )
      ( iso = 'ZMK' code = '27' country = 'Zambia' )
      ( iso = 'NGN' code = '28' country = 'Nigeria' )
      ( iso = 'UGX' code = '29' country = 'Ugandan Shilling' )
      ( iso = 'IRR' code = '30' country = 'Iran' )
      ( iso = 'JPY' code = '31' country = 'Japan' )
      ( iso = 'OMR' code = '32' country = 'Oman' )
      ( iso = 'AZN' code = '33' country = 'Azerbaijani Manat' )
      ( iso = 'SGD' code = '34' country = 'Singapore' )
      ( iso = 'COP' code = '35' country = 'Colombia' )
      ( iso = 'RSD' code = '36' country = 'Serbian Dinar' )
      ( iso = 'EGP' code = '37' country = 'Egypt' )
      ( iso = 'ARS' code = '38' country = 'Argentina' )
      ( iso = 'BRL' code = '39' country = 'Brazil' )
      ( iso = 'MZN' code = '40' country = 'Mozambique Metical' )
      ( iso = 'CLP' code = '41' country = 'Chile' )
      ( iso = 'GTQ' code = '42' country = 'Guatemala' )
      ( iso = 'MYR' code = '43' country = 'Malaysia' )
      ( iso = 'MAD' code = '44' country = 'Morocco' )
      ( iso = 'XPF' code = '45' country = 'French Pacific Franc' )
      ( iso = 'JMD' code = '46' country = 'Jamaican Dollar' )
      ( iso = 'PEN' code = '47' country = 'Peru' )
      ( iso = 'LKR' code = '48' country = 'Sri Lankan Rupee' )
      ( iso = 'DJF' code = '49' country = 'Djiboutian franc' )
      ( iso = 'VND' code = '52' country = 'Vietnam' )
      ( iso = 'SVC' code = '55' country = 'El Salvador' )
      ( iso = 'PHP' code = '56' country = 'Philippines' )
      ( iso = 'NIO' code = '57' country = 'Nicaragua' )
      ( iso = 'CRC' code = '58' country = 'Costa Rica' )
      ( iso = 'IDR' code = '59' country = 'Indonesia' )
      ( iso = 'TND' code = '60' country = 'Tunisia' )
      ( iso = 'ISK' code = '62' country = 'Iceland' )
      ( iso = 'RUB' code = '63' country = 'Russia' )
      ( iso = 'KRW' code = '65' country = 'Korea Republik (south)' )
      ( iso = 'SAR' code = '66' country = 'Saudi Arabia' )
      ( iso = 'HKD' code = '68' country = 'Hongkong' )
      ( iso = 'QAR' code = '70' country = 'Qatar' )
      ( iso = 'BHD' code = '71' country = 'Bahrain' )
      ( iso = 'MKD' code = '72' country = 'Macedonia' )
      ( iso = 'HUF' code = '73' country = 'Hungary' )
      ( iso = 'DZD' code = '74' country = 'Algerian Dinar' )
      ( iso = 'THB' code = '75' country = 'Thailand' )
      ( iso = 'ETB' code = '76' country = 'Ethiopia' )
      ( iso = 'KES' code = '77' country = 'Kenya' )
      ( iso = 'BDT' code = '78' country = 'Bangladesh' )
      ( iso = 'BOB' code = '79' country = 'Bolivia' )
      ( iso = 'DOP' code = '80' country = 'Dominican Republic' )
      ( iso = 'ILS' code = '82' country = 'Israel' )
      ( iso = 'VES' code = '83' country = 'Venezuelan Bolivares' )
      ( iso = 'TWD' code = '85' country = 'Taiwan' )
      ( iso = 'AED' code = '86' country = 'United Arab. Emirates' )
      ( iso = 'UAH' code = '87' country = 'Ukraine' )
      ( iso = 'PLN' code = '88' country = 'Poland' )
      ( iso = 'CNY' code = '89' country = 'China' )
      ( iso = 'HRK' code = '90' country = 'Croatia' )
      ( iso = 'KZT' code = '91' country = 'Kazakhstan' )
      ( iso = 'RON' code = '92' country = 'Romania' )
      ( iso = 'BGN' code = '93' country = 'Bulgaria' )
      ( iso = 'CZK' code = '94' country = 'Czech Republic' )
      ( iso = 'YER' code = '96' country = 'Yemen' )
      ( iso = 'JOD' code = '97' country = 'Jordan' )
      ( iso = 'EUR' code = '98' country = 'Europe' )
      ( iso = 'TMT' code = '99' country = 'Turkmenistan Manat' )
      ( iso = 'BAM' code = '01' country = 'Bosnian Mark' )
      ( iso = 'USD' code = '02' country = 'United States' )
      ( iso = 'GBP' code = '03' country = 'United Kingdom' )
      ( iso = 'BWP' code = '04' country = 'Botswana Pula' )
      ( iso = 'XOF' code = '05' country = 'CFA Franc BCEAO /Togo' )
      ( iso = 'DKK' code = '06' country = 'Denmark' )
      ( iso = 'NOK' code = '07' country = 'Norway' )
      ( iso = 'SEK' code = '08' country = 'Sweden' )
      ( iso = 'CHF' code = '09' country = 'Switzerland' )
      ( iso = 'TTD' code = '50' country = 'Trinidadisk dollar' )
      ( iso = 'XAF' code = '51' country = 'Central African CFA franc' )
      ( iso = 'GHS' code = '53' country = 'Ghanaian Cedis' )
      ( iso = 'ALL' code = '54' country = 'Albanian lek' )
      ( iso = 'AOA' code = '61' country = 'Angolansk kwanza' )
    ).
  ENDMETHOD.


  METHOD get_account_groups.
    rt_group = VALUE #(
      ( kind = c_kind-main    grp = '288' descr = 'External Bank - Main GL account' )
      ( kind = c_kind-int_in  grp = '484' descr = 'Interim In (External)' )
      ( kind = c_kind-int_out grp = '485' descr = 'Interim Out (External)' )
      ( kind = c_kind-ihb     grp = '253' descr = 'In-House Bank (IHBSG/IHBSE/IC)' )
      ( kind = c_kind-ihb_int grp = '488' descr = 'Interim In-House Bank (IHBSG/IHBSE/IC)' )
    ).
  ENDMETHOD.


  METHOD get_planning_levels.
    " pos 8 <- payment method (Interim Out / Interim IHB). Source: concept
    " slide 8 "Last digit of Bank GL account". Note: payment method 'X'
    " appears twice in the source (digit 6 = SFS netting, digit 5 = tax)
    " - first row wins here.
    " Out of scope: the cash-management planning levels (F0 / 01..06) on
    " concept slides 9-11 are a separate topic, not part of the GL account.
    rt_plvl = VALUE #(
      ( pmethod = 'A' digit = '6' level = 'B6' descr = 'Clearing - Treasury Payments' )
      ( pmethod = 'B' digit = '6' level = 'B6' descr = 'Clearing - Treasury Payments' )
      ( pmethod = 'C' digit = '1' level = 'B1' descr = 'Outgoing - Cheque' )
      ( pmethod = 'D' digit = '2' level = 'B2' descr = 'Outgoing - Direct Debit' )
      ( pmethod = 'F' digit = '9' level = 'B9' descr = 'Incoming - Factoring' )
      ( pmethod = 'N' digit = '4' level = 'B4' descr = 'Outgoing - Confirming' )
      ( pmethod = 'O' digit = '8' level = 'B8' descr = 'Outgoing - Certified Payments' )
      ( pmethod = 'T' digit = '3' level = 'B3' descr = 'Outgoing - Third Party' )
      ( pmethod = 'U' digit = '3' level = 'B3' descr = 'Outgoing - Third Party' )
      ( pmethod = 'W' digit = '6' level = 'B6' descr = 'Clearing - Treasury Payments' )
      ( pmethod = 'X' digit = '6' level = 'B6' descr = 'Clearing - Treasury Payments' )
      ( pmethod = 'X' digit = '5' level = 'B5' descr = 'Outgoing - Tax' )
      ( pmethod = 'Y' digit = '3' level = 'B3' descr = 'Outgoing - Third Party' )
      ( pmethod = '2' digit = '3' level = 'B3' descr = 'Outgoing - Third Party' )
      ( pmethod = 'Z' digit = '3' level = 'B3' descr = 'Outgoing - Third Party' )
      ( pmethod = 'M' digit = '3' level = 'B3' descr = 'Outgoing - Third Party' )
      ( pmethod = 'H' digit = '1' level = 'B1' descr = 'Outgoing - Cheque' )
      ( pmethod = 'G' digit = '1' level = 'B1' descr = 'Outgoing - Cheque' )
    ).
  ENDMETHOD.


  METHOD currency_code.
    DATA(lt) = get_currency_codes( ).
    READ TABLE lt INTO DATA(ls) WITH KEY iso = iv_iso.
    IF sy-subrc = 0.
      rv_code = ls-code.
    ENDIF.
  ENDMETHOD.


  METHOD group_of_kind.
    DATA(lt) = get_account_groups( ).
    READ TABLE lt INTO DATA(ls) WITH KEY kind = iv_kind.
    IF sy-subrc = 0.
      rv_group = ls-grp.
    ENDIF.
  ENDMETHOD.


  METHOD planning_digit.
    CASE iv_kind.
      WHEN c_kind-main.
        rv_digit = '0'.
      WHEN c_kind-int_in.
        rv_digit = '1'.
      WHEN c_kind-ihb.
        " Confirmed by concept slide 5 example 25399060
        " (253 + 99 + 06 + 0): IHB main behaves like the external main bank.
        rv_digit = '0'.
      WHEN c_kind-int_out OR c_kind-ihb_int.
        " Confirmed by concept slide 5 example 48899063
        " (488 + 99 + 06 + 3): IHB interim uses the same position-8
        " payment-method table as the external Interim Out (485).
        LOOP AT get_planning_levels( ) INTO DATA(ls) WHERE pmethod = iv_payment_method.
          rv_digit = ls-digit.
          EXIT.
        ENDLOOP.
    ENDCASE.
  ENDMETHOD.


ENDCLASS.
