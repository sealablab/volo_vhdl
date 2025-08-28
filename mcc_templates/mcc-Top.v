module CustomWrapper (
    input wire Clk,
    input wire Reset,

    input wire signed [15:0] InputA,
    input wire signed [15:0] InputB,
    input wire signed [15:0] InputC,


    output wire signed [15:0] OutputA,
    output wire signed [15:0] OutputB,
    output wire signed [15:0] OutputC,


    input wire [31:0] Control0,
    input wire [31:0] Control1,
    input wire [31:0] Control2,
    input wire [31:0] Control3,
    input wire [31:0] Control4,
    input wire [31:0] Control5,
    input wire [31:0] Control6,
    input wire [31:0] Control7,
    input wire [31:0] Control8,
    input wire [31:0] Control9,
    input wire [31:0] Control10,
    input wire [31:0] Control11,
    input wire [31:0] Control12,
    input wire [31:0] Control13,
    input wire [31:0] Control14,
    input wire [31:0] Control15
);

// _________ <= InputA;
// _________ <= InputB;
// _________ <= InputC;
// _________ <= InputD;

// assign ______ = Control0;
// assign ______ = Control1;
// assign ______ = Control2;
//        ......
// assign ______ = Control15;


// assign OutputA = ______;
// assign OutputB = ______;
// assign OutputC = ______;
// assign OutputD = ______;

endmodule
