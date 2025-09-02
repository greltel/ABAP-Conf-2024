CLASS zcl_abap_conference_2024 DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    ALIASES main FOR if_oo_adt_classrun~main.

ENDCLASS.



CLASS ZCL_ABAP_CONFERENCE_2024 IMPLEMENTATION.


  METHOD main.

    " &----------------------------------------------------------------------
    " & Line exists with comparison operators
    " &----------------------------------------------------------------------

    SELECT FROM sflight
    FIELDS *
    INTO TABLE @DATA(lt_sflight).



    IF REDUCE abap_bool( INIT price_ne_422 = abap_false
                         FOR ls_line IN lt_sflight WHERE ( carrid NE '422')
                         NEXT price_ne_422 = abap_true ) EQ abap_true.
*    IMPLEMENT LOGIC

    ENDIF.

    " &----------------------------------------------------------------------
    " & CORRESPONDING IN CONJUSTION WITH INSERT/APPEND
    " &----------------------------------------------------------------------

    DATA lt_sales_header TYPE tab_vbak.

    SELECT SINGLE FROM vbap
    FIELDS vbeln AS order,erdat AS creation_date,ernam
    INTO @DATA(ls_sales_item).

    INSERT CORRESPONDING #( ls_sales_item MAPPING vbeln = order
                                                  erdat = creation_date
                                          EXCEPT ernam ) INTO TABLE lt_sales_header.

    " &----------------------------------------------------------------------
    " & CORRESPONDING with LOOKUP Table
    " &----------------------------------------------------------------------
    TYPES:BEGIN OF t_country,
            country      TYPE i_countrytext-country,
            country_text TYPE i_countrytext-countryname,
          END OF t_country,

          tt_country TYPE STANDARD TABLE OF t_country WITH DEFAULT KEY.

    DATA lt_lookup TYPE HASHED TABLE OF i_countrytext WITH UNIQUE KEY country.

    DATA(lt_original) = VALUE tt_country( ( country = 'GR' ) ( country = 'DE'  ) ).

    SELECT FROM i_countrytext
    FIELDS *
    WHERE language EQ @syst-langu
    INTO TABLE @lt_lookup.

    DATA(lt_result_lookup) = CORRESPONDING tt_country( lt_original ##OPERATOR[LT_ORIGINAL]
                                                       FROM lt_lookup
                                                       USING country = country
                                                       MAPPING country_text = countryname ).

    " &----------------------------------------------------------------------
    " & LOOP at VALUE
    " &----------------------------------------------------------------------

    TYPES:tt_spfli_new TYPE STANDARD TABLE OF spfli WITH DEFAULT KEY.

    DATA lt_spfli_1  TYPE tt_spfli_new.
    DATA lt_spfli_2  TYPE tt_spfli_new.

    SELECT FROM spfli
    FIELDS *
    WHERE carrid EQ 'AA'
    INTO CORRESPONDING FIELDS OF TABLE @lt_spfli_1.

    SELECT FROM spfli FIELDS *
    WHERE carrid EQ 'AZ'
    INTO CORRESPONDING FIELDS OF TABLE @lt_spfli_2.

    LOOP AT VALUE tt_spfli_new( ( LINES OF lt_spfli_1 ) ( LINES OF lt_spfli_2 ) ( carrid = 'AV' )  ) ASSIGNING FIELD-SYMBOL(<fs>).

    ENDLOOP.

    " &----------------------------------------------------------------------
    " & Advanced Filtering of Internal Table
    " &----------------------------------------------------------------------

    DATA lt_flights TYPE /iwfnd/sflight_flight_t.

    SELECT FROM sflight
    FIELDS carrid,connid,fldate
    INTO CORRESPONDING FIELDS OF TABLE @lt_flights.

    DATA(lt_filtered_flights) = VALUE /iwfnd/sflight_flight_t( FOR <fs_line> IN lt_flights
                                                               ( LINES OF COND #( WHEN <fs_line>-fldate <= syst-datum
                                                                                  THEN VALUE #( ( <fs_line> ) ) ) ) ).

    " &----------------------------------------------------------------------
    " & Count Internal Table lines
    " &----------------------------------------------------------------------

    TYPES: BEGIN OF t_spfli,
             carrid TYPE s_carr_id,
           END OF t_spfli,

           tt_spfli TYPE SORTED TABLE OF t_spfli WITH NON-UNIQUE KEY carrid.

    DATA lt_spfli TYPE tt_spfli.

    SELECT FROM spfli
      FIELDS carrid
      INTO TABLE @lt_spfli.

    DATA(lv_lines) = lines( FILTER #( lt_spfli WHERE carrid = CONV #( 'LH' ) ) ).

    out->write( data = lv_lines
                name = CONV string( LET abap_conf_year = syst-datum+0(4)
                                        event_name     = 'ABAPConf'
                                    IN  |The event { event_name } year { abap_conf_year } | ) ).
  ENDMETHOD.
ENDCLASS.
