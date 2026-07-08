// =====================================================================
//  DECODER_7SEG.v
//  Converte um digito hexadecimal (4 bits) nos 7 segmentos de um
//  display da DE2-115.
//
//  Os displays HEX da DE2-115 sao ATIVO-BAIXO (anodo comum):
//    0 = segmento ACESO   |   1 = segmento APAGADO
//
//  Ordem dos bits: segmentos[6:0] = { g, f, e, d, c, b, a }
//
//         aaa
//        f   b
//        f   b
//         ggg
//        e   c
//        e   c
//         ddd
// =====================================================================
module DECODER_7SEG (
    input  wire [3:0] valor,      // 0x0 .. 0xF
    output reg  [6:0] segmentos   // ativo-baixo
);
    always @(*) begin
        case (valor)
            4'h0: segmentos = 7'b1000000; // 0
            4'h1: segmentos = 7'b1111001; // 1
            4'h2: segmentos = 7'b0100100; // 2
            4'h3: segmentos = 7'b0110000; // 3
            4'h4: segmentos = 7'b0011001; // 4
            4'h5: segmentos = 7'b0010010; // 5
            4'h6: segmentos = 7'b0000010; // 6
            4'h7: segmentos = 7'b1111000; // 7
            4'h8: segmentos = 7'b0000000; // 8
            4'h9: segmentos = 7'b0010000; // 9
            4'hA: segmentos = 7'b0001000; // A
            4'hB: segmentos = 7'b0000011; // b
            4'hC: segmentos = 7'b1000110; // C
            4'hD: segmentos = 7'b0100001; // d
            4'hE: segmentos = 7'b0000110; // E
            4'hF: segmentos = 7'b0001110; // F
            default: segmentos = 7'b1111111; // apagado
        endcase
    end
endmodule
