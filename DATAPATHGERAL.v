module DATAPATHGERAL (
    input        clk,
    input        botao_in,          // NOVO: botao de "enter" das instrucoes IN
    input [31:0] Dado_Switches_Ext, // entrada física das chaves do FPGA
	  output [31:0] Saida_Display_Out,
	  //saídas para teste//
	 output [31:0] debug_saida_ula,
    output [31:0] debug_dado1,
    output [31:0] debug_dado2,
	 output [5:0]  debug_regescrira_banco,
    output [31:0] debug_pc_atual,
    output [31:0] debug_instrucao,
    output [5:0]  debug_opcode,
	 output [31:0] debug_imediato_estendido,
    output [31:0] debug_dado_lido_mem
);
    // =========================================================
    // Endereços dos registradores específicos
    // =========================================================
    localparam RZ_ADDR   = 6'd0;
    localparam RIN_ADDR  = 6'd58;
    localparam ROUT_ADDR = 6'd59;
    localparam RL_ADDR   = 6'd60;
    localparam RAL_ADDR  = 6'd61;
    localparam RPI_ADDR  = 6'd62;
    localparam RH_ADDR   = 6'd63;

    // =========================================================
    // Fios da instrução e do PC
    // =========================================================
    wire [31:0] fio_pc_atual;
    wire [31:0] fio_instrucao;

    // Campos extraídos da instrução
    wire [5:0]  fio_opcode   = fio_instrucao[31:26];
    wire [5:0]  fio_campo_rd = fio_instrucao[25:20];
    wire [5:0]  fio_campo_rs = fio_instrucao[19:14];
    wire [5:0]  fio_campo_rt = fio_instrucao[13:8];
    wire [25:0] fio_campo_26 = fio_instrucao[25:0];
    wire [19:0] fio_campo_20 = fio_instrucao[19:0];
    wire [13:0] fio_campo_14 = fio_instrucao[13:0];

    // =========================================================
    // Fios dos sinais de controle (saídas da UC)
    // =========================================================
    wire        fio_branch, fio_jump, fio_jr, fio_hlt;
    wire        fio_regwrite, fio_rhwrite, fio_rpiwrite, fio_ralwrite;
    wire        fio_memwrite, fio_memread;
    wire        fio_memtoreg, fio_ulasource, fio_push, fio_pop;
    wire        fio_resp, fio_switcheson, fio_portaon, fio_pilha;
    wire [5:0]  fio_ulacontrol;
    wire        fio_rd_rs,  fio_r1esp;
    wire [5:0]  fio_reg1;
    wire [1:0]  fio_rd_rs_rt;
    wire        fio_r2esp;
    wire [5:0]  fio_reg2;
    wire        fio_rwesp;
    wire [5:0]  fio_regw;
    wire        fio_selimm1, fio_selimm2;

    // =========================================================
    // Fios de saída do DATAPATH (Banco + ULA)
    // =========================================================
    wire [31:0] fio_saida_ula;
    wire        fio_z_flag;
    wire [31:0] fio_dado1_out; // Dado_1 do banco → JR e DISPLAY
    wire [31:0] fio_dado2_out; // Dado_2 do banco → escrita nas memórias

    // =========================================================
    // Fios do extensor de sinal
    // =========================================================
    wire [31:0] fio_imediato_estendido;

    // =========================================================
    // Fios das memórias
    // =========================================================
    wire [31:0] fio_dado_dados;       // saída da memória de dados
    wire [31:0] fio_dado_pilha_out;   // saída da memória da pilha
    wire [31:0] fio_dado_lido_mem;    // dado selecionado (dados ou pilha)
    wire        fio_we_dados, fio_re_dados;
    wire        fio_we_pilha, fio_re_pilha;

    // =========================================================
    // Fios do módulo SWITCHES
    // =========================================================
    wire [31:0] fio_saida_switches;

    // =========================================================
    // Fios dos MUXes de seleção de registradores
    // =========================================================
    wire [5:0] fio_mux_rd_rs;
    wire [5:0] fio_reg1_banco;
    wire [5:0] fio_mux_rd_rs_rt;
    wire [5:0] fio_reg2_banco;
    wire [5:0] fio_regescrira_banco;

    // =========================================================
    // Fios do subtrator e MUX Pop (atualização do RPI)
    // =========================================================
    wire [31:0] fio_rpi_menos_1;
    wire [31:0] fio_dado_rpi;

    // =========================================================
    // MUXes antes do Banco — Porta 1
    // MUX RD/RS: seleciona entre RD e RS
    // MUX R1esp: seleciona entre campo da instrução e registrador específico
    // =========================================================
    assign fio_mux_rd_rs  = (fio_rd_rs == 1'b1) ? fio_campo_rs : fio_campo_rd;
    assign fio_reg1_banco = (fio_r1esp == 1'b1) ? fio_reg1 : fio_mux_rd_rs;

    // =========================================================
    // MUXes antes do Banco — Porta 2
    // MUX RD/RS/RT: seleciona entre RD, RS e RT
    // MUX R2esp: seleciona entre campo da instrução e registrador específico
    // =========================================================
    assign fio_mux_rd_rs_rt = (fio_rd_rs_rt == 2'b00) ? fio_campo_rd :
                              (fio_rd_rs_rt == 2'b01) ? fio_campo_rs :
                                                        fio_campo_rt;
    assign fio_reg2_banco = (fio_r2esp == 1'b1) ? fio_reg2 : fio_mux_rd_rs_rt;

    // =========================================================
    // MUX do Registrador de Escrita
    // RWesp: seleciona entre RD da instrução e registrador específico
    // =========================================================
    assign fio_regescrira_banco = (fio_rwesp == 1'b1) ? fio_regw : fio_campo_rd;

    // =========================================================
    // Portas AND — separação entre memória de dados e pilha
    // Pilha=0: acessa memória de dados
    // Pilha=1: acessa memória da pilha
    // =========================================================
    assign fio_we_dados = fio_memwrite & ~fio_pilha;
    assign fio_re_dados = fio_memread  & ~fio_pilha;
    assign fio_we_pilha = fio_memwrite &  fio_pilha;
    assign fio_re_pilha = fio_memread  &  fio_pilha;

    // =========================================================
    // MUX seleção do dado lido (memória de dados ou pilha)
    // =========================================================
    assign fio_dado_lido_mem = (fio_pilha == 1'b1) ? fio_dado_pilha_out
                                                    : fio_dado_dados;

    // =========================================================
    // Subtrator dedicado e MUX Pop
    // PUSH: RPI recebe RPI+1 (saída da ULA)
    // POP:  RPI recebe RPI-1 (saída do subtrator)
    // =========================================================
    assign fio_rpi_menos_1 = fio_saida_ula - 32'd1;
    assign fio_dado_rpi    = (fio_pop == 1'b1) ? fio_rpi_menos_1
                                               : fio_saida_ula;
	
	 //fios para análise dos testes
	 assign debug_saida_ula           = fio_saida_ula;
    assign debug_dado1               = fio_dado1_out;
    assign debug_dado2               = fio_dado2_out;
    assign debug_reg1_banco          = fio_reg1_banco;
    assign debug_reg2_banco          = fio_reg2_banco;
    assign debug_regescrira_banco    = fio_regescrira_banco;
    assign debug_pc_atual            = fio_pc_atual;
    assign debug_instrucao           = fio_instrucao;
    assign debug_opcode              = fio_opcode;
	 assign debug_imediato_estendido  = fio_imediato_estendido;
    assign debug_dado_lido_mem       = fio_dado_lido_mem;

    // =========================================================
    // Botao de "enter" das instrucoes IN
    // Quando a instrucao atual e IN (SwitchesON=1), segura o PC ate
    // o usuario apertar o botao. Cada aperto libera UMA IN (para a
    // proxima, soltar e apertar de novo).
    // =========================================================
    wire fio_segura_pc;
    BOTAO_IN #(.CLK_HZ(1000000), .DEBOUNCE_MS(10), .ATIVO_BAIXO(1'b1)) meu_botao_in (
        .clk        (clk),
        .botao_bruto(botao_in),
        .em_in      (fio_switcheson),   // SwitchesON = 1 exatamente na IN
        .segura_pc  (fio_segura_pc)
    );

    // =========================================================
    // Instância do Program Counter
    // Atualiza na borda de descida do clock
    // Branch calcula PC_atual + 1 + Imediato_Branch internamente
    // =========================================================
    PROGRAMCOUNTER meu_pc (
        .clk            (clk),
        .HLT            (fio_hlt),
        .segura_in      (fio_segura_pc),   // NOVO: trava na IN ate o botao
        .Branch         (fio_branch),
        .z_flag         (fio_z_flag),
        .Jump           (fio_jump),
        .JR             (fio_jr),
        .Imediato_Branch(fio_imediato_estendido),   // END14 estendido
        .Imediato_Jump  ({6'b000000, fio_campo_26}),// endereço absoluto de 26 bits
        .Endereco_JR    (fio_dado1_out),            // valor do registrador RD
        .PC_atual       (fio_pc_atual)
    );

    // =========================================================
    // Instância da Memória de Instruções (ROM)
    // Lê a instrução no endereço apontado pelo PC
    // =========================================================
    MEMORIADEINSTRUCOES minha_mem_instrucoes (
        .addr(fio_pc_atual[7:0]),
        .clk (clk),
        .q   (fio_instrucao)
    );

    // =========================================================
    // Instância da Unidade de Controle
    // Decodifica o opcode e gera todos os sinais de controle
    // =========================================================
    UNIDADEDECONTROLE minha_uc (
        .opcode    (fio_opcode),
        .Branch    (fio_branch),
        .Jump      (fio_jump),
        .JR        (fio_jr),
        .HLT       (fio_hlt),
        .RegWrite  (fio_regwrite),
        .RHwrite   (fio_rhwrite),
        .RPIwrite  (fio_rpiwrite),
        .RALwrite  (fio_ralwrite),
        .MemWrite  (fio_memwrite),
        .MemRead   (fio_memread),
        .MemtoReg  (fio_memtoreg),
        .ULASource (fio_ulasource),
        .Push      (fio_push),
        .Pop       (fio_pop),
        .Resp      (fio_resp),
        .SwitchesON(fio_switcheson),
        .PortaON   (fio_portaon),
        .Pilha     (fio_pilha),
        .ULAControl(fio_ulacontrol),
        .RD_RS     (fio_rd_rs),
        .R1esp     (fio_r1esp),
        .Reg1      (fio_reg1),
        .RD_RS_RT  (fio_rd_rs_rt),
        .R2esp     (fio_r2esp),
        .Reg2      (fio_reg2),
        .RWesp     (fio_rwesp),
        .RegW      (fio_regw),
        .SelImm1   (fio_selimm1),
        .SelImm2   (fio_selimm2)
    );

    // =========================================================
    // Instância do Extensor de Sinal
    // Contém os MUXes de seleção do imediato (14, 20 ou 26 bits)
    // e realiza a extensão de sinal para 32 bits
    // =========================================================
    EXTENSORDESINAL meu_extensor (
        .Imediato_26(fio_campo_26),
        .Imediato_20(fio_campo_20),
        .Imediato_14(fio_campo_14),
        .SelImm1    (fio_selimm1),
        .SelImm2    (fio_selimm2),
        .Saida      (fio_imediato_estendido)
    );

    // =========================================================
    // Instância do DATAPATH (Banco de Registradores + ULA + MUXes)
    // Contém os MUXes antes e após a ULA
    // Banco escreve na borda de subida do clock
    // =========================================================
    DATAPATH meu_datapath (
        .clk                (clk),
        .RegWrite           (fio_regwrite),
        .RHwrite            (fio_rhwrite),
        .RPIwrite           (fio_rpiwrite),
        .RALwrite           (fio_ralwrite),
        .ULASource          (fio_ulasource),
        .Push               (fio_push),
        .Resp               (fio_resp),
        .MemtoReg           (fio_memtoreg),
        .SwitchesON         (fio_switcheson),
        .opcode             (fio_ulacontrol),         // opcode para a ULA
        .Registrador_1      (fio_reg1_banco),         // vem dos MUXes de seleção
        .Registrador_2      (fio_reg2_banco),
        .Registrador_Escrita(fio_regescrira_banco),
        .Imediato_Estendido (fio_imediato_estendido), // vem do extensor
        .Dado_RPI           (fio_dado_rpi),           // RPI+1 ou RPI-1
        .Dado_RAL           (fio_pc_atual + 32'd1),   // PC+1 salvo por JAL
        .Dado_Memoria       (fio_dado_lido_mem),      // dado lido da memória
        .Dado_Switches      (fio_saida_switches),     // valor das chaves
        .Saida_ULA          (fio_saida_ula),
        .z_flag             (fio_z_flag),
        .Dado_1_Out         (fio_dado1_out),          // para JR e DISPLAY
        .Dado_2_Out         (fio_dado2_out)           // para escrita nas memórias
    );

    // =========================================================
    // Instância da Memória de Dados
    // Escrita: posedge | Leitura: negedge
    // Habilitada quando Pilha=0
    // =========================================================
    MEMORIADEDADOS minha_mem_dados (
        .data      (fio_dado2_out),
        .write_addr(fio_saida_ula[5:0]),
        .read_addr (fio_saida_ula[5:0]),
        .we        (fio_we_dados),
        .clk       (clk),
        .q         (fio_dado_dados)
    );

    // =========================================================
    // Instância da Memória da Pilha
    // Escrita: posedge | Leitura: negedge
    // Habilitada quando Pilha=1
    // =========================================================
    MEMORIADEPILHA minha_mem_pilha (
        .data      (fio_dado2_out),
        .write_addr(fio_saida_ula[3:0]),
        .read_addr (fio_saida_ula[3:0]),
        .we        (fio_we_pilha),
        .clk       (clk),
        .q         (fio_dado_pilha_out)
    );

    // =========================================================
    // Instância do módulo SWITCHES
    // Repassa o valor das chaves físicas do FPGA
    // =========================================================
    SWITCHES meu_switches (
        .Dado_Switches(Dado_Switches_Ext),
        .Saida        (fio_saida_switches)
    );

    // =========================================================
    // Instância do módulo DISPLAY
    // Captura o valor de ROUT na borda de descida quando PortaON=1
    // =========================================================
    DISPLAY meu_display (
        .clk         (clk),
        .PortaON     (fio_portaon),
        .Dado_Display(fio_dado1_out),
        .Saida_Display(Saida_Display_Out)  // conectar aos pinos do FPGA futuramente
    );

endmodule
