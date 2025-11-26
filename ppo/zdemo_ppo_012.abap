*&---------------------------------------------------------------------*
*& Report ZDEMO_PPO_012
*&---------------------------------------------------------------------*
*& FIELD-SYMBOLS vs WORK AREA Performance Comparison
*&---------------------------------------------------------------------*
REPORT zdemo_ppo_012.

CLASS lcl_field_symbols_comparison DEFINITION.
  PUBLIC SECTION.
    " Performance measurement data
    DATA: mv_time_field_symbols TYPE i,
          mv_time_work_area     TYPE i.

    " Data structure for testing
    TYPES: BEGIN OF ts_test_data,
             key_field  TYPE i,      " Key field
             data_field TYPE string, " Some data field
             extra_data TYPE string, " Additional data to increase size
           END OF ts_test_data.

    DATA: mt_test_data TYPE TABLE OF ts_test_data.

    METHODS:
      init,
      test_field_symbols,
      test_work_area,
      display_results.
ENDCLASS.

CLASS lcl_field_symbols_comparison IMPLEMENTATION.

  METHOD init.
    " Generate test data
    DATA: lv_counter TYPE i VALUE 1.

    " Generate 1000 test records with larger data to make memory differences more noticeable
    DO 1000 TIMES.
      APPEND VALUE #( key_field = lv_counter
                      data_field = |Data for key { lv_counter } with some additional content to increase memory usage|
                      extra_data = |Extra data field { lv_counter } with even more content to make the data structure larger| )
        TO mt_test_data.
      lv_counter = lv_counter + 1.
    ENDDO.

    cl_demo_output=>write( |Generated { lines( mt_test_data ) } test records| ).
    cl_demo_output=>write( 'FIELD-SYMBOLS vs WORK AREA performance comparison initialized' ).
  ENDMETHOD.

  METHOD test_field_symbols.
    DATA: lv_timestamp_begin TYPE i,
          lv_timestamp_end   TYPE i,
          lv_counter         TYPE i.

    " Test with FIELD-SYMBOLS (more efficient)
    GET RUN TIME FIELD lv_timestamp_begin.
    
    FIELD-SYMBOLS: <fs_data> TYPE ts_test_data.
    lv_counter = 0.
    
    LOOP AT mt_test_data ASSIGNING <fs_data>.
      " Modify data using field symbol (no data copy)
      <fs_data>-data_field = |Modified { <fs_data>-data_field }|.
      lv_counter = lv_counter + 1.
    ENDLOOP.
    
    GET RUN TIME FIELD lv_timestamp_end.
    mv_time_field_symbols = lv_timestamp_end - lv_timestamp_begin.

    cl_demo_output=>write( |FIELD-SYMBOLS test completed: { lv_counter } iterations| ).
  ENDMETHOD.

  METHOD test_work_area.
    DATA: lv_timestamp_begin TYPE i,
          lv_timestamp_end   TYPE i,
          lv_counter         TYPE i.

    " Test with work area (less efficient - data copy)
    GET RUN TIME FIELD lv_timestamp_begin.
    
    DATA: ls_work_area TYPE ts_test_data.
    lv_counter = 0.
    
    LOOP AT mt_test_data INTO ls_work_area.
      " Modify data in work area (data copy occurs)
      ls_work_area-data_field = |Modified { ls_work_area-data_field }|.
      MODIFY mt_test_data FROM ls_work_area INDEX sy-tabix.
      lv_counter = lv_counter + 1.
    ENDLOOP.
    
    GET RUN TIME FIELD lv_timestamp_end.
    mv_time_work_area = lv_timestamp_end - lv_timestamp_begin.

    cl_demo_output=>write( |WORK AREA test completed: { lv_counter } iterations| ).
  ENDMETHOD.

  METHOD display_results.
    DATA: lv_improvement TYPE p LENGTH 5 DECIMALS 2,
          lv_speedup     TYPE p LENGTH 5 DECIMALS 2.

    cl_demo_output=>write( '=== FIELD-SYMBOLS vs WORK AREA PERFORMANCE COMPARISON ===' ).
    cl_demo_output=>write( 'Comparison: LOOP AT ... ASSIGNING vs LOOP AT ... INTO' ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).

    " Calculate improvement
    IF mv_time_work_area > 0.
      lv_improvement = ( 1 - ( mv_time_field_symbols / mv_time_work_area ) ) * 100.
      lv_speedup = mv_time_work_area / mv_time_field_symbols.
    ELSE.
      lv_improvement = 0.
      lv_speedup = 1.
    ENDIF.

    cl_demo_output=>write( |Time with FIELD-SYMBOLS: { mv_time_field_symbols } microseconds| ).
    cl_demo_output=>write( |Time with WORK AREA:     { mv_time_work_area } microseconds| ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).
    cl_demo_output=>write( |Performance improvement: { lv_improvement }%| ).
    cl_demo_output=>write( |Speedup factor: { lv_speedup }x| ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).
    cl_demo_output=>write( 'TECHNICAL INSIGHTS:' ).
    cl_demo_output=>write( '- FIELD-SYMBOLS: Direct memory access, no data copying' ).
    cl_demo_output=>write( '- WORK AREA: Data is copied to work area for each iteration' ).
    cl_demo_output=>write( '- Recommendation: Use FIELD-SYMBOLS for better performance' ).
  ENDMETHOD.

ENDCLASS.

START-OF-SELECTION.
  PERFORM main.

FORM main.
  CONSTANTS: lc_num_of_iterations TYPE i VALUE 10.

  DATA(object) = NEW lcl_field_symbols_comparison( ).
  object->init( ).

  " Warm-up run to avoid JIT compilation effects
  object->test_field_symbols( ).
  object->test_work_area( ).

  " Actual measurement runs
  DO lc_num_of_iterations TIMES.
    object->test_field_symbols( ).
    object->test_work_area( ).
  ENDDO.

  object->display_results( ).
  cl_demo_output=>display( ).
ENDFORM.
