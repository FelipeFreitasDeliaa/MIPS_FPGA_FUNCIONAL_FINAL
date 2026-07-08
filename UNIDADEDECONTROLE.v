module UNIDADEDECONTROLE (
    input  [5:0] opcode,

    // Controle de fluxo
    output reg        Branch,
    output reg        Jump,
    output reg        JR,
    output reg        HLT,

    // Controle de escrita/leitura
    output reg        RegWrite,
    output reg        RHwrite,
    output reg        RPIwrite,
    output reg        RALwrite,
    output reg        MemWrite,
    output reg        MemRead,

    // Controle dos MUXes de dados
    output reg        MemtoReg,
    output reg        ULASource,
    output reg        Push,
    output reg        Pop,
    output reg        Resp,
    output reg        SwitchesON,
    output reg        PortaON,
    output reg        Pilha,

    // Controle da ULA
    output reg [5:0]  ULAControl,

    // MUXes antes do Banco - Porta 1
    output reg        RD_RS,   // 0=RD, 1=RS (MUX antes de R1esp)
    output reg        R1esp,   // 0=campo instrução, 1=registrador específico
    output reg [5:0]  Reg1,    // endereço do registrador específico para porta 1

    // MUXes antes do Banco - Porta 2
    output reg [1:0]  RD_RS_RT,// 00=RD, 01=RS, 10=RT (MUX antes de R2esp)
    output reg        R2esp,   // 0=campo instrução, 1=registrador específico
    output reg [5:0]  Reg2,    // endereço do registrador específico para porta 2

    // MUX do Registrador de Escrita
    output reg        RWesp,   // 0=RD da instrução, 1=registrador específico
    output reg [5:0]  RegW,    // endereço do registrador específico para escrita

    // MUXes antes do Extensor de Sinal
    output reg        SelImm1, // 0=14bits, 1=20bits
    output reg        SelImm2  // 0=saída MUX anterior, 1=26bits
);

    // Endereços dos registradores específicos
    localparam RZ_ADDR   = 6'd0;
    localparam RIN_ADDR  = 6'd58;
    localparam ROUT_ADDR = 6'd59;
    localparam RL_ADDR   = 6'd60;
    localparam RAL_ADDR  = 6'd61;
    localparam RPI_ADDR  = 6'd62;
    localparam RH_ADDR   = 6'd63;

    // Opcodes
    localparam ADD_OP    = 6'b000000;
    localparam SUB_OP    = 6'b000001;
    localparam MUL_OP    = 6'b000010;
    localparam DIV_OP    = 6'b000011;
    localparam AND_OP    = 6'b000100;
    localparam OR_OP     = 6'b000101;
    localparam NOR_OP    = 6'b000110;
    localparam XNOR_OP   = 6'b000111;
    localparam ADDI_OP   = 6'b001000;
    localparam SUBI_OP   = 6'b001001;
    localparam MULI_OP   = 6'b001010;
    localparam DIVI_OP   = 6'b001011;
    localparam ANDI_OP   = 6'b001100;
    localparam ORI_OP    = 6'b001101;
    localparam SL_OP     = 6'b001110;
    localparam SR_OP     = 6'b001111;
    localparam BEQ_OP    = 6'b010000;
    localparam BNE_OP    = 6'b010001;
    localparam BLT_OP    = 6'b010010;
    localparam BGT_OP    = 6'b010011;
    localparam LOADD_OP  = 6'b010100;
    localparam STORED_OP = 6'b010101;
    localparam LOADR_OP  = 6'b010110;
    localparam STORER_OP = 6'b010111;
    localparam LOADI_OP  = 6'b011000;
    localparam STOREI_OP = 6'b011001;
    localparam MOV_OP    = 6'b011010;
    localparam MOVI_OP   = 6'b011011;
    localparam JMP_OP    = 6'b011100;
    localparam JR_OP     = 6'b011101;
    localparam JAL_OP    = 6'b011110;
    localparam PUSH_OP   = 6'b011111;
    localparam POP_OP    = 6'b100000;
    localparam IN_OP     = 6'b100001;
    localparam OUT_OP    = 6'b100010;
    localparam NOP_OP    = 6'b100011;
    localparam HLT_OP    = 6'b100100;

    always @(*) begin

        // =====================================================
        // Valores padrão — evitam latches e representam estado
        // seguro quando nenhuma instrução válida é decodificada
        // =====================================================
        Branch    = 0; 
		  Jump      = 0; 
		  JR        = 0; 
		  HLT      = 0;
        RegWrite  = 0; 
		  RHwrite   = 0; 
		  RPIwrite  = 0; 
		  RALwrite = 0;
        MemWrite  = 0; 
		  MemRead   = 0;
        MemtoReg  = 0; 
		  ULASource = 0; 
		  Push      = 0; 
		  Pop      = 0;
        Resp      = 0; 
		  SwitchesON= 0; 
		  PortaON   = 0; 
		  Pilha    = 0;
        ULAControl= opcode;
        RD_RS     = 0; 
		  R1esp     = 0; 
		  Reg1      = RZ_ADDR;
        RD_RS_RT  = 2'b00; 
		  R2esp = 0; 
		  Reg2      = RZ_ADDR;
        RWesp     = 0; 
		  RegW      = RZ_ADDR;
        SelImm1   = 0; 
		  SelImm2   = 0;

        case (opcode)

            // =================================================
            // Formato 1: ADD, SUB, AND, OR, NOR, XNOR
            // RD = RS op RT
            // =================================================
            ADD_OP, SUB_OP, AND_OP, OR_OP, NOR_OP, XNOR_OP: begin
                RegWrite  = 1;
                RD_RS     = 1;       // RS → Registrador 1
                R1esp     = 0;
                RD_RS_RT  = 2'b10;  // RT → Registrador 2
                R2esp     = 0;
                RWesp     = 0;       // RD → Registrador de Escrita
                ULASource = 0;       // Dado 2 do banco (RT)
                Resp      = 0;
                MemtoReg  = 0;
                SwitchesON= 0;
            end

            // =================================================
            // Formato 4: MUL, DIV
            // RH, RL = RD op RS
            // =================================================
            MUL_OP, DIV_OP: begin
                RegWrite  = 1;       // escreve RL
                RHwrite   = 1;       // escreve RH
                RD_RS     = 0;       // RD → Registrador 1
                R1esp     = 0;
                RD_RS_RT  = 2'b01;  // RS → Registrador 2
                R2esp     = 0;
                RWesp     = 1;       // RL → Registrador de Escrita
                RegW      = RL_ADDR;
                ULASource = 0;
                Resp      = 0;
                MemtoReg  = 0;
                SwitchesON= 0;
            end

            // =================================================
            // Formato 2: ADDI, SUBI, ANDI, ORI, SL, SR
            // RD = RS op IM14
            // =================================================
            ADDI_OP, SUBI_OP, ANDI_OP, ORI_OP, SL_OP, SR_OP: begin
                RegWrite  = 1;
                RD_RS     = 1;       // RS → Registrador 1
                R1esp     = 0;
                RWesp     = 0;       // RD → Registrador de Escrita
                ULASource = 1;       // Imediato estendido
                SelImm1   = 0;       // seleciona 14 bits
                SelImm2   = 0;
                Resp      = 0;
                MemtoReg  = 0;
                SwitchesON= 0;
            end

            // =================================================
            // Formato 5: MULI, DIVI
            // RH, RL = RD op IM20
            // =================================================
            MULI_OP, DIVI_OP: begin
                RegWrite  = 1;       // escreve RL
                RHwrite   = 1;       // escreve RH
                RD_RS     = 0;       // RD → Registrador 1
                R1esp     = 0;
                RWesp     = 1;       // RL → Registrador de Escrita
                RegW      = RL_ADDR;
                ULASource = 1;       // Imediato estendido
                SelImm1   = 1;       // seleciona 20 bits
                SelImm2   = 0;
                Resp      = 0;
                MemtoReg  = 0;
                SwitchesON= 0;
            end

            // =================================================
            // Formato 3: BEQ, BNE, BLT, BGT
            // if(condição) PC = PC+1+END14
            // =================================================
            BEQ_OP, BNE_OP, BLT_OP, BGT_OP: begin
                Branch    = 1;
                RD_RS     = 1;       // RS → Registrador 1
                R1esp     = 0;
                RD_RS_RT  = 2'b00;  // RD → Registrador 2
                R2esp     = 0;
                ULASource = 0;       // compara Dado1 (RS) com Dado2 (RD)
                SelImm1   = 0;       // END14 para calcular endereço de salto
                SelImm2   = 0;
            end

            // =================================================
            // Formato 3: LOADD
            // RD = MEM(RS + END14)
            // =================================================
            LOADD_OP: begin
                RegWrite  = 1;
                MemRead   = 1;
                MemtoReg  = 1;
                RD_RS     = 1;       // RS → Registrador 1 (base)
                R1esp     = 0;
                RWesp     = 0;       // RD → Registrador de Escrita
                ULASource = 1;       // END14 estendido
                SelImm1   = 0;       // seleciona 14 bits
                SelImm2   = 0;
                SwitchesON= 0;
            end

            // =================================================
            // Formato 3: STORED
            // MEM(RS + END14) = RD
            // =================================================
            STORED_OP: begin
                MemWrite  = 1;
                RD_RS     = 1;       // RS → Registrador 1 (base)
                R1esp     = 0;
                RD_RS_RT  = 2'b00;  // RD → Registrador 2 (dado a salvar)
                R2esp     = 0;
                ULASource = 1;       // END14 estendido
                SelImm1   = 0;       // seleciona 14 bits
                SelImm2   = 0;
            end

            // =================================================
            // Formato 4: LOADR
            // RD = MEM(RS)
            // =================================================
            LOADR_OP: begin
                RegWrite  = 1;
                MemRead   = 1;
                MemtoReg  = 1;
                RD_RS     = 1;       // RS → Registrador 1
                R1esp     = 0;
                R2esp     = 1;       // RZ → Registrador 2 (endereço = RS+0)
                Reg2      = RZ_ADDR;
                RWesp     = 0;       // RD → Registrador de Escrita
                ULASource = 0;       // Dado2 = RZ (soma RS+0)
                Resp      = 0;
                SwitchesON= 0;
            end

            // =================================================
            // Formato 4: STORER
            // MEM(RS) = RD
            // =================================================
            STORER_OP: begin
                MemWrite  = 1;
                RD_RS     = 1;       // RS → Registrador 1 (endereço)
                R1esp     = 0;
                RD_RS_RT  = 2'b00;  // RD → Registrador 2 (dado a salvar)
                R2esp     = 0;
                ULASource = 0;
                Resp      = 1;       // força RZ na entrada B da ULA (endereço = RS+0)
            end

            // =================================================
            // Formato 6: LOADI
            // RD = MEM(END20)
            // =================================================
            LOADI_OP: begin
                RegWrite  = 1;
                MemRead   = 1;
                MemtoReg  = 1;
                R1esp     = 1;       // RZ → Registrador 1
                Reg1      = RZ_ADDR;
                RWesp     = 0;       // RD → Registrador de Escrita
                ULASource = 1;       // END20 estendido
                SelImm1   = 1;       // seleciona 20 bits
                SelImm2   = 0;
                SwitchesON= 0;
            end

            // =================================================
            // Formato 6: STOREI
            // MEM(END20) = RD
            // =================================================
            STOREI_OP: begin
                MemWrite  = 1;
                R1esp     = 1;       // RZ → Registrador 1
                Reg1      = RZ_ADDR;
                RD_RS_RT  = 2'b00;  // RD → Registrador 2 (dado a salvar)
                R2esp     = 0;
                ULASource = 1;       // END20 estendido
                SelImm1   = 1;       // seleciona 20 bits
                SelImm2   = 0;
            end

            // =================================================
            // Formato 4: MOV
            // RD = RS
            // =================================================
            MOV_OP: begin
                RegWrite  = 1;
                RD_RS     = 1;       // RS → Registrador 1
                R1esp     = 0;
                R2esp     = 1;       // RZ → Registrador 2 (RS + 0 = RS)
                Reg2      = RZ_ADDR;
                RWesp     = 0;       // RD → Registrador de Escrita
                ULASource = 0;
                Resp      = 0;
                MemtoReg  = 0;
                SwitchesON= 0;
            end

            // =================================================
            // Formato 5: MOVI
            // RD = IM20
            // =================================================
            MOVI_OP: begin
                RegWrite  = 1;
                R1esp     = 1;       // RZ → Registrador 1 (0 + IM20 = IM20)
                Reg1      = RZ_ADDR;
                RWesp     = 0;       // RD → Registrador de Escrita
                ULASource = 1;       // IM20 estendido
                SelImm1   = 1;       // seleciona 20 bits
                SelImm2   = 0;
                Resp      = 0;
                MemtoReg  = 0;
                SwitchesON= 0;
            end

            // =================================================
            // Formato 8: JMP
            // PC = END26
            // =================================================
            JMP_OP: begin
                Jump      = 1;
                SelImm2   = 1;       // seleciona 26 bits para o PC
            end

            // =================================================
            // Formato 7: JR
            // PC = RD
            // =================================================
            JR_OP: begin
                JR        = 1;
                RD_RS     = 0;       // RD → Registrador 1 (contém o endereço)
                R1esp     = 0;
            end

            // =================================================
            // Formato 8: JAL
            // RAL = PC+1 ; PC = END26
            // =================================================
            JAL_OP: begin
                Jump      = 1;
                RALwrite  = 1;       // salva PC+1 em RAL
                SelImm2   = 1;       // seleciona 26 bits para o PC
            end

            // =================================================
            // Formato 7: PUSH
            // PILHA(+RPI) = RD ; RPI = RPI+1
            // =================================================
            PUSH_OP: begin
                Pilha     = 1;       // acessa memória da pilha
                MemWrite  = 1;       // escreve na pilha
                RPIwrite  = 1;       // atualiza RPI para RPI+1
                R1esp     = 1;       // RPI → Registrador 1
                Reg1      = RPI_ADDR;
                RD_RS_RT  = 2'b00;  // RD → Registrador 2 (dado a empilhar)
                R2esp     = 0;
                ULASource = 1;       // seleciona saída do MUX Push
                Push      = 1;       // força constante 1 antes da ULA (RPI+1)
                MemtoReg  = 0;
                SwitchesON= 0;
            end

            // =================================================
            // Formato 7: POP
            // RD = PILHA(RPI) ; RPI = RPI-1
            // =================================================
            POP_OP: begin
                Pilha     = 1;       // acessa memória da pilha
                RegWrite  = 1;       // escreve RD
                RPIwrite  = 1;       // atualiza RPI para RPI-1
                Pop       = 1;       // ativa subtrator dedicado (RPI-1)
                MemRead   = 1;       // lê da pilha
                MemtoReg  = 1;       // dado lido da memória vai para o banco
                R1esp     = 1;       // RPI → Registrador 1 (endereço do topo)
                Reg1      = RPI_ADDR;
                R2esp     = 1;       // RZ → Registrador 2 (RPI+0 = RPI)
                Reg2      = RZ_ADDR;
                RWesp     = 0;       // RD → Registrador de Escrita
                ULASource = 0;
                SwitchesON= 0;
            end

            // =================================================
            // Formato 9: IN
            // RIN = SWITCH
            // =================================================
            IN_OP: begin
                RegWrite  = 1;
                SwitchesON= 1;       // dado vem dos switches
                RWesp     = 1;       // RIN → Registrador de Escrita
                RegW      = RIN_ADDR;
            end

            // =================================================
            // Formato 10: OUT
            // DISPLAY = ROUT
            // =================================================
            OUT_OP: begin
                PortaON   = 1;       // habilita o display
                R1esp     = 1;       // ROUT → Registrador 1
                Reg1      = ROUT_ADDR;
            end

            // =================================================
            // Formato 11: NOP
            // Aguarda um ciclo — todos os sinais permanecem em 0
            // =================================================
            NOP_OP: begin
                // todos os sinais já estão em 0 pelos valores padrão
            end

            // =================================================
            // Formato 11: HLT
            // Para o processador — PC não é mais atualizado
            // =================================================
            HLT_OP: begin
                HLT = 1;
            end

            default: begin
                // estado seguro — todos os sinais em 0
            end

        endcase
    end

endmodule
