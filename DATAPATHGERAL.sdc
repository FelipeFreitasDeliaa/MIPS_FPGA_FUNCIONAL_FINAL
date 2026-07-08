# =====================================================================
#  DATAPATHGERAL.sdc  -  Restricoes de tempo (TimeQuest) para a DE2-115
#
#  Sem SDC, o Quartus assume o clock em 1 GHz e reporta slack de -155 ns
#  (analise inutil). Aqui dizemos a verdade: o clock fisico e 50 MHz e o
#  processador roda em um clock DERIVADO de 1 MHz.
#
#  Adicione ao projeto:
#    set_global_assignment -name SDC_FILE DATAPATHGERAL.sdc
#
#  Obs.: assume o TOPO_DE2_115 com a instancia do divisor chamada
#  'div_1mhz'. Se renomear, ajuste o get_registers abaixo.
# =====================================================================

# ---- Clock fisico de entrada: 50 MHz = 20 ns ----
create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]

# ---- Clock GERADO de 1 MHz (o divisor faz toggle a cada 25 ciclos,
#      periodo total = 50 ciclos de CLOCK_50) ----
create_generated_clock -name clk_1mhz -source [get_ports {CLOCK_50}] \
    -divide_by 50 [get_registers {*div_1mhz|clk_out}]

derive_clock_uncertainty

# ---- I/O assincrono (chaves, botoes, displays): sem tempo rigido ----
set_false_path -from [get_ports {SW[*]}]  -to [all_registers]
set_false_path -from [get_ports {KEY[*]}] -to [all_registers]
set_false_path -from [all_registers] -to [get_ports {HEX0[*] HEX1[*] HEX2[*] HEX3[*] HEX4[*] HEX5[*] HEX6[*] HEX7[*]}]
